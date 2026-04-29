// Migration 008 — MISMO 3.6.2-aligned ontology expansion.
//
// Substantially extends the curated business-attribute catalog using
// commonly-documented MISMO 3.6.2 reference-model entity and attribute
// names (Loan, Party, Property, Income, Asset, Liability, Credit,
// HMDA, Underwriting, Closing Disclosure, etc.).
//
// IMPORTANT: this seed is derived from public MISMO documentation and
// regulator-published derivatives (URLA / ULAD, HMDA, TRID). It is NOT
// the canonical MISMO XSD and is NOT licensed redistribution of
// MISMO content. For a production deployment that must conform
// exactly, replace this migration with one generated from the
// licensed MISMO 3.6.2 reference XSD obtained via
// https://www.mismo.org/standards-resources/license-form/.
//
// MERGE-based, idempotent. Existing attributes (from migration 006)
// are not overwritten — ON CREATE only.

// ===============================================================
// 1. New entities
// ===============================================================

MERGE (e:Entity {name: 'Income'})
ON CREATE SET e.description = 'Borrower income source (employment, investment, rental, etc.)';
MERGE (e:Entity {name: 'Asset'})
ON CREATE SET e.description = 'Borrower-owned asset used in qualification (deposit account, retirement, gift, etc.)';
MERGE (e:Entity {name: 'Liability'})
ON CREATE SET e.description = 'Outstanding debt or financial obligation of the borrower';
MERGE (e:Entity {name: 'CreditReport'})
ON CREATE SET e.description = 'Credit bureau report referenced during underwriting';
MERGE (e:Entity {name: 'Insurance'})
ON CREATE SET e.description = 'Insurance policy associated with the loan or property';
MERGE (e:Entity {name: 'Escrow'})
ON CREATE SET e.description = 'Escrow account item or aggregate balance';
MERGE (e:Entity {name: 'Underwriting'})
ON CREATE SET e.description = 'Underwriting determination for a loan';
MERGE (e:Entity {name: 'ClosingDisclosure'})
ON CREATE SET e.description = 'TRID closing disclosure record';
MERGE (e:Entity {name: 'Title'})
ON CREATE SET e.description = 'Title insurance and chain-of-title information';
MERGE (e:Entity {name: 'HMDARecord'})
ON CREATE SET e.description = 'HMDA reportable data for fair-lending monitoring';
MERGE (e:Entity {name: 'LoanProduct'})
ON CREATE SET e.description = 'Loan product features, terms, and pricing definition';
MERGE (e:Entity {name: 'LoanCondition'})
ON CREATE SET e.description = 'Conditional approval requirement attached to the loan';
MERGE (e:Entity {name: 'VerificationOfEmployment'})
ON CREATE SET e.description = 'Employment verification record (verbal, written, third-party)';
MERGE (e:Entity {name: 'DownPaymentSource'})
ON CREATE SET e.description = 'Source of borrower funds for down payment / closing costs';

// ===============================================================
// 2. Existing entities — MISMO attribute expansion
// ===============================================================

// --- Borrower (extends migration 006) ---
MATCH (e:Entity {name: 'Borrower'})
UNWIND [
  {id: 'borrower.middle_name', name: 'middle_name', description: 'Borrower middle name (MISMO MiddleName)', data_type: 'string', pii: 'RESTRICTED', is_key: false},
  {id: 'borrower.suffix_name', name: 'suffix_name', description: 'Name suffix (Jr / Sr / III) (MISMO SuffixName)', data_type: 'string', pii: 'INTERNAL', is_key: false},
  {id: 'borrower.tax_identifier_type', name: 'tax_identifier_type', description: 'Tax ID type code SSN / ITIN / EIN (MISMO TaxpayerIdentifierType)', data_type: 'string', pii: 'INTERNAL', is_key: false},
  {id: 'borrower.tax_identifier_value', name: 'tax_identifier_value', description: 'Tax identifier value (MISMO TaxpayerIdentifierValue)', data_type: 'string', pii: 'RESTRICTED', is_key: false},
  {id: 'borrower.us_citizenship_indicator', name: 'us_citizenship_indicator', description: 'US citizen flag (MISMO USCitizenshipIndicator)', data_type: 'boolean', pii: 'INTERNAL', is_key: false},
  {id: 'borrower.residency_type', name: 'residency_type', description: 'Permanent / Non-permanent resident alien (MISMO BorrowerResidencyType)', data_type: 'string', pii: 'INTERNAL', is_key: false},
  {id: 'borrower.alien_registration_number', name: 'alien_registration_number', description: 'USCIS A-Number (MISMO AlienRegistrationIdentifier)', data_type: 'string', pii: 'RESTRICTED', is_key: false},
  {id: 'borrower.preferred_language_type', name: 'preferred_language_type', description: 'Preferred written language (MISMO BorrowerLanguagePreferenceType)', data_type: 'string', pii: 'INTERNAL', is_key: false},
  {id: 'borrower.dependent_count', name: 'dependent_count', description: 'Number of dependents (MISMO DependentCount)', data_type: 'integer', pii: 'INTERNAL', is_key: false},
  {id: 'borrower.military_service_indicator', name: 'military_service_indicator', description: 'Active or veteran service flag (MISMO MilitaryServiceIndicator)', data_type: 'boolean', pii: 'INTERNAL', is_key: false},
  {id: 'borrower.military_service_branch', name: 'military_service_branch', description: 'Service branch code (MISMO MilitaryServiceBranchType)', data_type: 'string', pii: 'INTERNAL', is_key: false},
  {id: 'borrower.ethnicity_type', name: 'ethnicity_type', description: 'HMDA ethnicity (MISMO HMDAEthnicityType)', data_type: 'string', pii: 'INTERNAL', is_key: false},
  {id: 'borrower.race_type', name: 'race_type', description: 'HMDA race (MISMO HMDARaceType)', data_type: 'string', pii: 'INTERNAL', is_key: false},
  {id: 'borrower.sex_type', name: 'sex_type', description: 'HMDA sex (MISMO HMDASexType)', data_type: 'string', pii: 'INTERNAL', is_key: false},
  {id: 'borrower.application_signed_date', name: 'application_signed_date', description: 'Date borrower signed the application (MISMO ApplicationSignedDate)', data_type: 'date', pii: 'INTERNAL', is_key: false},
  {id: 'borrower.first_time_homebuyer_indicator', name: 'first_time_homebuyer_indicator', description: 'First-time homebuyer flag (MISMO FirstTimeHomebuyerIndicator)', data_type: 'boolean', pii: 'INTERNAL', is_key: false},
  {id: 'borrower.address_type', name: 'address_type', description: 'Mailing / Property / Prior (MISMO AddressType)', data_type: 'string', pii: 'INTERNAL', is_key: false},
  {id: 'borrower.years_at_current_address', name: 'years_at_current_address', description: 'Years at current address (MISMO BorrowerResidencyDurationYearsCount)', data_type: 'integer', pii: 'INTERNAL', is_key: false},
  {id: 'borrower.borrower_classification_type', name: 'borrower_classification_type', description: 'Primary / Co-borrower / Title-only (MISMO BorrowerClassificationType)', data_type: 'string', pii: 'INTERNAL', is_key: false},
  {id: 'borrower.application_taken_method_type', name: 'application_taken_method_type', description: 'How application was collected (MISMO ApplicationTakenMethodType)', data_type: 'string', pii: 'INTERNAL', is_key: false}
] AS attr
MERGE (a:BusinessAttribute {id: attr.id})
ON CREATE SET a.name = attr.name, a.description = attr.description, a.data_type = attr.data_type, a.pii_classification = attr.pii, a.is_key = attr.is_key
MERGE (e)-[:HAS_ATTRIBUTE]->(a);

