"""Validation service — classifies a ChangeLine against the ontology and
external catalog.

For each ChangeLine, the service answers four questions:
  1. Does the target (entity+attribute or entity+table) already exist?
  2. Where does it physically live, if anywhere?
  3. Does the catalog confirm any user-supplied physical source?
  4. Given the requested change type, what is the correct classification?

Returns an enriched ChangeLine ready to persist.
"""
from __future__ import annotations

from uuid import uuid4

import structlog

from app.config import get_settings
from app.domain.requests import (
    ChangeLine,
    ChangeLineInput,
    ChangeType,
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
        """Classify every item; produce stamped ChangeLine records."""
        return [await self._classify_one(request_id, item) for item in items]

    async def _classify_one(
        self, request_id: str, item: ChangeLineInput
    ) -> ChangeLine:
        classification, reason = await self._classify_type(item)
        existing_sources = await self._lookup_sources(item)
        catalog_verified = await self._verify_catalog(item)

        return ChangeLine(
            id=uuid4(),
            request_id=request_id,
            type=item.type,
            entity=item.entity,
            attribute=item.attribute,
            table=item.table,
            source_system=item.source_system,
            source_table=item.source_table,
            source_column=item.source_column,
            new_logic=item.new_logic,
            business_definition=item.business_definition,
            data_type=item.data_type,
            classification=classification,
            classification_reason=reason,
            catalog_verified=catalog_verified,
            existing_sources=existing_sources,
        )

    async def _classify_type(
        self, item: ChangeLineInput
    ) -> tuple[Classification, str]:
        if item.type == ChangeType.ADD_ATTRIBUTE:
            if not item.attribute:
                return Classification.INVALID, "add_attribute requires an attribute name"
            exists = await self._attribute_exists(item.entity, item.attribute)
            if exists:
                return (
                    Classification.EXISTS,
                    f"{item.entity}.{item.attribute} already exists in the ontology — link instead of adding",
                )
            return (
                Classification.NET_NEW,
                f"{item.entity}.{item.attribute} is new — will be added on approval",
            )

        if item.type == ChangeType.CHANGE_LOGIC:
            if not item.attribute:
                return Classification.INVALID, "change_logic requires an attribute name"
            exists = await self._attribute_exists(item.entity, item.attribute)
            if not exists:
                return (
                    Classification.INVALID,
                    f"Cannot change logic — {item.entity}.{item.attribute} does not exist",
                )
            if not item.new_logic:
                return (
                    Classification.INVALID,
                    "change_logic requires `new_logic` describing the proposed change",
                )
            return (
                Classification.NEEDS_CHANGE,
                f"Logic change proposed for {item.entity}.{item.attribute}",
            )

        if item.type == ChangeType.ADD_TABLE:
            if not item.table:
                return Classification.INVALID, "add_table requires a table name"
            return (
                Classification.NET_NEW,
                f"New table '{item.table}' will be added on approval",
            )

        if item.type == ChangeType.DELETE_TABLE:
            if not item.table:
                return Classification.INVALID, "delete_table requires a table name"
            return (
                Classification.NEEDS_CHANGE,
                f"Table '{item.table}' will be deleted on approval",
            )

        return Classification.INVALID, f"Unknown change type: {item.type}"

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
        if not item.attribute:
            return []
        driver = get_driver()
        async with driver.session(database=get_settings().neo4j_database) as session:
            result = await session.run(
                get_query("get_attribute_sources"),
                entity=item.entity,
                attribute=item.attribute,
            )
            return [record["column_id"] async for record in result]

    async def _verify_catalog(self, item: ChangeLineInput) -> bool | None:
        if not (item.source_system and item.source_table and item.source_column):
            return None
        v = await self._catalog.verify_column(
            system_id=item.source_system,
            schema=item.source_table.split(".")[0]
            if item.source_table and "." in item.source_table
            else None,
            table=item.source_table.split(".")[-1] if item.source_table else "",
            column=item.source_column,
        )
        return v.found


def get_validation_service() -> ValidationService:
    return ValidationService(catalog=get_catalog_client())
