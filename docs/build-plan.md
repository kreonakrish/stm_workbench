# Build plan — V1 (3-6 months, 2-4 engineers)

## How to use this document
- Each task has an ID (e.g. T-001). Reference IDs in commits and PR titles.
- Tasks within a phase can sometimes be parallelized; phases must be sequential.
- "Out of V1 scope" tasks are explicitly deferred to V2. Do not start them.
- When a task is complete, update its checkbox here and tag the commit
  with the task ID.

---

## Phase 1 — Foundation (weeks 1-4)
Goal: a working skeleton that runs locally with tests, schema, and CI.

- [ ] **T-001**: Repo scaffolding
  - Backend: pyproject.toml, FastAPI skeleton, pytest configured
  - Frontend: package.json, Vite + React + TS skeleton
  - Schemas, docs, .claude directories already populated
  - docker-compose.yml for local Neo4j + Redis
  - Pre-commit hooks for ruff, mypy, eslint

- [ ] **T-002**: Neo4j schema migration framework + migration 001
  - Migration runner in `/backend/app/graph/migrations.py`
  - Reads numbered .cypher files, tracks applied migrations
  - Migration 001 already drafted; runner applies it
  - Test: clean DB → run migrations → verify constraints exist

- [ ] **T-003**: FastAPI app skeleton
  - Health endpoint, OpenAPI generation
  - Auth middleware (placeholder JWT validator; SSO integration in T-053)
  - Structured error handling, request ID propagation
  - Logging with correlation IDs

- [ ] **T-004**: Neo4j async driver wrapper + query loader
  - Driver lifecycle management (startup/shutdown)
  - Cypher query loader: `.cypher` files in queries/, named registry
  - Integration test harness: spin up test Neo4j, apply migrations,
    seed data, run queries
  - Connection pool tuning baseline

- [ ] **T-005**: Pydantic domain models
  - Request, Stage, Transition, Mapping, MappingVersion, etc.
  - Validators for usage_context, severity, decision enums
  - Tests for serialization and validation edge cases

- [ ] **T-006**: Workflow engine
  - Load template from graph by ID
  - Compute allowed transitions from current stage
  - Validate guard expressions (start with simple role-based guards)
  - Execute transition: write event, update current stage pointer
  - Tests cover: valid transition, invalid transition, guard rejection

- [ ] **T-007**: Frontend skeleton
  - Vite + React 18 + TS + Tailwind + shadcn/ui setup
  - Layout shell with auth-aware nav
  - Loading, error, and empty state primitives in /components
  - Routing with react-router

- [ ] **T-008**: OpenAPI → TypeScript client pipeline
  - openapi-typescript codegen integrated into npm scripts
  - Generated client lives in /frontend/src/api/, never hand-edited
  - CI step: regenerate client, fail if drift

---

## Phase 2 — Crawlers and Erwin reader (weeks 4-8)
Goal: legacy ETL metadata and Erwin model state in the graph.

- [ ] **T-010**: Ab Initio EME crawler
  - Read-only metadata extraction via `air` commands or EME API
  - Produces `:AbInitioGraph`, `:AbInitioComponent` nodes and lineage edges
  - Scheduled refresh via Celery beat
  - Documented runbook for environment-specific config

- [ ] **T-011**: Informatica repository crawler
  - PowerCenter OPB_* table queries (mappings, sessions, workflows)
  - IICS REST API support if applicable
  - Produces `:InformaticaMapping` nodes with column-level lineage
  - Scheduled refresh

- [ ] **T-012**: Erwin Mart reader
  - REST API client for Erwin DI Suite (or XML export ingestion fallback)
  - Snapshot stored as `:ErwinModelSnapshot` with `:ErwinEntity` children
  - Scheduled daily refresh; content-hash detects changes
  - Time-box discovery to 2 weeks; if blocked, document fallback path

- [ ] **T-013**: Crawler observability
  - Metrics: last successful run, items extracted, errors
  - Slack/email alerts on failure
  - Admin UI placeholder showing crawler status

---

## Phase 3 — Discovery cascade (weeks 6-12)
Goal: automated mapping suggestions with conformance pre-check.

- [ ] **T-020**: Cascade orchestrator
  - Async Celery task triggered on intake submission
  - Orchestrates layers in order, stops early on high-confidence match
  - Writes results back to request as graph nodes
  - Status updates published via SSE/Redis pub-sub

- [ ] **T-021**: Layer 0 — Prior-evidence retrieval
  - Cypher queries against existing Ab Initio + Informatica edges
  - "This source column is mapped to this target in N existing graphs"
  - Confidence scored by number and recency of prior mappings

- [ ] **T-022**: Layer 1 — Exact and fuzzy match
  - Exact: name + type match
  - Fuzzy: token overlap, Levenshtein
  - Returns ranked candidates with confidence

- [ ] **T-023**: Layer 2 — Embedding similarity
  - Reuse existing embedding pipeline if available
  - Embed column descriptions + sample values
  - Cosine similarity against UDM target attribute embeddings

- [ ] **T-024**: Layer 3 — KG-context reuse
  - Lineage-based: "this column flows from a column already mapped to X"
  - Graph traversal queries

