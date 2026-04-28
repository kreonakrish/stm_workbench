// Fetch a Request by ID, including current stage and recent transition events.
//
// Parameters:
//   request_id

MATCH (r:Request {id: $request_id})-[:CURRENTLY_IN]->(stage:Stage)
OPTIONAL MATCH (r)-[:HAS_TRANSITION_EVENT]->(event:TransitionEvent)
WITH r, stage, event
ORDER BY event.at DESC
WITH r, stage, collect(event)[..10] AS recent_events
RETURN r AS request,
       stage AS current_stage,
       recent_events;
