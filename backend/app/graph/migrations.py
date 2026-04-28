"""Neo4j schema migration runner.

Applies numbered .cypher migration files from /schemas/neo4j/ in order.
Tracks applied migrations via :SchemaMigration nodes in the graph.

Run via:
    python -m app.graph.migrations
"""
from __future__ import annotations

import asyncio
import logging
import re
from pathlib import Path

import structlog
from neo4j import AsyncDriver

from app.config import get_settings
from app.graph.driver import close_driver, get_driver

logger = structlog.get_logger(__name__)

MIGRATIONS_DIR = Path(__file__).parent.parent.parent.parent / "schemas" / "neo4j"
MIGRATION_PATTERN = re.compile(r"^(\d{3})_.+\.cypher$")


async def get_applied_migrations(driver: AsyncDriver) -> set[str]:
    """Return the set of migration_ids already applied."""
    async with driver.session(database=get_settings().neo4j_database) as session:
        result = await session.run(
            "MATCH (m:SchemaMigration) RETURN m.migration_id AS id"
        )
        return {record["id"] async for record in result}


async def apply_migration(driver: AsyncDriver, path: Path) -> None:
    """Apply a single migration file."""
    cypher = path.read_text(encoding="utf-8")
    # Strip // line comments before splitting, so a semicolon inside a comment
    # ("Does NOT seed any data; seeding is done...") doesn't fragment the parse.
    cleaned = "\n".join(ln for ln in cypher.splitlines() if not ln.lstrip().startswith("//"))
    statements = [s.strip() for s in cleaned.split(";") if s.strip()]

    async with driver.session(database=get_settings().neo4j_database) as session:
        for stmt in statements:
            await session.run(stmt)
    logger.info("migration_applied", migration=path.name)


async def run_migrations() -> None:
    """Find and apply all pending migrations in order."""
    driver = get_driver()
    await driver.verify_connectivity()

    applied = await get_applied_migrations(driver)
    logger.info("applied_migrations_loaded", count=len(applied))

    migration_files = sorted(
        p for p in MIGRATIONS_DIR.glob("*.cypher")
        if MIGRATION_PATTERN.match(p.name)
    )

    for path in migration_files:
        match = MIGRATION_PATTERN.match(path.name)
        assert match is not None
        migration_id = path.stem  # e.g. "001_initial"
        if migration_id in applied:
            logger.debug("migration_skipped", migration=migration_id, reason="already_applied")
            continue
        logger.info("migration_applying", migration=migration_id)
        await apply_migration(driver, path)

    logger.info("migrations_complete")


def main() -> None:
    logging.basicConfig(level=logging.INFO)
    asyncio.run(_main())


async def _main() -> None:
    try:
        await run_migrations()
    finally:
        await close_driver()


if __name__ == "__main__":
    main()
