"""Tests for the entity/attribute listing endpoints."""
from __future__ import annotations

import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_list_entities_returns_seeded_entities(client: AsyncClient) -> None:
    response = await client.get("/api/v1/ontology/entities")
    assert response.status_code == 200
    names = {e["name"] for e in response.json()}
    expected = {"Borrower", "MortgageLoan", "Property", "Lender"}
    assert expected.issubset(names)


@pytest.mark.asyncio
async def test_list_attributes_returns_borrower_seed(client: AsyncClient) -> None:
    response = await client.get("/api/v1/ontology/entities/Borrower/attributes")
    assert response.status_code == 200
    names = {a["name"] for a in response.json()}
    assert {"borrower_id", "ssn", "current_fico_score", "annual_income"}.issubset(
        names
    )
    # borrower_id is the unique key
    by_name = {a["name"]: a for a in response.json()}
    assert by_name["borrower_id"]["is_key"] is True


@pytest.mark.asyncio
async def test_list_attributes_unknown_entity_returns_empty(
    client: AsyncClient,
) -> None:
    response = await client.get("/api/v1/ontology/entities/NoSuchEntity/attributes")
    assert response.status_code == 200
    assert response.json() == []
