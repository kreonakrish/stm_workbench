// Count nodes per label using a single pass over the data.
// Bounded by the cardinality of (label, node) pairs, not nodes — fine
// for our scale (<<10k labels expected).

MATCH (n)
UNWIND labels(n) AS label
RETURN label, count(*) AS count
ORDER BY label;
