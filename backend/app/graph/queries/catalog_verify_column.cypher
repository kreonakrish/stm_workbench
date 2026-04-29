// Verify a physical column exists in the workbench graph (the local
// graph-as-catalog stub). Real catalog clients hit an external API
// instead.
//
// Parameters:
//   column_id

MATCH (c:PhysicalColumn {id: $column_id})
RETURN c.id AS id LIMIT 1;
