"""Validation service — classifies a ChangeLine against the ontology and
external catalog.

Each change line gets:
  1. classification (exists / net_new / needs_change / invalid),
  2. existing physical sources for any referenced ontology attribute,
  3. catalog confirmation for any user-supplied source location.

Classification semantics, by category:

  DDL
    ADD_COLUMN     — exists if (entity, target_attribute) already in
                     ontology; net_new otherwise.
    MODIFY_COLUMN  — needs_change if attribute exists; invalid otherwise.
    DROP_COLUMN    — needs_change if attribute exists; invalid otherwise.
    ADD_TABLE      — net_new (unless target_table matches a known dataset
                     — checked by catalog).
    DROP_TABLE     — needs_change (table existence is a catalog concern,
                     not an ontology one).

  DML
    BACKFILL / DATA_CORRECTION / DELETE_HISTORICAL — needs_change.
    Operate on existing tables; if the target_attribute is set and not
    found, classify invalid so users notice typos.

  ETL_LOGIC
    NEW_MAPPING                 — net_new.
    MODIFY_MAPPING              — needs_change if target attribute
                                  exists; invalid otherwise.
    MODIFY_TRANSFORMATION /
      MODIFY_FILTER /
      MODIFY_AGGREGATION /
      MODIFY_JOIN               — needs_change; transformation_logic
                                  required.
"""
from __future__ import annotations

from uuid import uuid4

import structlog

from app.config import get_settings
from app.domain.requests import (
    ChangeAction,
    ChangeCategory,
    ChangeLine,
    ChangeLineInput,
    Classification,
)
from app.graph.driver import get_driver
from app.graph.queries import get_query
from app.services.catalog_client import CatalogClient, get_catalog_client

logger = structlog.get_logger(__name__)


