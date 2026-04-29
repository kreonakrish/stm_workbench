"""Pydantic models for the external catalog client (stub)."""
from __future__ import annotations

from pydantic import BaseModel


class CatalogVerification(BaseModel):
    """Result of asking an external catalog whether a column physically exists."""
    system_id: str
    schema_: str | None = None
    table: str
    column: str
    found: bool
    note: str | None = None
