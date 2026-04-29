"""Crawler API — trigger a crawl run and persist the observations."""
from __future__ import annotations

from fastapi import APIRouter, Depends, status

from app.domain.physical import CrawlRunInput, CrawlRunResult
from app.services.crawler_service import (
    CrawlerService,
    get_crawler_service,
)

router = APIRouter()


@router.post(
    "/crawler/runs",
    response_model=CrawlRunResult,
    status_code=status.HTTP_201_CREATED,
    summary="Trigger a crawler run; upserts physical-source nodes",
)
async def run_crawler(
    payload: CrawlRunInput,
    service: CrawlerService = Depends(get_crawler_service),
) -> CrawlRunResult:
    return await service.run(payload)
