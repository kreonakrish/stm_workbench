"""Tests for the request lifecycle.

These tests use a Neo4j testcontainer; run with:
    pytest tests/test_request_lifecycle.py -v

Requires Docker available locally.
"""
from __future__ import annotations

import asyncio
from collections.abc import AsyncIterator

import pytest
import pytest_asyncio
from httpx import ASGITransport, AsyncClient
from neo4j import AsyncGraphDatabase

from app.config import Settings, get_settings
from app.graph.driver import close_driver
from app.graph.migrations import run_migrations
from app.main import create_app


@pytest_asyncio.fixture(scope="session")
async def neo4j_test_settings() -> AsyncIterator[Settings]:
    """Override settings to point at a test Neo4j instance.

    Assumes a Neo4j is running locally on bolt://localhost:7687 with
    test credentials. In CI, this is provided by docker-compose.
    """
    test_settings = Settings(
        environment="local",
        neo4j_uri="bolt://localhost:7687",
        neo4j_user="neo4j",
        neo4j_password="password",
    )

    # Override the cached settings
    get_settings.cache_clear()

    def _override() -> Settings:
        return test_settings

    import app.config as config_module
    original = config_module.get_settings
    config_module.get_settings = _override  # type: ignore[assignment]

    yield test_settings

    config_module.get_settings = original  # type: ignore[assignment]
    get_settings.cache_clear()


@pytest_asyncio.fixture(scope="session", autouse=True)
async def apply_migrations(neo4j_test_settings: Settings) -> AsyncIterator[None]:
    """Apply schema migrations before tests run."""
    await run_migrations()
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
        async with driver.session() as session:
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
        async with driver.session() as session:
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