// --- MortgageLoan (extends migration 006) ---
MATCH (e:Entity {name: 'MortgageLoan'})
UNWIND [
  {id: 'mortgageloan.lender_loan_identifier', name: 'lender_loan_identifier', description: 'Lender-assigned loan number (MISMO LenderLoanIdentifier)', data_type: 'string', pii: 'INTERNAL', is_key: false},
  {id: 'mortgageloan.mers_min_number', name: 'mers_min_number', description: 'MERS Mortgage Identification Number (MISMO MERSMINNumber)', data_type: 'string', pii: 'INTERNAL', is_key: false},
  {id: 'mortgageloan.note_amount', name: 'note_amount', description: 'Original principal amount stated on the note (MISMO NoteAmount)', data_type: 'decimal', pii: 'INTERNAL', is_key: false},
  {id: 'mortgageloan.note_rate_percent', name: 'note_rate_percent', description: 'Note rate at origination (MISMO NoteRatePercent)', data_type: 'decimal', pii: 'NONE', is_key: false},
  {id: 'mortgageloan.note_date', name: 'note_date', description: 'Note execution date (MISMO NoteDate)', data_type: 'date', pii: 'NONE', is_key: false},
  {id: 'mortgageloan.amortization_type', name: 'amortization_type', description: 'Fixed / GEM / GPM / ARM / etc (MISMO AmortizationType)', data_type: 'string', pii: 'NONE', is_key: false},
  {id: 'mortgageloan.lien_priority_type', name: 'lien_priority_type', description: 'First / Second / Other (MISMO LienPriorityType)', data_type: 'string', pii: 'NONE', is_key: false},
  {id: 'mortgageloan.balloon_indicator', name: 'balloon_indicator', description: 'Balloon-payment loan flag (MISMO BalloonIndicator)', data_type: 'boolean', pii: 'NONE', is_key: false},
  {id: 'mortgageloan.balloon_payment_amount', name: 'balloon_payment_amount', description: 'Final balloon payment amount (MISMO BalloonPaymentAmount)', data_type: 'decimal', pii: 'NONE', is_key: false},
  {id: 'mortgageloan.prepayment_penalty_indicator', name: 'prepayment_penalty_indicator', description: 'Prepayment penalty present (MISMO PrepaymentPenaltyIndicator)', data_type: 'boolean', pii: 'NONE', is_key: false},
  {id: 'mortgageloan.buydown_temporary_indicator', name: 'buydown_temporary_indicator', description: 'Temporary rate buydown flag (MISMO BuydownTemporarySubsidyFundingIndicator)', data_type: 'boolean', pii: 'NONE', is_key: false},
  {id: 'mortgageloan.assumability_indicator', name: 'assumability_indicator', description: 'Loan can be assumed flag (MISMO AssumabilityIndicator)', data_type: 'boolean', pii: 'NONE', is_key: false},
  {id: 'mortgageloan.combined_ltv_ratio_percent', name: 'combined_ltv_ratio_percent', description: 'CLTV across all liens (MISMO CombinedLTVRatioPercent)', data_type: 'decimal', pii: 'NONE', is_key: false},
  {id: 'mortgageloan.total_ltv_ratio_percent', name: 'total_ltv_ratio_percent', description: 'TLTV including HELOC max (MISMO TotalLTVRatioPercent)', data_type: 'decimal', pii: 'NONE', is_key: false},
  {id: 'mortgageloan.subordinate_financing_present_indicator', name: 'subordinate_financing_present_indicator', description: 'Other financing present (MISMO SubordinateFinancingPresentIndicator)', data_type: 'boolean', pii: 'NONE', is_key: false},
  {id: 'mortgageloan.conventional_indicator', name: 'conventional_indicator', description: 'Conventional vs government (MISMO ConventionalIndicator)', data_type: 'boolean', pii: 'NONE', is_key: false},
  {id: 'mortgageloan.conformance_status', name: 'conformance_status', description: 'Conforming / Jumbo / Super-jumbo (MISMO LoanConformanceStatus)', data_type: 'string', pii: 'NONE', is_key: false},
  {id: 'mortgageloan.hmda_loan_type', name: 'hmda_loan_type', description: 'HMDA loan type code (MISMO HMDALoanType)', data_type: 'string', pii: 'NONE', is_key: false},
  {id: 'mortgageloan.hmda_loan_purpose_type', name: 'hmda_loan_purpose_type', description: 'HMDA purpose code (MISMO HMDALoanPurposeType)', data_type: 'string', pii: 'NONE', is_key: false},
  {id: 'mortgageloan.arm_initial_period_months', name: 'arm_initial_period_months', description: 'Initial fixed period for ARM (MISMO ARMInitialFixedPeriodEffectiveMonthsCount)', data_type: 'integer', pii: 'NONE', is_key: false},
  {id: 'mortgageloan.arm_index_type', name: 'arm_index_type', description: 'Underlying index (MISMO IndexType)', data_type: 'string', pii: 'NONE', is_key: false},
  {id: 'mortgageloan.arm_margin_rate', name: 'arm_margin_rate', description: 'Margin over index (MISMO MarginRatePercent)', data_type: 'decimal', pii: 'NONE', is_key: false},
  {id: 'mortgageloan.automated_underwriting_system_type', name: 'automated_underwriting_system_type', description: 'AUS used (DU / LP / Other) (MISMO AutomatedUnderwritingSystemType)', data_type: 'string', pii: 'NONE', is_key: false},
  {id: 'mortgageloan.automated_underwriting_recommendation_type', name: 'automated_underwriting_recommendation_type', description: 'AUS decision (MISMO AutomatedUnderwritingRecommendationType)', data_type: 'string', pii: 'NONE', is_key: false},
  {id: 'mortgageloan.decision_credit_score_value', name: 'decision_credit_score_value', description: 'Score used for decisioning (MISMO DecisionCreditScoreValue)', data_type: 'integer', pii: 'INTERNAL', is_key: false},
  {id: 'mortgageloan.escrow_indicator', name: 'escrow_indicator', description: 'Escrow account established (MISMO EscrowIndicator)', data_type: 'boolean', pii: 'NONE', is_key: false},
  {id: 'mortgageloan.regulation_z_total_loan_amount', name: 'regulation_z_total_loan_amount', description: 'TILA total loan amount (MISMO RegulationZTotalLoanAmount)', data_type: 'decimal', pii: 'NONE', is_key: false},
  {id: 'mortgageloan.application_received_date', name: 'application_received_date', description: 'Date of complete application (MISMO ApplicationReceivedDate)', data_type: 'date', pii: 'NONE', is_key: false},
  {id: 'mortgageloan.disbursement_date', name: 'disbursement_date', description: 'Funding / disbursement date (MISMO DisbursementDate)', data_type: 'date', pii: 'NONE', is_key: false},
  {id: 'mortgageloan.first_payment_due_date', name: 'first_payment_due_date', description: 'First payment due (MISMO FirstPaymentDueDate)', data_type: 'date', pii: 'NONE', is_key: false}
] AS attr
MERGE (a:BusinessAttribute {id: attr.id})
ON CREATE SET a.name = attr.name, a.description = attr.description, a.data_type = attr.data_type, a.pii_classification = attr.pii, a.is_key = attr.is_key
MERGE (e)-[:HAS_ATTRIBUTE]->(a);

// --- Property (extends migration 006) ---
MATCH (e:Entity {name: 'Property'})
UNWIND [
  {id: 'property.street_address_line2', name: 'street_address_line2', description: 'Apt / suite / unit (MISMO AddressLineText)', data_type: 'string', pii: 'RESTRICTED', is_key: false},
  {id: 'property.county_name', name: 'county_name', description: 'County (MISMO CountyName)', data_type: 'string', pii: 'INTERNAL', is_key: false},
  {id: 'property.county_fips', name: 'county_fips', description: 'County FIPS code (MISMO CountyFIPSCode)', data_type: 'string', pii: 'NONE', is_key: false},
  {id: 'property.legal_description', name: 'legal_description', description: 'Legal description text (MISMO PropertyLegalDescription)', data_type: 'string', pii: 'INTERNAL', is_key: false},
  {id: 'property.parcel_identifier', name: 'parcel_identifier', description: 'APN / tax parcel ID (MISMO ParcelIdentifier)', data_type: 'string', pii: 'INTERNAL', is_key: false},
  {id: 'property.property_estate_type', name: 'property_estate_type', description: 'Fee simple / Leasehold (MISMO PropertyEstateType)', data_type: 'string', pii: 'NONE', is_key: false},
  {id: 'property.property_usage_type', name: 'property_usage_type', description: 'Primary / Secondary / Investment (MISMO PropertyUsageType)', data_type: 'string', pii: 'NONE', is_key: false},
  {id: 'property.construction_method_type', name: 'construction_method_type', description: 'Site-built / Manufactured / Modular (MISMO ConstructionMethodType)', data_type: 'string', pii: 'NONE', is_key: false},
  {id: 'property.acreage_number', name: 'acreage_number', description: 'Land area in acres (MISMO PropertyAcreageNumber)', data_type: 'decimal', pii: 'NONE', is_key: false},
  {id: 'property.attached_indicator', name: 'attached_indicator', description: 'Attached vs detached (MISMO AttachmentType)', data_type: 'boolean', pii: 'NONE', is_key: false},
  {id: 'property.bedroom_count', name: 'bedroom_count', description: 'Bedroom count (MISMO BedroomCount)', data_type: 'integer', pii: 'NONE', is_key: false},
  {id: 'property.bathroom_count', name: 'bathroom_count', description: 'Bathroom count (MISMO BathroomCount)', data_type: 'decimal', pii: 'NONE', is_key: false},
  {id: 'property.assessed_value_amount', name: 'assessed_value_amount', description: 'Assessed value for tax (MISMO PropertyAssessedValueAmount)', data_type: 'decimal', pii: 'NONE', is_key: false},
  {id: 'property.assessment_year', name: 'assessment_year', description: 'Tax assessment year (MISMO PropertyAssessmentYear)', data_type: 'integer', pii: 'NONE', is_key: false},
  {id: 'property.gross_living_area_square_feet', name: 'gross_living_area_square_feet', description: 'GLA (MISMO PropertyGrossLivingAreaSquareFeetCount)', data_type: 'integer', pii: 'NONE', is_key: false},
  {id: 'property.year_built', name: 'year_built_mismo', description: 'Year structure built (MISMO PropertyStructureBuiltYear)', data_type: 'integer', pii: 'NONE', is_key: false},
  {id: 'property.flood_zone_identifier', name: 'flood_zone_identifier', description: 'FEMA flood zone (MISMO FloodMapZoneIdentifier)', data_type: 'string', pii: 'NONE', is_key: false},
  {id: 'property.census_tract_identifier', name: 'census_tract_identifier', description: 'Census tract (MISMO CensusTractIdentifier)', data_type: 'string', pii: 'NONE', is_key: false},
  {id: 'property.msa_identifier', name: 'msa_identifier', description: 'MSA / MD code (MISMO MSAIdentifier)', data_type: 'string', pii: 'NONE', is_key: false}
] AS attr
MERGE (a:BusinessAttribute {id: attr.id})
ON CREATE SET a.name = attr.name, a.description = attr.description, a.data_type = attr.data_type, a.pii_classification = attr.pii, a.is_key = attr.is_key
MERGE (e)-[:HAS_ATTRIBUTE]->(a);

