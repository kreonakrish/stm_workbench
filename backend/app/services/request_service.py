"""Request service — business logic for the request lifecycle.

Orchestrates graph operations for creating, fetching, and transitioning
requests. Use this service from API endpoints; do not call graph queries
directly from API handlers.

On create: validation classifies each ChangeLineInput before persistence
so each persisted :ChangeLine carries its classification + sources.
"""
from __future__ import annotations

from uuid import UUID, uuid4

import structlog
from fastapi import HTTPException, status

from app.config import get_settings
from app.domain.requests import (
    ChangeAction,
    ChangeCategory,
    ChangeLine,
    Classification,
    CreateRequestInput,
    PipelineLayer,
    Request,
    TransitionEvent,
    TransitionResult,
)
from app.graph.driver import get_driver
from app.graph.queries import get_query
from app.services.validation_service import (
    ValidationService,
    get_validation_service,
)
from app.workflow.engine import WorkflowEngine, get_workflow_engine

logger = structlog.get_logger(__name__)


class RequestService:
    def __init__(
        self, workflow: WorkflowEngine, validator: ValidationService
    ) -> None:
        self._workflow = workflow
        self._validator = validator

    async def create_request(
        self, payload: CreateRequestInput, *, requester_id: str
    ) -> Request:
        """Validate change items, persist the request and items, and return it."""
        request_id = uuid4()

        classified_items = await self._validator.classify_all(
            request_id=str(request_id), items=payload.items
        )

        items_for_cypher = [
            {
                "id": str(it.id),
                "category": it.category.value,
                "action": it.action.value,
                "pipeline_layer": it.pipeline_layer.value,
                "entity": it.entity,
                "target_attribute": it.target_attribute,
                "target_dataset": it.target_dataset,
                "target_table": it.target_table,
                "target_column": it.target_column,
                "target_data_type": it.target_data_type,
                "target_nullable": it.target_nullable,
                "source_system": it.source_system,
                "source_dataset": it.source_dataset,
                "source_table": it.source_table,
                "source_column": it.source_column,
                "transformation_logic": it.transformation_logic,
                "business_definition": it.business_definition,
                "rationale": it.rationale,
                "impact_notes": it.impact_notes,
                "classification": it.classification.value,
                "classification_reason": it.classification_reason,
                "catalog_verified": it.catalog_verified,
                "existing_sources": it.existing_sources,
            }
            for it in classified_items
        ]

        cypher = get_query("create_request")
        driver = get_driver()
        async with driver.session(database=get_settings().neo4j_database) as session:
            result = await session.run(
                cypher,
                request_id=str(request_id),
                title=payload.title,
                business_question=payload.business_question,
                usage_context=payload.usage_context.value,
                consumption_pattern=payload.consumption_pattern.value,
                deadline=payload.deadline.isoformat() if payload.deadline else None,
                requester_id=requester_id,
                template_id=payload.template_id,
                items=items_for_cypher,
            )
            record = await result.single()

        if record is None:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Failed to create request — workflow template not found",
            )

        logger.info(
            "request_created",
            request_id=str(request_id),
            item_count=len(classified_items),
        )

        fetched = await self.get_request(request_id)
        assert fetched is not None
        return fetched

    async def get_request(self, request_id: UUID) -> Request | None:
        cypher = get_query("get_request_by_id")
        driver = get_driver()
        async with driver.session(database=get_settings().neo4j_database) as session:
            result = await session.run(cypher, request_id=str(request_id))
            record = await result.single()

        if record is None:
            return None

        r = record["request"]
        stage = record["current_stage"]
        events = record["recent_events"] or []
        items = record["items"] or []

        return Request(
            id=UUID(r["id"]),
            title=r["title"],
            business_question=r["business_question"],
            usage_context=r["usage_context"],
            consumption_pattern=r["consumption_pattern"],
            deadline=r.get("deadline"),
            requester_id=r["requester_id"],
            current_stage_id=stage["id"],
            current_stage_name=stage["name"],
            created_at=r["created_at"].to_native(),
            recent_events=[
                TransitionEvent(
                    id=UUID(e["id"]),
                    request_id=UUID(e["request_id"]),
                    from_stage=e.get("from_stage"),
                    to_stage=e["to_stage"],
                    actor=e["actor"],
                    at=e["at"].to_native(),
                    rationale=e.get("rationale"),
                )
                for e in events
            ],
            items=[_item_from_record(cl) for cl in items if cl is not None],
        )

    async def transition(
        self,
        *,
        request_id: UUID,
        to_stage_id: str,
        rationale: str | None,
        actor: str,
    ) -> TransitionResult:
        """Transition a request through the workflow engine."""
        result = await self._workflow.transition(
            request_id=request_id,
            to_stage_id=to_stage_id,
            actor=actor,
            rationale=rationale,
        )
        return result


def _item_from_record(cl: dict) -> ChangeLine:
    return ChangeLine(
        id=UUID(cl["id"]),
        request_id=UUID(cl["request_id"]),
        category=ChangeCategory(cl["category"]),
        action=ChangeAction(cl["action"]),
        pipeline_layer=PipelineLayer(cl["pipeline_layer"]),
        entity=cl["entity"],
        target_attribute=cl.get("target_attribute"),
        target_dataset=cl.get("target_dataset"),
        target_table=cl.get("target_table"),
        target_column=cl.get("target_column"),
        target_data_type=cl.get("target_data_type"),
        target_nullable=cl.get("target_nullable"),
        source_system=cl.get("source_system"),
        source_dataset=cl.get("source_dataset"),
        source_table=cl.get("source_table"),
        source_column=cl.get("source_column"),
        transformation_logic=cl.get("transformation_logic"),
        business_definition=cl.get("business_definition"),
        rationale=cl.get("rationale"),
        impact_notes=cl.get("impact_notes"),
        classification=Classification(cl["classification"]),
        classification_reason=cl.get("classification_reason"),
        catalog_verified=cl.get("catalog_verified"),
        existing_sources=list(cl.get("existing_sources") or []),
    )


def get_request_service() -> RequestService:
    """FastAPI dependency for RequestService."""
    return RequestService(
        workflow=get_workflow_engine(),
        validator=get_validation_service(),
    )
