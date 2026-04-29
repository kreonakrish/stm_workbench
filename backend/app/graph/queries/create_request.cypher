// Create a new :Request node, link to its initial stage, and persist any
// :ChangeLine items submitted with the request. Uses :STM* namespaced
// workflow labels per ADR 0006.
//
// Parameters:
//   request_id, title, business_question, usage_context,
//   consumption_pattern, deadline, requester_id, template_id,
//   items: list of {id, category, action, pipeline_layer, entity,
//                   target_attribute, target_dataset, target_table,
//                   target_column, target_data_type, target_nullable,
//                   source_system, source_dataset, source_table,
//                   source_column, transformation_logic,
//                   business_definition, rationale, impact_notes,
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
    category: item.category,
    action: item.action,
    pipeline_layer: item.pipeline_layer,
    entity: item.entity,
    target_attribute: item.target_attribute,
    target_dataset: item.target_dataset,
    target_table: item.target_table,
    target_column: item.target_column,
    target_data_type: item.target_data_type,
    target_nullable: item.target_nullable,
    source_system: item.source_system,
    source_dataset: item.source_dataset,
    source_table: item.source_table,
    source_column: item.source_column,
    transformation_logic: item.transformation_logic,
    business_definition: item.business_definition,
    rationale: item.rationale,
    impact_notes: item.impact_notes,
    classification: item.classification,
    classification_reason: item.classification_reason,
    catalog_verified: item.catalog_verified,
    existing_sources: item.existing_sources,
    created_at: datetime()
})
CREATE (r)-[:HAS_CHANGE]->(cl)
RETURN r;
