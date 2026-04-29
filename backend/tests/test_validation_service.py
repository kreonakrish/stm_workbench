"""Tests for the validation/classification service.

Migration 006 seeds :BusinessAttribute nodes for Borrower (incl. ssn,
fico_score, current_fico_score), MortgageLoan (incl. loan_id,
loan_status), and Property. Migration 007 wires sample physical sources.
"""
from __future__ import annotations

import pytest
from httpx import AsyncClient


def _line(**overrides):
    base = {
        "category": "ddl",
        "action": "add_column",
        "pipeline_layer": "transformation",
        "entity": "Borrower",
    }
    base.update(overrides)
    return base


@pytest.mark.asyncio
async def test_add_column_for_existing_attribute_classified_exists(
    client: AsyncClient,
) -> None:
    response = await client.post(
        "/api/v1/intake/preview",
        json=[_line(target_attribute="ssn", target_data_type="VARCHAR(11)")],
    )
    assert response.status_code == 200
    body = response.json()
    assert body[0]["classification"] == "exists"
    assert "already exists" in body[0]["classification_reason"].lower()


@pytest.mark.asyncio
async def test_add_column_for_brand_new_attribute_classified_net_new(
    client: AsyncClient,
) -> None:
    response = await client.post(
        "/api/v1/intake/preview",
        json=[
            _line(
                target_attribute="twitter_handle",
                target_data_type="STRING",
            )
        ],
    )
    assert response.status_code == 200
    body = response.json()
    assert body[0]["classification"] == "net_new"


@pytest.mark.asyncio
async def test_modify_transformation_on_existing_attribute_needs_change(
    client: AsyncClient,
) -> None:
    response = await client.post(
        "/api/v1/intake/preview",
        json=[
            _line(
                category="etl_logic",
                action="modify_transformation",
                target_attribute="current_fico_score",
                transformation_logic="Pull bureau weekly instead of monthly",
            )
        ],
    )
    assert response.status_code == 200
    body = response.json()
    assert body[0]["classification"] == "needs_change"


@pytest.mark.asyncio
async def test_modify_transformation_on_unknown_attribute_invalid(
    client: AsyncClient,
) -> None:
    response = await client.post(
        "/api/v1/intake/preview",
        json=[
            _line(
                category="etl_logic",
                action="modify_transformation",
                target_attribute="totally_made_up_attr",
                transformation_logic="anything",
            )
        ],
    )
    assert response.status_code == 200
    body = response.json()
    assert body[0]["classification"] == "invalid"


@pytest.mark.asyncio
async def test_add_column_surfaces_existing_physical_sources(
    client: AsyncClient,
) -> None:
    """borrower.fico_score has a seeded physical source on Oracle (migration 007)."""
    response = await client.post(
        "/api/v1/intake/preview",
        json=[_line(target_attribute="fico_score", target_data_type="NUMBER(3)")],
    )
    assert response.status_code == 200
    body = response.json()
    assert body[0]["classification"] == "exists"
    sources = body[0]["existing_sources"]
    assert any("oracle_loan_prod" in s for s in sources)


@pytest.mark.asyncio
async def test_action_category_mismatch_classified_invalid(
    client: AsyncClient,
) -> None:
    """A DML action under a DDL category should be flagged."""
    response = await client.post(
        "/api/v1/intake/preview",
        json=[_line(category="ddl", action="backfill")],
    )
    assert response.status_code == 200
    body = response.json()
    assert body[0]["classification"] == "invalid"
    assert "category" in body[0]["classification_reason"].lower()


@pytest.mark.asyncio
async def test_dml_backfill_requires_rationale(client: AsyncClient) -> None:
    response = await client.post(
        "/api/v1/intake/preview",
        json=[
            _line(
                category="dml",
                action="backfill",
                target_attribute="ssn",
            )
        ],
    )
    assert response.status_code == 200
    body = response.json()
    assert body[0]["classification"] == "invalid"
    assert "rationale" in body[0]["classification_reason"].lower()


@pytest.mark.asyncio
async def test_dml_backfill_with_rationale_needs_change(
    client: AsyncClient,
) -> None:
    response = await client.post(
        "/api/v1/intake/preview",
        json=[
            _line(
                category="dml",
                action="backfill",
                target_attribute="ssn",
                rationale="Reload last 30 days from corrected source",
            )
        ],
    )
    assert response.status_code == 200
    assert response.json()[0]["classification"] == "needs_change"
