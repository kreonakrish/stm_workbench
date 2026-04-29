// Fetch a Request by ID, including current stage and recent transition events.
// Uses :STM* namespaced workflow labels per ADR 0006.
//
// Parameters:
//   request_id

MATCH (r:Request {id: $request_id})-[:CURRENTLY_IN]->(stage:STMStage)
OPTIONAL MATCH (r)-[:HAS_TRANSITION_EVENT]->(event:STMTransitionEvent)
WITH r, stage, event
ORDER BY event.at DESC
WITH r, stage, collect(event)[..10] AS recent_events
RETURN r AS request,
       stage AS current_stage,
       recent_events;
