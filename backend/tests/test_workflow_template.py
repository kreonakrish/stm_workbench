"""Tests for the workflow template endpoint.

Migration 004 seeds the default 7-stage template; these tests verify
the read endpoint surfaces stages in declared order with role gates,
and returns the forward transitions from the seed.
"""
from __future__ import annotations

import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_get_default_template_returns_seven_stages(client: AsyncClient) -> None:
    response = await client.get("/api/v1/templates/default")
    assert response.status_code == 200
    body = response.json()

    assert body["id"] == "default"
    assert body["version"] == 1

    stages = body["stages"]
    assert [s["id"] for s in stages] == [
        "intake",
        "discovery",
        "jad",
        "drb",
        "stm_authoring",
        "awaiting_sync",
        "closed",
    ]


@pytest.mark.asyncio
async def test_default_template_intake_is_initial_with_requester_gate(
    client: AsyncClient,
) -> None:
    response = await client.get("/api/v1/templates/default")
    assert response.status_code == 200
    intake = next(s for s in response.json()["stages"] if s["id"] == "intake")
    assert intake["is_initial"] is True
    assert intake["allowed_actors"] == ["requester"]


@pytest.mark.asyncio
async def test_default_template_closed_is_terminal(client: AsyncClient) -> None:
    response = await client.get("/api/v1/templates/default")
    assert response.status_code == 200
    closed = next(s for s in response.json()["stages"] if s["id"] == "closed")
    assert closed["is_terminal"] is True


@pytest.mark.asyncio
async def test_default_template_has_six_forward_transitions(
    client: AsyncClient,
) -> None:
    response = await client.get("/api/v1/templates/default")
    assert response.status_code == 200
    transitions = response.json()["transitions"]

    expected = {
        ("intake", "discovery"),
        ("discovery", "jad"),
        ("jad", "drb"),
        ("drb", "stm_authoring"),
        ("stm_authoring", "awaiting_sync"),
        ("awaiting_sync", "closed"),
    }
    actual = {(t["from_stage_id"], t["to_stage_id"]) for t in transitions}
    assert actual == expected


@pytest.mark.asyncio
async def test_get_unknown_template_returns_404(client: AsyncClient) -> None:
    response = await client.get("/api/v1/templates/no-such-template")
    assert response.status_code == 404
