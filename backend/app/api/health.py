"""Health endpoints — liveness and readiness."""
from __future__ import annotations

from fastapi import APIRouter, status
from pydantic import BaseModel

from app.graph.driver import get_driver

router = APIRouter()


class HealthStatus(BaseModel):
    status: str
    neo4j: str


@router.get("/health", status_code=status.HTTP_200_OK, response_model=HealthStatus)
async def health() -> HealthStatus:
    """Liveness probe."""
    return HealthStatus(status="ok", neo4j="not_checked")


@router.get("/ready", status_code=status.HTTP_200_OK, response_model=HealthStatus)
async def ready() -> HealthStatus:
    """Readiness probe — verifies Neo4j connectivity."""
    driver = get_driver()
    try:
        await driver.verify_connectivity()
        return HealthStatus(status="ready", neo4j="ok")
    except Exception as exc:
        return HealthStatus(status="degraded", neo4j=f"error: {exc!s}")
