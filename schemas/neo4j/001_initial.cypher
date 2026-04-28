// Migration 001 — Initial schema for V1
// Idempotent: safe to re-run.
//
// Establishes uniqueness constraints and indexes for all V1 node labels.
// Does NOT seed any data; seeding is done via separate scripts.

// ---------------------------------------------------------------
// Uniqueness constraints (one per label that uses an `id` property)
// ---------------------------------------------------------------

CREATE CONSTRAINT request_id_unique IF NOT EXISTS
FOR (n:Request) REQUIRE n.id IS UNIQUE;

CREATE CONSTRAINT workflow_template_id_unique IF NOT EXISTS
FOR (n:WorkflowTemplate) REQUIRE n.id IS UNIQUE;

CREATE CONSTRAINT stage_id_unique IF NOT EXISTS
FOR (n:Stage) REQUIRE n.id IS UNIQUE;

CREATE CONSTRAINT transition_id_unique IF NOT EXISTS
FOR (n:Transition) REQUIRE n.id IS UNIQUE;

CREATE CONSTRAINT transition_event_id_unique IF NOT EXISTS
FOR (n:TransitionEvent) REQUIRE n.id IS UNIQUE;

CREATE CONSTRAINT comment_id_unique IF NOT EXISTS
FOR (n:Comment) REQUIRE n.id IS UNIQUE;

CREATE CONSTRAINT decision_id_unique IF NOT EXISTS
FOR (n:Decision) REQUIRE n.id IS UNIQUE;

CREATE CONSTRAINT open_question_id_unique IF NOT EXISTS
FOR (n:OpenQuestion) REQUIRE n.id IS UNIQUE;

CREATE CONSTRAINT candidate_mapping_id_unique IF NOT EXISTS
FOR (n:CandidateMapping) REQUIRE n.id IS UNIQUE;

CREATE CONSTRAINT mapping_id_unique IF NOT EXISTS
FOR (n:Mapping) REQUIRE n.id IS UNIQUE;

CREATE CONSTRAINT mapping_version_id_unique IF NOT EXISTS
FOR (n:MappingVersion) REQUIRE n.id IS UNIQUE;

CREATE CONSTRAINT conformance_finding_id_unique IF NOT EXISTS
FOR (n:ConformanceFinding) REQUIRE n.id IS UNIQUE;

CREATE CONSTRAINT approval_id_unique IF NOT EXISTS
FOR (n:Approval) REQUIRE n.id IS UNIQUE;

CREATE CONSTRAINT erwin_snapshot_id_unique IF NOT EXISTS
FOR (n:ErwinModelSnapshot) REQUIRE n.id IS UNIQUE;

CREATE CONSTRAINT generated_code_id_unique IF NOT EXISTS
FOR (n:GeneratedCodeArtifact) REQUIRE n.id IS UNIQUE;

CREATE CONSTRAINT contract_rule_id_unique IF NOT EXISTS
FOR (n:ContractRule) REQUIRE n.id IS UNIQUE;

CREATE CONSTRAINT schema_migration_id_unique IF NOT EXISTS
FOR (n:SchemaMigration) REQUIRE n.migration_id IS UNIQUE;

// ---------------------------------------------------------------
// Indexes for common query patterns
// ---------------------------------------------------------------

CREATE INDEX request_current_stage IF NOT EXISTS
FOR (n:Request) ON (n.current_stage_id);

CREATE INDEX request_requester IF NOT EXISTS
FOR (n:Request) ON (n.requester_id);

CREATE INDEX request_created_at IF NOT EXISTS
FOR (n:Request) ON (n.created_at);

CREATE INDEX request_usage_context IF NOT EXISTS
FOR (n:Request) ON (n.usage_context);

CREATE INDEX mapping_version_valid_from IF NOT EXISTS
FOR (n:MappingVersion) ON (n.valid_from);

CREATE INDEX mapping_version_valid_to IF NOT EXISTS
FOR (n:MappingVersion) ON (n.valid_to);

CREATE INDEX comment_request_id IF NOT EXISTS
FOR (n:Comment) ON (n.request_id);

CREATE INDEX approval_request_id IF NOT EXISTS
FOR (n:Approval) ON (n.request_id);

CREATE INDEX conformance_finding_request IF NOT EXISTS
FOR (n:ConformanceFinding) ON (n.request_id);

CREATE INDEX transition_event_request IF NOT EXISTS
FOR (n:TransitionEvent) ON (n.request_id, n.at);

CREATE INDEX candidate_mapping_request IF NOT EXISTS
FOR (n:CandidateMapping) ON (n.request_id);

// ---------------------------------------------------------------
// Record this migration
// ---------------------------------------------------------------

MERGE (m:SchemaMigration {migration_id: '001_initial'})
ON CREATE SET m.applied_at = datetime(),
              m.description = 'Initial schema — constraints and indexes for V1 node labels';
