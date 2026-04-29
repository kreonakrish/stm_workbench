// Migration 006 — Seed :Entity and :BusinessAttribute nodes (S1).
//
// These are the curated business attributes intake validation queries against.
// Coverage is intentionally partial — common Home Lending attributes for the
// most central entities. Additional entities/attributes land via subsequent
// migrations or through an admin UI.
//
// Idempotent (MERGE on stable IDs).

// ---------------------------------------------------------------
// Entities — promoted hl_kg labels carrying Business Attributes.
// ---------------------------------------------------------------

MERGE (e:Entity {name: 'Borrower'})       ON CREATE SET e.description = 'Mortgage applicant or co-applicant';
MERGE (e:Entity {name: 'CoBorrower'})     ON CREATE SET e.description = 'Co-applicant on a joint mortgage application';
MERGE (e:Entity {name: 'MortgageLoan'})   ON CREATE SET e.description = 'A mortgage origination or servicing record';
MERGE (e:Entity {name: 'Property'})       ON CREATE SET e.description = 'Real-estate collateral attached to a mortgage';
MERGE (e:Entity {name: 'Lender'})         ON CREATE SET e.description = 'Originating lender of a mortgage';
MERGE (e:Entity {name: 'Servicer'})       ON CREATE SET e.description = 'Servicing entity for a mortgage';
MERGE (e:Entity {name: 'Investor'})       ON CREATE SET e.description = 'Holder of the mortgage note (e.g. GSE, private buyer)';
MERGE (e:Entity {name: 'LoanOfficer'})    ON CREATE SET e.description = 'Originating loan officer';
MERGE (e:Entity {name: 'Employer'})       ON CREATE SET e.description = 'Employer reported by a borrower for income verification';
MERGE (e:Entity {name: 'Appraisal'})      ON CREATE SET e.description = 'Property appraisal record';
MERGE (e:Entity {name: 'Document'})       ON CREATE SET e.description = 'Collected document associated with a loan';
MERGE (e:Entity {name: 'Fee'})            ON CREATE SET e.description = 'Fee charged or collected on a loan';
MERGE (e:Entity {name: 'Payment'})        ON CREATE SET e.description = 'A payment event on a loan account';

// ---------------------------------------------------------------
// Business attributes — id format: <entity_lowercase>.<attribute>
// pii_classification: NONE | INTERNAL | RESTRICTED
// ---------------------------------------------------------------

// --- Borrower ---
MATCH (e:Entity {name: 'Borrower'})
MERGE (a:BusinessAttribute {id: 'borrower.borrower_id'}) ON CREATE SET a.name='borrower_id', a.description='Unique borrower identifier', a.data_type='string', a.pii_classification='INTERNAL', a.is_key=true
MERGE (e)-[:HAS_ATTRIBUTE]->(a);

MATCH (e:Entity {name: 'Borrower'})
MERGE (a:BusinessAttribute {id: 'borrower.first_name'}) ON CREATE SET a.name='first_name', a.description='Borrower legal first name', a.data_type='string', a.pii_classification='RESTRICTED', a.is_key=false
MERGE (e)-[:HAS_ATTRIBUTE]->(a);

MATCH (e:Entity {name: 'Borrower'})
MERGE (a:BusinessAttribute {id: 'borrower.last_name'}) ON CREATE SET a.name='last_name', a.description='Borrower legal last name', a.data_type='string', a.pii_classification='RESTRICTED', a.is_key=false
MERGE (e)-[:HAS_ATTRIBUTE]->(a);

MATCH (e:Entity {name: 'Borrower'})
MERGE (a:BusinessAttribute {id: 'borrower.ssn'}) ON CREATE SET a.name='ssn', a.description='Social Security Number', a.data_type='string', a.pii_classification='RESTRICTED', a.is_key=false
MERGE (e)-[:HAS_ATTRIBUTE]->(a);

MATCH (e:Entity {name: 'Borrower'})
MERGE (a:BusinessAttribute {id: 'borrower.dob'}) ON CREATE SET a.name='dob', a.description='Date of birth', a.data_type='date', a.pii_classification='RESTRICTED', a.is_key=false
MERGE (e)-[:HAS_ATTRIBUTE]->(a);

