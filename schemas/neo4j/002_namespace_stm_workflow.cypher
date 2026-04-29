// Migration 002 — Namespace STM workflow labels with `:STM*` prefix.
// See ADR 0006.
//
// Idempotent: safe to re-run.
// - Old constraints are dropped IF EXISTS.
// - New constraints use IF NOT EXISTS.
// - Existing nodes are relabelled via SET/REMOVE; the WHERE clause makes
//   the relabel a no-op once already migrated.

// ---------------------------------------------------------------
// Drop old constraints (pre-namespace).
// ---------------------------------------------------------------

DROP CONSTRAINT workflow_template_id_unique IF EXISTS;
DROP CONSTRAINT stage_id_unique IF EXISTS;
DROP CONSTRAINT transition_id_unique IF EXISTS;
DROP CONSTRAINT transition_event_id_unique IF EXISTS;

// ---------------------------------------------------------------
// Create new namespaced constraints.
// ---------------------------------------------------------------

CREATE CONSTRAINT stm_workflow_template_id_unique IF NOT EXISTS
FOR (n:STMWorkflowTemplate) REQUIRE n.id IS UNIQUE;

CREATE CONSTRAINT stm_stage_id_unique IF NOT EXISTS
FOR (n:STMStage) REQUIRE n.id IS UNIQUE;

CREATE CONSTRAINT stm_transition_id_unique IF NOT EXISTS
FOR (n:STMTransition) REQUIRE n.id IS UNIQUE;

CREATE CONSTRAINT stm_transition_event_id_unique IF NOT EXISTS
FOR (n:STMTransitionEvent) REQUIRE n.id IS UNIQUE;

// ---------------------------------------------------------------
// Relabel any existing data (no-op when already migrated).
// ---------------------------------------------------------------

MATCH (n:WorkflowTemplate) WHERE NOT n:STMWorkflowTemplate
SET n:STMWorkflowTemplate REMOVE n:WorkflowTemplate;

MATCH (n:Stage) WHERE NOT n:STMStage
SET n:STMStage REMOVE n:Stage;

MATCH (n:Transition) WHERE NOT n:STMTransition
SET n:STMTransition REMOVE n:Transition;

MATCH (n:TransitionEvent) WHERE NOT n:STMTransitionEvent
SET n:STMTransitionEvent REMOVE n:TransitionEvent;

// ---------------------------------------------------------------
// Record this migration.
// ---------------------------------------------------------------

MERGE (m:SchemaMigration {migration_id: '002_namespace_stm_workflow'})
ON CREATE SET m.applied_at = datetime(),
              m.description = 'Namespace STM workflow labels with :STM* prefix (ADR 0006)';
