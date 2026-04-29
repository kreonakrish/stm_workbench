"""Ontology API — schema visualization and typeahead search."""
from __future__ import annotations

from fastapi import APIRouter, Depends, Query

from app.domain.ontology import OntologySchema
from app.domain.ontology_search import SearchResponse
from app.services.ontology_service import OntologyService, get_ontology_service

router = APIRouter()


@router.get(
    "/ontology/schema",
    response_model=OntologySchema,
    summary="Return the metagraph: labels, relationship types, and counts",
)
async def get_ontology_schema(
    service: OntologyService = Depends(get_ontology_service),
) -> OntologySchema:
    return await service.get_schema()


@router.get(
    "/ontology/search",
    response_model=SearchResponse,
    summary="Typeahead over labels and indexed properties",
)
async def search_ontology(
    q: str = Query(..., min_length=1, description="Substring to match"),
    cursor: str | None = Query(None, description="Opaque pagination cursor"),
    limit: int = Query(20, ge=1, le=100),
    service: OntologyService = Depends(get_ontology_service),
) -> SearchResponse:
    return await service.search(query=q, cursor=cursor, limit=limit)
