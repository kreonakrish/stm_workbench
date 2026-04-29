"""Pytest fixtures shared across the backend test suite.

Spins up an ephemeral Neo4j container per session and points the app at
it via env-var injection (so all modules that did `from app.config import
get_settings` see the override). Migration 004 seeds the default workflow
template once at session start; per-test cleanup wipes only request-
instance data so the template (and the ontology bootstrap from migration
003) persists across tests.

httpx's ASGITransport does not fire FastAPI lifespan events, so the
singleton driver is also closed between tests — the next test creates a
fresh driver bound to its own event loop.
"""
from __future__ import annotations

import os
from collections.abc import AsyncIterator

import pytest_asyncio
from httpx import ASGITransport, AsyncClient
from testcontainers.neo4j import Neo4jContainer

from app.config import Settings, get_settings
from app.graph.driver import close_driver, get_driver
from app.graph.migrations import run_migrations
from app.main import create_app

_NEO4J_ENV_KEYS = ("NEO4J_URI", "NEO4J_USER", "NEO4J_PASSWORD", "NEO4J_DATABASE")


@pytest_asyncio.fixture(scope="session")
async def neo4j_test_settings() -> AsyncIterator[Settings]:
    """Spin up an ephemeral Neo4j container and point the app at it via env vars."""
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
    """Apply schema migrations (including the default workflow seed), then
    drop the singleton driver so each test creates a fresh driver in its
    own event loop.
    """
    await run_migrations()
    await close_driver()
    yield


@pytest_asyncio.fixture(autouse=True)
async def _per_test_cleanup() -> AsyncIterator[None]:
    """After each test: wipe request-instance data, then close the driver.

    Workflow template, stages, transitions, schema-migration tracking, and
    ontology constraint metadata all survive — only the per-test request
    data is removed so each test starts from a known clean state.
    """
    yield
    try:
        driver = get_driver()
        async with driver.session(database=get_settings().neo4j_database) as session:
            await session.run(
                "MATCH (n) WHERE n:Request OR n:STMTransitionEvent DETACH DELETE n"
            )
    except Exception:
        # Driver may not have been initialized if the test never touched the DB.
        pass
    await close_driver()


@pytest_asyncio.fixture
async def client() -> AsyncIterator[AsyncClient]:
    app = create_app()
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac
