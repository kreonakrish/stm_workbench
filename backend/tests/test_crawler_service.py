"""Tests for the stub crawler + linker."""
from __future__ import annotations

import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_fixture_crawler_run_links_known_columns(
    client: AsyncClient,
) -> None:
    response = await client.post(
        "/api/v1/crawler/runs",
        json={"connector": "fixture", "system_id": "oracle_loan_prod"},
    )
    assert response.status_code == 201
    body = response.json()
    assert body["columns_seen"] >= 5
    # The seed includes BORROWER_ID, SSN, FICO_SCORE, etc., which will
    # auto-link to the BusinessAttributes seeded in migration 006.
    assert body["columns_linked"] >= 4
    # LAST_BUREAU_PULL_DT is intentionally not in the seed; should orphan.
    assert body["columns_orphaned"] >= 1


@pytest.mark.asyncio
async def test_fixture_crawler_snowflake_observations(client: AsyncClient) -> None:
    response = await client.post(
        "/api/v1/crawler/runs",
        json={"connector": "fixture", "system_id": "snowflake_analytics"},
    )
    assert response.status_code == 201
    body = response.json()
    assert body["system_id"] == "snowflake_analytics"
    assert body["columns_seen"] >= 3