class ValidationService:
    def __init__(self, catalog: CatalogClient) -> None:
        self._catalog = catalog

    async def classify_all(
        self, *, request_id: str, items: list[ChangeLineInput]
    ) -> list[ChangeLine]:
        return [await self._classify_one(request_id, item) for item in items]

    async def _classify_one(
        self, request_id: str, item: ChangeLineInput
    ) -> ChangeLine:
        classification, reason = await self._classify(item)
        existing_sources = await self._lookup_sources(item)
        catalog_verified = await self._verify_catalog(item)

        return ChangeLine(
            id=uuid4(),
            request_id=request_id,
            category=item.category,
            action=item.action,
            pipeline_layer=item.pipeline_layer,
            entity=item.entity,
            target_attribute=item.target_attribute,
            target_dataset=item.target_dataset,
            target_table=item.target_table,
            target_column=item.target_column,
            target_data_type=item.target_data_type,
            target_nullable=item.target_nullable,
            source_system=item.source_system,
            source_dataset=item.source_dataset,
            source_table=item.source_table,
            source_column=item.source_column,
            transformation_logic=item.transformation_logic,
            business_definition=item.business_definition,
            rationale=item.rationale,
            impact_notes=item.impact_notes,
            classification=classification,
            classification_reason=reason,
            catalog_verified=catalog_verified,
            existing_sources=existing_sources,
        )

    async def _classify(
        self, item: ChangeLineInput
    ) -> tuple[Classification, str]:
        # First: refuse action/category mismatches.
        if not _action_matches_category(item.category, item.action):
            return (
                Classification.INVALID,
                f"action '{item.action.value}' is not valid under category '{item.category.value}'",
            )

        # DDL
        if item.action == ChangeAction.ADD_COLUMN:
            if not item.target_attribute:
                return Classification.INVALID, "add_column requires target_attribute"
            if not item.target_data_type:
                return Classification.INVALID, "add_column requires target_data_type"
            if await self._attribute_exists(item.entity, item.target_attribute):
                return (
                    Classification.EXISTS,
                    f"{item.entity}.{item.target_attribute} already exists in the ontology — link instead of adding",
                )
            return (
                Classification.NET_NEW,
                f"{item.entity}.{item.target_attribute} is new — will be added on approval",
            )

        if item.action == ChangeAction.MODIFY_COLUMN:
            if not item.target_attribute:
                return Classification.INVALID, "modify_column requires target_attribute"
            if not await self._attribute_exists(item.entity, item.target_attribute):
                return (
                    Classification.INVALID,
                    f"Cannot modify {item.entity}.{item.target_attribute} — attribute does not exist",
                )
            return (
                Classification.NEEDS_CHANGE,
                f"Column modification proposed for {item.entity}.{item.target_attribute}",
            )

        if item.action == ChangeAction.DROP_COLUMN:
            if not item.target_attribute:
                return Classification.INVALID, "drop_column requires target_attribute"
            if not await self._attribute_exists(item.entity, item.target_attribute):
                return (
                    Classification.INVALID,
                    f"Cannot drop {item.entity}.{item.target_attribute} — attribute does not exist",
                )
            return (
                Classification.NEEDS_CHANGE,
                f"Column drop proposed for {item.entity}.{item.target_attribute}",
            )

        if item.action == ChangeAction.ADD_TABLE:
            if not item.target_table:
                return Classification.INVALID, "add_table requires target_table"
            return (
                Classification.NET_NEW,
                f"New table '{item.target_table}' will be added on approval",
            )

        if item.action == ChangeAction.DROP_TABLE:
            if not item.target_table:
                return Classification.INVALID, "drop_table requires target_table"
            return (
                Classification.NEEDS_CHANGE,
                f"Table '{item.target_table}' will be dropped on approval",
            )

        # DML
        if item.action in (
            ChangeAction.BACKFILL,
            ChangeAction.DATA_CORRECTION,
            ChangeAction.DELETE_HISTORICAL,
        ):
            if (
                item.target_attribute
                and not await self._attribute_exists(item.entity, item.target_attribute)
            ):
                return (
                    Classification.INVALID,
                    f"DML target {item.entity}.{item.target_attribute} does not exist",
                )
            if not item.rationale:
                return (
                    Classification.INVALID,
                    f"{item.action.value} requires a rationale",
                )
            return (
                Classification.NEEDS_CHANGE,
                f"{item.action.value.replace('_', ' ').title()} on existing data",
            )

        # ETL Logic
        if item.action == ChangeAction.NEW_MAPPING:
            if not item.target_attribute:
                return Classification.INVALID, "new_mapping requires target_attribute"
            return (
                Classification.NET_NEW,
                f"New mapping for {item.entity}.{item.target_attribute}",
            )

        if item.action == ChangeAction.MODIFY_MAPPING:
            if not item.target_attribute:
                return Classification.INVALID, "modify_mapping requires target_attribute"
            if not await self._attribute_exists(item.entity, item.target_attribute):
                return (
                    Classification.INVALID,
                    f"Cannot modify mapping — {item.entity}.{item.target_attribute} does not exist",
                )
            return (
                Classification.NEEDS_CHANGE,
                f"Mapping update for {item.entity}.{item.target_attribute}",
            )

        if item.action in (
            ChangeAction.MODIFY_TRANSFORMATION,
            ChangeAction.MODIFY_FILTER,
            ChangeAction.MODIFY_AGGREGATION,
            ChangeAction.MODIFY_JOIN,
        ):
            if not item.transformation_logic:
                return (
                    Classification.INVALID,
                    f"{item.action.value} requires transformation_logic",
                )
            if (
                item.target_attribute
                and not await self._attribute_exists(item.entity, item.target_attribute)
            ):
                return (
                    Classification.INVALID,
                    f"Target {item.entity}.{item.target_attribute} does not exist",
                )
            label = item.action.value.replace("_", " ").title()
            return (
                Classification.NEEDS_CHANGE,
                f"{label} for {item.entity}"
                + (f".{item.target_attribute}" if item.target_attribute else ""),
            )

        return Classification.INVALID, f"Unhandled action: {item.action.value}"

    async def _attribute_exists(self, entity: str, attribute: str) -> bool:
        driver = get_driver()
        async with driver.session(database=get_settings().neo4j_database) as session:
            result = await session.run(
                get_query("check_attribute_exists"),
                entity=entity,
                attribute=attribute,
            )
            record = await result.single()
        return record is not None

    async def _lookup_sources(self, item: ChangeLineInput) -> list[str]:
        if not item.target_attribute:
            return []
        driver = get_driver()
        async with driver.session(database=get_settings().neo4j_database) as session:
            result = await session.run(
                get_query("get_attribute_sources"),
                entity=item.entity,
                attribute=item.target_attribute,
            )
            return [record["column_id"] async for record in result]

    async def _verify_catalog(self, item: ChangeLineInput) -> bool | None:
        if not (item.source_system and item.source_table and item.source_column):
            return None
        v = await self._catalog.verify_column(
            system_id=item.source_system,
            schema=item.source_dataset,
            table=item.source_table,
            column=item.source_column,
        )
        return v.found


# ---------------------------------------------------------------
# Action ↔ category consistency
# ---------------------------------------------------------------

_DDL_ACTIONS = {
    ChangeAction.ADD_TABLE,
    ChangeAction.DROP_TABLE,
    ChangeAction.ADD_COLUMN,
    ChangeAction.DROP_COLUMN,
    ChangeAction.MODIFY_COLUMN,
}
_DML_ACTIONS = {
    ChangeAction.BACKFILL,
    ChangeAction.DATA_CORRECTION,
    ChangeAction.DELETE_HISTORICAL,
}
_ETL_ACTIONS = {
    ChangeAction.NEW_MAPPING,
    ChangeAction.MODIFY_MAPPING,
    ChangeAction.MODIFY_TRANSFORMATION,
    ChangeAction.MODIFY_FILTER,
    ChangeAction.MODIFY_AGGREGATION,
    ChangeAction.MODIFY_JOIN,
}


def _action_matches_category(category: ChangeCategory, action: ChangeAction) -> bool:
    if category == ChangeCategory.DDL:
        return action in _DDL_ACTIONS
    if category == ChangeCategory.DML:
        return action in _DML_ACTIONS
    if category == ChangeCategory.ETL_LOGIC:
        return action in _ETL_ACTIONS
    return False


def get_validation_service() -> ValidationService:
    return ValidationService(catalog=get_catalog_client())