// --- Lender (extends migration 006) ---
MATCH (e:Entity {name: 'Lender'})
UNWIND [
  {id: 'lender.legal_entity_identifier', name: 'legal_entity_identifier', description: 'GLEIF LEI (MISMO LegalEntityIdentifier)', data_type: 'string', pii: 'NONE', is_key: false},
  {id: 'lender.nmls_identifier', name: 'nmls_identifier', description: 'NMLS company ID (MISMO NMLSIdentifier)', data_type: 'string', pii: 'NONE', is_key: false},
  {id: 'lender.charter_type', name: 'charter_type', description: 'National / State / Federal (MISMO LenderCharterType)', data_type: 'string', pii: 'NONE', is_key: false},
  {id: 'lender.regulator_type', name: 'regulator_type', description: 'Primary regulator (MISMO LenderRegulatorType)', data_type: 'string', pii: 'NONE', is_key: false},
  {id: 'lender.office_address', name: 'office_address', description: 'Headquarters address (MISMO OfficeAddress)', data_type: 'string', pii: 'NONE', is_key: false},
  {id: 'lender.office_state', name: 'office_state', description: 'Headquarters state (MISMO OfficeState)', data_type: 'string', pii: 'NONE', is_key: false}
] AS attr
MERGE (a:BusinessAttribute {id: attr.id})
ON CREATE SET a.name = attr.name, a.description = attr.description, a.data_type = attr.data_type, a.pii_classification = attr.pii, a.is_key = attr.is_key
MERGE (e)-[:HAS_ATTRIBUTE]->(a);

// --- Servicer (extends migration 006) ---
MATCH (e:Entity {name: 'Servicer'})
UNWIND [
  {id: 'servicer.servicer_loan_identifier', name: 'servicer_loan_identifier', description: 'Servicer-assigned loan number (MISMO ServicerLoanIdentifier)', data_type: 'string', pii: 'INTERNAL', is_key: false},
  {id: 'servicer.servicing_transfer_date', name: 'servicing_transfer_date', description: 'Date servicing transferred (MISMO ServicingTransferDate)', data_type: 'date', pii: 'NONE', is_key: false},
  {id: 'servicer.servicing_fee_percent', name: 'servicing_fee_percent', description: 'Servicing fee bps (MISMO ServicingFeePercent)', data_type: 'decimal', pii: 'NONE', is_key: false},
  {id: 'servicer.impound_account_type', name: 'impound_account_type', description: 'Escrow / no-escrow (MISMO ImpoundAccountType)', data_type: 'string', pii: 'NONE', is_key: false},
  {id: 'servicer.servicing_status', name: 'servicing_status', description: 'Active / Released / Released Servicing Retained (MISMO ServicingStatus)', data_type: 'string', pii: 'NONE', is_key: false}
] AS attr
MERGE (a:BusinessAttribute {id: attr.id})
ON CREATE SET a.name = attr.name, a.description = attr.description, a.data_type = attr.data_type, a.pii_classification = attr.pii, a.is_key = attr.is_key
MERGE (e)-[:HAS_ATTRIBUTE]->(a);

// --- Investor (extends migration 006) ---
MATCH (e:Entity {name: 'Investor'})
UNWIND [
  {id: 'investor.investor_loan_identifier', name: 'investor_loan_identifier', description: 'Investor-assigned loan number (MISMO InvestorLoanIdentifier)', data_type: 'string', pii: 'INTERNAL', is_key: false},
  {id: 'investor.commitment_identifier', name: 'commitment_identifier', description: 'Commitment contract id (MISMO InvestorCommitmentIdentifier)', data_type: 'string', pii: 'NONE', is_key: false},
  {id: 'investor.investor_remittance_type', name: 'investor_remittance_type', description: 'Remittance schedule (MISMO InvestorRemittanceType)', data_type: 'string', pii: 'NONE', is_key: false},
  {id: 'investor.pool_identifier', name: 'pool_identifier', description: 'Securitization pool ID (MISMO PoolIdentifier)', data_type: 'string', pii: 'NONE', is_key: false},
  {id: 'investor.security_balance_amount', name: 'security_balance_amount', description: 'Outstanding security balance (MISMO SecurityBalanceAmount)', data_type: 'decimal', pii: 'NONE', is_key: false},
  {id: 'investor.guarantee_fee_percent', name: 'guarantee_fee_percent', description: 'GSE guarantee fee (MISMO GuaranteeFeePercent)', data_type: 'decimal', pii: 'NONE', is_key: false}
] AS attr
MERGE (a:BusinessAttribute {id: attr.id})
ON CREATE SET a.name = attr.name, a.description = attr.description, a.data_type = attr.data_type, a.pii_classification = attr.pii, a.is_key = attr.is_key
MERGE (e)-[:HAS_ATTRIBUTE]->(a);

// --- LoanOfficer ---
MATCH (e:Entity {name: 'LoanOfficer'})
UNWIND [
  {id: 'loanofficer.officer_id', name: 'officer_id', description: 'Internal loan officer identifier', data_type: 'string', pii: 'INTERNAL', is_key: true},
  {id: 'loanofficer.name', name: 'name', description: 'Loan officer full name', data_type: 'string', pii: 'INTERNAL', is_key: false},
  {id: 'loanofficer.nmls_identifier', name: 'nmls_identifier', description: 'Originator NMLS ID (MISMO NMLSIdentifier)', data_type: 'string', pii: 'INTERNAL', is_key: false},
  {id: 'loanofficer.license_number', name: 'license_number', description: 'State license number (MISMO LicenseIdentifier)', data_type: 'string', pii: 'INTERNAL', is_key: false},
  {id: 'loanofficer.email', name: 'email', description: 'Officer contact email', data_type: 'string', pii: 'INTERNAL', is_key: false},
  {id: 'loanofficer.phone', name: 'phone', description: 'Officer contact phone', data_type: 'string', pii: 'INTERNAL', is_key: false},
  {id: 'loanofficer.originator_compensation_amount', name: 'originator_compensation_amount', description: 'Compensation amount (MISMO OriginatorCompensationAmount)', data_type: 'decimal', pii: 'INTERNAL', is_key: false},
  {id: 'loanofficer.originator_compensation_paid_by_type', name: 'originator_compensation_paid_by_type', description: 'Borrower / Lender (MISMO OriginatorCompensationPaidByType)', data_type: 'string', pii: 'NONE', is_key: false}
] AS attr
MERGE (a:BusinessAttribute {id: attr.id})
ON CREATE SET a.name = attr.name, a.description = attr.description, a.data_type = attr.data_type, a.pii_classification = attr.pii, a.is_key = attr.is_key
MERGE (e)-[:HAS_ATTRIBUTE]->(a);

// --- Employer ---
MATCH (e:Entity {name: 'Employer'})
UNWIND [
  {id: 'employer.employer_id', name: 'employer_id', description: 'Internal employer identifier', data_type: 'string', pii: 'INTERNAL', is_key: true},
  {id: 'employer.name', name: 'name', description: 'Employer legal name (MISMO EmployerName)', data_type: 'string', pii: 'INTERNAL', is_key: false},
  {id: 'employer.dba_name', name: 'dba_name', description: 'Doing-business-as name', data_type: 'string', pii: 'INTERNAL', is_key: false},
  {id: 'employer.address', name: 'address', description: 'Employer address line', data_type: 'string', pii: 'INTERNAL', is_key: false},
  {id: 'employer.city', name: 'city', description: 'Employer city', data_type: 'string', pii: 'INTERNAL', is_key: false},
  {id: 'employer.state', name: 'state', description: 'Employer state code', data_type: 'string', pii: 'INTERNAL', is_key: false},
  {id: 'employer.zip', name: 'zip', description: 'Employer zip code', data_type: 'string', pii: 'INTERNAL', is_key: false},
  {id: 'employer.phone', name: 'phone', description: 'Employer phone', data_type: 'string', pii: 'INTERNAL', is_key: false},
  {id: 'employer.industry_classification_code', name: 'industry_classification_code', description: 'NAICS / SIC code (MISMO EmployerIndustryClassificationCode)', data_type: 'string', pii: 'NONE', is_key: false}
] AS attr
MERGE (a:BusinessAttribute {id: attr.id})
ON CREATE SET a.name = attr.name, a.description = attr.description, a.data_type = attr.data_type, a.pii_classification = attr.pii, a.is_key = attr.is_key
MERGE (e)-[:HAS_ATTRIBUTE]->(a);

