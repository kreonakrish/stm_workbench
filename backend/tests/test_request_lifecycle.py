"""Tests for the request lifecycle.

These tests spin up an ephemeral Neo4j via testcontainers; run with:
    pytest tests/test_request_lifecycle.py -v

Requires Docker available locally.
"""
from __future__ import annotations

import os
from collections.abc import AsyncIterator

import pytest
import pytest_asyncio
from httpx import ASGITransport, AsyncClient
from neo4j import AsyncGraphDatabase
from testcontainers.neo4j import Neo4jContainer

from app.config import Settings, get_settings
from app.graph.driver import close_driver
from app.graph.migrations import run_migrations
from app.main import create_app

_NEO4J_ENV_KEYS = ("NEO4J_URI", "NEO4J_USER", "NEO4J_PASSWORD", "NEO4J_DATABASE")


@pytest_asyncio.fixture(scope="session")
async def neo4j_test_settings() -> AsyncIterator[Settings]:
    """Spin up an ephemeral Neo4j container and point the app at it via env vars.

    Env-var injection is required — modules that did `from app.config import
    get_settings` hold a bound reference, so monkey-patching the function on
    the config module wouldn't reach them. Pydantic-settings reads env on
    first instantiation, so clearing the lru_cache propagates the override
    everywhere.

    A fresh container per pytest session — never touches the developer's local DB.
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
    driver opened lazily during a test is never closed between tests. Without
    this reset the next test reuses a connection bound to a now-closed event
    loop, surfacing as `'NoneType' object has no attribute 'send'`.
    """
    yield
    await close_driver()


@pytest_asyncio.fixture
async def seed_default_template(neo4j_test_settings: Settings) -> AsyncIterator[None]:
    """Seed a minimal default workflow template."""
    driver = AsyncGraphDatabase.driver(
        neo4j_test_settings.neo4j_uri,
        auth=(neo4j_test_settings.neo4j_user, neo4j_test_settings.neo4j_password),
    )
    try:
        async with driver.session(database=neo4j_test_settings.neo4j_database) as session:
            await session.run("""
                MERGE (t:WorkflowTemplate {id: 'default'})
                ON CREATE SET t.name = 'Default V1', t.version = 1, t.applies_to = ['all']
                MERGE (s1:Stage {id: 'intake'})
                ON CREATE SET s1.name = 'Intake', s1.is_initial = true, s1.allowed_actors = ['requester']
                MERGE (s2:Stage {id: 'discovery'})
                ON CREATE SET s2.name = 'Discovery', s2.is_initial = false, s2.allowed_actors = ['data_owner']
                MERGE (t)-[:HAS_STAGE]->(s1)
                MERGE (t)-[:HAS_STAGE]->(s2)
                MERGE (s1)-[:ALLOWS_TRANSITION]->(tr:Transition {id: 'intake_to_discovery'})-[:TO]->(s2)
            """)
        yield
        async with driver.session(database=neo4j_test_settings.neo4j_database) as session:
            await session.run("MATCH (n) DETACH DELETE n")
    finally:
        await driver.close()


@pytest_asyncio.fixture
async def client(seed_default_template: None) -> AsyncIterator[AsyncClient]:
    app = create_app()
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac


@pytest.mark.asyncio
async def test_health_endpoint(client: AsyncClient) -> None:
    response = await client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "ok"


@pytest.mark.asyncio
async def test_create_request_happy_path(client: AsyncClient) -> None:
    response = await client.post(
        "/api/v1/requests",
        json={
            "title": "New borrower FICO attribute for CCAR",
            "business_question": "We need current FICO at portfolio level for monthly monitoring",
            "usage_context": "regulatory",
            "consumption_pattern": "report",
            "template_id": "default",
        },
    )
    assert response.status_code == 201
    body = response.json()
    assert body["title"].startswith("New borrower FICO")
    assert body["current_stage_name"] == "Intake"
    assert body["usage_context"] == "regulatory"


@pytest.mark.asyncio
async def test_transition_request(client: AsyncClient) -> None:
    create_resp = await client.post(
        "/api/v1/requests",
        json={
            "title": "Test transition",
            "business_question": "Testing the workflow transition",
            "usage_context": "analytics",
            "consumption_pattern": "dashboard",
            "template_id": "default",
        },
    )
    assert create_resp.status_code == 201
    request_id = create_resp.json()["id"]

    transition_resp = await client.post(
        f"/api/v1/requests/{request_id}/transition",
        json={"to_stage_id": "discovery", "rationale": "Routing to data owner"},
    )
    assert transition_resp.status_code == 200
    body = transition_resp.json()
    assert body["request"]["current_stage_name"] == "Discovery"
    assert body["event"]["from_stage"] == "intake"
    assert body["event"]["to_stage"] == "discovery"


@pytest.mark.asyncio
async def test_invalid_transition_rejected(client: AsyncClient) -> None:
    create_resp = await client.post(
        "/api/v1/requests",
        json={
            "title": "Invalid transition test",
            "business_question": "Testing rejection of invalid transitions",
            "usage_context": "adhoc",
            "consumption_pattern": "feed",
            "template_id": "default",
        },
    )
    request_id = create_resp.json()["id"]

    response = await client.post(
        f"/api/v1/requests/{request_id}/transition",
        json={"to_stage_id": "drb", "rationale": "Trying to skip stages"},
    )
    assert response.status_code == 409
    assert response.json()["detail"]["code"] == "invalid_transition"


@pytest.mark.asyncio
async def test_get_nonexistent_request_returns_404(client: AsyncClient) -> None:
    response = await client.get("/api/v1/requests/00000000-0000-0000-0000-000000000000")
    assert response.status_code == 404
