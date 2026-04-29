// Migration 007 — Seed sample :PhysicalSystem nodes and a small map of
// :PhysicalTable / :PhysicalColumn nodes linked to BusinessAttributes (S1).
//
// Without this seed the validation pipeline would have no source-system
// data to surface when a user asks "where does borrower_id live?". The
// crawler (S4) extends this set as it scans real systems; this migration
// gives the workbench a working starting point on a cold install.
//
// Idempotent.

// ---------------------------------------------------------------
// Source systems we crawl from.
// ---------------------------------------------------------------

MERGE (s:PhysicalSystem {id: 'oracle_loan_prod'})
ON CREATE SET s.name = 'Oracle Loan Production', s.kind = 'oracle';

MERGE (s:PhysicalSystem {id: 'snowflake_analytics'})
ON CREATE SET s.name = 'Snowflake Analytics', s.kind = 'snowflake';

MERGE (s:PhysicalSystem {id: 'mysql_servicing'})
ON CREATE SET s.name = 'MySQL Servicing', s.kind = 'mysql';

MERGE (s:PhysicalSystem {id: 's3_loan_lake'})
ON CREATE SET s.name = 'S3 Loan Lake', s.kind = 's3';

MERGE (s:PhysicalSystem {id: 'glue_catalog_prod'})
ON CREATE SET s.name = 'AWS Glue Catalog (Prod)', s.kind = 'glue';

MERGE (s:PhysicalSystem {id: 'sql_server_origination'})
ON CREATE SET s.name = 'SQL Server Origination', s.kind = 'sql_server';

// ---------------------------------------------------------------
// Sample physical mappings — Borrower attributes in two systems
// (Oracle origination + Snowflake analytics) so the user can see a
// duplicated-source case (current_fico_score in both).
// ---------------------------------------------------------------

MATCH (s:PhysicalSystem {id: 'oracle_loan_prod'})
MERGE (t:PhysicalTable {id: 'oracle_loan_prod.LOAN_DB.BORROWER'})
ON CREATE SET t.name = 'BORROWER', t.schema = 'LOAN_DB'
MERGE (t)-[:IN_SYSTEM]->(s);

MATCH (t:PhysicalTable {id: 'oracle_loan_prod.LOAN_DB.BORROWER'})
MERGE (c:PhysicalColumn {id: 'oracle_loan_prod.LOAN_DB.BORROWER.BORROWER_ID'})
ON CREATE SET c.name = 'BORROWER_ID', c.data_type = 'VARCHAR2(20)', c.nullable = false
MERGE (c)-[:IN_TABLE]->(t)
WITH c
MATCH (a:BusinessAttribute {id: 'borrower.borrower_id'})
MERGE (a)-[:SOURCED_FROM]->(c);

MATCH (t:PhysicalTable {id: 'oracle_loan_prod.LOAN_DB.BORROWER'})
MERGE (c:PhysicalColumn {id: 'oracle_loan_prod.LOAN_DB.BORROWER.SSN'})
ON CREATE SET c.name = 'SSN', c.data_type = 'VARCHAR2(11)', c.nullable = false
MERGE (c)-[:IN_TABLE]->(t)
WITH c
MATCH (a:BusinessAttribute {id: 'borrower.ssn'})
MERGE (a)-[:SOURCED_FROM]->(c);

MATCH (t:PhysicalTable {id: 'oracle_loan_prod.LOAN_DB.BORROWER'})
MERGE (c:PhysicalColumn {id: 'oracle_loan_prod.LOAN_DB.BORROWER.FICO_SCORE'})
ON CREATE SET c.name = 'FICO_SCORE', c.data_type = 'NUMBER(3)', c.nullable = true
MERGE (c)-[:IN_TABLE]->(t)
WITH c
MATCH (a:BusinessAttribute {id: 'borrower.fico_score'})
MERGE (a)-[:SOURCED_FROM]->(c);

MATCH (t:PhysicalTable {id: 'oracle_loan_prod.LOAN_DB.BORROWER'})
MERGE (c:PhysicalColumn {id: 'oracle_loan_prod.LOAN_DB.BORROWER.ANNUAL_INCOME'})
ON CREATE SET c.name = 'ANNUAL_INCOME', c.data_type = 'NUMBER(12,2)', c.nullable = true
MERGE (c)-[:IN_TABLE]->(t)
WITH c
MATCH (a:BusinessAttribute {id: 'borrower.annual_income'})
MERGE (a)-[:SOURCED_FROM]->(c);

