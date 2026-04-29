// List physical-column sources for a given (entity, attribute), with
// system + table context for display.
//
// Parameters:
//   entity, attribute

MATCH (e:Entity {name: $entity})-[:HAS_ATTRIBUTE]->(a:BusinessAttribute {name: $attribute})
MATCH (a)-[:SOURCED_FROM]->(c:PhysicalColumn)-[:IN_TABLE]->(t:PhysicalTable)-[:IN_SYSTEM]->(s:PhysicalSystem)
RETURN s.id AS system_id, s.name AS system_name, s.kind AS system_kind,
       t.schema AS schema, t.name AS table, c.name AS column, c.id AS column_id,
       c.data_type AS data_type
ORDER BY s.id, t.schema, t.name, c.name
LIMIT 50;