MATCH (e:Entity {name: 'Borrower'})
MERGE (a:BusinessAttribute {id: 'borrower.email'}) ON CREATE SET a.name='email', a.description='Borrower contact email', a.data_type='string', a.pii_classification='RESTRICTED', a.is_key=false
MERGE (e)-[:HAS_ATTRIBUTE]->(a);

MATCH (e:Entity {name: 'Borrower'})
MERGE (a:BusinessAttribute {id: 'borrower.phone'}) ON CREATE SET a.name='phone', a.description='Borrower contact phone', a.data_type='string', a.pii_classification='RESTRICTED', a.is_key=false
MERGE (e)-[:HAS_ATTRIBUTE]->(a);

MATCH (e:Entity {name: 'Borrower'})
MERGE (a:BusinessAttribute {id: 'borrower.fico_score'}) ON CREATE SET a.name='fico_score', a.description='FICO score captured at application', a.data_type='integer', a.pii_classification='INTERNAL', a.is_key=false
MERGE (e)-[:HAS_ATTRIBUTE]->(a);

MATCH (e:Entity {name: 'Borrower'})
MERGE (a:BusinessAttribute {id: 'borrower.current_fico_score'}) ON CREATE SET a.name='current_fico_score', a.description='Most recent FICO score from monthly bureau pull', a.data_type='integer', a.pii_classification='INTERNAL', a.is_key=false
MERGE (e)-[:HAS_ATTRIBUTE]->(a);

MATCH (e:Entity {name: 'Borrower'})
MERGE (a:BusinessAttribute {id: 'borrower.annual_income'}) ON CREATE SET a.name='annual_income', a.description='Verified annual income at origination', a.data_type='decimal', a.pii_classification='INTERNAL', a.is_key=false
MERGE (e)-[:HAS_ATTRIBUTE]->(a);

MATCH (e:Entity {name: 'Borrower'})
MERGE (a:BusinessAttribute {id: 'borrower.monthly_debt'}) ON CREATE SET a.name='monthly_debt', a.description='Monthly debt obligation at origination', a.data_type='decimal', a.pii_classification='INTERNAL', a.is_key=false
MERGE (e)-[:HAS_ATTRIBUTE]->(a);

MATCH (e:Entity {name: 'Borrower'})
MERGE (a:BusinessAttribute {id: 'borrower.employment_status'}) ON CREATE SET a.name='employment_status', a.description='W2 / Self-Employed / Retired / Other', a.data_type='string', a.pii_classification='INTERNAL', a.is_key=false
MERGE (e)-[:HAS_ATTRIBUTE]->(a);

MATCH (e:Entity {name: 'Borrower'})
MERGE (a:BusinessAttribute {id: 'borrower.citizenship_status'}) ON CREATE SET a.name='citizenship_status', a.description='US Citizen / Permanent Resident / Non-Resident', a.data_type='string', a.pii_classification='INTERNAL', a.is_key=false
MERGE (e)-[:HAS_ATTRIBUTE]->(a);

MATCH (e:Entity {name: 'Borrower'})
MERGE (a:BusinessAttribute {id: 'borrower.marital_status'}) ON CREATE SET a.name='marital_status', a.description='Borrower marital status at application', a.data_type='string', a.pii_classification='INTERNAL', a.is_key=false
MERGE (e)-[:HAS_ATTRIBUTE]->(a);

// --- MortgageLoan ---
MATCH (e:Entity {name: 'MortgageLoan'})
MERGE (a:BusinessAttribute {id: 'mortgageloan.loan_id'}) ON CREATE SET a.name='loan_id', a.description='Unique loan identifier', a.data_type='string', a.pii_classification='INTERNAL', a.is_key=true
MERGE (e)-[:HAS_ATTRIBUTE]->(a);

MATCH (e:Entity {name: 'MortgageLoan'})
MERGE (a:BusinessAttribute {id: 'mortgageloan.borrower_id'}) ON CREATE SET a.name='borrower_id', a.description='FK to primary borrower', a.data_type='string', a.pii_classification='INTERNAL', a.is_key=false
MERGE (e)-[:HAS_ATTRIBUTE]->(a);

