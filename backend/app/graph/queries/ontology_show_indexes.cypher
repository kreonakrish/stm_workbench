// All node-level indexes (including those backing constraints).
// Returns one row per index; properties is a list because composite indexes exist.

SHOW INDEXES
YIELD entityType, labelsOrTypes, properties, owningConstraint
WHERE entityType = 'NODE' AND labelsOrTypes IS NOT NULL
RETURN labelsOrTypes AS labels, properties, owningConstraint;
