"""Workflow templates API."""
from __future__ import annotations

from fastapi import APIRouter, Depends

from app.domain.workflow import WorkflowTemplate
from app.services.workflow_service import WorkflowService, get_workflow_service

router = APIRouter()


@router.get(
    "/templates/{template_id}",
    response_model=WorkflowTemplate,
    summary="Fetch a workflow template with stages and transitions",
)
async def get_workflow_template(
    template_id: str,
    service: WorkflowService = Depends(get_workflow_service),
) -> WorkflowTemplate:
    return await service.get_template(template_id)
