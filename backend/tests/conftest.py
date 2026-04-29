"""Pytest fixtures shared across the backend test suite.

Spins up an ephemeral Neo4j container per session and points the app at
it via env-var injection (so all modules that did `from app.config import
get_settings` see the override). Closes the singleton driver between
tests so each test creates a fresh driver bound to its own event loop —
httpx's ASGITransport does not fire FastAPI lifespan events, so we
cannot rely on the application's own startup/shutdown hooks here.
"""
from __future__ import annotations

import os
from collections.abc import AsyncIterator

import pytest_asyncio
from testcontainers.neo4j import Neo4jContainer

from app.config import Settings, get_settings
from app.graph.driver import close_driver
from app.graph.migrations import run_migrations

_NEO4J_ENV_KEYS = ("NEO4J_URI", "NEO4J_USER", "NEO4J_PASSWORD", "NEO4J_DATABASE")


@pytest_asyncio.fixture(scope="session")
async def neo4j_test_settings() -> AsyncIterator[Settings]:
    """Spin up an ephemeral Neo4j container and point the app at it via env vars.

    Env-var injection is required — modules that did `from app.config import
    get_settings` hold a bound reference, so monkey-patching the function on
    the config module wouldn't reach them. Pydantic-settings reads env on
    first instantiation, so clearing the lru_cache propagates the override
    everywhere.
    """
    saved_env = {k: os.environ.get(k) for k in _NEO4J_ENV_KEYS}

    with Neo4jContainer("neo4j:5.25-community") as neo4j:
        bolt_url = neo4j.get_connection_url()

        os.environ["NEO4J_URI"] = bolt_url
        os.environ["NEO4J_USER"] = "neo4j"
        os.environ["NEO4J_PASSWORD"] = neo4j.password
        os.environ["NEO4J_DATABASE"] = "neo4j"
        get_settings.cache_clear()

        try:
            yield get_settings()
        finally:
            get_settings.cache_clear()
            for k, v in saved_env.items():
                if v is None:
                    os.environ.pop(k, None)
                else:
                    os.environ[k] = v


@pytest_asyncio.fixture(scope="session", autouse=True)
async def apply_migrations(neo4j_test_settings: Settings) -> AsyncIterator[None]:
    """Apply schema migrations, then drop the singleton driver.

    Migrations open the driver on the session-scope event loop; closing it
    here forces each function-scoped test's lifespan to create a fresh driver
    bound to its own loop, avoiding cross-loop Future errors.
    """
    await run_migrations()
    await close_driver()
    yield


@pytest_asyncio.fixture(autouse=True)
async def _reset_driver_between_tests() -> AsyncIterator[None]:
    """Close the singleton Neo4j driver after each test.

    httpx's ASGITransport does NOT fire FastAPI lifespan events, so the
    driver opened lazily during a test is never closed between tests.
    Without this reset the next test reuses a connection bound to a
    now-closed event loop, surfacing as
    `'NoneType' object has no attribute 'send'`.
    """
    yield
    await close_driver()
