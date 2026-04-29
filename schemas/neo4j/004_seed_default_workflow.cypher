// Migration 004 — Seed the default STM workflow template.
//
// CLAUDE.md non-negotiable #2: workflow definition is graph data, not code.
// This migration is the initial seed; future stage/transition/guard changes
// land via further migrations or via API/UI mutations against the graph.
//
// Idempotent: every node and relationship uses MERGE.

// ---------------------------------------------------------------
// Template
// ---------------------------------------------------------------

MERGE (t:STMWorkflowTemplate {id: 'default'})
ON CREATE SET t.name = 'Default V1',
              t.version = 1,
              t.applies_to = ['all'],
              t.created_at = datetime();

// ---------------------------------------------------------------
// Stages — order property drives the swimlane render order.
// allowed_actors is the role gate per ADR 0002 / CLAUDE.md authz rules.
// ---------------------------------------------------------------

MERGE (intake:STMStage {id: 'intake'})
ON CREATE SET intake.name = 'Intake',
              intake.is_initial = true,
              intake.is_terminal = false,
              intake.allowed_actors = ['requester'],
              intake.order = 1;

MERGE (disc:STMStage {id: 'discovery'})
ON CREATE SET disc.name = 'Discovery',
              disc.is_initial = false,
              disc.is_terminal = false,
              disc.allowed_actors = ['data_owner', 'discovery_agent'],
              disc.order = 2;

MERGE (jad:STMStage {id: 'jad'})
ON CREATE SET jad.name = 'JAD',
              jad.is_initial = false,
              jad.is_terminal = false,
              jad.allowed_actors = ['jad_facilitator', 'sme', 'business_lead'],
              jad.order = 3;

MERGE (drb:STMStage {id: 'drb'})
ON CREATE SET drb.name = 'DRB',
              drb.is_initial = false,
              drb.is_terminal = false,
              drb.allowed_actors = ['drb_member'],
              drb.order = 4;

MERGE (stm:STMStage {id: 'stm_authoring'})
ON CREATE SET stm.name = 'STM Authoring',
              stm.is_initial = false,
              stm.is_terminal = false,
              stm.allowed_actors = ['stm_author'],
              stm.order = 5;

MERGE (sync:STMStage {id: 'awaiting_sync'})
ON CREATE SET sync.name = 'Awaiting Sync',
              sync.is_initial = false,
              sync.is_terminal = false,
              sync.allowed_actors = ['sync_operator'],
              sync.order = 6;

MERGE (closed:STMStage {id: 'closed'})
ON CREATE SET closed.name = 'Closed',
              closed.is_initial = false,
              closed.is_terminal = true,
              closed.allowed_actors = [],
              closed.order = 7;

// ---------------------------------------------------------------
// Wire all stages to the template.
// ---------------------------------------------------------------

MATCH (t:STMWorkflowTemplate {id: 'default'})
MATCH (s:STMStage)
WHERE s.id IN ['intake','discovery','jad','drb','stm_authoring','awaiting_sync','closed']
MERGE (t)-[:HAS_STAGE]->(s);

// ---------------------------------------------------------------
// Forward transitions (linear path through the lifecycle).
// Reverse / revision transitions are deliberately omitted from the
// initial seed; revisions land in a follow-up migration once the
// guard model is wired (T-006 follow-up).
// ---------------------------------------------------------------

MATCH (intake:STMStage {id: 'intake'}), (disc:STMStage {id: 'discovery'})
MERGE (intake)-[:ALLOWS_TRANSITION]->(t1:STMTransition {id: 'intake_to_discovery'})
MERGE (t1)-[:TO]->(disc);

MATCH (disc:STMStage {id: 'discovery'}), (jad:STMStage {id: 'jad'})
MERGE (disc)-[:ALLOWS_TRANSITION]->(t2:STMTransition {id: 'discovery_to_jad'})
MERGE (t2)-[:TO]->(jad);

MATCH (jad:STMStage {id: 'jad'}), (drb:STMStage {id: 'drb'})
MERGE (jad)-[:ALLOWS_TRANSITION]->(t3:STMTransition {id: 'jad_to_drb'})
MERGE (t3)-[:TO]->(drb);

MATCH (drb:STMStage {id: 'drb'}), (stm:STMStage {id: 'stm_authoring'})
MERGE (drb)-[:ALLOWS_TRANSITION]->(t4:STMTransition {id: 'drb_to_stm_authoring'})
MERGE (t4)-[:TO]->(stm);

MATCH (stm:STMStage {id: 'stm_authoring'}), (sync:STMStage {id: 'awaiting_sync'})
MERGE (stm)-[:ALLOWS_TRANSITION]->(t5:STMTransition {id: 'stm_authoring_to_awaiting_sync'})
MERGE (t5)-[:TO]->(sync);

MATCH (sync:STMStage {id: 'awaiting_sync'}), (closed:STMStage {id: 'closed'})
MERGE (sync)-[:ALLOWS_TRANSITION]->(t6:STMTransition {id: 'awaiting_sync_to_closed'})
MERGE (t6)-[:TO]->(closed);

// ---------------------------------------------------------------
// Record this migration.
// ---------------------------------------------------------------

MERGE (m:SchemaMigration {migration_id: '004_seed_default_workflow'})
ON CREATE SET m.applied_at = datetime(),
              m.description = 'Seed default 7-stage STM workflow template with role gates';
