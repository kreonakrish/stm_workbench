"""Tests for the validation/classification service.

Migration 006 seeds :BusinessAttribute nodes for Borrower (incl. ssn,
fico_score, current_fico_score), MortgageLoan (incl. loan_id,
loan_status), and Property. Migration 007 wires sample physical sources.
"""
from __future__ import annotations

import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_preview_classifies_existing_attribute_as_exists(
    client: AsyncClient,
) -> None:
    response = await client.post(
        "/api/v1/intake/preview",
        json=[
            {
                "type": "add_attribute",
                "entity": "Borrower",
                "attribute": "ssn",
            }
        ],
    )
    assert response.status_code == 200
    body = response.json()
    assert body[0]["classification"] == "exists"
    assert "already exists" in body[0]["classification_reason"].lower()


@pytest.mark.asyncio
async def test_preview_classifies_brand_new_attribute_as_net_new(
    client: AsyncClient,
) -> None:
    response = await client.post(
        "/api/v1/intake/preview",
        json=[
            {
                "type": "add_attribute",
                "entity": "Borrower",
                "attribute": "twitter_handle",
                "data_type": "string",
            }
        ],
    )
    assert response.status_code == 200
    body = response.json()
    assert body[0]["classification"] == "net_new"


@pytest.mark.asyncio
async def test_preview_change_logic_on_existing_attribute_returns_needs_change(
    client: AsyncClient,
) -> None:
    response = await client.post(
        "/api/v1/intake/preview",
        json=[
            {
                "type": "change_logic",
                "entity": "Borrower",
                "attribute": "current_fico_score",
                "new_logic": "Pull bureau weekly instead of monthly",
            }
        ],
    )
    assert response.status_code == 200
    body = response.json()
    assert body[0]["classification"] == "needs_change"


@pytest.mark.asyncio
async def test_preview_change_logic_on_unknown_attribute_returns_invalid(
    client: AsyncClient,
) -> None:
    response = await client.post(
        "/api/v1/intake/preview",
        json=[
            {
                "type": "change_logic",
                "entity": "Borrower",
                "attribute": "totally_made_up_attr",
                "new_logic": "anything",
            }
        ],
    )
    assert response.status_code == 200
    body = response.json()
    assert body[0]["classification"] == "invalid"


@pytest.mark.asyncio
async def test_preview_surfaces_existing_physical_sources(
    client: AsyncClient,
) -> None:
    """borrower.fico_score has a seeded physical source on Oracle (migration 007)."""
    response = await client.post(
        "/api/v1/intake/preview",
        json=[
            {
                "type": "add_attribute",
                "entity": "Borrower",
                "attribute": "fico_score",
            }
        ],
    )
    assert response.status_code == 200
    body = response.json()
    assert body[0]["classification"] == "exists"
    sources = body[0]["existing_sources"]
    assert any("oracle_loan_prod" in s for s in sources)
