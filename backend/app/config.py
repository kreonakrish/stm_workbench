"""Application configuration loaded from environment variables.

Uses pydantic-settings for typed, validated config. Add new settings here;
do not read os.environ directly elsewhere in the codebase.
"""
from __future__ import annotations

from functools import lru_cache
from typing import Literal

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
    )

    # Environment
    environment: Literal["local", "dev", "staging", "prod"] = "local"

    # Neo4j
    neo4j_uri: str = "bolt://localhost:7687"
    neo4j_user: str = "neo4j"
    neo4j_password: str = "password"
    neo4j_database: str = "neo4j"
    neo4j_max_connection_pool_size: int = 50

    # Redis
    redis_url: str = "redis://localhost:6379/0"

    # Auth (placeholder; replaced with real SSO in T-053)
    jwt_secret: str = "dev-secret-replace-in-prod"
    jwt_algorithm: str = "HS256"

    # CORS
    cors_origins: list[str] = Field(default_factory=lambda: ["http://localhost:5173"])

    # Celery
    celery_broker_url: str = "redis://localhost:6379/1"
    celery_result_backend: str = "redis://localhost:6379/2"


@lru_cache(maxsize=1)
def get_settings() -> Settings:
    """Return cached Settings instance."""
    return Settings()
