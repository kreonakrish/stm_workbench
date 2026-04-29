"""Intake helpers — preview classification and Excel ingest.

Both endpoints return the *classified* form of the change lines without
persisting anything, so the user can iterate on a draft before
submitting via POST /api/v1/requests.
"""
from __future__ import annotations

from uuid import uuid4

from fastapi import APIRouter, Depends, File, HTTPException, UploadFile, status

from app.domain.requests import ChangeLine, ChangeLineInput
from app.services.excel_service import ExcelParseError, parse_excel
from app.services.validation_service import (
    ValidationService,
    get_validation_service,
)

router = APIRouter()


@router.post(
    "/intake/preview",
    response_model=list[ChangeLine],
    summary="Classify a list of change lines without persisting them",
)
async def preview_intake(
    items: list[ChangeLineInput],
    validator: ValidationService = Depends(get_validation_service),
) -> list[ChangeLine]:
    return await validator.classify_all(
        request_id=str(uuid4()), items=items
    )


@router.post(
    "/intake/parse-excel",
    response_model=list[ChangeLine],
    summary="Parse an .xlsx upload into classified change lines (no persist)",
)
async def parse_excel_upload(
    file: UploadFile = File(...),
    validator: ValidationService = Depends(get_validation_service),
) -> list[ChangeLine]:
    if file.filename and not file.filename.lower().endswith(".xlsx"):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Upload must be an .xlsx file",
        )
    content = await file.read()
    try:
        items = parse_excel(content)
    except ExcelParseError as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail=str(exc)
        ) from exc
    return await validator.classify_all(
        request_id=str(uuid4()), items=items
    )
