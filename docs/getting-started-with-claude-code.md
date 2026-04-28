# How to start with Claude Code

This document describes how to drive the build forward using Claude Code.
Read this once before your first session.

## First session checklist

Before you start:

- [ ] Project unzipped to a directory
- [ ] `cd` into that directory
- [ ] `git init && git add . && git commit -m "Initial scaffold"` — version
      control before any AI-generated changes
- [ ] Local Neo4j running on `neo4j://127.0.0.1:7687` (not containerized)
- [ ] Docker Desktop running (for the Redis container)
- [ ] Open a terminal in the project root
- [ ] Run `claude` to start Claude Code

## How to phrase tasks

The pattern that works best is:

> Implement T-NNN per `/docs/build-plan.md`. Read `/CLAUDE.md` and the
> relevant ADRs in `/docs/adr/` first. When you're done, confirm against
> the Definition of Done in `/CLAUDE.md` before declaring complete.

That's it. The CLAUDE.md and build-plan provide all the context; you don't
need to repeat the architecture in every prompt.

## What to do, by phase

### Before T-001
- Confirm your local Neo4j is reachable at http://localhost:7474
- Run `docker compose up -d` (brings up Redis only)
- `cd backend && uv sync`

### T-001 (repo scaffolding completion)
- The scaffold is mostly complete — T-001 is verifying it works
- Expected: backend installs, frontend installs, both run

### T-002 (migration runner)
- Most of this exists already; T-002 is testing it end-to-end
- Run `uv run python -m app.graph.migrations` and verify constraints exist
  in Neo4j browser

### T-003 onwards
- Each session works one task. Commit per task.
- Do not let sessions drift across tasks — that pollutes the context.

## Discipline rules

1. **One task per session.** If Claude Code finishes a task with budget
   left over, do not let it pick up the next task in the same session.
   End the session, commit, start fresh.

2. **Read CLAUDE.md every session.** The first message of every session
   should explicitly request this. Yes, even though it's redundant.

3. **Schema changes require human review.** The `.claude/settings.json`
   already enforces this via `ask` permissions on `/schemas/neo4j/**`.

4. **ADRs for new patterns.** If Claude Code wants to introduce a new
   pattern (e.g. switching to a different cache, adding a new database,
   changing the auth model), require it to draft an ADR first and wait
   for approval before implementing.

5. **Tests before declaring complete.** Every task ends with a test run.
   "It compiles" is not done. "All tests pass" is done.

6. **Performance is a first-class concern from day one.** Don't ship
   unbounded queries, missing pagination, or unindexed fields. The
   Definition of Done covers this — enforce it.

## Failure modes to watch for

**Scope creep within a task.** Claude Code may want to "improve" adjacent
code while working on a task. Push back: "Keep this PR focused on T-NNN.
Open a separate task for that change." Mixed-purpose commits are hard to
review and hard to revert.

**Inline Cypher.** If Claude Code generates a query as a Python string
instead of a `.cypher` file, that's a CLAUDE.md violation. Have it move
the query to `/backend/app/graph/queries/` and reference it via
`get_query()`.

**Skipping tests.** "I added the feature; tests are out of scope" is the
single most common failure mode. Definition of Done requires tests.
Enforce it.

**New dependencies without ADR.** "I added `httpx-cache` to make caching
easier" — no, that's an ADR. Either revert or write the ADR first.

**Refactoring drift.** "While I was here, I cleaned up X." No. That's a
separate task. Revert any incidental refactoring that wasn't part of the
task scope.

## When to bring in human review

- Schema migrations (always)
- ADR drafts (always)
- Auth and security changes (always)
- Anything touching production credentials (always)
- Performance-sensitive Cypher queries (review the EXPLAIN plan)
- The first version of any major module (frontend pages, services)

## Recommended cadence

- Daily: 1-2 task completions, each in its own session
- Weekly: review the build-plan.md progress, adjust if needed
- Per phase: tag the commit, run a full test suite, write a phase summary

## When you finish V1

- All Phase 1-6 tasks complete
- Pilot stakeholder group using the system on real requests
- Cycle time data collected
- V2 contract designs documented (T-054)
- Retrospective: what went well, what to change for V2
