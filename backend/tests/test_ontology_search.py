"""Tests for the ontology search endpoint."""
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
async def test_search_finds_property_match(client: AsyncClient) -> None:
    response = await client.get("/api/v1/ontology/search", params={"q": "borrower_id"})
    assert response.status_code == 200
    body = response.json()

    hits = body["hits"]
    top = hits[0]
    assert top["label"] == "Borrower"
    assert top["property"] == "borrower_id"
    assert top["display"] == "Borrower.borrower_id"
    assert top["unique"] is True


@pytest.mark.asyncio
async def test_search_finds_label_match(client: AsyncClient) -> None:
    response = await client.get("/api/v1/ontology/search", params={"q": "Borrower"})
    assert response.status_code == 200
    body = response.json()

    label_hits = [h for h in body["hits"] if h["property"] is None]
    assert any(h["label"] == "Borrower" for h in label_hits)


@pytest.mark.asyncio
async def test_search_property_match_outranks_label_match(client: AsyncClient) -> None:
    """When a property name matches the query, it should rank above a label match."""
    response = await client.get("/api/v1/ontology/search", params={"q": "ssn"})
    assert response.status_code == 200
    body = response.json()

    hits = body["hits"]
    assert hits, "expected at least one hit"
    # Top hit should be a property match (Borrower.ssn), not a label
    assert hits[0]["property"] is not None


@pytest.mark.asyncio
async def test_search_pagination_with_cursor(client: AsyncClient) -> None:
    """Common substring should produce many hits; cursor walks them."""
    first = await client.get(
        "/api/v1/ontology/search", params={"q": "id", "limit": 5}
    )
    assert first.status_code == 200
    body = first.json()
    assert len(body["hits"]) == 5
    assert body["next_cursor"] is not None

    second = await client.get(
        "/api/v1/ontology/search",
        params={"q": "id", "limit": 5, "cursor": body["next_cursor"]},
    )
    assert second.status_code == 200
    body2 = second.json()
    # Second page is non-empty and disjoint from first
    first_displays = {h["display"] for h in body["hits"]}
    second_displays = {h["display"] for h in body2["hits"]}
    assert second_displays
    assert first_displays.isdisjoint(second_displays)


@pytest.mark.asyncio
async def test_search_empty_query_rejected(client: AsyncClient) -> None:
    response = await client.get("/api/v1/ontology/search", params={"q": ""})
    assert response.status_code == 422  # Pydantic min_length=1
