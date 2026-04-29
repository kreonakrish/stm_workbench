// Fetch a workflow template with its stages (in declared order) and
// all transitions within the template.
//
// Parameters:
//   template_id

MATCH (t:STMWorkflowTemplate {id: $template_id})
OPTIONAL MATCH (t)-[:HAS_STAGE]->(s:STMStage)
WITH t, s ORDER BY coalesce(s.order, 999) ASC
WITH t, collect(s {.id, .name, .is_initial, .is_terminal, .allowed_actors, .order}) AS stages
OPTIONAL MATCH (t)-[:HAS_STAGE]->(from:STMStage)-[:ALLOWS_TRANSITION]->(tr:STMTransition)-[:TO]->(to:STMStage)
WITH t, stages,
     collect(DISTINCT {
       id: tr.id,
       from_stage_id: from.id,
       to_stage_id: to.id
     }) AS transitions
RETURN t {.id, .name, .version} AS template, stages, transitions;
