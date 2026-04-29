// Fetch a Request by ID with current stage, recent transition events,
// and all attached :ChangeLine items (each with its :ChangeColumn list).
//
// Parameters:
//   request_id

MATCH (r:Request {id: $request_id})-[:CURRENTLY_IN]->(stage:STMStage)
OPTIONAL MATCH (r)-[:HAS_TRANSITION_EVENT]->(event:STMTransitionEvent)
WITH r, stage, event ORDER BY event.at DESC
WITH r, stage, collect(event)[..10] AS recent_events
OPTIONAL MATCH (r)-[:HAS_CHANGE]->(cl:ChangeLine)
WITH r, stage, recent_events, cl ORDER BY cl.created_at ASC
OPTIONAL MATCH (cl)-[:HAS_COLUMN]->(col:ChangeColumn)
WITH r, stage, recent_events, cl, col ORDER BY cl.created_at ASC, col.position ASC
WITH r, stage, recent_events, cl,
     [c IN collect(col) WHERE c IS NOT NULL] AS cols
WITH r, stage, recent_events,
     collect(CASE WHEN cl IS NULL THEN NULL ELSE cl {.*, columns: cols} END) AS items
RETURN r AS request,
       stage AS current_stage,
       recent_events,
       [it IN items WHERE it IS NOT NULL] AS items;
