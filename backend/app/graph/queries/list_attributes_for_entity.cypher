// List BusinessAttributes for a given entity, ordered by key-status then name.
// Used for the attribute-picker dropdown in the structured intake form.
//
// Parameters:
//   entity

MATCH (e:Entity {name: $entity})-[:HAS_ATTRIBUTE]->(a:BusinessAttribute)
RETURN a.id AS id, a.name AS name, a.description AS description,
       a.data_type AS data_type, a.pii_classification AS pii_classification,
       coalesce(a.is_key, false) AS is_key
ORDER BY is_key DESC, a.name ASC
LIMIT 500;
