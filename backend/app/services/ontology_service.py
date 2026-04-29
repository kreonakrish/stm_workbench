"""Ontology service — assembles the metagraph and serves typeahead search.

Used by the schema-visualization endpoint to power the Ontology page.
Sources:
  - SHOW INDEXES → schema-defined labels and their indexed/unique properties.
  - MATCH (n) UNWIND labels(n) → live node counts per label.
  - MATCH ()-[r]->() → live relationship summary (type, count, label pairs).

Schema-only labels (declared via constraints/indexes but with no instance
data yet — the case immediately after migration 003) appear in the
response with count=0; this is intentional so the UI can show the full
ontology shape before any crawls have populated it.
"""
from __future__ import annotations

import base64

import structlog

from app.config import get_settings
from app.domain.ontology import (
    LabelSchema,
    OntologySchema,
    PropertySchema,
    RelationshipSchema,
)
from app.domain.ontology_search import SearchHit, SearchResponse
from app.graph.driver import get_driver
from app.graph.queries import get_query

logger = structlog.get_logger(__name__)


def _encode_cursor(offset: int) -> str:
    return base64.urlsafe_b64encode(str(offset).encode()).decode().rstrip("=")


def _decode_cursor(cursor: str) -> int:
    pad = "=" * (-len(cursor) % 4)
    return int(base64.urlsafe_b64decode((cursor + pad).encode()).decode())


