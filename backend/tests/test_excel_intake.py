"""Tests for the Excel intake parser + endpoint."""
from __future__ import annotations

from io import BytesIO

import pytest
from httpx import AsyncClient
from openpyxl import Workbook


def _make_xlsx(rows: list[list[object]]) -> bytes:
    wb = Workbook()
    ws = wb.active
    for row in rows:
        ws.append(row)
    buf = BytesIO()
    wb.save(buf)
    return buf.getvalue()


@pytest.mark.asyncio
async def test_parse_excel_classifies_uploaded_rows(client: AsyncClient) -> None:
    xlsx = _make_xlsx(
        [
            [
                "category",
                "action",
                "pipeline_layer",
                "entity",
                "target_attribute",
                "target_data_type",
                "transformation_logic",
            ],
            ["ddl", "add_column", "transformation", "Borrower", "ssn", "VARCHAR(11)", None],
            ["ddl", "add_column", "transformation", "Borrower", "twitter_handle", "STRING", None],
            [
                "etl_logic",
                "modify_transformation",
                "transformation",
                "Borrower",
                "current_fico_score",
                None,
                "weekly bureau pull",
            ],
        ]
    )
    response = await client.post(
        "/api/v1/intake/parse-excel",
        files={
            "file": (
                "intake.xlsx",
                xlsx,
                "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
            )
        },
    )
    assert response.status_code == 200
    body = response.json()
    assert len(body) == 3
    assert body[0]["classification"] == "exists"
    assert body[1]["classification"] == "net_new"
    assert body[2]["classification"] == "needs_change"


@pytest.mark.asyncio
async def test_parse_excel_skips_rows_missing_required_fields(
    client: AsyncClient,
) -> None:
    xlsx = _make_xlsx(
        [
            ["category", "action", "pipeline_layer", "entity", "target_attribute"],
            ["ddl", "add_column", "transformation", "Borrower", "ssn"],
            [None, "add_column", "transformation", "Borrower", "ignored"],
            ["ddl", "add_column", "transformation", None, "ignored"],
        ]
    )
    response = await client.post(
        "/api/v1/intake/parse-excel",
        files={
            "file": (
                "intake.xlsx",
                xlsx,
                "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
            )
        },
    )
    assert response.status_code == 200
    body = response.json()
    assert len(body) == 1


@pytest.mark.asyncio
async def test_parse_excel_rejects_missing_required_headers(
    client: AsyncClient,
) -> None:
    xlsx = _make_xlsx(
        [
            ["foo", "bar"],
            ["x", "y"],
        ]
    )
    response = await client.post(
        "/api/v1/intake/parse-excel",
        files={
            "file": (
                "bad.xlsx",
                xlsx,
                "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
            )
        },
    )
    assert response.status_code == 400
    assert "category" in response.json()["detail"].lower()
