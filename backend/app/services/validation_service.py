"""Validation service — classifies a ChangeLine (and each of its target
columns) against the ontology + external catalog.

Each line's `target_columns` carries its own per-column classification.
The line-level classification is the worst-case roll-up:

    invalid > needs_change > net_new > exists

Line-level rules (no columns):
  ADD_TABLE / DROP_TABLE — table-level actions; net_new / needs_change
  BACKFILL / DATA_CORRECTION / DELETE_HISTORICAL — needs_change, requires
    `rationale`; if `target_columns` is given, every column must exist.
  ETL_LOGIC actions — require `transformation_logic`; if columns are
    listed, every listed column must exist (modifying a column we don't
    know about is invalid).

Column-level rules (DDL ADD/DROP/MODIFY_COLUMN, NEW_MAPPING,
MODIFY_MAPPING):
  ADD_COLUMN / NEW_MAPPING — column exists in ontology → exists; else
    net_new. data_type required for ADD_COLUMN.
  DROP_COLUMN / MODIFY_COLUMN / MODIFY_MAPPING — column must exist
    (needs_change). Missing → invalid.
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
    ClassifiedColumn,
    Classification,
    TargetColumnSpec,
)
from app.graph.driver import get_driver
from app.graph.queries import get_query
from app.services.catalog_client import CatalogClient, get_catalog_client

logger = structlog.get_logger(__name__)


_RANK = {
    Classification.INVALID: 3,
    Classification.NEEDS_CHANGE: 2,
    Classification.NET_NEW: 1,
    Classification.EXISTS: 0,
}


def _worst(classifications: list[Classification]) -> Classification:
    if not classifications:
        return Classification.NET_NEW
    return max(classifications, key=lambda c: _RANK[c])


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
        if not _action_matches_category(item.category, item.action):
            return self._invalid_line(
                request_id,
                item,
                f"action '{item.action.value}' is not valid under category '{item.category.value}'",
            )

        column_results = await self._classify_columns(item)
        line_classification, line_reason = await self._classify_line(item, column_results)

        catalog_verified = await self._verify_catalog(item)

        return ChangeLine(
            id=uuid4(),
            request_id=request_id,
            category=item.category,
            action=item.action,
            pipeline_layer=item.pipeline_layer,
            entity=item.entity,
            target_columns=column_results,
            target_dataset=item.target_dataset,
            target_table=item.target_table,
            source_system=item.source_system,
            source_dataset=item.source_dataset,
            source_table=item.source_table,
            source_column=item.source_column,
            transformation_logic=item.transformation_logic,
            rationale=item.rationale,
            impact_notes=item.impact_notes,
            classification=line_classification,
            classification_reason=line_reason,
            catalog_verified=catalog_verified,
        )

    async def _classify_columns(
        self, item: ChangeLineInput
    ) -> list[ClassifiedColumn]:
        results: list[ClassifiedColumn] = []
        for spec in item.target_columns:
            classification, reason = await self._classify_column(item, spec)
            sources = (
                await self._lookup_sources(item.entity, spec.attribute)
                if spec.attribute
                else []
            )
            results.append(
                ClassifiedColumn(
                    id=uuid4(),
                    attribute=spec.attribute,
                    data_type=spec.data_type,
                    nullable=spec.nullable,
                    business_definition=spec.business_definition,
                    classification=classification,
                    classification_reason=reason,
                    existing_sources=sources,
                )
            )
        return results

    async def _classify_column(
        self, item: ChangeLineInput, spec: TargetColumnSpec
    ) -> tuple[Classification, str]:
        if not spec.attribute:
            return Classification.INVALID, "Column requires an attribute name"

        action = item.action
        exists = await self._attribute_exists(item.entity, spec.attribute)

        if action in (ChangeAction.ADD_COLUMN, ChangeAction.NEW_MAPPING):
            if action == ChangeAction.ADD_COLUMN and not spec.data_type:
                return (
                    Classification.INVALID,
                    f"{spec.attribute}: add_column requires a data_type",
                )
            if exists:
                return (
                    Classification.EXISTS,
                    f"{item.entity}.{spec.attribute} already exists in the ontology — link instead of adding",
                )
            return (
                Classification.NET_NEW,
                f"{item.entity}.{spec.attribute} is new — will be added on approval",
            )

        if action in (
            ChangeAction.DROP_COLUMN,
            ChangeAction.MODIFY_COLUMN,
            ChangeAction.MODIFY_MAPPING,
        ):
            if not exists:
                return (
                    Classification.INVALID,
                    f"{item.entity}.{spec.attribute} does not exist in the ontology",
                )
            return (
                Classification.NEEDS_CHANGE,
                f"{item.entity}.{spec.attribute} will be modified",
            )

        # DML / table-level / non-column-attribute ETL actions can still list
        # affected columns. Each must exist (else flag invalid) but the line-
        # level rule decides whether it's needs_change or net_new.
        if not exists:
            return (
                Classification.INVALID,
                f"{item.entity}.{spec.attribute} does not exist in the ontology",
            )
        return (
            Classification.NEEDS_CHANGE,
            f"{item.entity}.{spec.attribute} affected by this change",
        )

    async def _classify_line(
        self,
        item: ChangeLineInput,
        column_results: list[ClassifiedColumn],
    ) -> tuple[Classification, str]:
        # 1. Column-level actions: at least one column required, then roll up.
        column_required = item.action in (
            ChangeAction.ADD_COLUMN,
            ChangeAction.DROP_COLUMN,
            ChangeAction.MODIFY_COLUMN,
            ChangeAction.NEW_MAPPING,
            ChangeAction.MODIFY_MAPPING,
        )
        if column_required and not column_results:
            return (
                Classification.INVALID,
                f"{item.action.value} requires at least one target column",
            )
        if column_required:
            rolled = _worst([c.classification for c in column_results])
            return rolled, _summary_reason(item, rolled, column_results)

        # 2. Table-level DDL.
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

        # 3. DML.
        if item.action in (
            ChangeAction.BACKFILL,
            ChangeAction.DATA_CORRECTION,
            ChangeAction.DELETE_HISTORICAL,
        ):
            if not item.rationale:
                return (
                    Classification.INVALID,
                    f"{item.action.value} requires a rationale",
                )
            if column_results:
                rolled = _worst([c.classification for c in column_results])
                # Even with all columns valid, DML is never net_new — coerce
                # to needs_change.
                if rolled in (Classification.NET_NEW, Classification.EXISTS):
                    rolled = Classification.NEEDS_CHANGE
                return rolled, _summary_reason(item, rolled, column_results)
            return (
                Classification.NEEDS_CHANGE,
                f"{item.action.value.replace('_', ' ').title()} on existing data",
            )

        # 4. Other ETL-Logic actions (modify_transformation / filter /
        #    aggregation / join). transformation_logic required.
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
            if column_results:
                rolled = _worst([c.classification for c in column_results])
                return rolled, _summary_reason(item, rolled, column_results)
            return (
                Classification.NEEDS_CHANGE,
                f"{item.action.value.replace('_', ' ').title()} for {item.entity}",
            )

        return Classification.INVALID, f"Unhandled action: {item.action.value}"

    @staticmethod
    def _invalid_line(
        request_id: str, item: ChangeLineInput, reason: str
    ) -> ChangeLine:
        return ChangeLine(
            id=uuid4(),
            request_id=request_id,
            category=item.category,
            action=item.action,
            pipeline_layer=item.pipeline_layer,
            entity=item.entity,
            target_columns=[],
            target_dataset=item.target_dataset,
            target_table=item.target_table,
            source_system=item.source_system,
            source_dataset=item.source_dataset,
            source_table=item.source_table,
            source_column=item.source_column,
            transformation_logic=item.transformation_logic,
            rationale=item.rationale,
            impact_notes=item.impact_notes,
            classification=Classification.INVALID,
            classification_reason=reason,
            catalog_verified=None,
        )

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

    async def _lookup_sources(self, entity: str, attribute: str) -> list[str]:
        driver = get_driver()
        async with driver.session(database=get_settings().neo4j_database) as session:
            result = await session.run(
                get_query("get_attribute_sources"),
                entity=entity,
                attribute=attribute,
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


def _summary_reason(
    item: ChangeLineInput,
    rolled: Classification,
    columns: list[ClassifiedColumn],
) -> str:
    counts: dict[str, int] = {}
    for c in columns:
        counts[c.classification.value] = counts.get(c.classification.value, 0) + 1
    if rolled == Classification.INVALID:
        return f"{counts.get('invalid', 0)} of {len(columns)} column(s) invalid"
    if len(counts) == 1:
        only = next(iter(counts))
        if only == "exists":
            return f"All {len(columns)} column(s) already exist in the ontology"
        if only == "net_new":
            return f"All {len(columns)} column(s) are net new"
        if only == "needs_change":
            return f"All {len(columns)} column(s) need changes"
    parts = []
    for k in ("exists", "net_new", "needs_change", "invalid"):
        if counts.get(k):
            parts.append(f"{counts[k]} {k.replace('_', ' ')}")
    return ", ".join(parts) if parts else f"{item.action.value} on {item.entity}"


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
