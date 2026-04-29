"""Ontology API — schema visualization."""
from __future__ import annotations

from fastapi import APIRouter, Depends

from app.domain.ontology import OntologySchema
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
