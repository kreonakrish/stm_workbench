# STM Workbench

Workflow platform for automating the Source-to-Target Mapping (STM) lifecycle
on top of the Home Lending Knowledge Graph.

## What this is

A web application that takes data requests from intake through discovery, JAD,
DRB, STM authoring, and downstream sync — using Neo4j as the single source of
truth for catalog metadata, workflow state, decisions, and STM versions.

See `/docs/build-plan.md` for the V1 task breakdown.
See `/CLAUDE.md` for the architectural rules every contribution must follow.
See `/docs/adr/` for foundational decisions.

## Quick start

### Prerequisites
- Local Neo4j 5.x (Community or Enterprise) running on `neo4j://127.0.0.1:7687`
- Docker (for Redis only)
- Python 3.12+
- Node.js 20+
- `uv` (recommended) or `pip` for Python deps

### 1. Start dependencies
```bash
docker compose up -d        # Redis only
```

Redis runs on `localhost:46379`. Neo4j is **not** in docker-compose — start your
local Neo4j separately and confirm it's reachable at http://localhost:7474.
Set `NEO4J_PASSWORD` in your `backend/.env` (copy from `.env.example`).

### 2. Backend
```bash
cd backend
uv sync                                                       # install deps
uv run python -m app.graph.migrations                         # apply schema
uv run uvicorn app.main:app --host 127.0.0.1 --port 48000     # serve on :48000
```

OpenAPI docs at http://127.0.0.1:48000/docs.

### 3. Frontend
```bash
cd frontend
npm install
npm run generate-api    # regenerate TypeScript client from OpenAPI
npm run dev             # serve on :45173
```

### 4. Tests
```bash
cd backend && uv run pytest
cd frontend && npm test
```

## How to work in this repo

Read these in order:

1. **`/CLAUDE.md`** — Architectural rules. Non-negotiable.
2. **`/docs/build-plan.md`** — Numbered task list. Each session works on one task.
3. **`/schemas/neo4j/README.md`** — The graph schema.
4. **`/docs/adr/`** — Decisions you must respect or supersede with a new ADR.

For Claude Code sessions, start each session with the task ID:
> "Implement T-NNN per /docs/build-plan.md. Read /CLAUDE.md and the relevant
> ADRs in /docs/adr/ first. Confirm against the Definition of Done before
> declaring complete."

## Repository layout

```
/backend          Python FastAPI service
  /app/api        Thin HTTP routers
  /app/domain     Pydantic models
  /app/graph      Neo4j driver, queries, migrations
  /app/services   Business logic
  /app/workflow   Workflow engine
  /app/crawlers   Source system crawlers (Ab Initio, Informatica, Erwin, etc.)
  /app/codegen    PySpark + DDL templates
  /app/sync       Erwin Mart and Catalog sync clients (V2)
  /app/jobs       Celery background tasks
/frontend         React + TypeScript + Vite
/schemas/neo4j    Cypher migrations
/docs/adr         Architecture decision records
/docs/runbooks    Operational runbooks
```

## V1 scope summary

- ✅ Foundation: schema, migrations, FastAPI skeleton, React skeleton
- ✅ Crawlers: Ab Initio EME, Informatica repository, Erwin Mart (read-only)
- ✅ Discovery cascade: prior-evidence, exact, fuzzy, embedding, KG-context
- ✅ Conformance pre-check against Erwin snapshot
- ✅ Workflow surface: Intake, Discovery, JAD board, DRB, STM authoring
- ✅ Codegen: PySpark + DDL from approved STMs
- ✅ Attribute backtrack via graph traversal
- ❌ Erwin write-back (V2)
- ❌ Catalog sync (V2)
- ❌ Multiple workflow templates (V2)
- ❌ Mobile UI (V2)