// Snowflake analytics has the latest FICO snapshot
MATCH (s:PhysicalSystem {id: 'snowflake_analytics'})
MERGE (t:PhysicalTable {id: 'snowflake_analytics.ANALYTICS.BORROWER_CREDIT_MONTHLY'})
ON CREATE SET t.name = 'BORROWER_CREDIT_MONTHLY', t.schema = 'ANALYTICS'
MERGE (t)-[:IN_SYSTEM]->(s);

MATCH (t:PhysicalTable {id: 'snowflake_analytics.ANALYTICS.BORROWER_CREDIT_MONTHLY'})
MERGE (c:PhysicalColumn {id: 'snowflake_analytics.ANALYTICS.BORROWER_CREDIT_MONTHLY.CURRENT_FICO_SCORE'})
ON CREATE SET c.name = 'CURRENT_FICO_SCORE', c.data_type = 'NUMBER(3)', c.nullable = true
MERGE (c)-[:IN_TABLE]->(t)
WITH c
MATCH (a:BusinessAttribute {id: 'borrower.current_fico_score'})
MERGE (a)-[:SOURCED_FROM]->(c);

MATCH (t:PhysicalTable {id: 'snowflake_analytics.ANALYTICS.BORROWER_CREDIT_MONTHLY'})
MERGE (c:PhysicalColumn {id: 'snowflake_analytics.ANALYTICS.BORROWER_CREDIT_MONTHLY.BORROWER_ID'})
ON CREATE SET c.name = 'BORROWER_ID', c.data_type = 'STRING', c.nullable = false
MERGE (c)-[:IN_TABLE]->(t)
WITH c
MATCH (a:BusinessAttribute {id: 'borrower.borrower_id'})
MERGE (a)-[:SOURCED_FROM]->(c);

// MySQL servicing has the loan record
MATCH (s:PhysicalSystem {id: 'mysql_servicing'})
MERGE (t:PhysicalTable {id: 'mysql_servicing.servicing.loan'})
ON CREATE SET t.name = 'loan', t.schema = 'servicing'
MERGE (t)-[:IN_SYSTEM]->(s);

MATCH (t:PhysicalTable {id: 'mysql_servicing.servicing.loan'})
MERGE (c:PhysicalColumn {id: 'mysql_servicing.servicing.loan.loan_id'})
ON CREATE SET c.name = 'loan_id', c.data_type = 'VARCHAR(32)', c.nullable = false
MERGE (c)-[:IN_TABLE]->(t)
WITH c
MATCH (a:BusinessAttribute {id: 'mortgageloan.loan_id'})
MERGE (a)-[:SOURCED_FROM]->(c);

MATCH (t:PhysicalTable {id: 'mysql_servicing.servicing.loan'})
MERGE (c:PhysicalColumn {id: 'mysql_servicing.servicing.loan.loan_status'})
ON CREATE SET c.name = 'loan_status', c.data_type = 'VARCHAR(32)', c.nullable = false
MERGE (c)-[:IN_TABLE]->(t)
WITH c
MATCH (a:BusinessAttribute {id: 'mortgageloan.loan_status'})
MERGE (a)-[:SOURCED_FROM]->(c);

MATCH (t:PhysicalTable {id: 'mysql_servicing.servicing.loan'})
MERGE (c:PhysicalColumn {id: 'mysql_servicing.servicing.loan.interest_rate'})
ON CREATE SET c.name = 'interest_rate', c.data_type = 'DECIMAL(6,4)', c.nullable = false
MERGE (c)-[:IN_TABLE]->(t)
WITH c
MATCH (a:BusinessAttribute {id: 'mortgageloan.interest_rate'})
MERGE (a)-[:SOURCED_FROM]->(c);

// ---------------------------------------------------------------
// Record this migration.
// ---------------------------------------------------------------

MERGE (m:SchemaMigration {migration_id: '007_seed_physical_sources'})
ON CREATE SET m.applied_at = datetime(),
              m.description = 'Seed PhysicalSystem nodes (6 systems) and sample PhysicalTable/PhysicalColumn mappings for Borrower + MortgageLoan attributes (S1)';
