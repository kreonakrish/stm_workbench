// Create a new :Request node and link to its initial stage.
// Uses :STM* namespaced workflow labels per ADR 0006.
//
// Parameters:
//   request_id, title, business_question, usage_context,
//   consumption_pattern, deadline, requester_id, template_id

MATCH (template:STMWorkflowTemplate {id: $template_id})-[:HAS_STAGE]->(initial:STMStage {is_initial: true})
CREATE (r:Request {
    id: $request_id,
    title: $title,
    business_question: $business_question,
    usage_context: $usage_context,
    consumption_pattern: $consumption_pattern,
    deadline: $deadline,
    requester_id: $requester_id,
    current_stage_id: initial.id,
    created_at: datetime(),
    created_by: $requester_id
})
CREATE (r)-[:FOLLOWS_TEMPLATE]->(template)
CREATE (r)-[:CURRENTLY_IN]->(initial)
CREATE (event:STMTransitionEvent {
    id: randomUUID(),
    request_id: r.id,
    from_stage: null,
    to_stage: initial.id,
    actor: $requester_id,
    at: datetime(),
    rationale: 'Request created'
})
CREATE (r)-[:HAS_TRANSITION_EVENT]->(event)
RETURN r;
