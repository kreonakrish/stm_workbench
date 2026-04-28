# ADR 0001: Neo4j is the single source of truth

## Status
Accepted

## Context
The platform spans workflow state, catalog metadata, lineage, business
glossary, and STM versioning. A common failure pattern in enterprise data
platforms is splitting these across a relational workflow database and a
graph catalog, which produces synchronization problems and dual sources
of truth.

## Decision
Neo4j holds all of: catalog metadata, requests, decisions, comments,
approvals, workflow definitions, STMs, STM versions, generated code
references, Erwin model snapshots, and lineage. Erwin Mart and the
external Catalog (Collibra/Alation/etc.) are downstream subscribers
reconciled to the graph.

Redis is used as a cache for read-heavy graph queries. Redis is not a
source of truth — its contents must always be reconstructible from the
graph.

## Consequences
- All application state queries are Cypher. Backend developers must be
  fluent in Cypher.
- Schema migrations are Cypher migrations, numbered and committed in
  `/schemas/neo4j/`.
- Performance work focuses on Cypher query optimization, indexing, and
  Redis caching of expensive read queries.
- Reconciliation jobs detect drift between graph and downstream systems
  and report (do not auto-correct) discrepancies.
- Backup and disaster recovery plans treat the Neo4j cluster as the
  primary data tier.
