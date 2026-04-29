// Upsert a single (system, schema, table, column) tuple; auto-link to a
// :BusinessAttribute when the column name matches by case-insensitive equality.
// Returns whether the upsert resulted in a new link.
//
// Parameters:
//   system_id, schema, table, column, data_type, nullable

MATCH (s:PhysicalSystem {id: $system_id})
MERGE (t:PhysicalTable {id: $system_id + '.' + coalesce($schema, '') + '.' + $table})
ON CREATE SET t.schema = $schema, t.name = $table
MERGE (t)-[:IN_SYSTEM]->(s)
MERGE (c:PhysicalColumn {id: $system_id + '.' + coalesce($schema, '') + '.' + $table + '.' + $column})
ON CREATE SET c.name = $column, c.data_type = $data_type, c.nullable = $nullable
ON MATCH  SET c.data_type = coalesce($data_type, c.data_type),
              c.nullable  = coalesce($nullable, c.nullable)
MERGE (c)-[:IN_TABLE]->(t)
WITH c
OPTIONAL MATCH (a:BusinessAttribute) WHERE toLower(a.name) = toLower(c.name)
WITH c, a
FOREACH (att IN CASE WHEN a IS NULL THEN [] ELSE [a] END | MERGE (att)-[:SOURCED_FROM]->(c))
RETURN c.id AS column_id, a IS NOT NULL AS linked;
