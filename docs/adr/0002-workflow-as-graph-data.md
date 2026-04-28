# ADR 0002: Workflow definition is graph data, not code

## Status
Accepted

## Context
The platform must support multiple stakeholder groups (Risk, REDS, Capital
Markets, D&A) with potentially different approval paths. Hardcoding
workflow stages and transitions in Python code means every change requires
a deploy and creates merge conflicts when multiple groups need different
flows.

## Decision
Workflow templates are graph subgraphs. A `:WorkflowTemplate` node has
`:HAS_STAGE` edges to `:Stage` nodes, and stages have `:ALLOWS_TRANSITION`
edges to `:Transition` nodes that point `:TO` other stages. Guards on
transitions (e.g. "only Data Architect can move to DRB-approved") are
expressed as data on the `:Transition` node, evaluated by the workflow
engine at runtime.

A `:Request` node has `:FOLLOWS_TEMPLATE` to its workflow template and
`:CURRENTLY_IN` to its current stage. Stage transitions create
immutable `:TransitionEvent` nodes for audit.

## Consequences
- Adding a new stage or modifying a transition is a Cypher operation, not
  a deploy.
- The workflow engine is thin: load template, find allowed transitions
  from current stage, validate guard, write transition event, update
  current stage pointer.
- Multiple workflow templates can coexist; different request types follow
  different templates.
- Workflow versioning: a template change creates a new template version;
  in-flight requests continue on their original version.
- Validation: every transition request is validated against the template;
  invalid transitions are rejected at the API layer.