// --- Appraisal ---
MATCH (e:Entity {name: 'Appraisal'})
UNWIND [
  {id: 'appraisal.appraisal_id', name: 'appraisal_id', description: 'Internal appraisal identifier', data_type: 'string', pii: 'INTERNAL', is_key: true},
  {id: 'appraisal.appraisal_form_type', name: 'appraisal_form_type', description: 'URAR 1004 / Condo 1073 / Multi 1025 / etc (MISMO AppraisalFormType)', data_type: 'string', pii: 'NONE', is_key: false},
  {id: 'appraisal.appraisal_value_amount', name: 'appraisal_value_amount', description: 'Appraised value (MISMO AppraisedValueAmount)', data_type: 'decimal', pii: 'NONE', is_key: false},
  {id: 'appraisal.effective_date', name: 'effective_date', description: 'Appraisal effective date (MISMO AppraisalEffectiveDate)', data_type: 'date', pii: 'NONE', is_key: false},
  {id: 'appraisal.completed_date', name: 'completed_date', description: 'Date appraisal completed (MISMO AppraisalCompletedDate)', data_type: 'date', pii: 'NONE', is_key: false},
  {id: 'appraisal.appraiser_name', name: 'appraiser_name', description: 'Appraiser name (MISMO AppraiserName)', data_type: 'string', pii: 'INTERNAL', is_key: false},
  {id: 'appraisal.appraiser_license_identifier', name: 'appraiser_license_identifier', description: 'Appraiser license # (MISMO AppraiserLicenseIdentifier)', data_type: 'string', pii: 'INTERNAL', is_key: false},
  {id: 'appraisal.appraisal_method_type', name: 'appraisal_method_type', description: 'Sales comparison / Cost / Income (MISMO AppraisalMethodType)', data_type: 'string', pii: 'NONE', is_key: false},
  {id: 'appraisal.value_product_type', name: 'value_product_type', description: 'AVM / BPO / Full appraisal (MISMO ValueProductType)', data_type: 'string', pii: 'NONE', is_key: false}
] AS attr
MERGE (a:BusinessAttribute {id: attr.id})
ON CREATE SET a.name = attr.name, a.description = attr.description, a.data_type = attr.data_type, a.pii_classification = attr.pii, a.is_key = attr.is_key
MERGE (e)-[:HAS_ATTRIBUTE]->(a);

// --- Document (extends migration 006) ---
MATCH (e:Entity {name: 'Document'})
UNWIND [
  {id: 'document.document_class_type', name: 'document_class_type', description: 'Income / Asset / ID / Insurance (MISMO DocumentClassificationType)', data_type: 'string', pii: 'INTERNAL', is_key: false},
  {id: 'document.required_indicator', name: 'required_indicator', description: 'Required for funding (MISMO DocumentRequiredIndicator)', data_type: 'boolean', pii: 'NONE', is_key: false},
  {id: 'document.expiration_date', name: 'expiration_date', description: 'Document expiration (MISMO DocumentExpirationDate)', data_type: 'date', pii: 'INTERNAL', is_key: false},
  {id: 'document.received_date', name: 'received_date', description: 'Date document received (MISMO DocumentReceivedDate)', data_type: 'date', pii: 'INTERNAL', is_key: false},
  {id: 'document.upload_date', name: 'upload_date', description: 'Date uploaded to LOS (MISMO DocumentUploadDate)', data_type: 'date', pii: 'INTERNAL', is_key: false},
  {id: 'document.borrower_signed_date', name: 'borrower_signed_date', description: 'Borrower signature date (MISMO BorrowerSignedDate)', data_type: 'date', pii: 'INTERNAL', is_key: false},
  {id: 'document.lender_signed_date', name: 'lender_signed_date', description: 'Lender signature date (MISMO LenderSignedDate)', data_type: 'date', pii: 'INTERNAL', is_key: false},
  {id: 'document.notarized_indicator', name: 'notarized_indicator', description: 'Notarization required (MISMO NotarizedIndicator)', data_type: 'boolean', pii: 'NONE', is_key: false},
  {id: 'document.delivery_method_type', name: 'delivery_method_type', description: 'Email / Mail / E-sign (MISMO DocumentDeliveryMethodType)', data_type: 'string', pii: 'NONE', is_key: false},
  {id: 'document.status', name: 'status', description: 'Pending / Received / Cleared / Rejected (MISMO DocumentStatusType)', data_type: 'string', pii: 'INTERNAL', is_key: false}
] AS attr
MERGE (a:BusinessAttribute {id: attr.id})
ON CREATE SET a.name = attr.name, a.description = attr.description, a.data_type = attr.data_type, a.pii_classification = attr.pii, a.is_key = attr.is_key
MERGE (e)-[:HAS_ATTRIBUTE]->(a);

// --- Fee (extends migration 006) ---
MATCH (e:Entity {name: 'Fee'})
UNWIND [
  {id: 'fee.fee_paid_by_type', name: 'fee_paid_by_type', description: 'Borrower / Seller / Lender / Other (MISMO FeePaidByType)', data_type: 'string', pii: 'NONE', is_key: false},
  {id: 'fee.fee_paid_to_type', name: 'fee_paid_to_type', description: 'Lender / Broker / 3rd-party (MISMO FeePaidToType)', data_type: 'string', pii: 'NONE', is_key: false},
  {id: 'fee.fee_payment_paid_outside_closing_indicator', name: 'fee_payment_paid_outside_closing_indicator', description: 'POC flag (MISMO FeePaymentPaidOutsideClosingIndicator)', data_type: 'boolean', pii: 'NONE', is_key: false},
  {id: 'fee.fee_process_timing_type', name: 'fee_process_timing_type', description: 'At Closing / POC / Application (MISMO FeeProcessTimingType)', data_type: 'string', pii: 'NONE', is_key: false},
  {id: 'fee.integrated_disclosure_section_type', name: 'integrated_disclosure_section_type', description: 'LE/CD section A/B/C/E/F/G/H (MISMO IntegratedDisclosureSectionType)', data_type: 'string', pii: 'NONE', is_key: false},
  {id: 'fee.regulation_z_points_and_fees_indicator', name: 'regulation_z_points_and_fees_indicator', description: 'Counts toward QM points-and-fees (MISMO RegulationZPointsAndFeesIndicator)', data_type: 'boolean', pii: 'NONE', is_key: false},
  {id: 'fee.fee_percent_basis_type', name: 'fee_percent_basis_type', description: 'Loan amount / property value basis (MISMO FeePercentBasisType)', data_type: 'string', pii: 'NONE', is_key: false},
  {id: 'fee.fee_collected_date', name: 'fee_collected_date', description: 'Date fee collected', data_type: 'date', pii: 'NONE', is_key: false}
] AS attr
MERGE (a:BusinessAttribute {id: attr.id})
ON CREATE SET a.name = attr.name, a.description = attr.description, a.data_type = attr.data_type, a.pii_classification = attr.pii, a.is_key = attr.is_key
MERGE (e)-[:HAS_ATTRIBUTE]->(a);

// --- Payment (extends migration 006) ---
MATCH (e:Entity {name: 'Payment'})
UNWIND [
  {id: 'payment.payment_id', name: 'payment_id', description: 'Internal payment identifier', data_type: 'string', pii: 'INTERNAL', is_key: true},
  {id: 'payment.payment_amount', name: 'payment_amount', description: 'Total payment received (MISMO PaymentAmount)', data_type: 'decimal', pii: 'INTERNAL', is_key: false},
  {id: 'payment.payment_due_date', name: 'payment_due_date', description: 'Payment due date (MISMO PaymentDueDate)', data_type: 'date', pii: 'NONE', is_key: false},
  {id: 'payment.payment_received_date', name: 'payment_received_date', description: 'Payment received date (MISMO PaymentReceivedDate)', data_type: 'date', pii: 'NONE', is_key: false},
  {id: 'payment.principal_amount', name: 'principal_amount', description: 'Principal portion (MISMO PrincipalAmount)', data_type: 'decimal', pii: 'INTERNAL', is_key: false},
  {id: 'payment.interest_amount', name: 'interest_amount', description: 'Interest portion (MISMO InterestAmount)', data_type: 'decimal', pii: 'INTERNAL', is_key: false},
  {id: 'payment.escrow_amount', name: 'escrow_amount', description: 'Escrow portion (MISMO EscrowAmount)', data_type: 'decimal', pii: 'INTERNAL', is_key: false},
  {id: 'payment.late_fee_amount', name: 'late_fee_amount', description: 'Late charges (MISMO LateChargeAmount)', data_type: 'decimal', pii: 'INTERNAL', is_key: false},
  {id: 'payment.payment_status_type', name: 'payment_status_type', description: 'On time / Late / NSF (MISMO PaymentStatusType)', data_type: 'string', pii: 'INTERNAL', is_key: false}
] AS attr
MERGE (a:BusinessAttribute {id: attr.id})
ON CREATE SET a.name = attr.name, a.description = attr.description, a.data_type = attr.data_type, a.pii_classification = attr.pii, a.is_key = attr.is_key
MERGE (e)-[:HAS_ATTRIBUTE]->(a);

// ===============================================================
// 3. New entities — attribute seed
// ===============================================================