MATCH (e:Entity {name: 'MortgageLoan'})
MERGE (a:BusinessAttribute {id: 'mortgageloan.property_id'}) ON CREATE SET a.name='property_id', a.description='FK to collateral property', a.data_type='string', a.pii_classification='INTERNAL', a.is_key=false
MERGE (e)-[:HAS_ATTRIBUTE]->(a);

MATCH (e:Entity {name: 'MortgageLoan'})
MERGE (a:BusinessAttribute {id: 'mortgageloan.loan_amount'}) ON CREATE SET a.name='loan_amount', a.description='Original principal balance', a.data_type='decimal', a.pii_classification='INTERNAL', a.is_key=false
MERGE (e)-[:HAS_ATTRIBUTE]->(a);

MATCH (e:Entity {name: 'MortgageLoan'})
MERGE (a:BusinessAttribute {id: 'mortgageloan.interest_rate'}) ON CREATE SET a.name='interest_rate', a.description='Note rate at origination (annualized)', a.data_type='decimal', a.pii_classification='NONE', a.is_key=false
MERGE (e)-[:HAS_ATTRIBUTE]->(a);

MATCH (e:Entity {name: 'MortgageLoan'})
MERGE (a:BusinessAttribute {id: 'mortgageloan.term_months'}) ON CREATE SET a.name='term_months', a.description='Loan term in months (e.g. 360 for 30-year)', a.data_type='integer', a.pii_classification='NONE', a.is_key=false
MERGE (e)-[:HAS_ATTRIBUTE]->(a);

MATCH (e:Entity {name: 'MortgageLoan'})
MERGE (a:BusinessAttribute {id: 'mortgageloan.ltv'}) ON CREATE SET a.name='ltv', a.description='Loan-to-Value ratio at origination', a.data_type='decimal', a.pii_classification='NONE', a.is_key=false
MERGE (e)-[:HAS_ATTRIBUTE]->(a);

MATCH (e:Entity {name: 'MortgageLoan'})
MERGE (a:BusinessAttribute {id: 'mortgageloan.dti'}) ON CREATE SET a.name='dti', a.description='Debt-to-Income ratio at origination', a.data_type='decimal', a.pii_classification='NONE', a.is_key=false
MERGE (e)-[:HAS_ATTRIBUTE]->(a);

MATCH (e:Entity {name: 'MortgageLoan'})
MERGE (a:BusinessAttribute {id: 'mortgageloan.product_type'}) ON CREATE SET a.name='product_type', a.description='Conventional / FHA / VA / Jumbo', a.data_type='string', a.pii_classification='NONE', a.is_key=false
MERGE (e)-[:HAS_ATTRIBUTE]->(a);

MATCH (e:Entity {name: 'MortgageLoan'})
MERGE (a:BusinessAttribute {id: 'mortgageloan.loan_purpose'}) ON CREATE SET a.name='loan_purpose', a.description='Purchase / Refi-Rate-Term / Refi-Cashout', a.data_type='string', a.pii_classification='NONE', a.is_key=false
MERGE (e)-[:HAS_ATTRIBUTE]->(a);

MATCH (e:Entity {name: 'MortgageLoan'})
MERGE (a:BusinessAttribute {id: 'mortgageloan.origination_date'}) ON CREATE SET a.name='origination_date', a.description='Date loan was originated', a.data_type='date', a.pii_classification='NONE', a.is_key=false
MERGE (e)-[:HAS_ATTRIBUTE]->(a);

MATCH (e:Entity {name: 'MortgageLoan'})
MERGE (a:BusinessAttribute {id: 'mortgageloan.maturity_date'}) ON CREATE SET a.name='maturity_date', a.description='Loan maturity (final payment due) date', a.data_type='date', a.pii_classification='NONE', a.is_key=false
MERGE (e)-[:HAS_ATTRIBUTE]->(a);

MATCH (e:Entity {name: 'MortgageLoan'})
MERGE (a:BusinessAttribute {id: 'mortgageloan.loan_status'}) ON CREATE SET a.name='loan_status', a.description='Active / Paid Off / Charged Off / Foreclosure', a.data_type='string', a.pii_classification='NONE', a.is_key=false
MERGE (e)-[:HAS_ATTRIBUTE]->(a);

