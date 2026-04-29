// Full ontology catalog: every entity, its business attributes, and every
// physical column that backs each attribute. One row per
// (entity, attribute, source) combination — assembled into a nested
// payload by the service. Bounded by ontology size, not data size, so
// the LIMIT is a generous safeguard rather than a real constraint.

MATCH (e:Entity)
OPTIONAL MATCH (e)-[:HAS_ATTRIBUTE]->(a:BusinessAttribute)
OPTIONAL MATCH (a)-[:SOURCED_FROM]->(c:PhysicalColumn)
              -[:IN_TABLE]->(t:PhysicalTable)
              -[:IN_SYSTEM]->(s:PhysicalSystem)
RETURN e.name AS entity,
       e.description AS entity_description,
       a.id AS attribute_id,
       a.name AS attribute_name,
       a.description AS attribute_description,
       a.data_type AS attribute_data_type,
       a.pii_classification AS pii_classification,
       coalesce(a.is_key, false) AS is_key,
       s.id AS system_id,
       s.name AS system_name,
       s.kind AS system_kind,
       t.schema AS source_schema,
       t.name AS source_table,
       c.id AS column_id,
       c.name AS column_name,
       c.data_type AS column_data_type
ORDER BY entity, is_key DESC, attribute_name, system_id, source_schema, source_table, column_name
LIMIT 5000;
