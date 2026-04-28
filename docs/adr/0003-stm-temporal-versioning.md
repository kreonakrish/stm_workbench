# ADR 0003: STM temporal versioning via SCD-2-style graph modeling

## Status
Accepted

## Context
STMs evolve over time as business logic changes, regulations update, and
new requirements emerge. The platform must support querying historical
state ("what did this mapping look like on April 1, 2024 when the
regulator pulled the report?") and showing the lineage of changes.

## Decision
A `:Mapping` node is a stable identifier for a logical mapping. It has
`:HAS_VERSION` edges to one or more `:MappingVersion` nodes. Each
`:MappingVersion` is a complete subgraph capturing the full mapping at
a point in time, with `valid_from` and `valid_to` timestamps. The current
version has `valid_to` set to NULL.

New versions are created on every approved change, never UPDATE in place.
Versions chain via `:SUPERSEDES` edges. Each version is `:DRIVEN_BY` the
request that produced it, providing full audit lineage from any version
back to the originating request, JAD decisions, and DRB approval.

## Consequences
- Storage grows over time. This is acceptable; storage is cheap relative
  to the value of provenance.
- Historical queries filter by `valid_from <= T < (valid_to OR INFINITY)`.
- The "current version" view requires filtering on `valid_to IS NULL`;
  all current-state queries must include this filter.
- Diff between versions is a graph traversal, not a stored field.
- Code generation produces new artifacts per version; deployed code links
  to the specific version it was generated from.
- Retention policy: never delete versions. Soft-delete with a status flag
  if absolutely necessary; hard-delete only via documented procedure.