MATCH (e:Entity {name: 'MortgageLoan'})
MERGE (a:BusinessAttribute {id: 'mortgageloan.mortgage_insurance_required'}) ON CREATE SET a.name='mortgage_insurance_required', a.description='Whether MI/PMI is required on this loan', a.data_type='boolean', a.pii_classification='NONE', a.is_key=false
MERGE (e)-[:HAS_ATTRIBUTE]->(a);

// --- Property ---
MATCH (e:Entity {name: 'Property'})
MERGE (a:BusinessAttribute {id: 'property.property_id'}) ON CREATE SET a.name='property_id', a.description='Unique property identifier', a.data_type='string', a.pii_classification='INTERNAL', a.is_key=true
MERGE (e)-[:HAS_ATTRIBUTE]->(a);

MATCH (e:Entity {name: 'Property'})
MERGE (a:BusinessAttribute {id: 'property.street_address'}) ON CREATE SET a.name='street_address', a.description='Street address line', a.data_type='string', a.pii_classification='RESTRICTED', a.is_key=false
MERGE (e)-[:HAS_ATTRIBUTE]->(a);

MATCH (e:Entity {name: 'Property'})
MERGE (a:BusinessAttribute {id: 'property.city'}) ON CREATE SET a.name='city', a.description='Property city', a.data_type='string', a.pii_classification='INTERNAL', a.is_key=false
MERGE (e)-[:HAS_ATTRIBUTE]->(a);

MATCH (e:Entity {name: 'Property'})
MERGE (a:BusinessAttribute {id: 'property.state'}) ON CREATE SET a.name='state', a.description='Property state (USPS 2-letter code)', a.data_type='string', a.pii_classification='INTERNAL', a.is_key=false
MERGE (e)-[:HAS_ATTRIBUTE]->(a);

MATCH (e:Entity {name: 'Property'})
MERGE (a:BusinessAttribute {id: 'property.zip_code'}) ON CREATE SET a.name='zip_code', a.description='5-digit postal code', a.data_type='string', a.pii_classification='INTERNAL', a.is_key=false
MERGE (e)-[:HAS_ATTRIBUTE]->(a);

MATCH (e:Entity {name: 'Property'})
MERGE (a:BusinessAttribute {id: 'property.property_type'}) ON CREATE SET a.name='property_type', a.description='SFR / Condo / Townhouse / 2-4 Unit', a.data_type='string', a.pii_classification='NONE', a.is_key=false
MERGE (e)-[:HAS_ATTRIBUTE]->(a);

MATCH (e:Entity {name: 'Property'})
MERGE (a:BusinessAttribute {id: 'property.year_built'}) ON CREATE SET a.name='year_built', a.description='Year of property construction', a.data_type='integer', a.pii_classification='NONE', a.is_key=false
MERGE (e)-[:HAS_ATTRIBUTE]->(a);

MATCH (e:Entity {name: 'Property'})
MERGE (a:BusinessAttribute {id: 'property.square_footage'}) ON CREATE SET a.name='square_footage', a.description='Gross living area in square feet', a.data_type='integer', a.pii_classification='NONE', a.is_key=false
MERGE (e)-[:HAS_ATTRIBUTE]->(a);

MATCH (e:Entity {name: 'Property'})
MERGE (a:BusinessAttribute {id: 'property.appraisal_value'}) ON CREATE SET a.name='appraisal_value', a.description='Most recent appraised value', a.data_type='decimal', a.pii_classification='NONE', a.is_key=false
MERGE (e)-[:HAS_ATTRIBUTE]->(a);

MATCH (e:Entity {name: 'Property'})
MERGE (a:BusinessAttribute {id: 'property.num_units'}) ON CREATE SET a.name='num_units', a.description='Number of dwelling units in the property', a.data_type='integer', a.pii_classification='NONE', a.is_key=false
MERGE (e)-[:HAS_ATTRIBUTE]->(a);

// --- Lender ---
MATCH (e:Entity {name: 'Lender'})
MERGE (a:BusinessAttribute {id: 'lender.lender_id'}) ON CREATE SET a.name='lender_id', a.description='Unique lender identifier', a.data_type='string', a.pii_classification='NONE', a.is_key=true
MERGE (e)-[:HAS_ATTRIBUTE]->(a);

