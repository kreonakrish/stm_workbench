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
    CAPITAL_MARKETS = "capital_markets"
    FINANCE = "finance"
    REDS = "reds"
    RISK = "risk"


class ConsumptionPattern(str, Enum):
    REPORT = "report"
    FEED = "feed"
    MODEL = "model"
    DASHBOARD = "dashboard"


class ChangeCategory(str, Enum):
    """The kind of pipeline change.

    DDL        — schema-level (ADD/DROP/MODIFY table or column).
    DML        — data-level (backfill, correction, historical purge).
    ETL_LOGIC  — transformation/mapping/filter/join/aggregation logic.
    """
    DDL = "ddl"
    DML = "dml"
    ETL_LOGIC = "etl_logic"


class PipelineLayer(str, Enum):
    """Where in the data pipeline the change applies.

    INGESTION       — source-system → raw landing zone.
    TRANSFORMATION  — raw → curated business-conformed layer.
    PROVISIONING    — curated → consumption (semantic, mart, feed).
    """
    INGESTION = "ingestion"
    TRANSFORMATION = "transformation"
    PROVISIONING = "provisioning"


class ChangeAction(str, Enum):
    """Specific action within a category. The form validates that the chosen
    action is consistent with the category (DDL→ADD/DROP/MODIFY_*, etc.)."""
    # DDL
    ADD_TABLE = "add_table"
    DROP_TABLE = "drop_table"
    ADD_COLUMN = "add_column"
    DROP_COLUMN = "drop_column"
    MODIFY_COLUMN = "modify_column"
    # DML
    BACKFILL = "backfill"
    DATA_CORRECTION = "data_correction"
    DELETE_HISTORICAL = "delete_historical"
    # ETL Logic
    NEW_MAPPING = "new_mapping"
    MODIFY_MAPPING = "modify_mapping"
    MODIFY_TRANSFORMATION = "modify_transformation"
    MODIFY_FILTER = "modify_filter"
    MODIFY_AGGREGATION = "modify_aggregation"
    MODIFY_JOIN = "modify_join"


class Classification(str, Enum):
    """How a change line resolved against the ontology + physical sources."""
    EXISTS = "exists"
    NET_NEW = "net_new"
    NEEDS_CHANGE = "needs_change"
    INVALID = "invalid"


class ChangeLineInput(BaseModel):
    """Input form of a structured change line, sent on intake.

    Required fields are category, action, pipeline_layer, entity. Other
    fields are conditional — DDL column actions need target_column +
    target_data_type; ETL_LOGIC actions need transformation_logic; DML
    actions usually need source/target tables and a rationale.

    Validation runs server-side after persistence; the API does not reject
    under-filled rows here so the user can save a draft and refine.
    """
    category: ChangeCategory
    action: ChangeAction
    pipeline_layer: PipelineLayer
    entity: str

    target_attribute: str | None = None
    target_dataset: str | None = None
    target_table: str | None = None
    target_column: str | None = None
    target_data_type: str | None = None
    target_nullable: bool | None = None

    source_system: str | None = None
    source_dataset: str | None = None
    source_table: str | None = None
    source_column: str | None = None

    transformation_logic: str | None = None
    business_definition: str | None = None
    rationale: str | None = None
    impact_notes: str | None = None


class ChangeLine(BaseModel):
    """A change line as stored in the graph + returned via API."""
    id: UUID
    request_id: UUID
    category: ChangeCategory
    action: ChangeAction
    pipeline_layer: PipelineLayer
    entity: str

    target_attribute: str | None = None
    target_dataset: str | None = None
    target_table: str | None = None
    target_column: str | None = None
    target_data_type: str | None = None
    target_nullable: bool | None = None

    source_system: str | None = None
    source_dataset: str | None = None
    source_table: str | None = None
    source_column: str | None = None

    transformation_logic: str | None = None
    business_definition: str | None = None
    rationale: str | None = None
    impact_notes: str | None = None

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
