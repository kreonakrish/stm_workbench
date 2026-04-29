# ADR 0006: Namespace STM workflow labels with `:STM*` prefix

## Status
Accepted

## Context
The single source of truth (ADR 0001) is one Neo4j graph. We are about to
import the home-lending business ontology from
`github.com/kreonakrish/hl_knowledge_graph` into the workbench database so
intake requests can be validated against existing business attributes (see
ADR 0007).

That ontology already defines labels that overlap conceptually with the
STM workflow nodes scaffolded in migration 001:

| Workbench label (current) | hl_knowledge_graph label  |
|---------------------------|---------------------------|
| `:Stage`                  | `:WorkflowStage`          |
| `:WorkflowTemplate`       | (none — would shadow `:WorkflowStage` semantics) |
| `:Transition`             | (none — generic name, easy to clash) |
| `:TransitionEvent`        | (none — generic name, easy to clash) |

If we import as-is, future ontology updates could collide with workflow
nodes, queries that traverse the ontology might incidentally hit workflow
nodes, and provenance becomes confusing.

`:Request` does not collide with any ontology label and is unambiguous in
context — keep it.

## Decision
Prefix all workbench-internal workflow labels with `STM` to make them
disjoint from any current or future business-ontology label:

- `:WorkflowTemplate`  → `:STMWorkflowTemplate`
- `:Stage`             → `:STMStage`
- `:Transition`        → `:STMTransition`
- `:TransitionEvent`   → `:STMTransitionEvent`

`:Request` remains unprefixed.

Constraint and index names mirror this with a `stm_` prefix
(`stm_workflow_template_id_unique`, `stm_stage_id_unique`, etc.).

Migration `002_namespace_stm_workflow.cypher` performs this rename in a
single idempotent pass: drops old constraints, creates new constraints,
and migrates any existing nodes with `SET n:NewLabel REMOVE n:OldLabel`.

## Consequences
**Easier**
- Importing or re-syncing the hl_knowledge_graph ontology is collision-free.
- Cypher queries are self-documenting: a query that mentions `:STMStage`
  is unambiguously about workflow state, never business meaning.
- Label-based authorisation policies (e.g. "only admins can edit
  `:STM*` nodes") become trivial.

**Harder**
- Every cypher query and migration must be updated. We pay this cost once.
- The convention is one more thing reviewers must remember.
- Slightly more verbose label names in queries.

**Out of scope**
- Whether to similarly prefix `:Request`, `:Comment`, `:Decision`,
  `:Approval`, `:Mapping*`, `:ConformanceFinding`, etc. None currently
  collide with the ontology; prefix them only if a real conflict arises.
