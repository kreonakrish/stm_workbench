// Fetch a Request by ID with current stage, recent transition events,
// and all attached :ChangeLine items.
//
// Parameters:
//   request_id

MATCH (r:Request {id: $request_id})-[:CURRENTLY_IN]->(stage:STMStage)
OPTIONAL MATCH (r)-[:HAS_TRANSITION_EVENT]->(event:STMTransitionEvent)
WITH r, stage, event ORDER BY event.at DESC
WITH r, stage, collect(event)[..10] AS recent_events
OPTIONAL MATCH (r)-[:HAS_CHANGE]->(cl:ChangeLine)
WITH r, stage, recent_events, cl ORDER BY cl.created_at ASC
WITH r, stage, recent_events, collect(cl) AS items
RETURN r AS request,
       stage AS current_stage,
       recent_events,
       items;
