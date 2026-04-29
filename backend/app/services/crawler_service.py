"""Source-system crawlers + ontology linker.

A crawler observes the schema of one source system and emits a list of
:CrawlerObservation records; the linker upserts those into the workbench
graph as :PhysicalTable / :PhysicalColumn nodes and auto-links them to
:BusinessAttribute by case-insensitive name match.

The fixture connector ships in this module so the workflow can be
demonstrated end-to-end without a real database. Real connectors plug
into the same `Crawler` protocol.
"""
from __future__ import annotations

from datetime import datetime, timezone
from typing import Protocol
from uuid import uuid4

import structlog

from app.config import get_settings
from app.domain.physical import (
    CrawlerObservation,
    CrawlRunInput,
    CrawlRunResult,
)
from app.graph.driver import get_driver
from app.graph.queries import get_query

logger = structlog.get_logger(__name__)


class Crawler(Protocol):
    """A source-system crawler. Implementations are stateless and side-effect-free.

    The linker is responsible for persisting observations.
    """

    system_id: str

    async def crawl(self) -> list[CrawlerObservation]: ...


class FixtureCrawler:
    """Demo crawler: emits a small, hand-curated set of observations so the
    intake/validation workflow can be exercised without external systems.

    Observations include both columns the seed has already mapped (which
    will dedupe via MERGE) and a few that aren't yet in the seed (which
    the linker will register and either auto-link by name or leave
    orphaned for curation).
    """

    def __init__(self, system_id: str = "oracle_loan_prod") -> None:
        self.system_id = system_id

    async def crawl(self) -> list[CrawlerObservation]:
        if self.system_id == "oracle_loan_prod":
            return [
                CrawlerObservation(
                    system_id=self.system_id,
                    schema="LOAN_DB",
                    table="BORROWER",
                    column=col,
                    data_type=dtype,
                    nullable=nullable,
                )
                for col, dtype, nullable in [
                    ("BORROWER_ID", "VARCHAR2(20)", False),
                    ("FIRST_NAME", "VARCHAR2(50)", False),
                    ("LAST_NAME", "VARCHAR2(50)", False),
                    ("SSN", "VARCHAR2(11)", False),
                    ("DOB", "DATE", True),
                    ("EMAIL", "VARCHAR2(120)", True),
                    ("FICO_SCORE", "NUMBER(3)", True),
                    ("ANNUAL_INCOME", "NUMBER(12,2)", True),
                    ("EMPLOYMENT_STATUS", "VARCHAR2(20)", True),
                    # An attribute the seed does NOT currently know about — will
                    # be registered as orphaned for curation.
                    ("LAST_BUREAU_PULL_DT", "DATE", True),
                ]
            ]
        if self.system_id == "snowflake_analytics":
            return [
                CrawlerObservation(
                    system_id=self.system_id,
                    schema="ANALYTICS",
                    table="BORROWER_CREDIT_MONTHLY",
                    column=col,
                    data_type=dtype,
                    nullable=nullable,
                )
                for col, dtype, nullable in [
                    ("BORROWER_ID", "STRING", False),
                    ("CURRENT_FICO_SCORE", "NUMBER(3)", True),
                    ("AS_OF_DATE", "DATE", False),
                    # Orphan: not yet in the seed
                    ("FICO_BAND", "STRING", True),
                ]
            ]
        return []


class CrawlerService:
    """Orchestrates crawler runs: observe → upsert → record provenance."""

    async def run(self, payload: CrawlRunInput) -> CrawlRunResult:
        crawler = self._build_crawler(payload)
        started = datetime.now(timezone.utc)
        observations = await crawler.crawl()
        linked = 0
        seen = len(observations)

        driver = get_driver()
        async with driver.session(database=get_settings().neo4j_database) as session:
            for obs in observations:
                result = await session.run(
                    get_query("upsert_physical_column"),
                    system_id=obs.system_id,
                    schema=obs.schema_,
                    table=obs.table,
                    column=obs.column,
                    data_type=obs.data_type,
                    nullable=obs.nullable,
                )
                record = await result.single()
                if record and record["linked"]:
                    linked += 1

        finished = datetime.now(timezone.utc)
        run_id = str(uuid4())
        async with driver.session(database=get_settings().neo4j_database) as session:
            await session.run(
                get_query("record_crawl_run"),
                id=run_id,
                connector=payload.connector,
                system_id=crawler.system_id,
                started_at=started.isoformat(),
                finished_at=finished.isoformat(),
                columns_seen=seen,
                columns_linked=linked,
                columns_orphaned=seen - linked,
            )

        logger.info(
            "crawl_run_complete",
            connector=payload.connector,
            system_id=crawler.system_id,
            seen=seen,
            linked=linked,
            orphaned=seen - linked,
        )

        return CrawlRunResult(
            id=run_id,
            connector=payload.connector,
            system_id=crawler.system_id,
            started_at=started,
            finished_at=finished,
            columns_seen=seen,
            columns_linked=linked,
            columns_orphaned=seen - linked,
        )

    @staticmethod
    def _build_crawler(payload: CrawlRunInput) -> Crawler:
        if payload.connector in ("fixture", "demo"):
            return FixtureCrawler(system_id=payload.system_id or "oracle_loan_prod")
        raise ValueError(f"Unknown crawler connector: {payload.connector}")


def get_crawler_service() -> CrawlerService:
    return CrawlerService()
