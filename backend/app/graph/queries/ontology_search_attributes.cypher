// Substring search over the curated ontology — :BusinessAttribute first,
// :Entity as a secondary hit. Rank/pagination is applied by the caller.
//
// Parameters:
//   q   — lowercased substring to match.

CALL () {
    MATCH (e:Entity)-[:HAS_ATTRIBUTE]->(a:BusinessAttribute)
    WHERE toLower(a.name) CONTAINS $q OR toLower(a.id) CONTAINS $q
    RETURN 'attribute' AS kind,
           e.name AS entity,
           a.name AS attribute,
           coalesce(a.is_key, false) AS is_key,
           a.description AS description
    UNION
    MATCH (e:Entity)
    WHERE toLower(e.name) CONTAINS $q
    RETURN 'entity' AS kind,
           e.name AS entity,
           null AS attribute,
           false AS is_key,
           e.description AS description
}
RETURN kind, entity, attribute, is_key, description
LIMIT 200;
