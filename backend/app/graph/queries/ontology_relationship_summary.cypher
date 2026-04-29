// Aggregate relationship metadata: type, count, distinct start/end label pairs.
// LIMIT bounds the scan in case real data lands; sample is enough to recover
// the schema shape.

MATCH (s)-[r]->(e)
WITH type(r) AS rt, labels(s) AS s_labels, labels(e) AS e_labels
LIMIT 100000
WITH rt,
     count(*) AS rel_count,
     collect(DISTINCT s_labels) AS s_label_lists,
     collect(DISTINCT e_labels) AS e_label_lists
RETURN rt AS type,
       rel_count AS count,
       reduce(acc = [], lst IN s_label_lists | acc + lst) AS start_labels,
       reduce(acc = [], lst IN e_label_lists | acc + lst) AS end_labels
ORDER BY rt;
