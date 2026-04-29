"""Ontology service — assembles the metagraph response from Neo4j metadata.

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

import structlog

from app.config import get_settings
from app.domain.ontology import (
    LabelSchema,
    OntologySchema,
    PropertySchema,
    RelationshipSchema,
)
from app.graph.driver import get_driver
from app.graph.queries import get_query

logger = structlog.get_logger(__name__)


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


def get_ontology_service() -> OntologyService:
    return OntologyService()
