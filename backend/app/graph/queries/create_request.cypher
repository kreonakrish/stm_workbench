// Create a new :Request node, link to its initial stage, and persist any
// :ChangeLine items submitted with the request. Uses :STM* namespaced
// workflow labels per ADR 0006.
//
// Parameters:
//   request_id, title, business_question, usage_context,
//   consumption_pattern, deadline, requester_id, template_id,
//   items: list of {id, type, entity, attribute, table, source_system,
//                   source_table, source_column, new_logic,
//                   business_definition, data_type,
//                   classification, classification_reason,
//                   catalog_verified, existing_sources}

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
WITH r
UNWIND $items AS item
CREATE (cl:ChangeLine {
    id: item.id,
    request_id: r.id,
    type: item.type,
    entity: item.entity,
    attribute: item.attribute,
    table: item.table,
    source_system: item.source_system,
    source_table: item.source_table,
    source_column: item.source_column,
    new_logic: item.new_logic,
    business_definition: item.business_definition,
    data_type: item.data_type,
    classification: item.classification,
    classification_reason: item.classification_reason,
    catalog_verified: item.catalog_verified,
    existing_sources: item.existing_sources,
    created_at: datetime()
})
CREATE (r)-[:HAS_CHANGE]->(cl)
RETURN r;
