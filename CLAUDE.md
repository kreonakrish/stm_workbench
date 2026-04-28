# STM Workbench — Claude Code Instructions

## What this project is
A workflow platform that automates the Source-to-Target Mapping (STM) lifecycle
for the Home Lending Knowledge Graph. Single source of truth is Neo4j. Stages:
Intake → Discovery → JAD → DRB → STM → Sync (Catalog + Erwin). All workflow
state, decisions, comments, approvals, mappings, and lineage are graph data.

## Non-negotiable architectural rules
1. **Neo4j is the single source of truth.** Never introduce a parallel RDBMS
   for workflow state, requests, decisions, or STMs. Catalog and Erwin are
   downstream subscribers, not co-equal sources.
2. **Workflow definition is graph data, not code.** Stages, transitions, and
   guards are nodes and edges. Adding a stage must not require a deploy.
3. **STM versioning is temporal graph modeling.** Each version is a full
   subgraph linked by `:SUPERSEDES`. Never overwrite an STM in place.
4. **Every user action produces a graph edit with provenance.** Comments,
   approvals, transitions, edits — all are nodes with author, timestamp,
   rationale where applicable.
5. **Sealed Spark transformation engine contract.** Generated PySpark must
   accept only business/operational date partitions. No first-occurrence
   detection inside the engine. If a mapping would violate the contract,
   flag it at conformance pre-check, not at code generation.
6. **Idempotent sync to downstream systems.** Erwin and Catalog writes must
   be retryable without side effects. Reconciliation reports run nightly.

## Tech stack (do not change without explicit approval via ADR)
- Python 3.12, FastAPI for the API layer
- Neo4j 5.x with the official Python driver (use `neo4j.AsyncDriver`)
- Pydantic v2 for all request/response models
- React 18 + TypeScript + Vite for the frontend
- shadcn/ui component library + Tailwind for styling
- pytest for backend tests, Vitest for frontend tests
- Auth via the bank's SSO (OAuth2/OIDC); never build custom auth
- Background jobs via Celery + Redis
- Containerized deployment, target Kubernetes

## Repository layout
```
/backend
  /app
    /api          # FastAPI routers per resource
    /domain       # Domain models (Pydantic), pure business logic
    /graph        # Neo4j queries, schema management, migrations
    /services     # Cross-cutting services (cascade, validation, conformance)
    /workflow     # Workflow engine: state machine over graph data
    /crawlers     # Source crawlers (existing + new Ab Initio, Informatica)
    /codegen      # PySpark + DDL template engine
    /sync         # Erwin and Catalog sync clients
    /jobs         # Celery tasks
  /tests
/frontend
  /src
    /pages        # Intake, Discovery, JAD board, DRB, STM views
    /components   # Reusable UI primitives
    /api          # Generated TypeScript client from FastAPI OpenAPI
    /hooks
/schemas
  /neo4j          # Cypher schema migrations, numbered
  /openapi        # OpenAPI specs (generated)
/docs
  /adr            # Architecture decision records
  /runbooks
```

## How to work in this codebase

### Before writing code
- Read `/schemas/neo4j/README.md` and the latest migration to understand
  the current node and relationship types.
- Read `/docs/adr/` for prior architectural decisions. Do not contradict them.
- Read `/docs/build-plan.md` to identify the task ID you are working on.
- For any new feature, identify which existing module owns it. Do not create
  a new module unless none of the existing ones is a fit.

### When writing Cypher
- All Cypher lives in `/backend/app/graph/queries/` as named `.cypher` files
  loaded via a registry. Never inline Cypher strings in business logic.
- Every query has a corresponding integration test against a test Neo4j
  instance with seeded data.
- Use parameterized queries always. Never f-string user input into Cypher.
- Prefer `MATCH` with explicit relationship direction. Bidirectional matches
  are a code smell; investigate before using.

### When writing API endpoints
- Every endpoint has a Pydantic request and response model.
- Endpoints are thin: validate input, call a service, return response.
  Business logic lives in `/backend/app/services/`.
- Every endpoint has at minimum: a happy-path test, an auth-failure test,
  and a validation-failure test.
- Mutations return the updated resource state, not just a 200.

### When writing the frontend
- Use the generated TypeScript client from `/frontend/src/api/`. Do not
  hand-write fetch calls.
- State management: TanStack Query for server state, React Context only
  for genuinely cross-cutting client state (auth, theme).
- Components in `/frontend/src/components/` are presentational and
  prop-driven. Pages in `/frontend/src/pages/` orchestrate.
- Every component that fetches data has loading, error, and empty states.

### Scalability requirements (large user base)
- All list endpoints must support cursor-based pagination. No offset
  pagination on graph queries — it does not scale.
- All graph queries must have a `LIMIT` clause and a documented expected
  cardinality. Unbounded traversals are forbidden.
- The Discovery cascade runs as an async Celery task, not in the request
  thread. The intake API returns immediately; the UI polls or subscribes.
- Use Redis for caching read-heavy graph queries (Erwin model snapshot,
  workflow templates, ownership graph). Cache invalidation on graph writes
  via a pub/sub channel.
- The JAD Kanban board uses server-sent events for real-time updates,
  not polling. SSE channel per workflow stage.
- Every Cypher query has an `EXPLAIN` reviewed before merge for queries
  expected to run >100/min.

### Security and compliance
- Every API endpoint requires authentication. No exceptions.
- Authorization is policy-based: a request action is allowed if the user's
  role matches the stage's allowed-actor list in the workflow definition.
- All graph mutations carry `created_by`, `created_at`, and where applicable
  `rationale`. The audit trail is the graph itself.
- PII handling: physical column nodes carry a `pii_classification` tag;
  the cascade and codegen respect it.

## What NOT to do
- Do not introduce a new database. Neo4j is canonical, Redis is cache, that's it.
- Do not build a custom workflow engine framework. The state machine is
  thin code reading from graph-defined transitions.
- Do not add a real-time collaborative editor. Async comments are sufficient.
- Do not generate code with embedded Cypher strings — load from `.cypher` files.
- Do not add new Python or npm dependencies without justification in an ADR.
- Do not refactor existing modules opportunistically. If a refactor is
  needed, propose it as a separate task and get approval before starting.

## How to run a session
1. State the task ID from `/docs/build-plan.md` you are working on.
2. Read CLAUDE.md, the relevant ADRs, and the schema README.
3. Implement the task end-to-end (code + tests + docs).
4. Run the full test suite locally before declaring complete.
5. Confirm against the Definition of Done below.
6. Commit with the task ID in the message.

## Definition of done for any task
- [ ] Code follows the layout and conventions above
- [ ] Pydantic models for all API inputs and outputs
- [ ] Cypher queries in `.cypher` files with tests
- [ ] Unit tests passing, integration tests passing
- [ ] OpenAPI spec regenerated, TypeScript client regenerated (if API changed)
- [ ] No new dependencies without ADR
- [ ] Performance: list endpoints paginated, graph queries bounded
- [ ] Audit trail: all mutations carry provenance
- [ ] Documentation: any new module has a README; any architectural choice
      has an ADR in `/docs/adr/`
