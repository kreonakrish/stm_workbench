"""Pydantic models for ontology search."""
from __future__ import annotations

from pydantic import BaseModel, Field


class SearchHit(BaseModel):
    """A single typeahead match — either a label or a (label, property) pair."""

    label: str
    property: str | None = None  # None when the match is on the label name only
    display: str  # rendered path: "Borrower" or "Borrower.borrower_id"
    unique: bool = False  # property-level matches: is the property a unique key?


class SearchResponse(BaseModel):
    hits: list[SearchHit] = Field(default_factory=list)
    next_cursor: str | None = None