class OntologyService:
    async def get_schema(self) -> OntologySchema:
        driver = get_driver()
        async with driver.session(database=get_settings().neo4j_database) as session:
            indexes_result = await session.run(get_query("ontology_show_indexes"))
            index_rows = [record.data() async for record in indexes_result]

            counts_result = await session.run(get_query("ontology_label_counts"))
            counts: dict[str, int] = {}
            async for record in counts_result:
                counts[record["label"]] = record["count"]

            rels_result = await session.run(get_query("ontology_relationship_summary"))
            relationships: list[RelationshipSchema] = []
            async for record in rels_result:
                relationships.append(
                    RelationshipSchema(
                        type=record["type"],
                        count=record["count"],
                        start_labels=sorted(set(record["start_labels"] or [])),
                        end_labels=sorted(set(record["end_labels"] or [])),
                    )
                )

        labels = self._merge_label_schema(index_rows, counts)
        logger.info(
            "ontology_schema_assembled",
            label_count=len(labels),
            relationship_count=len(relationships),
        )
        return OntologySchema(labels=labels, relationships=relationships)

    @staticmethod
    def _merge_label_schema(
        index_rows: list[dict], counts: dict[str, int]
    ) -> list[LabelSchema]:
        """Merge index/constraint rows + live counts into per-label schema.

        Each label collects:
          - all properties referenced by any index targeting it
          - whether the property is unique (constraint-backed)
          - the live node count (0 if none)
        """
        # label -> property_name -> PropertySchema (mutated as we accumulate)
        per_label: dict[str, dict[str, PropertySchema]] = {}

        for row in index_rows:
            for label in row.get("labels") or []:
                props_for_label = per_label.setdefault(label, {})
                is_unique = bool(row.get("owningConstraint"))
                for prop_name in row.get("properties") or []:
                    existing = props_for_label.get(prop_name)
                    if existing is None:
                        props_for_label[prop_name] = PropertySchema(
                            name=prop_name,
                            indexed=True,
                            unique=is_unique,
                        )
                    else:
                        existing.indexed = True
                        if is_unique:
                            existing.unique = True

        # Fold in any labels that have data but no schema (e.g. crawler-discovered)
        for label in counts:
            per_label.setdefault(label, {})

        return [
            LabelSchema(
                name=label,
                count=counts.get(label, 0),
                properties=sorted(props.values(), key=lambda p: p.name),
            )
            for label, props in sorted(per_label.items())
        ]


    async def list_entities(self) -> list[dict]:
        """All curated entities with attribute counts. Used by the entity-picker."""
        driver = get_driver()
        async with driver.session(database=get_settings().neo4j_database) as session:
            result = await session.run(get_query("list_entities"))
            return [r.data() async for r in result]

    async def get_catalog(self) -> list[dict]:
        """Hierarchical catalog: entity → attributes → physical sources.

        One entry per Entity, each containing its sorted list of
        BusinessAttributes, each with the physical PhysicalColumn rows
        that source it (de-duplicated, ordered by system / table / column).
        """
        driver = get_driver()
        async with driver.session(database=get_settings().neo4j_database) as session:
            result = await session.run(get_query("get_ontology_catalog"))
            rows = [r.data() async for r in result]

        entities: dict[str, dict] = {}
        for row in rows:
            entity_name = row["entity"]
            entity = entities.setdefault(
                entity_name,
                {
                    "name": entity_name,
                    "description": row.get("entity_description"),
                    "attributes": {},
                },
            )
            attribute_id = row.get("attribute_id")
            if not attribute_id:
                continue
            attribute = entity["attributes"].setdefault(
                attribute_id,
                {
                    "id": attribute_id,
                    "name": row.get("attribute_name"),
                    "description": row.get("attribute_description"),
                    "data_type": row.get("attribute_data_type"),
                    "pii_classification": row.get("pii_classification"),
                    "is_key": bool(row.get("is_key")),
                    "sources": [],
                },
            )
            column_id = row.get("column_id")
            if column_id:
                attribute["sources"].append(
                    {
                        "system_id": row.get("system_id"),
                        "system_name": row.get("system_name"),
                        "system_kind": row.get("system_kind"),
                        "schema": row.get("source_schema"),
                        "table": row.get("source_table"),
                        "column": row.get("column_name"),
                        "column_id": column_id,
                        "data_type": row.get("column_data_type"),
                    }
                )

        catalog: list[dict] = []
        for name in sorted(entities):
            entity = entities[name]
            attributes = sorted(
                entity["attributes"].values(),
                key=lambda a: (not a.get("is_key"), a.get("name") or ""),
            )
            catalog.append(
                {
                    "name": entity["name"],
                    "description": entity["description"],
                    "attribute_count": len(attributes),
                    "attributes": attributes,
                }
            )
        return catalog

    async def list_attributes(self, entity: str) -> list[dict]:
        """All BusinessAttributes attached to a given entity."""
        driver = get_driver()
        async with driver.session(database=get_settings().neo4j_database) as session:
            result = await session.run(
                get_query("list_attributes_for_entity"), entity=entity
            )
            return [r.data() async for r in result]

    async def search(
        self, *, query: str, cursor: str | None = None, limit: int = 20
    ) -> SearchResponse:
        """Typeahead over curated :BusinessAttribute and :Entity nodes.

        Empty query returns no hits. Ranking: exact > prefix > substring on
        the attribute / entity name. Attribute hits beat entity hits within
        the same tier; key-flagged attributes rank slightly higher.
        """
        if not query.strip():
            return SearchResponse(hits=[], next_cursor=None)

        q = query.strip().lower()
        driver = get_driver()
        async with driver.session(database=get_settings().neo4j_database) as session:
            result = await session.run(
                get_query("ontology_search_attributes"), q=q
            )
            raw = [r.data() async for r in result]

        hits = self._rank_hits(raw, q)
        offset = _decode_cursor(cursor) if cursor else 0
        page = hits[offset : offset + limit]
        next_offset = offset + limit
        next_cursor = _encode_cursor(next_offset) if next_offset < len(hits) else None
        return SearchResponse(hits=page, next_cursor=next_cursor)

    @staticmethod
    def _rank_hits(rows: list[dict], q: str) -> list[SearchHit]:
        """Score (entity, attribute) pairs and return them in best-first order."""

        def score(s: str | None, term: str) -> int | None:
            if not s:
                return None
            s = s.lower()
            if s == term:
                return 0
            if s.startswith(term):
                return 1
            if term in s:
                return 2
            return None

        scored: list[tuple[int, str, SearchHit]] = []
        for row in rows:
            entity = row.get("entity")
            if not entity:
                continue
            attribute = row.get("attribute")
            if attribute:
                s = score(attribute, q)
                if s is None:
                    continue
                bonus = -1 if row.get("is_key") else 0
                display = f"{entity}.{attribute}"
                scored.append(
                    (
                        s * 2 + bonus,
                        display,
                        SearchHit(
                            label=entity,
                            property=attribute,
                            display=display,
                            unique=bool(row.get("is_key")),
                        ),
                    )
                )
            else:
                s = score(entity, q)
                if s is None:
                    continue
                scored.append(
                    (
                        s * 2 + 10,  # entity hits ranked below attribute hits
                        entity,
                        SearchHit(label=entity, display=entity),
                    )
                )
        scored.sort(key=lambda t: (t[0], t[1]))
        # Dedupe on display in case the cypher UNION emitted duplicates
        seen: set[str] = set()
        out: list[SearchHit] = []
        for _, display, hit in scored:
            if display in seen:
                continue
            seen.add(display)
            out.append(hit)
        return out


def get_ontology_service() -> OntologyService:
    return OntologyService()
