// Create a new :Request node, link to its initial stage, persist any
// :ChangeLine items and their per-line :ChangeColumn children. Uses
// :STM* namespaced workflow labels per ADR 0006.
//
// Parameters:
//   request_id, title, business_question, usage_context,
//   consumption_pattern, deadline, requester_id, template_id,
//   items: list of {
//     id, category, action, pipeline_layer, entity,
//     target_dataset, target_table,
//     source_system, source_dataset, source_table, source_column,
//     transformation_logic, rationale, impact_notes,
//     classification, classification_reason, catalog_verified,
//     columns: list of {
//       id, attribute, data_type, nullable, business_definition,
//       classification, classification_reason, existing_sources
//     }
//   }

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
    target_dataset: item.target_dataset,
    target_table: item.target_table,
    source_system: item.source_system,
    source_dataset: item.source_dataset,
    source_table: item.source_table,
    source_column: item.source_column,
    transformation_logic: item.transformation_logic,
    rationale: item.rationale,
    impact_notes: item.impact_notes,
    classification: item.classification,
    classification_reason: item.classification_reason,
    catalog_verified: item.catalog_verified,
    created_at: datetime()
})
CREATE (r)-[:HAS_CHANGE]->(cl)
WITH cl, item
UNWIND range(0, size(item.columns) - 1) AS col_index
WITH cl, item.columns[col_index] AS col, col_index
CREATE (c:ChangeColumn {
    id: col.id,
    change_line_id: cl.id,
    position: col_index,
    attribute: col.attribute,
    data_type: col.data_type,
    nullable: col.nullable,
    business_definition: col.business_definition,
    classification: col.classification,
    classification_reason: col.classification_reason,
    existing_sources: col.existing_sources
})
CREATE (cl)-[:HAS_COLUMN]->(c)
RETURN count(cl) AS line_count;