- [ ] **T-025**: Validation runner
  - Type and nullability checks
  - Cardinality and distinct-count comparison
  - Sample-row probe applying transform to N rows
  - Results attached to candidate mapping

- [ ] **T-026**: Conformance pre-check service
  - Runs against current `:ErwinModelSnapshot`
  - Checks: target exists, type alignment, naming convention
  - Checks against `:ContractRule` nodes (sealed engine rules)
  - Produces `:ConformanceFinding` nodes with severity

- [ ] **T-027**: Cascade results UI integration
  - Discovery workspace renders ranked candidates
  - Reviewer can accept/reject/extend; actions persist as graph edits

---

## Phase 4 — Workflow surface (weeks 10-18)
Goal: end-to-end stakeholder UX from Intake through DRB.

- [ ] **T-030**: Intake API + form UI
  - Structured form: business_question, usage_context,
    consumption_pattern, deadline
  - Creates `:Request` node, triggers cascade
  - Status page for requester

- [ ] **T-031**: Routing engine
  - Graph lookup of ownership based on UDM domain + source systems
  - Auto-assigns DRI per stage
  - Suggested-owner fallback when no exact match

- [ ] **T-032**: Discovery workspace UI
  - Reviewer view: pre-loaded candidates with evidence
  - Accept / reject / extend / escalate-to-JAD actions
  - Disagreement reason codes captured

- [ ] **T-033**: JAD Kanban board UI
  - Stage columns, request cards, drag-to-transition
  - SSE for real-time updates
  - Saved views per user

- [ ] **T-034**: Comment threads
  - Threaded comments on requests (parent_comment_id)
  - @-mentions trigger notifications
  - Markdown rendering, link to request artifacts

- [ ] **T-035**: DRB approval workspace
  - Conformance findings prominent at top
  - Multi-approver model: each approver records individual decision
  - Conditional approval with structured conditions
  - Bulk approve for green-conformance items (V1.5; flag-gated)

- [ ] **T-036**: STM authoring UI
  - Draft pre-populated from Discovery + JAD outputs
  - Form-driven editing, inline validation
  - On approval: create `:MappingVersion`, supersede prior version
  - Version diff view

- [ ] **T-037**: Status views
  - "My queue" — requests where user is DRI
  - "Awaiting my input" — requests where user is consulted
  - "Watching" — requests where user is informed
  - Filters: stage, usage_context, deadline

---

## Phase 5 — Codegen and lineage (weeks 16-22)
Goal: approved STMs produce executable artifacts; backtrack works.

- [ ] **T-040**: PySpark template (one canonical pattern)
  - Sealed-engine contract: business/operational date partitions only
  - Reads from approved `:MappingVersion`
  - Output stored as `:GeneratedCodeArtifact` with content hash

- [ ] **T-041**: DDL template (Snowflake target)
  - Generates CREATE TABLE / CREATE OR REPLACE TABLE
  - Respects column types, constraints from target attribute definitions

- [ ] **T-042**: Codegen service
  - Reads approved STM subgraph
  - Renders templates, stores artifacts, links to MappingVersion
  - Regeneration produces new artifact with `:SUPERSEDES`

- [ ] **T-043**: Attribute backtrack API
  - Cypher traversal: from any attribute back through versions to sources
  - Returns request, JAD decisions, approvals along the path
  - Exposed as REST endpoint and as graph query example

- [ ] **T-044**: STM version diff view in UI
  - Side-by-side comparison of two MappingVersions
  - Highlights what changed and why (linked to driving request)

---

## Phase 6 — Pilot and harden (weeks 22-26)
Goal: real users on real requests, measurable outcomes, V2 readiness.

- [ ] **T-050**: Pilot onboarding
  - Pick stakeholder group (recommend D&A) and one subject area
  - Migrate 5-10 in-flight requests into the platform
  - Daily standups with pilot users for first 2 weeks

- [ ] **T-051**: Observability
  - Metrics: cycle time per stage, request throughput, cascade hit rate
  - Logs centralized; trace IDs propagate end-to-end
  - SLA-clock dashboard published to stakeholders

- [ ] **T-052**: Performance hardening
  - EXPLAIN review for all queries running >100/min
  - Redis caching for hot reads (Erwin snapshot, workflow templates)
  - Pagination audit on all list endpoints

- [ ] **T-053**: Security and SSO integration
  - Replace placeholder auth with real OAuth2/OIDC
  - Threat model documented
  - Pen-test prep checklist

- [ ] **T-054**: V2 contract design
  - API contract for Erwin write-back (validated against Erwin docs)
  - API contract for Catalog sync (Collibra/Alation/etc.)
  - Reconciliation report design

---

## Out of V1 scope (do not start without explicit approval)
- Erwin write-back implementation
- Catalog sync (any direction)
- LLM layer of cascade beyond what existing pipeline provides
- Multiple workflow templates (V1 ships one default template)
- Mobile UI
- Bulk approval actions (gated to V1.5 if pilot demand exists)
- Real-time collaborative editing
- Custom BI dashboards (use whatever stakeholders already use)
