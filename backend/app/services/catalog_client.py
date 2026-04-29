"""Catalog client — stub.

Production wiring talks to the bank's data-catalog API (Apache Atlas /
Collibra / Alation / etc.). For the workbench skeleton we ship a stub that
treats the local graph as the catalog: a (system, table, column) tuple is
'verified' if a matching :PhysicalColumn exists in the workbench DB.

Replace `LocalGraphCatalogClient` with a real HTTP client when the catalog
team exposes its API; the interface (`CatalogClient.verify_column`) is the
seam.
"""
from __future__ import annotations

from typing import Protocol

import structlog

from app.config import get_settings
from app.domain.catalog import CatalogVerification
from app.graph.driver import get_driver
from app.graph.queries import get_query

logger = structlog.get_logger(__name__)


class CatalogClient(Protocol):
    async def verify_column(
        self, *, system_id: str, schema: str | None, table: str, column: str
    ) -> CatalogVerification: ...


class LocalGraphCatalogClient:
    """Stub: treats the workbench graph as the catalog."""

    async def verify_column(
        self, *, system_id: str, schema: str | None, table: str, column: str
    ) -> CatalogVerification:
        column_id = f"{system_id}.{schema or ''}.{table}.{column}"
        driver = get_driver()
        async with driver.session(database=get_settings().neo4j_database) as session:
            result = await session.run(
                get_query("catalog_verify_column"), column_id=column_id
            )
            record = await result.single()
        found = record is not None
        return CatalogVerification(
            system_id=system_id,
            schema=schema,
            table=table,
            column=column,
            found=found,
            note=None if found else "Column not present in catalog",
        )


def get_catalog_client() -> CatalogClient:
    return LocalGraphCatalogClient()