// --- Income ---
MATCH (e:Entity {name: 'Income'})
UNWIND [
  {id: 'income.income_id', name: 'income_id', description: 'Internal income record id', data_type: 'string', pii: 'INTERNAL', is_key: true},
  {id: 'income.income_type', name: 'income_type', description: 'Base / Bonus / Commission / Overtime / SelfEmployed / Investment / Rental / Pension / SocialSecurity / Other (MISMO IncomeType)', data_type: 'string', pii: 'INTERNAL', is_key: false},
  {id: 'income.monthly_total_amount', name: 'monthly_total_amount', description: 'Monthly amount (MISMO MonthlyTotalAmount)', data_type: 'decimal', pii: 'INTERNAL', is_key: false},
  {id: 'income.annual_total_amount', name: 'annual_total_amount', description: 'Annualized amount (MISMO AnnualTotalAmount)', data_type: 'decimal', pii: 'INTERNAL', is_key: false},
  {id: 'income.income_period_type', name: 'income_period_type', description: 'Annual / Monthly / Hourly (MISMO IncomePeriodType)', data_type: 'string', pii: 'INTERNAL', is_key: false},
  {id: 'income.employment_classification_type', name: 'employment_classification_type', description: 'Primary / Secondary / Tertiary (MISMO EmploymentClassificationType)', data_type: 'string', pii: 'INTERNAL', is_key: false},
  {id: 'income.self_employed_indicator', name: 'self_employed_indicator', description: 'Self-employed flag (MISMO SelfEmployedIndicator)', data_type: 'boolean', pii: 'INTERNAL', is_key: false},
  {id: 'income.declining_indicator', name: 'declining_indicator', description: 'Declining income flag', data_type: 'boolean', pii: 'INTERNAL', is_key: false},
  {id: 'income.income_starting_date', name: 'income_starting_date', description: 'Date income started (MISMO IncomeStartingDate)', data_type: 'date', pii: 'INTERNAL', is_key: false},
  {id: 'income.income_ending_date', name: 'income_ending_date', description: 'Date income ended (MISMO IncomeEndingDate)', data_type: 'date', pii: 'INTERNAL', is_key: false},
  {id: 'income.verification_status_type', name: 'verification_status_type', description: 'Verified / Unverified / Pending (MISMO VerificationStatusType)', data_type: 'string', pii: 'INTERNAL', is_key: false},
  {id: 'income.verification_date', name: 'verification_date', description: 'Date verified', data_type: 'date', pii: 'INTERNAL', is_key: false},
  {id: 'income.borrower_id', name: 'borrower_id', description: 'FK to borrower', data_type: 'string', pii: 'INTERNAL', is_key: false},
  {id: 'income.employer_id', name: 'employer_id', description: 'FK to employer', data_type: 'string', pii: 'INTERNAL', is_key: false}
] AS attr
MERGE (a:BusinessAttribute {id: attr.id})
ON CREATE SET a.name = attr.name, a.description = attr.description, a.data_type = attr.data_type, a.pii_classification = attr.pii, a.is_key = attr.is_key
MERGE (e)-[:HAS_ATTRIBUTE]->(a);

// --- Asset ---
MATCH (e:Entity {name: 'Asset'})
UNWIND [
  {id: 'asset.asset_id', name: 'asset_id', description: 'Internal asset record id', data_type: 'string', pii: 'INTERNAL', is_key: true},
  {id: 'asset.asset_type', name: 'asset_type', description: 'Checking / Savings / MutualFund / Retirement / Stock / Bond / RealEstate / Gift / Other (MISMO AssetType)', data_type: 'string', pii: 'INTERNAL', is_key: false},
  {id: 'asset.account_identifier', name: 'account_identifier', description: 'Account number (MISMO AccountIdentifier)', data_type: 'string', pii: 'RESTRICTED', is_key: false},
  {id: 'asset.account_holder_name', name: 'account_holder_name', description: 'Account holder name (MISMO AccountHolderName)', data_type: 'string', pii: 'RESTRICTED', is_key: false},
  {id: 'asset.cash_or_market_value_amount', name: 'cash_or_market_value_amount', description: 'Current value (MISMO AssetCashOrMarketValueAmount)', data_type: 'decimal', pii: 'INTERNAL', is_key: false},
  {id: 'asset.account_balance_amount', name: 'account_balance_amount', description: 'Account balance (MISMO AccountBalanceAmount)', data_type: 'decimal', pii: 'INTERNAL', is_key: false},
  {id: 'asset.depository_institution_name', name: 'depository_institution_name', description: 'Bank / brokerage name (MISMO DepositoryInstitutionName)', data_type: 'string', pii: 'INTERNAL', is_key: false},
  {id: 'asset.gift_indicator', name: 'gift_indicator', description: 'Asset is a gift (MISMO GiftIndicator)', data_type: 'boolean', pii: 'INTERNAL', is_key: false},
  {id: 'asset.gift_source_type', name: 'gift_source_type', description: 'Relative / Employer / Other (MISMO GiftFundsSourceType)', data_type: 'string', pii: 'INTERNAL', is_key: false},
  {id: 'asset.pledged_indicator', name: 'pledged_indicator', description: 'Asset pledged (MISMO PledgedAssetIndicator)', data_type: 'boolean', pii: 'INTERNAL', is_key: false},
  {id: 'asset.verification_status_type', name: 'verification_status_type', description: 'Verified / Unverified / Pending (MISMO VerificationStatusType)', data_type: 'string', pii: 'INTERNAL', is_key: false},
  {id: 'asset.verification_date', name: 'verification_date', description: 'Date verified', data_type: 'date', pii: 'INTERNAL', is_key: false},
  {id: 'asset.borrower_id', name: 'borrower_id', description: 'FK to borrower', data_type: 'string', pii: 'INTERNAL', is_key: false}
] AS attr
MERGE (a:BusinessAttribute {id: attr.id})
ON CREATE SET a.name = attr.name, a.description = attr.description, a.data_type = attr.data_type, a.pii_classification = attr.pii, a.is_key = attr.is_key
MERGE (e)-[:HAS_ATTRIBUTE]->(a);

// --- Liability ---
MATCH (e:Entity {name: 'Liability'})
UNWIND [
  {id: 'liability.liability_id', name: 'liability_id', description: 'Internal liability record id', data_type: 'string', pii: 'INTERNAL', is_key: true},
  {id: 'liability.liability_type', name: 'liability_type', description: 'Mortgage / CreditCard / AutoLoan / StudentLoan / Alimony / ChildSupport / Other (MISMO LiabilityType)', data_type: 'string', pii: 'INTERNAL', is_key: false},
  {id: 'liability.creditor_name', name: 'creditor_name', description: 'Creditor name (MISMO CreditorName)', data_type: 'string', pii: 'INTERNAL', is_key: false},
  {id: 'liability.account_identifier', name: 'account_identifier', description: 'Account number (MISMO AccountIdentifier)', data_type: 'string', pii: 'RESTRICTED', is_key: false},
  {id: 'liability.unpaid_balance_amount', name: 'unpaid_balance_amount', description: 'Unpaid balance (MISMO LiabilityUnpaidBalanceAmount)', data_type: 'decimal', pii: 'INTERNAL', is_key: false},
  {id: 'liability.monthly_payment_amount', name: 'monthly_payment_amount', description: 'Monthly payment (MISMO LiabilityMonthlyPaymentAmount)', data_type: 'decimal', pii: 'INTERNAL', is_key: false},
  {id: 'liability.remaining_term_months_count', name: 'remaining_term_months_count', description: 'Months remaining (MISMO RemainingTermMonthsCount)', data_type: 'integer', pii: 'INTERNAL', is_key: false},
  {id: 'liability.payoff_status_indicator', name: 'payoff_status_indicator', description: 'Will be paid off at closing (MISMO LiabilityPayoffStatusIndicator)', data_type: 'boolean', pii: 'INTERNAL', is_key: false},
  {id: 'liability.exclusion_from_dti_indicator', name: 'exclusion_from_dti_indicator', description: 'Excluded from DTI (MISMO LiabilityExclusionIndicator)', data_type: 'boolean', pii: 'NONE', is_key: false},
  {id: 'liability.subject_property_indicator', name: 'subject_property_indicator', description: 'Liability secured by subject property (MISMO SubjectLoanResubordinationIndicator)', data_type: 'boolean', pii: 'NONE', is_key: false},
  {id: 'liability.borrower_id', name: 'borrower_id', description: 'FK to borrower', data_type: 'string', pii: 'INTERNAL', is_key: false}
] AS attr
MERGE (a:BusinessAttribute {id: attr.id})
ON CREATE SET a.name = attr.name, a.description = attr.description, a.data_type = attr.data_type, a.pii_classification = attr.pii, a.is_key = attr.is_key
MERGE (e)-[:HAS_ATTRIBUTE]->(a);

