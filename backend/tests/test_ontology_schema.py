"""Tests for the ontology schema endpoint.

Verifies that, after bootstrap migrations land, the schema endpoint:
- enumerates the home-lending ontology labels imported by migration 003,
- captures unique-property metadata from constraint-backed indexes,
- merges in live label counts (which are mostly 0 on a fresh container).
"""
from __future__ import annotations

from collections.abc import AsyncIterator

import pytest
import pytest_asyncio
from httpx import ASGITransport, AsyncClient

from app.main import create_app


@pytest_asyncio.fixture
async def client() -> AsyncIterator[AsyncClient]:
    app = create_app()
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac


@pytest.mark.asyncio
async def test_schema_endpoint_returns_hl_ontology_labels(client: AsyncClient) -> None:
    response = await client.get("/api/v1/ontology/schema")
    assert response.status_code == 200
    body = response.json()

    assert "labels" in body
    assert "relationships" in body

    label_names = {label["name"] for label in body["labels"]}

    # A handful of home-lending ontology labels we expect from migration 003.
    expected_present = {"Borrower", "MortgageLoan", "Property", "Lender", "Investor"}
    missing = expected_present - label_names
    assert not missing, f"missing expected ontology labels: {missing}"


@pytest.mark.asyncio
async def test_schema_endpoint_marks_unique_properties(client: AsyncClient) -> None:
    response = await client.get("/api/v1/ontology/schema")
    assert response.status_code == 200
    body = response.json()

    borrower = next((lbl for lbl in body["labels"] if lbl["name"] == "Borrower"), None)
    assert borrower is not None

    borrower_id = next(
        (p for p in borrower["properties"] if p["name"] == "borrower_id"), None
    )
    assert borrower_id is not None
    assert borrower_id["unique"] is True
    assert borrower_id["indexed"] is True


@pytest.mark.asyncio
async def test_schema_endpoint_includes_indexed_only_property(
    client: AsyncClient,
) -> None:
    """Indexed-but-not-unique properties should still surface, marked correctly."""
    response = await client.get("/api/v1/ontology/schema")
    assert response.status_code == 200
    body = response.json()

    borrower = next((lbl for lbl in body["labels"] if lbl["name"] == "Borrower"), None)
    assert borrower is not None

    # borrower.ssn has an index but no uniqueness constraint
    ssn = next((p for p in borrower["properties"] if p["name"] == "ssn"), None)
    assert ssn is not None
    assert ssn["indexed"] is True
    assert ssn["unique"] is False


@pytest.mark.asyncio
async def test_schema_endpoint_zero_counts_for_ontology_labels(
    client: AsyncClient,
) -> None:
    """Ontology labels (Borrower, etc.) should report count=0 on a fresh DB.

    Workbench-internal labels (:SchemaMigration, :STM*) may legitimately have
    instance data from migrations and seeds, so they are excluded.
    """
    response = await client.get("/api/v1/ontology/schema")
    assert response.status_code == 200
    body = response.json()

    workbench_internal = {"SchemaMigration"}
    for label in body["labels"]:
        if label["name"].startswith("STM") or label["name"] in workbench_internal:
            continue
        assert label["count"] == 0, f"unexpected non-zero count for {label['name']}"
