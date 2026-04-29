// Does this entity already have a BusinessAttribute by this name?
//
// Parameters:
//   entity, attribute

MATCH (e:Entity {name: $entity})-[:HAS_ATTRIBUTE]->(a:BusinessAttribute {name: $attribute})
RETURN a.id AS id, a.is_key AS is_key, a.data_type AS data_type LIMIT 1;
