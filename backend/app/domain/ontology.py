"""Pydantic models for the ontology metagraph."""
from __future__ import annotations

from pydantic import BaseModel, Field


class PropertySchema(BaseModel):
    name: str
    indexed: bool = False
    unique: bool = False


class LabelSchema(BaseModel):
    name: str
    count: int = 0
    properties: list[PropertySchema] = Field(default_factory=list)


class RelationshipSchema(BaseModel):
    type: str
    count: int = 0
    start_labels: list[str] = Field(default_factory=list)
    end_labels: list[str] = Field(default_factory=list)


class OntologySchema(BaseModel):
    labels: list[LabelSchema]
    relationships: list[RelationshipSchema]
