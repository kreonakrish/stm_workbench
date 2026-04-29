"""Tests for the request lifecycle.

Migration 004 seeds the default workflow template, so individual tests
do not need to seed it themselves. Shared fixtures (testcontainer,
migrations, per-test cleanup, ASGI client) live in conftest.py.
"""
from __future__ import annotations

import pytest
from httpx import AsyncClient


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
