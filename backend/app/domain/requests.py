"""Domain models for requests and workflow state.

These are the canonical Pydantic models used at API boundaries and within
services. They map to graph nodes but are not graph-aware themselves;
mapping happens in /backend/app/graph/.
"""
from __future__ import annotations

from datetime import datetime
from enum import Enum
from typing import Literal
from uuid import UUID, uuid4

from pydantic import BaseModel, ConfigDict, Field


class UsageContext(str, Enum):
    REGULATORY = "regulatory"
    MANAGEMENT = "management"
    ANALYTICS = "analytics"
    ADHOC = "adhoc"


class ConsumptionPattern(str, Enum):
    REPORT = "report"
    FEED = "feed"
    MODEL = "model"
    DASHBOARD = "dashboard"


class StageName(str, Enum):
    INTAKE = "intake"
    DISCOVERY = "discovery"
    JAD = "jad"
    DRB = "drb"
    STM_AUTHORING = "stm_authoring"
    AWAITING_SYNC = "awaiting_sync"
    CLOSED = "closed"


class Stage(BaseModel):
    model_config = ConfigDict(frozen=True)
    id: str
    name: str
    allowed_actors: list[str] = Field(default_factory=list)
    is_initial: bool = False


class TransitionEvent(BaseModel):
    model_config = ConfigDict(frozen=True)
    id: UUID = Field(default_factory=uuid4)
    request_id: UUID
    from_stage: str | None
    to_stage: str
    actor: str
    at: datetime
    rationale: str | None = None


class CreateRequestInput(BaseModel):
    """Input for creating a new STM request."""
    title: str = Field(min_length=3, max_length=200)
    business_question: str = Field(min_length=10, max_length=2000)
    usage_context: UsageContext
    consumption_pattern: ConsumptionPattern
    deadline: datetime | None = None
    template_id: str = "default"


class Request(BaseModel):
    """A request as exposed via API."""
    id: UUID
    title: str
    business_question: str
    usage_context: UsageContext
    consumption_pattern: ConsumptionPattern
    deadline: datetime | None
    requester_id: str
    current_stage_id: str
    current_stage_name: str
    created_at: datetime
    recent_events: list[TransitionEvent] = Field(default_factory=list)


class TransitionInput(BaseModel):
    """Input for transitioning a request to a new stage."""
    to_stage_id: str
    rationale: str | None = Field(default=None, max_length=2000)


class TransitionResult(BaseModel):
    """Result of a successful transition."""
    request: Request
    event: TransitionEvent


class WorkflowError(BaseModel):
    """Structured error for workflow violations."""
    code: Literal[
        "invalid_transition",
        "guard_failed",
        "stage_not_found",
        "request_not_found",
        "unauthorized_actor",
    ]
    message: str
    details: dict[str, str] | None = None
