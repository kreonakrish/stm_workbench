// Migration 010 — Schema for :ChangeColumn (multi-column change lines).
//
// A ChangeLine now carries a list of target columns instead of a single
// target_attribute. Each column is its own :ChangeColumn node linked to
// its parent :ChangeLine via :HAS_COLUMN, with `position` preserving
// declaration order so reads return columns deterministically.
//
// Idempotent.

CREATE CONSTRAINT change_column_id_unique IF NOT EXISTS
FOR (n:ChangeColumn) REQUIRE n.id IS UNIQUE;

CREATE INDEX change_column_change_line IF NOT EXISTS
FOR (n:ChangeColumn) ON (n.change_line_id);

MERGE (m:SchemaMigration {migration_id: '010_change_column_schema'})
ON CREATE SET m.applied_at = datetime(),
              m.description = 'Constraint + index for :ChangeColumn — per-column entries inside a ChangeLine';