MATCH (e:Entity {name: 'Lender'})
MERGE (a:BusinessAttribute {id: 'lender.name'}) ON CREATE SET a.name='name', a.description='Legal name of the lender', a.data_type='string', a.pii_classification='NONE', a.is_key=false
MERGE (e)-[:HAS_ATTRIBUTE]->(a);

MATCH (e:Entity {name: 'Lender'})
MERGE (a:BusinessAttribute {id: 'lender.license_number'}) ON CREATE SET a.name='license_number', a.description='State or federal lender license number', a.data_type='string', a.pii_classification='INTERNAL', a.is_key=false
MERGE (e)-[:HAS_ATTRIBUTE]->(a);

// --- Servicer ---
MATCH (e:Entity {name: 'Servicer'})
MERGE (a:BusinessAttribute {id: 'servicer.servicer_id'}) ON CREATE SET a.name='servicer_id', a.description='Unique servicer identifier', a.data_type='string', a.pii_classification='NONE', a.is_key=true
MERGE (e)-[:HAS_ATTRIBUTE]->(a);

MATCH (e:Entity {name: 'Servicer'})
MERGE (a:BusinessAttribute {id: 'servicer.name'}) ON CREATE SET a.name='name', a.description='Legal name of the servicer', a.data_type='string', a.pii_classification='NONE', a.is_key=false
MERGE (e)-[:HAS_ATTRIBUTE]->(a);

// --- Investor ---
MATCH (e:Entity {name: 'Investor'})
MERGE (a:BusinessAttribute {id: 'investor.investor_id'}) ON CREATE SET a.name='investor_id', a.description='Unique investor identifier', a.data_type='string', a.pii_classification='NONE', a.is_key=true
MERGE (e)-[:HAS_ATTRIBUTE]->(a);

MATCH (e:Entity {name: 'Investor'})
MERGE (a:BusinessAttribute {id: 'investor.name'}) ON CREATE SET a.name='name', a.description='Legal name of the investor (e.g. Fannie Mae)', a.data_type='string', a.pii_classification='NONE', a.is_key=false
MERGE (e)-[:HAS_ATTRIBUTE]->(a);

// --- Document ---
MATCH (e:Entity {name: 'Document'})
MERGE (a:BusinessAttribute {id: 'document.document_id'}) ON CREATE SET a.name='document_id', a.description='Unique document identifier', a.data_type='string', a.pii_classification='INTERNAL', a.is_key=true
MERGE (e)-[:HAS_ATTRIBUTE]->(a);

MATCH (e:Entity {name: 'Document'})
MERGE (a:BusinessAttribute {id: 'document.document_type'}) ON CREATE SET a.name='document_type', a.description='W2 / 1099 / Bank Statement / Tax Return / ...', a.data_type='string', a.pii_classification='INTERNAL', a.is_key=false
MERGE (e)-[:HAS_ATTRIBUTE]->(a);

// --- Fee ---
MATCH (e:Entity {name: 'Fee'})
MERGE (a:BusinessAttribute {id: 'fee.fee_id'}) ON CREATE SET a.name='fee_id', a.description='Unique fee identifier', a.data_type='string', a.pii_classification='INTERNAL', a.is_key=true
MERGE (e)-[:HAS_ATTRIBUTE]->(a);

MATCH (e:Entity {name: 'Fee'})
MERGE (a:BusinessAttribute {id: 'fee.fee_type'}) ON CREATE SET a.name='fee_type', a.description='Origination / Underwriting / Appraisal / Recording / ...', a.data_type='string', a.pii_classification='NONE', a.is_key=false
MERGE (e)-[:HAS_ATTRIBUTE]->(a);

MATCH (e:Entity {name: 'Fee'})
MERGE (a:BusinessAttribute {id: 'fee.amount'}) ON CREATE SET a.name='amount', a.description='Fee amount in USD', a.data_type='decimal', a.pii_classification='NONE', a.is_key=false
MERGE (e)-[:HAS_ATTRIBUTE]->(a);

// ---------------------------------------------------------------
// Record this migration.
// ---------------------------------------------------------------

MERGE (m:SchemaMigration {migration_id: '006_seed_ontology_attributes'})
ON CREATE SET m.applied_at = datetime(),
              m.description = 'Seed :Entity nodes and curated :BusinessAttribute catalog for Borrower, MortgageLoan, Property, Lender, Servicer, Investor, Document, Fee (S1)';
