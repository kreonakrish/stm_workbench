"""STM Workbench backend application.

Entry point for the FastAPI application. Wires up middleware, routers,
and lifecycle hooks. Keep this file thin; logic lives in routers and services.
"""
from __future__ import annotations

import logging
from contextlib import asynccontextmanager
from typing import AsyncIterator

import structlog
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api import (
    crawler,
    health,
    intake,
    ontology,
    requests as requests_router,
    workflow,
)
from app.config import get_settings
from app.graph.driver import close_driver, get_driver
from app.middleware import RequestIdMiddleware

logger = structlog.get_logger(__name__)


def configure_logging() -> None:
    """Configure structured JSON logging."""
    logging.basicConfig(
        format="%(message)s",
        level=logging.INFO,
    )
    structlog.configure(
        processors=[
            structlog.contextvars.merge_contextvars,
            structlog.processors.add_log_level,
            structlog.processors.TimeStamper(fmt="iso"),
            structlog.processors.dict_tracebacks,
            structlog.processors.JSONRenderer(),
        ],
        wrapper_class=structlog.make_filtering_bound_logger(logging.INFO),
        logger_factory=structlog.PrintLoggerFactory(),
    )


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncIterator[None]:
    """Startup and shutdown lifecycle for the application."""
    configure_logging()
    settings = get_settings()
    logger.info("starting_app", environment=settings.environment)

    # Initialize Neo4j driver eagerly so connection issues surface at startup
    driver = get_driver()
    await driver.verify_connectivity()
    logger.info("neo4j_connected", uri=settings.neo4j_uri)

    yield

    logger.info("shutting_down")
    await close_driver()


def create_app() -> FastAPI:
    """Application factory."""
    settings = get_settings()
    app = FastAPI(
        title="STM Workbench",
        description="Workflow platform for STM lifecycle automation",
        version="0.1.0",
        lifespan=lifespan,
    )

    # Middleware
    app.add_middleware(RequestIdMiddleware)
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origins,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    # Routers
    app.include_router(health.router, tags=["health"])
    app.include_router(requests_router.router, prefix="/api/v1", tags=["requests"])
    app.include_router(ontology.router, prefix="/api/v1", tags=["ontology"])
    app.include_router(workflow.router, prefix="/api/v1", tags=["workflow"])
    app.include_router(intake.router, prefix="/api/v1", tags=["intake"])
    app.include_router(crawler.router, prefix="/api/v1", tags=["crawler"])

    return app


app = create_app()
