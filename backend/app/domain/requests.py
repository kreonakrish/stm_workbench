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


class ChangeType(str, Enum):
    ADD_ATTRIBUTE = "add_attribute"
    CHANGE_LOGIC = "change_logic"
    ADD_TABLE = "add_table"
    DELETE_TABLE = "delete_table"


class Classification(str, Enum):
    """How a change line resolved against the ontology + physical sources."""
    EXISTS = "exists"            # ontology already has this attribute/table
    NET_NEW = "net_new"          # nothing matches; truly new
    NEEDS_CHANGE = "needs_change"  # exists but the user wants to change its logic
    INVALID = "invalid"          # references non-existent target (e.g. change_logic on
                                 # an attribute that doesn't exist)


class ChangeLineInput(BaseModel):
    """Input form of a change line, sent on intake.

    Not every field is required for every type:
      add_attribute  : entity, attribute, business_definition (recommended),
                       data_type, optional source_system/table/column
      change_logic   : entity, attribute, new_logic
      add_table      : entity, table, source_system
      delete_table   : entity, table, source_system
    Validation runs after persistence; the API does not reject under-filled
    rows here so the user can save a draft and refine.
    """
    type: ChangeType
    entity: str
    attribute: str | None = None
    table: str | None = None
    source_system: str | None = None
    source_table: str | None = None
    source_column: str | None = None
    new_logic: str | None = None
    business_definition: str | None = None
    data_type: str | None = None


class ChangeLine(BaseModel):
    """A change line as stored in the graph + returned via API."""
    id: UUID
    request_id: UUID
    type: ChangeType
    entity: str
    attribute: str | None = None
    table: str | None = None
    source_system: str | None = None
    source_table: str | None = None
    source_column: str | None = None
    new_logic: str | None = None
    business_definition: str | None = None
    data_type: str | None = None
    classification: Classification
    classification_reason: str | None = None
    catalog_verified: bool | None = None
    existing_sources: list[str] = Field(default_factory=list)


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
    items: list[ChangeLineInput] = Field(default_factory=list)


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
    items: list[ChangeLine] = Field(default_factory=list)


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
