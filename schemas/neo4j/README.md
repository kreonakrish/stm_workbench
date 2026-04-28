# Neo4j schema

The graph schema is the foundation of this platform. Changes are versioned
migrations in this directory, applied in order. Migrations are forward-only
for V1; rollback is by restoring from backup.

Read this document before writing any Cypher.

## Conventions

- Node labels are PascalCase (`:Request`, `:MappingVersion`).
- Relationship types are SCREAMING_SNAKE_CASE (`:HAS_VERSION`, `:CURRENTLY_IN`).
- Property names are snake_case (`created_at`, `valid_from`).
- Every node has an `id` property (UUID v4) unless explicitly noted.
- Every node has `created_at` and `created_by` properties for provenance.
- Mutations create new nodes; updates that change semantics create new
  versions, not field updates.

## Node labels

### Catalog (existing — extend as needed)
- `:SourceSystem` — `name`, `type`, `connection_metadata`
- `:Schema` — `system_name`, `schema_name`
- `:Table` — `schema`, `name`
- `:Column` — `table`, `name`, `data_type`, `nullable`, `profile_*`
- `:BusinessTerm` — `name`, `definition`, `owner`, `status`
- `:LogicalAttribute` — `term_id`, `name`, `type`, `usage_context`
- `:PhysicalColumn` — alias view over `:Column` for clarity in mappings

### Workflow
- `:Request` — `id`, `title`, `business_question`, `usage_context`
  (regulatory|management|analytics|adhoc), `consumption_pattern`,
  `deadline`, `current_stage_id`, `requester_id`, `created_at`
- `:WorkflowTemplate` — `id`, `name`, `version`, `applies_to` (request types)
- `:Stage` — `id`, `name`, `allowed_actors`, `exit_criteria`
- `:Transition` — `id`, `from_stage_id`, `to_stage_id`, `guard_expression`
- `:TransitionEvent` — immutable; `request_id`, `from_stage`, `to_stage`,
  `actor`, `at`, `rationale`

### Decision and discussion
- `:Comment` — `request_id`, `author`, `body`, `at`, `parent_comment_id`
- `:Decision` — `request_id`, `question`, `resolution`, `rationale`,
  `alternatives_considered`, `decided_by`, `at`
- `:OpenQuestion` — `request_id`, `question`, `candidates`, `status`

### Mapping and STM
- `:CandidateMapping` — `request_id`, `source_column_id`,
  `target_attribute_id`, `confidence`, `evidence_sources`,
  `validation_results`
- `:Mapping` — stable identifier; `id`, `source_signature`,
  `target_signature`, `status`
- `:MappingVersion` — `id`, `mapping_id`, `version_number`,
  `valid_from`, `valid_to` (NULL if current), `request_id` (driver),
  `approved_by`, `transformation_logic`
- `:ConformanceFinding` — `request_id`, `severity` (green|amber|red),
  `category`, `description`, `erwin_reference`

### Approvals
- `:Approval` — `request_id`, `stage`, `approver_id`, `decision`
  (approved|conditional|rejected), `conditions`, `rationale`, `at`

### Erwin and codegen
- `:ErwinModelSnapshot` — `id`, `captured_at`, `version`, `content_hash`
- `:ErwinEntity` — `snapshot_id`, `name`, `attributes` (json)
- `:GeneratedCodeArtifact` — `id`, `mapping_version_id`, `type`
  (pyspark|ddl|dbt), `template_version`, `content_hash`,
  `generated_at`, `storage_uri`

### Contract rules (sealed engine)
- `:ContractRule` — `id`, `rule_type`, `description`, `validation_logic`,
  `active`, `version`

## Key relationships

```
(:Request)-[:CURRENTLY_IN]->(:Stage)
(:Request)-[:FOLLOWS_TEMPLATE]->(:WorkflowTemplate)
(:WorkflowTemplate)-[:HAS_STAGE]->(:Stage)
(:Stage)-[:ALLOWS_TRANSITION]->(:Transition)-[:TO]->(:Stage)
(:Request)-[:HAS_TRANSITION_EVENT]->(:TransitionEvent)
(:Request)-[:HAS_CANDIDATE]->(:CandidateMapping)
(:Request)-[:RESULTED_IN]->(:Mapping)
(:Mapping)-[:HAS_VERSION]->(:MappingVersion)
(:MappingVersion)-[:SUPERSEDES]->(:MappingVersion)
(:MappingVersion)-[:DRIVEN_BY]->(:Request)
(:MappingVersion)-[:MAPS]->(:PhysicalColumn)         // source side
(:MappingVersion)-[:TO]->(:LogicalAttribute)         // target side
(:Request)-[:HAS_COMMENT]->(:Comment)
(:Request)-[:HAS_APPROVAL]->(:Approval)
(:Request)-[:HAS_FINDING]->(:ConformanceFinding)
(:GeneratedCodeArtifact)-[:GENERATED_FROM]->(:MappingVersion)
(:ConformanceFinding)-[:VIOLATES]->(:ContractRule)
```

## Indexes and constraints (defined in migration 001)

- Unique constraint on `id` for every node label that has it
- Index on `:Request(current_stage_id)`
- Index on `:Request(requester_id)`
- Index on `:Request(created_at)`
- Index on `:MappingVersion(valid_from, valid_to)` for temporal queries
- Index on `:Comment(request_id)`
- Index on `:Approval(request_id)`
- Index on `:ConformanceFinding(request_id)`
- Index on `:TransitionEvent(request_id, at)`

## Temporal modeling

STMs and Mappings use SCD-2-like versioning:
- Each `:MappingVersion` has `valid_from` and `valid_to`
- `valid_to IS NULL` indicates the current version
- A new version is created on every approved change
- Querying historical state filters by:
  `valid_from <= $T < COALESCE(valid_to, datetime('9999-12-31'))`

Never UPDATE a `:MappingVersion` in place. Create a new version, set the
prior version's `valid_to`, and link with `:SUPERSEDES`.

## Migration discipline

- Migrations are numbered: `001_initial.cypher`, `002_*.cypher`, etc.
- Each migration is idempotent where possible (use `IF NOT EXISTS`
  for constraints and indexes).
- Migrations are applied in order via the migration runner in
  `/backend/app/graph/migrations.py`.
- A `:SchemaMigration` node records each applied migration with `at` and
  `migration_id`.
- Never edit a committed migration; write a new one to amend.
