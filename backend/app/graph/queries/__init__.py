"""Cypher query loader.

Loads .cypher files from /backend/app/graph/queries/ into a named registry.
Code must reference queries by name; inline Cypher strings are forbidden.

Usage:
    from app.graph.queries import get_query
    cypher = get_query("create_request")
    async with driver.session() as session:
        result = await session.run(cypher, params)
"""
from __future__ import annotations

from functools import lru_cache
from pathlib import Path

QUERIES_DIR = Path(__file__).parent


@lru_cache(maxsize=128)
def get_query(name: str) -> str:
    """Return the Cypher text for a named query.

    Args:
        name: Filename without .cypher extension.

    Raises:
        FileNotFoundError: if no such query exists.
    """
    path = QUERIES_DIR / f"{name}.cypher"
    if not path.exists():
        raise FileNotFoundError(f"No Cypher query named '{name}' in {QUERIES_DIR}")
    return path.read_text(encoding="utf-8")


def list_queries() -> list[str]:
    """Return all registered query names (for diagnostics and tests)."""
    return sorted(p.stem for p in QUERIES_DIR.glob("*.cypher"))
