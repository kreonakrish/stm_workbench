"""Neo4j async driver wrapper.

Provides a singleton AsyncDriver with proper lifecycle management.
Use `async with driver.session() as session` for queries; never construct
a driver manually.
"""
from __future__ import annotations

from neo4j import AsyncDriver, AsyncGraphDatabase

from app.config import get_settings

_driver: AsyncDriver | None = None


def get_driver() -> AsyncDriver:
    """Return the singleton Neo4j async driver, creating it if needed."""
    global _driver
    if _driver is None:
        settings = get_settings()
        _driver = AsyncGraphDatabase.driver(
            settings.neo4j_uri,
            auth=(settings.neo4j_user, settings.neo4j_password),
            max_connection_pool_size=settings.neo4j_max_connection_pool_size,
        )
    return _driver


async def close_driver() -> None:
    """Close the driver on shutdown.

    Always clears the singleton, even if close errors — a partially-closed
    driver bound to a defunct event loop must not be reused.
    """
    global _driver
    if _driver is not None:
        try:
            await _driver.close()
        finally:
            _driver = None