// --- CreditReport ---
MATCH (e:Entity {name: 'CreditReport'})
UNWIND [
  {id: 'creditreport.credit_report_id', name: 'credit_report_id', description: 'Internal credit report id', data_type: 'string', pii: 'INTERNAL', is_key: true},
  {id: 'creditreport.credit_report_request_date', name: 'credit_report_request_date', description: 'Date report pulled (MISMO CreditReportRequestDate)', data_type: 'date', pii: 'INTERNAL', is_key: false},
  {id: 'creditreport.credit_score_value', name: 'credit_score_value', description: 'Credit score (MISMO CreditScoreValue)', data_type: 'integer', pii: 'INTERNAL', is_key: false},
  {id: 'creditreport.credit_score_source_type', name: 'credit_score_source_type', description: 'Equifax / Experian / TransUnion (MISMO CreditScoreSourceType)', data_type: 'string', pii: 'INTERNAL', is_key: false},
  {id: 'creditreport.credit_score_model_name_type', name: 'credit_score_model_name_type', description: 'FICO 8 / Vantage / Beacon (MISMO CreditScoreModelNameType)', data_type: 'string', pii: 'INTERNAL', is_key: false},
  {id: 'creditreport.credit_score_factor_text', name: 'credit_score_factor_text', description: 'Top reason codes (MISMO CreditScoreFactorText)', data_type: 'string', pii: 'INTERNAL', is_key: false},
  {id: 'creditreport.credit_inquiry_count', name: 'credit_inquiry_count', description: 'Recent inquiry count (MISMO CreditInquiryCount)', data_type: 'integer', pii: 'INTERNAL', is_key: false},
  {id: 'creditreport.public_record_count', name: 'public_record_count', description: 'Public records count (MISMO PublicRecordCount)', data_type: 'integer', pii: 'INTERNAL', is_key: false},
  {id: 'creditreport.collection_count', name: 'collection_count', description: 'Collections account count (MISMO CollectionCount)', data_type: 'integer', pii: 'INTERNAL', is_key: false},
  {id: 'creditreport.borrower_id', name: 'borrower_id', description: 'FK to borrower', data_type: 'string', pii: 'INTERNAL', is_key: false}
] AS attr
MERGE (a:BusinessAttribute {id: attr.id})
ON CREATE SET a.name = attr.name, a.description = attr.description, a.data_type = attr.data_type, a.pii_classification = attr.pii, a.is_key = attr.is_key
MERGE (e)-[:HAS_ATTRIBUTE]->(a);

// --- Insurance ---
MATCH (e:Entity {name: 'Insurance'})
UNWIND [
  {id: 'insurance.insurance_id', name: 'insurance_id', description: 'Internal policy id', data_type: 'string', pii: 'INTERNAL', is_key: true},
  {id: 'insurance.insurance_policy_type', name: 'insurance_policy_type', description: 'Hazard / Flood / Earthquake / Mortgage / Title / Other (MISMO InsurancePolicyType)', data_type: 'string', pii: 'NONE', is_key: false},
  {id: 'insurance.policy_identifier', name: 'policy_identifier', description: 'Policy number (MISMO PolicyIdentifier)', data_type: 'string', pii: 'INTERNAL', is_key: false},
  {id: 'insurance.carrier_name', name: 'carrier_name', description: 'Carrier name (MISMO InsuranceCarrierName)', data_type: 'string', pii: 'NONE', is_key: false},
  {id: 'insurance.coverage_amount', name: 'coverage_amount', description: 'Coverage amount (MISMO InsuranceCoverageAmount)', data_type: 'decimal', pii: 'NONE', is_key: false},
  {id: 'insurance.premium_amount', name: 'premium_amount', description: 'Premium amount (MISMO InsurancePremiumAmount)', data_type: 'decimal', pii: 'NONE', is_key: false},
  {id: 'insurance.deductible_amount', name: 'deductible_amount', description: 'Deductible (MISMO InsuranceDeductibleAmount)', data_type: 'decimal', pii: 'NONE', is_key: false},
  {id: 'insurance.effective_date', name: 'effective_date', description: 'Coverage effective date (MISMO InsuranceEffectiveDate)', data_type: 'date', pii: 'NONE', is_key: false},
  {id: 'insurance.expiration_date', name: 'expiration_date', description: 'Coverage expiration date (MISMO InsuranceExpirationDate)', data_type: 'date', pii: 'NONE', is_key: false},
  {id: 'insurance.payment_frequency_type', name: 'payment_frequency_type', description: 'Annual / Monthly / Single (MISMO PaymentFrequencyType)', data_type: 'string', pii: 'NONE', is_key: false},
  {id: 'insurance.mortgagee_clause_indicator', name: 'mortgagee_clause_indicator', description: 'Lender named as mortgagee (MISMO MortgageeClauseIndicator)', data_type: 'boolean', pii: 'NONE', is_key: false},
  {id: 'insurance.loan_id', name: 'loan_id', description: 'FK to loan', data_type: 'string', pii: 'INTERNAL', is_key: false}
] AS attr
MERGE (a:BusinessAttribute {id: attr.id})
ON CREATE SET a.name = attr.name, a.description = attr.description, a.data_type = attr.data_type, a.pii_classification = attr.pii, a.is_key = attr.is_key
MERGE (e)-[:HAS_ATTRIBUTE]->(a);

// --- Escrow ---
MATCH (e:Entity {name: 'Escrow'})
UNWIND [
  {id: 'escrow.escrow_id', name: 'escrow_id', description: 'Internal escrow line id', data_type: 'string', pii: 'INTERNAL', is_key: true},
  {id: 'escrow.escrow_item_type', name: 'escrow_item_type', description: 'PropertyTax / HazardInsurance / FloodInsurance / MortgageInsurance / EarthquakeInsurance / Other (MISMO EscrowItemType)', data_type: 'string', pii: 'NONE', is_key: false},
  {id: 'escrow.escrow_monthly_payment_amount', name: 'escrow_monthly_payment_amount', description: 'Monthly escrow payment (MISMO EscrowMonthlyPaymentAmount)', data_type: 'decimal', pii: 'NONE', is_key: false},
  {id: 'escrow.escrow_aggregate_adjustment_amount', name: 'escrow_aggregate_adjustment_amount', description: 'Aggregate adjustment (MISMO EscrowAggregateAdjustmentAmount)', data_type: 'decimal', pii: 'NONE', is_key: false},
  {id: 'escrow.escrow_initial_balance_amount', name: 'escrow_initial_balance_amount', description: 'Initial balance (MISMO EscrowInitialBalanceAmount)', data_type: 'decimal', pii: 'NONE', is_key: false},
  {id: 'escrow.payee_name', name: 'payee_name', description: 'Payee name (MISMO PayeeName)', data_type: 'string', pii: 'NONE', is_key: false},
  {id: 'escrow.payment_due_date', name: 'payment_due_date', description: 'Disbursement due date', data_type: 'date', pii: 'NONE', is_key: false},
  {id: 'escrow.loan_id', name: 'loan_id', description: 'FK to loan', data_type: 'string', pii: 'INTERNAL', is_key: false}
] AS attr
MERGE (a:BusinessAttribute {id: attr.id})
ON CREATE SET a.name = attr.name, a.description = attr.description, a.data_type = attr.data_type, a.pii_classification = attr.pii, a.is_key = attr.is_key
MERGE (e)-[:HAS_ATTRIBUTE]->(a);

// --- Underwriting ---
MATCH (e:Entity {name: 'Underwriting'})
UNWIND [
  {id: 'underwriting.underwriting_id', name: 'underwriting_id', description: 'Internal underwriting decision id', data_type: 'string', pii: 'INTERNAL', is_key: true},
  {id: 'underwriting.decision_date', name: 'decision_date', description: 'Underwriting decision date (MISMO UnderwritingDecisionDate)', data_type: 'date', pii: 'NONE', is_key: false},
  {id: 'underwriting.decision_type', name: 'decision_type', description: 'Approved / Approved With Conditions / Denied / Withdrawn (MISMO UnderwritingDecisionType)', data_type: 'string', pii: 'NONE', is_key: false},
  {id: 'underwriting.underwriter_name', name: 'underwriter_name', description: 'Underwriter name (MISMO UnderwriterName)', data_type: 'string', pii: 'INTERNAL', is_key: false},
  {id: 'underwriting.automated_system_type', name: 'automated_system_type', description: 'DU / LP / Other (MISMO AutomatedUnderwritingSystemType)', data_type: 'string', pii: 'NONE', is_key: false},
  {id: 'underwriting.automated_recommendation_type', name: 'automated_recommendation_type', description: 'Approve/Eligible / Refer / Refer With Caution (MISMO AutomatedUnderwritingRecommendationType)', data_type: 'string', pii: 'NONE', is_key: false},
  {id: 'underwriting.automated_decision_text', name: 'automated_decision_text', description: 'Free text from AUS (MISMO AutomatedUnderwritingDecisionText)', data_type: 'string', pii: 'NONE', is_key: false},
  {id: 'underwriting.manual_underwriting_indicator', name: 'manual_underwriting_indicator', description: 'Manual UW required (MISMO ManualUnderwritingIndicator)', data_type: 'boolean', pii: 'NONE', is_key: false},
  {id: 'underwriting.documentation_level_type', name: 'documentation_level_type', description: 'Full / Reduced / Streamlined (MISMO DocumentationLevelType)', data_type: 'string', pii: 'NONE', is_key: false},
  {id: 'underwriting.loan_id', name: 'loan_id', description: 'FK to loan', data_type: 'string', pii: 'INTERNAL', is_key: false}
] AS attr
MERGE (a:BusinessAttribute {id: attr.id})
ON CREATE SET a.name = attr.name, a.description = attr.description, a.data_type = attr.data_type, a.pii_classification = attr.pii, a.is_key = attr.is_key
MERGE (e)-[:HAS_ATTRIBUTE]->(a);

