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


    async def search(
        self, *, query: str, cursor: str | None = None, limit: int = 20
    ) -> SearchResponse:
        """Typeahead over labels and their indexed properties.

        Empty query returns no hits. Ranking: exact > prefix > substring on
        property name first, then the same on label name. Properties with
        unique-key constraints rank slightly higher within their tier.
        """
        if not query.strip():
            return SearchResponse(hits=[], next_cursor=None)

        schema = await self.get_schema()
        hits = self._rank_hits(schema, query.strip().lower())

        offset = _decode_cursor(cursor) if cursor else 0
        page = hits[offset : offset + limit]
        next_offset = offset + limit
        next_cursor = _encode_cursor(next_offset) if next_offset < len(hits) else None
        return SearchResponse(hits=page, next_cursor=next_cursor)

    @staticmethod
    def _rank_hits(schema: OntologySchema, q: str) -> list[SearchHit]:
        """Score every (label, property) pair against `q` and return ordered hits.

        Lower score = better match. Properties beat labels when the user is
        looking for a field. Within each tier, exact match wins, then prefix,
        then substring.
        """

        def score_string(s: str, term: str) -> int | None:
            s = s.lower()
            if s == term:
                return 0
            if s.startswith(term):
                return 1
            if term in s:
                return 2
            return None

        scored: list[tuple[int, str, SearchHit]] = []
        for label in schema.labels:
            for prop in label.properties:
                ps = score_string(prop.name, q)
                if ps is not None:
                    bonus = -1 if prop.unique else 0
                    scored.append(
                        (
                            ps * 2 + bonus,
                            f"{label.name}.{prop.name}",
                            SearchHit(
                                label=label.name,
                                property=prop.name,
                                display=f"{label.name}.{prop.name}",
                                unique=prop.unique,
                            ),
                        )
                    )
            ls = score_string(label.name, q)
            if ls is not None:
                scored.append(
                    (
                        ls * 2 + 10,  # property hits beat label hits
                        label.name,
                        SearchHit(label=label.name, display=label.name),
                    )
                )
        scored.sort(key=lambda t: (t[0], t[1]))
        return [hit for _, _, hit in scored]


def get_ontology_service() -> OntologyService:
    return OntologyService()
