# ADR 0007: Bootstrap the business ontology via a one-time migration

## Status
Accepted

## Context
The STM workbench validates intake requests against the home-lending
business ontology to classify each requested attribute as
already-exists / net-new / needs-change-logic (see the project memory on
intake scope). The canonical ontology cypher lives at
`github.com/kreonakrish/hl_knowledge_graph/tree/main/cypher` and was
hand-curated by the same author as this workbench.

Two ways to bring that schema into the workbench Neo4j:

1. **One-time migration import.** Snapshot the hl_knowledge_graph schema
   (constraints + indexes) into a numbered migration file in
   `/schemas/neo4j/`. Re-running is idempotent (`IF NOT EXISTS`).
   Subsequent ontology evolution is handled by additional migrations.
2. **Periodic sync.** Have a Celery job pull the hl_knowledge_graph repo
   on a schedule and apply diffs.

Per ADR 0001, this graph is the single source of truth — once imported,
the schema is ours. The hl_knowledge_graph repo is the upstream curated
source, but we own our copy. Sync is only valuable if the upstream is a
fast-moving live system; it is not — it is a curated reference.

## Decision
Use **option 1**: one-time idempotent migration import.

- Migration `003_ontology_bootstrap.cypher` snapshots
  `hl_knowledge_graph/cypher/00_schema/01_constraints.cypher` and
  `02_indexes.cypher` at this date and applies them in our Neo4j.
- All `CREATE CONSTRAINT` and `CREATE INDEX` statements use
  `IF NOT EXISTS`, so re-running is safe.
- Future ontology schema changes land as new numbered migrations
  (`004_ontology_<topic>.cypher`, etc.), authored against the upstream
  diff.
- The seeding of ontology *instance data* (Borrower, MortgageLoan, etc.)
  is intentionally out of scope for this migration — it belongs to
  per-domain seed scripts that can be replayed independently.

## Consequences
**Easier**
- The migration runner already supports `IF NOT EXISTS` cypher and
  records applied migrations on `:SchemaMigration` nodes — no new
  machinery.
- Diffing future schema changes against this snapshot is a normal git
  diff against migration 003.
- New environments bootstrap by running migrations end-to-end. No
  external dependency on the hl_knowledge_graph repo at runtime.

**Harder**
- The two schemas can drift if upstream evolves and we forget to write a
  migration. Mitigation: a recurring task to diff upstream against
  `migration 003` (and successors) and open a PR if changes are warranted.
- Bulk schema changes upstream produce one big diff to translate into
  migrations.

## Notes
- The hl_knowledge_graph constraints define an `:WorkflowStage` label
  that conceptually overlaps with our workflow nodes. Migration 002
  (per ADR 0006) namespaces ours as `:STM*` to keep the layers disjoint.
- Ontology instance data ingestion (crawler-driven enrichment per the
  project memory) is a separate concern and lands in its own ADR when
  designed.