// --- ClosingDisclosure ---
MATCH (e:Entity {name: 'ClosingDisclosure'})
UNWIND [
  {id: 'closingdisclosure.cd_id', name: 'cd_id', description: 'Internal closing disclosure id', data_type: 'string', pii: 'INTERNAL', is_key: true},
  {id: 'closingdisclosure.cd_received_date', name: 'cd_received_date', description: 'Borrower received CD date (MISMO ClosingDisclosureReceivedDate)', data_type: 'date', pii: 'NONE', is_key: false},
  {id: 'closingdisclosure.closing_date', name: 'closing_date', description: 'Closing date (MISMO ClosingDate)', data_type: 'date', pii: 'NONE', is_key: false},
  {id: 'closingdisclosure.disbursement_date', name: 'disbursement_date', description: 'Disbursement date (MISMO DisbursementDate)', data_type: 'date', pii: 'NONE', is_key: false},
  {id: 'closingdisclosure.total_closing_costs_amount', name: 'total_closing_costs_amount', description: 'Total closing costs (MISMO TotalClosingCostsAmount)', data_type: 'decimal', pii: 'NONE', is_key: false},
  {id: 'closingdisclosure.total_loan_costs_amount', name: 'total_loan_costs_amount', description: 'Total loan costs A+B+C (MISMO TotalLoanCostsAmount)', data_type: 'decimal', pii: 'NONE', is_key: false},
  {id: 'closingdisclosure.total_other_costs_amount', name: 'total_other_costs_amount', description: 'Total other costs E+F+G+H (MISMO TotalOtherCostsAmount)', data_type: 'decimal', pii: 'NONE', is_key: false},
  {id: 'closingdisclosure.cash_to_close_amount', name: 'cash_to_close_amount', description: 'Cash from / to borrower (MISMO CashFromBorrowerAtClosingAmount)', data_type: 'decimal', pii: 'NONE', is_key: false},
  {id: 'closingdisclosure.prepaid_amount', name: 'prepaid_amount', description: 'Prepaid items total (MISMO PrepaidItemAmount)', data_type: 'decimal', pii: 'NONE', is_key: false},
  {id: 'closingdisclosure.total_initial_escrow_amount', name: 'total_initial_escrow_amount', description: 'Initial escrow at closing (MISMO TotalInitialEscrowAmount)', data_type: 'decimal', pii: 'NONE', is_key: false},
  {id: 'closingdisclosure.finance_charge_amount', name: 'finance_charge_amount', description: 'TILA finance charge (MISMO FinanceChargeAmount)', data_type: 'decimal', pii: 'NONE', is_key: false},
  {id: 'closingdisclosure.amount_financed_amount', name: 'amount_financed_amount', description: 'TILA amount financed (MISMO AmountFinancedAmount)', data_type: 'decimal', pii: 'NONE', is_key: false},
  {id: 'closingdisclosure.annual_percentage_rate', name: 'annual_percentage_rate', description: 'TILA APR (MISMO AnnualPercentageRatePercent)', data_type: 'decimal', pii: 'NONE', is_key: false},
  {id: 'closingdisclosure.loan_id', name: 'loan_id', description: 'FK to loan', data_type: 'string', pii: 'INTERNAL', is_key: false}
] AS attr
MERGE (a:BusinessAttribute {id: attr.id})
ON CREATE SET a.name = attr.name, a.description = attr.description, a.data_type = attr.data_type, a.pii_classification = attr.pii, a.is_key = attr.is_key
MERGE (e)-[:HAS_ATTRIBUTE]->(a);

// --- Title ---
MATCH (e:Entity {name: 'Title'})
UNWIND [
  {id: 'title.title_id', name: 'title_id', description: 'Internal title record id', data_type: 'string', pii: 'INTERNAL', is_key: true},
  {id: 'title.title_company_name', name: 'title_company_name', description: 'Title company (MISMO TitleCompanyName)', data_type: 'string', pii: 'NONE', is_key: false},
  {id: 'title.title_insurance_type', name: 'title_insurance_type', description: 'Owners / Lenders / Both (MISMO TitleInsuranceType)', data_type: 'string', pii: 'NONE', is_key: false},
  {id: 'title.policy_amount', name: 'policy_amount', description: 'Policy coverage (MISMO TitlePolicyAmount)', data_type: 'decimal', pii: 'NONE', is_key: false},
  {id: 'title.premium_amount', name: 'premium_amount', description: 'Title premium (MISMO TitlePremiumAmount)', data_type: 'decimal', pii: 'NONE', is_key: false},
  {id: 'title.effective_date', name: 'effective_date', description: 'Title effective date (MISMO TitleInsuranceEffectiveDate)', data_type: 'date', pii: 'NONE', is_key: false},
  {id: 'title.title_search_completed_date', name: 'title_search_completed_date', description: 'Title search completed (MISMO TitleSearchCompletedDate)', data_type: 'date', pii: 'NONE', is_key: false},
  {id: 'title.exception_count', name: 'exception_count', description: 'Number of title exceptions', data_type: 'integer', pii: 'NONE', is_key: false},
  {id: 'title.loan_id', name: 'loan_id', description: 'FK to loan', data_type: 'string', pii: 'INTERNAL', is_key: false}
] AS attr
MERGE (a:BusinessAttribute {id: attr.id})
ON CREATE SET a.name = attr.name, a.description = attr.description, a.data_type = attr.data_type, a.pii_classification = attr.pii, a.is_key = attr.is_key
MERGE (e)-[:HAS_ATTRIBUTE]->(a);

// --- HMDARecord ---
MATCH (e:Entity {name: 'HMDARecord'})
UNWIND [
  {id: 'hmdarecord.hmda_id', name: 'hmda_id', description: 'Internal HMDA record id', data_type: 'string', pii: 'INTERNAL', is_key: true},
  {id: 'hmdarecord.application_date', name: 'application_date', description: 'Application date for HMDA reporting (MISMO ApplicationReceivedDate)', data_type: 'date', pii: 'NONE', is_key: false},
  {id: 'hmdarecord.hmda_loan_type', name: 'hmda_loan_type', description: 'Conventional / FHA / VA / FSA-RHS (MISMO HMDALoanType)', data_type: 'string', pii: 'NONE', is_key: false},
  {id: 'hmdarecord.hmda_loan_purpose_type', name: 'hmda_loan_purpose_type', description: 'Purchase / Refi / HomeImprovement / Other (MISMO HMDALoanPurposeType)', data_type: 'string', pii: 'NONE', is_key: false},
  {id: 'hmdarecord.action_taken_type', name: 'action_taken_type', description: 'Originated / Approved Not Accepted / Denied / Withdrawn / Closed Incomplete / Purchased / Preapproval Denied / Preapproval Approved Not Accepted (MISMO HMDAActionTakenType)', data_type: 'string', pii: 'NONE', is_key: false},
  {id: 'hmdarecord.action_taken_date', name: 'action_taken_date', description: 'Action taken date (MISMO HMDAActionTakenDate)', data_type: 'date', pii: 'NONE', is_key: false},
  {id: 'hmdarecord.preapproval_type', name: 'preapproval_type', description: 'Requested / Not Requested / Not Applicable (MISMO HMDAPreapprovalType)', data_type: 'string', pii: 'NONE', is_key: false},
  {id: 'hmdarecord.lien_status_type', name: 'lien_status_type', description: 'First / Subordinate / Not Secured (MISMO HMDALienStatusType)', data_type: 'string', pii: 'NONE', is_key: false},
  {id: 'hmdarecord.ethnicity_type', name: 'ethnicity_type', description: 'HMDA ethnicity (MISMO HMDAEthnicityType)', data_type: 'string', pii: 'INTERNAL', is_key: false},
  {id: 'hmdarecord.race_type', name: 'race_type', description: 'HMDA race (MISMO HMDARaceType)', data_type: 'string', pii: 'INTERNAL', is_key: false},
  {id: 'hmdarecord.sex_type', name: 'sex_type', description: 'HMDA sex (MISMO HMDASexType)', data_type: 'string', pii: 'INTERNAL', is_key: false},
  {id: 'hmdarecord.reasons_for_denial_type', name: 'reasons_for_denial_type', description: 'Denial reason codes (MISMO HMDAReasonsForDenialType)', data_type: 'string', pii: 'INTERNAL', is_key: false},
  {id: 'hmdarecord.hoepa_loan_status_indicator', name: 'hoepa_loan_status_indicator', description: 'HOEPA covered (MISMO HMDAHOEPALoanStatusIndicator)', data_type: 'boolean', pii: 'NONE', is_key: false},
  {id: 'hmdarecord.loan_id', name: 'loan_id', description: 'FK to loan', data_type: 'string', pii: 'INTERNAL', is_key: false}
] AS attr
MERGE (a:BusinessAttribute {id: attr.id})
ON CREATE SET a.name = attr.name, a.description = attr.description, a.data_type = attr.data_type, a.pii_classification = attr.pii, a.is_key = attr.is_key
MERGE (e)-[:HAS_ATTRIBUTE]->(a);

