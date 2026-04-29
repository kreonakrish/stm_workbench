"""Pydantic models for workflow templates."""
from __future__ import annotations

from pydantic import BaseModel, Field


class StageDefinition(BaseModel):
    id: str
    name: str
    is_initial: bool = False
    is_terminal: bool = False
    allowed_actors: list[str] = Field(default_factory=list)
    order: int


class TransitionDefinition(BaseModel):
    id: str
    from_stage_id: str
    to_stage_id: str


class WorkflowTemplate(BaseModel):
    id: str
    name: str
    version: int
    stages: list[StageDefinition] = Field(default_factory=list)
    transitions: list[TransitionDefinition] = Field(default_factory=list)
