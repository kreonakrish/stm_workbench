// Migration 005 — Constraints for the intake-substance graph layer (S1).
//
// New labels:
//   :Entity              — a business entity type promoted from hl_kg labels
//                          (Borrower, MortgageLoan, ...) so it can carry curated
//                          BusinessAttributes and be addressed in cypher uniformly.
//   :BusinessAttribute   — a curated attribute on an Entity (the level at which
//                          intake validation operates).
//   :PhysicalSystem      — a source system (Oracle / Snowflake / S3 / ...).
//   :PhysicalTable       — a table inside a system.
//   :PhysicalColumn      — a column inside a table.
//   :ChangeLine          — a single typed change inside an intake request
//                          (add_attribute / change_logic / add_table / delete_table).
//   :CrawlRun            — provenance for a crawler invocation that upserted
//                          physical-system data.
//
// Idempotent.

// ---------------------------------------------------------------
// Uniqueness constraints
// ---------------------------------------------------------------

CREATE CONSTRAINT entity_name_unique IF NOT EXISTS
FOR (n:Entity) REQUIRE n.name IS UNIQUE;

CREATE CONSTRAINT business_attribute_id_unique IF NOT EXISTS
FOR (n:BusinessAttribute) REQUIRE n.id IS UNIQUE;

CREATE CONSTRAINT physical_system_id_unique IF NOT EXISTS
FOR (n:PhysicalSystem) REQUIRE n.id IS UNIQUE;

CREATE CONSTRAINT physical_table_id_unique IF NOT EXISTS
FOR (n:PhysicalTable) REQUIRE n.id IS UNIQUE;

CREATE CONSTRAINT physical_column_id_unique IF NOT EXISTS
FOR (n:PhysicalColumn) REQUIRE n.id IS UNIQUE;

CREATE CONSTRAINT change_line_id_unique IF NOT EXISTS
FOR (n:ChangeLine) REQUIRE n.id IS UNIQUE;

CREATE CONSTRAINT crawl_run_id_unique IF NOT EXISTS
FOR (n:CrawlRun) REQUIRE n.id IS UNIQUE;

// ---------------------------------------------------------------
// Indexes for typeahead and request-scoped lookups
// ---------------------------------------------------------------

CREATE INDEX business_attribute_name IF NOT EXISTS
FOR (n:BusinessAttribute) ON (n.name);

CREATE INDEX physical_column_name IF NOT EXISTS
FOR (n:PhysicalColumn) ON (n.name);

CREATE INDEX physical_table_name IF NOT EXISTS
FOR (n:PhysicalTable) ON (n.name);

CREATE INDEX change_line_request IF NOT EXISTS
FOR (n:ChangeLine) ON (n.request_id);

CREATE INDEX change_line_classification IF NOT EXISTS
FOR (n:ChangeLine) ON (n.classification);

// ---------------------------------------------------------------
// Record this migration
// ---------------------------------------------------------------

MERGE (m:SchemaMigration {migration_id: '005_intake_substance_schema'})
ON CREATE SET m.applied_at = datetime(),
              m.description = 'Constraints for :Entity, :BusinessAttribute, :Physical*, :ChangeLine, :CrawlRun (S1)';
