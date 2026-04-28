"""Workflow engine.

Reads workflow templates and transitions from the graph and validates
state transitions for requests. Per ADR 0002, workflow definitions are
graph data — this engine is intentionally thin.

The engine does NOT enforce all business rules; conformance pre-check
(T-026) and approval gates (T-035) layer additional checks on top.
"""
from __future__ import annotations

from uuid import UUID

import structlog
from fastapi import HTTPException, status

from app.domain.requests import Request, TransitionEvent, TransitionResult
from app.graph.driver import get_driver

logger = structlog.get_logger(__name__)


class WorkflowEngine:
    async def get_allowed_transitions(self, request_id: UUID) -> list[str]:
        """Return the IDs of stages this request can transition to."""
        driver = get_driver()
        cypher = """
        MATCH (r:Request {id: $request_id})-[:CURRENTLY_IN]->(stage:Stage)
        MATCH (stage)-[:ALLOWS_TRANSITION]->(t:Transition)-[:TO]->(target:Stage)
        RETURN target.id AS to_stage_id
        """
        async with driver.session() as session:
            result = await session.run(cypher, request_id=str(request_id))
            return [record["to_stage_id"] async for record in result]

    async def transition(
        self,
        *,
        request_id: UUID,
        to_stage_id: str,
        actor: str,
        rationale: str | None,
    ) -> TransitionResult:
        """Validate and execute a stage transition."""
        allowed = await self.get_allowed_transitions(request_id)
        if to_stage_id not in allowed:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail={
                    "code": "invalid_transition",
                    "message": f"Cannot transition to '{to_stage_id}' from current stage",
                    "allowed": allowed,
                },
            )

        # TODO(T-006 follow-up): evaluate guard expressions on the transition
        # node; reject with code='guard_failed' if any guard returns false.

        cypher = """
        MATCH (r:Request {id: $request_id})-[cur:CURRENTLY_IN]->(from_stage:Stage)
        MATCH (target:Stage {id: $to_stage_id})
        DELETE cur
        CREATE (r)-[:CURRENTLY_IN]->(target)
        SET r.current_stage_id = target.id
        CREATE (event:TransitionEvent {
            id: randomUUID(),
            request_id: r.id,
            from_stage: from_stage.id,
            to_stage: target.id,
            actor: $actor,
            at: datetime(),
            rationale: $rationale
        })
        CREATE (r)-[:HAS_TRANSITION_EVENT]->(event)
        RETURN r AS request, target AS current_stage, event AS event
        """
        driver = get_driver()
        async with driver.session() as session:
            result = await session.run(
                cypher,
                request_id=str(request_id),
                to_stage_id=to_stage_id,
                actor=actor,
                rationale=rationale,
            )
            record = await result.single()

        if record is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail={"code": "request_not_found", "message": "Request not found"},
            )

        r = record["request"]
        stage = record["current_stage"]
        e = record["event"]

        request = Request(
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
        )
        event = TransitionEvent(
            id=UUID(e["id"]),
            request_id=UUID(e["request_id"]),
            from_stage=e.get("from_stage"),
            to_stage=e["to_stage"],
            actor=e["actor"],
            at=e["at"].to_native(),
            rationale=e.get("rationale"),
        )
        logger.info(
            "transition_executed",
            request_id=str(request_id),
            from_stage=event.from_stage,
            to_stage=event.to_stage,
            actor=actor,
        )
        return TransitionResult(request=request, event=event)


def get_workflow_engine() -> WorkflowEngine:
    return WorkflowEngine()