// --- LoanProduct ---
MATCH (e:Entity {name: 'LoanProduct'})
UNWIND [
  {id: 'loanproduct.product_id', name: 'product_id', description: 'Internal product id', data_type: 'string', pii: 'NONE', is_key: true},
  {id: 'loanproduct.product_name', name: 'product_name', description: 'Product display name', data_type: 'string', pii: 'NONE', is_key: false},
  {id: 'loanproduct.product_description', name: 'product_description', description: 'Product description', data_type: 'string', pii: 'NONE', is_key: false},
  {id: 'loanproduct.product_type', name: 'product_type', description: 'Conventional / FHA / VA / Jumbo / NonQM (MISMO ProductType)', data_type: 'string', pii: 'NONE', is_key: false},
  {id: 'loanproduct.amortization_type', name: 'amortization_type', description: 'Fixed / ARM / Hybrid (MISMO AmortizationType)', data_type: 'string', pii: 'NONE', is_key: false},
  {id: 'loanproduct.conformance_indicator', name: 'conformance_indicator', description: 'Conforming Y/N', data_type: 'boolean', pii: 'NONE', is_key: false},
  {id: 'loanproduct.jumbo_indicator', name: 'jumbo_indicator', description: 'Jumbo Y/N', data_type: 'boolean', pii: 'NONE', is_key: false},
  {id: 'loanproduct.max_loan_amount', name: 'max_loan_amount', description: 'Product max loan amount', data_type: 'decimal', pii: 'NONE', is_key: false},
  {id: 'loanproduct.min_loan_amount', name: 'min_loan_amount', description: 'Product min loan amount', data_type: 'decimal', pii: 'NONE', is_key: false},
  {id: 'loanproduct.max_ltv_ratio', name: 'max_ltv_ratio', description: 'Max allowed LTV', data_type: 'decimal', pii: 'NONE', is_key: false},
  {id: 'loanproduct.max_dti_ratio', name: 'max_dti_ratio', description: 'Max allowed DTI', data_type: 'decimal', pii: 'NONE', is_key: false},
  {id: 'loanproduct.min_credit_score', name: 'min_credit_score', description: 'Min credit score required', data_type: 'integer', pii: 'NONE', is_key: false},
  {id: 'loanproduct.allowed_term_months', name: 'allowed_term_months', description: 'Allowed term lengths in months (e.g. 360,240,180)', data_type: 'string', pii: 'NONE', is_key: false}
] AS attr
MERGE (a:BusinessAttribute {id: attr.id})
ON CREATE SET a.name = attr.name, a.description = attr.description, a.data_type = attr.data_type, a.pii_classification = attr.pii, a.is_key = attr.is_key
MERGE (e)-[:HAS_ATTRIBUTE]->(a);

// --- LoanCondition ---
MATCH (e:Entity {name: 'LoanCondition'})
UNWIND [
  {id: 'loancondition.condition_id', name: 'condition_id', description: 'Internal condition id', data_type: 'string', pii: 'INTERNAL', is_key: true},
  {id: 'loancondition.condition_type', name: 'condition_type', description: 'PriorToDocs / PriorToFunding / AtClosing / PostClosing (MISMO ConditionType)', data_type: 'string', pii: 'NONE', is_key: false},
  {id: 'loancondition.condition_status', name: 'condition_status', description: 'Open / Cleared / Waived (MISMO ConditionStatusType)', data_type: 'string', pii: 'NONE', is_key: false},
  {id: 'loancondition.condition_description', name: 'condition_description', description: 'Free-form condition text', data_type: 'string', pii: 'NONE', is_key: false},
  {id: 'loancondition.condition_due_date', name: 'condition_due_date', description: 'Due date', data_type: 'date', pii: 'NONE', is_key: false},
  {id: 'loancondition.condition_satisfied_date', name: 'condition_satisfied_date', description: 'Date cleared', data_type: 'date', pii: 'NONE', is_key: false},
  {id: 'loancondition.required_for_funding_indicator', name: 'required_for_funding_indicator', description: 'Required to fund (MISMO RequiredForFundingIndicator)', data_type: 'boolean', pii: 'NONE', is_key: false},
  {id: 'loancondition.party_responsible_type', name: 'party_responsible_type', description: 'Borrower / Lender / 3rd-Party (MISMO ResponsiblePartyType)', data_type: 'string', pii: 'NONE', is_key: false},
  {id: 'loancondition.loan_id', name: 'loan_id', description: 'FK to loan', data_type: 'string', pii: 'INTERNAL', is_key: false}
] AS attr
MERGE (a:BusinessAttribute {id: attr.id})
ON CREATE SET a.name = attr.name, a.description = attr.description, a.data_type = attr.data_type, a.pii_classification = attr.pii, a.is_key = attr.is_key
MERGE (e)-[:HAS_ATTRIBUTE]->(a);

// --- VerificationOfEmployment ---
MATCH (e:Entity {name: 'VerificationOfEmployment'})
UNWIND [
  {id: 'verificationofemployment.voe_id', name: 'voe_id', description: 'Internal VOE id', data_type: 'string', pii: 'INTERNAL', is_key: true},
  {id: 'verificationofemployment.voe_request_date', name: 'voe_request_date', description: 'VOE request date (MISMO VerificationRequestDate)', data_type: 'date', pii: 'INTERNAL', is_key: false},
  {id: 'verificationofemployment.voe_received_date', name: 'voe_received_date', description: 'VOE received date (MISMO VerificationReceivedDate)', data_type: 'date', pii: 'INTERNAL', is_key: false},
  {id: 'verificationofemployment.voe_status_type', name: 'voe_status_type', description: 'Sent / Received / Verified (MISMO VerificationStatusType)', data_type: 'string', pii: 'INTERNAL', is_key: false},
  {id: 'verificationofemployment.voe_method_type', name: 'voe_method_type', description: 'Verbal / Written / ThirdParty (MISMO VerificationMethodType)', data_type: 'string', pii: 'INTERNAL', is_key: false},
  {id: 'verificationofemployment.third_party_provider', name: 'third_party_provider', description: 'TheWorkNumber / Equifax / Other', data_type: 'string', pii: 'INTERNAL', is_key: false},
  {id: 'verificationofemployment.position_title', name: 'position_title', description: 'Borrower position title (MISMO EmploymentPositionTitle)', data_type: 'string', pii: 'INTERNAL', is_key: false},
  {id: 'verificationofemployment.monthly_base_pay_amount', name: 'monthly_base_pay_amount', description: 'Verified base monthly pay (MISMO BasePayAmount)', data_type: 'decimal', pii: 'INTERNAL', is_key: false},
  {id: 'verificationofemployment.borrower_id', name: 'borrower_id', description: 'FK to borrower', data_type: 'string', pii: 'INTERNAL', is_key: false},
  {id: 'verificationofemployment.employer_id', name: 'employer_id', description: 'FK to employer', data_type: 'string', pii: 'INTERNAL', is_key: false}
] AS attr
MERGE (a:BusinessAttribute {id: attr.id})
ON CREATE SET a.name = attr.name, a.description = attr.description, a.data_type = attr.data_type, a.pii_classification = attr.pii, a.is_key = attr.is_key
MERGE (e)-[:HAS_ATTRIBUTE]->(a);

// --- DownPaymentSource ---
MATCH (e:Entity {name: 'DownPaymentSource'})
UNWIND [
  {id: 'downpaymentsource.source_id', name: 'source_id', description: 'Internal source id', data_type: 'string', pii: 'INTERNAL', is_key: true},
  {id: 'downpaymentsource.source_type', name: 'source_type', description: 'CheckingSavings / GiftFunds / RetirementFund / SaleOfAsset / SecuredLoan / Other (MISMO DownPaymentSourceType)', data_type: 'string', pii: 'INTERNAL', is_key: false},
  {id: 'downpaymentsource.amount', name: 'amount', description: 'Amount from this source (MISMO DownPaymentAmount)', data_type: 'decimal', pii: 'INTERNAL', is_key: false},
  {id: 'downpaymentsource.gift_donor_relationship', name: 'gift_donor_relationship', description: 'If gift, donor relationship to borrower (MISMO GiftDonorRelationshipType)', data_type: 'string', pii: 'INTERNAL', is_key: false},
  {id: 'downpaymentsource.borrower_id', name: 'borrower_id', description: 'FK to borrower', data_type: 'string', pii: 'INTERNAL', is_key: false}
] AS attr
MERGE (a:BusinessAttribute {id: attr.id})
ON CREATE SET a.name = attr.name, a.description = attr.description, a.data_type = attr.data_type, a.pii_classification = attr.pii, a.is_key = attr.is_key
MERGE (e)-[:HAS_ATTRIBUTE]->(a);

// ===============================================================
// 4. Record migration
// ===============================================================

MERGE (m:SchemaMigration {migration_id: '008_mismo_seed_expansion'})
ON CREATE SET m.applied_at = datetime(),
              m.description = 'MISMO 3.6.2-aligned ontology expansion — 14 new entities + ~250 additional curated attributes (knowledge-derived, not the canonical XSD)';
