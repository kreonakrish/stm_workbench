// List all curated entities with an attribute count.
// Used for the entity-picker dropdown in the structured intake form.

MATCH (e:Entity)
OPTIONAL MATCH (e)-[:HAS_ATTRIBUTE]->(a:BusinessAttribute)
RETURN e.name AS name, e.description AS description, count(a) AS attribute_count
ORDER BY e.name
LIMIT 200;
