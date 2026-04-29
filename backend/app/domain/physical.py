"""Pydantic models for physical-source nodes (systems / tables / columns)
and crawler runs."""
from __future__ import annotations

from datetime import datetime
from enum import Enum
from typing import Literal
from uuid import UUID

from pydantic import BaseModel, Field


class SystemKind(str, Enum):
    ORACLE = "oracle"
    MYSQL = "mysql"
    SNOWFLAKE = "snowflake"
    SQL_SERVER = "sql_server"
    GLUE = "glue"
    S3 = "s3"


class PhysicalColumn(BaseModel):
    id: str
    name: str
    table_id: str
    data_type: str | None = None
    nullable: bool | None = None


class PhysicalTable(BaseModel):
    id: str
    name: str
    schema_: str | None = Field(default=None, alias="schema")
    system_id: str

    model_config = {"populate_by_name": True}


class PhysicalSystem(BaseModel):
    id: str
    name: str
    kind: SystemKind


class CrawlerObservation(BaseModel):
    """One row a crawler emits — a fully-qualified column observation.

    A crawler produces a list of these; the linker upserts them into the graph.
    """
    system_id: str
    schema_: str | None = Field(default=None, alias="schema")
    table: str
    column: str
    data_type: str | None = None
    nullable: bool | None = None

    model_config = {"populate_by_name": True}


class CrawlRunInput(BaseModel):
    """Trigger a crawler. `connector` selects the crawler implementation."""
    connector: Literal["fixture", "demo"] = "fixture"
    system_id: str | None = None  # connector chooses its default if omitted


class CrawlRunResult(BaseModel):
    id: UUID
    connector: str
    system_id: str
    started_at: datetime
    finished_at: datetime
    columns_seen: int
    columns_linked: int
    columns_orphaned: int
