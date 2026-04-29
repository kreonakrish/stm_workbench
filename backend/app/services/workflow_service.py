"""Workflow template service — read-only access to seeded templates."""
from __future__ import annotations

import structlog
from fastapi import HTTPException, status

from app.config import get_settings
from app.domain.workflow import (
    StageDefinition,
    TransitionDefinition,
    WorkflowTemplate,
)
from app.graph.driver import get_driver
from app.graph.queries import get_query

logger = structlog.get_logger(__name__)


class WorkflowService:
    async def get_template(self, template_id: str) -> WorkflowTemplate:
        driver = get_driver()
        async with driver.session(database=get_settings().neo4j_database) as session:
            result = await session.run(
                get_query("get_workflow_template"), template_id=template_id
            )
            record = await result.single()

        if record is None or record["template"] is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Workflow template '{template_id}' not found",
            )

        template_props = record["template"]
        stages = [StageDefinition(**s) for s in record["stages"] or [] if s.get("id")]
        transitions = [
            TransitionDefinition(**t)
            for t in record["transitions"] or []
            if t.get("id")
        ]
        return WorkflowTemplate(
            id=template_props["id"],
            name=template_props["name"],
            version=template_props["version"],
            stages=stages,
            transitions=transitions,
        )


def get_workflow_service() -> WorkflowService:
    return WorkflowService()
