"""Requests API — create, get, transition.

Endpoints are thin: validate input, call a service, return a response.
Business logic lives in /backend/app/services/.
"""
from __future__ import annotations

from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status

from app.domain.requests import (
    CreateRequestInput,
    Request,
    TransitionInput,
    TransitionResult,
)
from app.services.request_service import RequestService, get_request_service

router = APIRouter()


@router.post(
    "/requests",
    status_code=status.HTTP_201_CREATED,
    response_model=Request,
    summary="Create a new STM request",
)
async def create_request(
    payload: CreateRequestInput,
    service: RequestService = Depends(get_request_service),
    # TODO(T-053): replace with real authenticated user
    requester_id: str = "dev-user",
) -> Request:
    return await service.create_request(payload, requester_id=requester_id)


@router.get(
    "/requests/{request_id}",
    response_model=Request,
    summary="Fetch a request by ID",
)
async def get_request(
    request_id: UUID,
    service: RequestService = Depends(get_request_service),
) -> Request:
    request = await service.get_request(request_id)
    if request is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Request {request_id} not found",
        )
    return request


@router.post(
    "/requests/{request_id}/transition",
    response_model=TransitionResult,
    summary="Transition a request to a new stage",
)
async def transition_request(
    request_id: UUID,
    payload: TransitionInput,
    service: RequestService = Depends(get_request_service),
    # TODO(T-053): replace with real authenticated user
    actor: str = "dev-user",
) -> TransitionResult:
    return await service.transition(
        request_id=request_id,
        to_stage_id=payload.to_stage_id,
        rationale=payload.rationale,
        actor=actor,
    )
