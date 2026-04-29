"""Extract FIBO LOAN module owl:Class nodes into a Neo4j seed migration.

Parses every .rdf under FIBO's LOAN/ directory, pulls out classes with
human-readable rdfs:label and skos:definition annotations, filters for
loan / mortgage / lending relevance, and emits a Cypher migration that
upserts each as a :Entity node with `description` derived from the
FIBO definition.

Usage:
    uv run --with rdflib python scripts/extract_fibo_loan_entities.py \\
        --fibo-dir /path/to/fibo \\
        --out schemas/neo4j/009_fibo_loan_entities.cypher
"""
from __future__ import annotations

import argparse
import re
from pathlib import Path

from rdflib import Graph, RDF, RDFS, OWL, URIRef
from rdflib.namespace import SKOS

KEYWORDS = (
    "mortgage",
    "loan",
    "credit",
    "borrower",
    "lender",
    "lending",
    "amortiz",
    "arm",
    "heloc",
    "refinance",
    "escrow",
    "servic",
    "underwrit",
    "appraisal",
    "lien",
    "foreclos",
    "real estate",
    "closing disclosure",
    "rate lock",
    "prepayment",
    "balloon",
    "buydown",
    "originator",
    "originat",
    "investor",
    "warehouse",
    "secondary market",
    "guarantee",
    "msr",
    "default",
    "delinqu",
    "modification",
    "forbearance",
)


def relevant(label: str | None, definition: str | None) -> bool:
    if not label and not definition:
        return False
    text = f"{label or ''} {definition or ''}".lower()
    return any(k in text for k in KEYWORDS)


def to_entity_name(label: str) -> str:
    """Convert an `rdfs:label` to a UpperCamelCase entity name."""
    cleaned = re.sub(r"[^a-zA-Z0-9 ]", " ", label)
    parts = [p for p in cleaned.split() if p]
    if not parts:
        return label.strip()
    return "".join(p[:1].upper() + p[1:] for p in parts)


def first_text(g: Graph, subject: URIRef, predicate: URIRef) -> str | None:
    for value in g.objects(subject, predicate):
        text = str(value).strip()
        if text:
            return text
    return None


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--fibo-dir", required=True, type=Path)
    parser.add_argument("--out", required=True, type=Path)
    args = parser.parse_args()

    loan_dir = args.fibo_dir / "LOAN"
    if not loan_dir.is_dir():
        raise SystemExit(f"LOAN/ not found in {args.fibo_dir}")

    classes: dict[str, dict[str, str]] = {}
    for rdf_path in sorted(loan_dir.rglob("*.rdf")):
        graph = Graph()
        try:
            graph.parse(str(rdf_path), format="application/rdf+xml")
        except Exception as exc:
            print(f"skip {rdf_path}: {exc}")
            continue

        for cls in graph.subjects(RDF.type, OWL.Class):
            if not isinstance(cls, URIRef):
                continue
            label = first_text(graph, cls, RDFS.label)
            if not label:
                continue
            definition = first_text(graph, cls, SKOS.definition)
            if not relevant(label, definition):
                continue
            entity_name = to_entity_name(label)
            existing = classes.get(entity_name)
            if existing and existing.get("definition"):
                continue
            classes[entity_name] = {
                "label": label,
                "definition": definition or "",
                "iri": str(cls),
            }

    print(f"extracted {len(classes)} relevant FIBO LOAN classes")

    lines = [
        "// Migration 009 — FIBO LOAN entity expansion.",
        "//",
        "// Imports curated owl:Class nodes from the FIBO LOAN module",
        "// (https://github.com/edmcouncil/fibo, MIT licensed) as :Entity nodes.",
        "// Filtered to mortgage- / loan- / lending-relevant classes via a keyword",
        "// match on rdfs:label + skos:definition.",
        "//",
        "// FIBO classes are formal ontology concepts; their `description` here is",
        "// the verbatim skos:definition. The FIBO IRI is preserved in the",
        "// `fibo_iri` property so future migrations can resolve back to the source.",
        "//",
        "// Idempotent (MERGE on Entity name).",
        "",
    ]

    for name in sorted(classes):
        info = classes[name]
        # Escape single quotes for Cypher
        definition = info["definition"].replace("'", r"\'")
        # Also handle semicolons and newlines that would break the migration runner
        definition = re.sub(r"\s+", " ", definition).strip()
        definition = definition.replace(";", ",")
        iri = info["iri"]
        lines.append(
            f"MERGE (e:Entity {{name: '{name}'}}) "
            f"ON CREATE SET e.description = '{definition}', e.fibo_iri = '{iri}', e.source = 'FIBO LOAN' "
            f"ON MATCH SET e.fibo_iri = coalesce(e.fibo_iri, '{iri}');"
        )

    lines.append("")
    lines.append(
        "MERGE (m:SchemaMigration {migration_id: '009_fibo_loan_entities'}) "
        "ON CREATE SET m.applied_at = datetime(), "
        f"m.description = 'FIBO LOAN entity import — {len(classes)} mortgage/loan-relevant classes from edmcouncil/fibo (MIT)';"
    )

    args.out.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"wrote {args.out}")


if __name__ == "__main__":
    main()
