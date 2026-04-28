"""Request service — business logic for the request lifecycle.

Orchestrates graph operations for creating, fetching, and transitioning
requests. Use this service from API endpoints; do not call graph queries
directly from API handlers.
"""
from __future__ import annotations

from uuid import UUID, uuid4

import structlog
from fastapi import HTTPException, status

from app.domain.requests import (
    CreateRequestInput,
    Request,
    TransitionEvent,
    TransitionResult,
)
from app.graph.driver import get_driver
from app.graph.queries import get_query
from app.workflow.engine import WorkflowEngine, get_workflow_engine

logger = structlog.get_logger(__name__)


class RequestService:
    def __init__(self, workflow: WorkflowEngine) -> None:
        self._workflow = workflow

    async def create_request(
        self, payload: CreateRequestInput, *, requester_id: str
    ) -> Request:
        """Create a new request and trigger downstream processing.

        Triggers the Discovery cascade asynchronously (T-020) once the
        request is persisted. The API returns immediately; cascade results
        are written back as graph nodes when ready.
        """
        request_id = uuid4()
        cypher = get_query("create_request")
        driver = get_driver()
        async with driver.session() as session:
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
            )
            record = await result.single()

        if record is None:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Failed to create request — workflow template not found",
            )

        logger.info("request_created", request_id=str(request_id))

        # TODO(T-020): enqueue Discovery cascade Celery task here
        # cascade_task.delay(str(request_id))

        fetched = await self.get_request(request_id)
        assert fetched is not None
        return fetched

    async def get_request(self, request_id: UUID) -> Request | None:
        cypher = get_query("get_request_by_id")
        driver = get_driver()
        async with driver.session() as session:
            result = await session.run(cypher, request_id=str(request_id))
            record = await result.single()

        if record is None:
            return None

        r = record["request"]
        stage = record["current_stage"]
        events = record["recent_events"] or []

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


def get_request_service() -> RequestService:
    """FastAPI dependency for RequestService."""
    return RequestService(workflow=get_workflow_engine())
