// Record a CrawlRun node so we have provenance for every crawler invocation.
//
// Parameters:
//   id, connector, system_id, started_at, finished_at,
//   columns_seen, columns_linked, columns_orphaned

CREATE (r:CrawlRun {
    id: $id,
    connector: $connector,
    system_id: $system_id,
    started_at: datetime($started_at),
    finished_at: datetime($finished_at),
    columns_seen: $columns_seen,
    columns_linked: $columns_linked,
    columns_orphaned: $columns_orphaned
})
WITH r
MATCH (s:PhysicalSystem {id: $system_id})
MERGE (s)-[:HAS_CRAWL]->(r)
RETURN r.id AS id;
