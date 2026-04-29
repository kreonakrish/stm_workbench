// Migration 003 — Bootstrap home-lending business ontology schema.
// See ADR 0007.
//
// Snapshot of github.com/kreonakrish/hl_knowledge_graph @ main, cypher/00_schema
// (01_constraints.cypher + 02_indexes.cypher) at the date this migration was
// authored. Subsequent ontology schema changes land as new numbered migrations.
//
// Idempotent: every CREATE uses IF NOT EXISTS.

// ==============================================================================
// CONSTRAINTS - Home Lending Knowledge Graph
// ==============================================================================
// Purpose: Define uniqueness constraints for entity nodes
// These constraints also automatically create indexes
// ==============================================================================

// --- Customer & Parties ---
CREATE CONSTRAINT borrower_id IF NOT EXISTS
FOR (b:Borrower) REQUIRE b.borrower_id IS UNIQUE;

CREATE CONSTRAINT co_borrower_id IF NOT EXISTS
FOR (cb:CoBorrower) REQUIRE cb.borrower_id IS UNIQUE;

CREATE CONSTRAINT lender_id IF NOT EXISTS
FOR (l:Lender) REQUIRE l.lender_id IS UNIQUE;

CREATE CONSTRAINT servicer_id IF NOT EXISTS
FOR (s:Servicer) REQUIRE s.servicer_id IS UNIQUE;

CREATE CONSTRAINT investor_id IF NOT EXISTS
FOR (i:Investor) REQUIRE i.investor_id IS UNIQUE;

CREATE CONSTRAINT broker_id IF NOT EXISTS
FOR (b:Broker) REQUIRE b.broker_id IS UNIQUE;

CREATE CONSTRAINT loan_officer_id IF NOT EXISTS
FOR (lo:LoanOfficer) REQUIRE lo.officer_id IS UNIQUE;

CREATE CONSTRAINT employer_id IF NOT EXISTS
FOR (e:Employer) REQUIRE e.employer_id IS UNIQUE;

CREATE CONSTRAINT settlement_agent_id IF NOT EXISTS
FOR (sa:SettlementAgent) REQUIRE sa.agent_id IS UNIQUE;

// --- Loan & Account ---
CREATE CONSTRAINT mortgage_loan_id IF NOT EXISTS
FOR (ml:MortgageLoan) REQUIRE ml.loan_id IS UNIQUE;

CREATE CONSTRAINT loan_account_id IF NOT EXISTS
FOR (la:LoanAccount) REQUIRE la.account_id IS UNIQUE;

CREATE CONSTRAINT note_id IF NOT EXISTS
FOR (n:Note) REQUIRE n.note_id IS UNIQUE;

CREATE CONSTRAINT payment_schedule_id IF NOT EXISTS
FOR (ps:PaymentSchedule) REQUIRE ps.schedule_id IS UNIQUE;

CREATE CONSTRAINT payment_id IF NOT EXISTS
FOR (p:Payment) REQUIRE p.payment_id IS UNIQUE;

// --- Property & Collateral ---
CREATE CONSTRAINT property_id IF NOT EXISTS
FOR (p:Property) REQUIRE p.property_id IS UNIQUE;

CREATE CONSTRAINT appraisal_id IF NOT EXISTS
FOR (a:Appraisal) REQUIRE a.appraisal_id IS UNIQUE;

CREATE CONSTRAINT valuation_model_id IF NOT EXISTS
FOR (vm:ValuationModel) REQUIRE vm.model_id IS UNIQUE;

CREATE CONSTRAINT comparable_sale_id IF NOT EXISTS
FOR (cs:ComparableSale) REQUIRE cs.comp_id IS UNIQUE;

// --- Geography ---
CREATE CONSTRAINT zip_code IF NOT EXISTS
FOR (z:Zip) REQUIRE z.zip_code IS UNIQUE;

CREATE CONSTRAINT county_fips IF NOT EXISTS
FOR (c:County) REQUIRE c.county_fips IS UNIQUE;

CREATE CONSTRAINT msa_code IF NOT EXISTS
FOR (m:MSA) REQUIRE m.msa_code IS UNIQUE;

CREATE CONSTRAINT census_tract_id IF NOT EXISTS
FOR (ct:CensusTract) REQUIRE ct.tract_id IS UNIQUE;

// --- Macro & Demographics ---
CREATE CONSTRAINT macro_snapshot_id IF NOT EXISTS
FOR (ms:MacroSnapshot) REQUIRE ms.snapshot_id IS UNIQUE;

CREATE CONSTRAINT demographic_snapshot_id IF NOT EXISTS
FOR (ds:DemographicSnapshot) REQUIRE ds.snapshot_id IS UNIQUE;

CREATE CONSTRAINT hpi_snapshot_id IF NOT EXISTS
FOR (hs:HPISnapshot) REQUIRE hs.snapshot_id IS UNIQUE;

// --- Marketing & Sales ---
CREATE CONSTRAINT lead_id IF NOT EXISTS
FOR (l:Lead) REQUIRE l.lead_id IS UNIQUE;

CREATE CONSTRAINT campaign_id IF NOT EXISTS
FOR (c:Campaign) REQUIRE c.campaign_id IS UNIQUE;

CREATE CONSTRAINT channel_id IF NOT EXISTS
FOR (ch:Channel) REQUIRE ch.channel_id IS UNIQUE;

CREATE CONSTRAINT touchpoint_id IF NOT EXISTS
FOR (t:Touchpoint) REQUIRE t.touchpoint_id IS UNIQUE;

// --- Events ---
CREATE CONSTRAINT event_id IF NOT EXISTS
FOR (e:Event) REQUIRE e.event_id IS UNIQUE;

CREATE CONSTRAINT origination_event_id IF NOT EXISTS
FOR (oe:OriginationEvent) REQUIRE oe.event_id IS UNIQUE;

CREATE CONSTRAINT servicing_event_id IF NOT EXISTS
FOR (se:ServicingEvent) REQUIRE se.event_id IS UNIQUE;

CREATE CONSTRAINT marketing_event_id IF NOT EXISTS
FOR (me:MarketingEvent) REQUIRE me.event_id IS UNIQUE;

// --- Phase 1: Core Operations ---

// Fees
CREATE CONSTRAINT fee_id IF NOT EXISTS
FOR (f:Fee) REQUIRE f.fee_id IS UNIQUE;

// Documents
CREATE CONSTRAINT document_id IF NOT EXISTS
FOR (d:Document) REQUIRE d.document_id IS UNIQUE;

// Communications
CREATE CONSTRAINT communication_id IF NOT EXISTS
FOR (c:Communication) REQUIRE c.communication_id IS UNIQUE;

// Conditions
CREATE CONSTRAINT condition_id IF NOT EXISTS
FOR (c:Condition) REQUIRE c.condition_id IS UNIQUE;

// --- Phase 2: AI Workflow ---

// AI Agents
CREATE CONSTRAINT ai_agent_id IF NOT EXISTS
FOR (a:AIAgent) REQUIRE a.agent_id IS UNIQUE;

// AI Interactions
CREATE CONSTRAINT ai_interaction_id IF NOT EXISTS
FOR (ai:AIInteraction) REQUIRE ai.interaction_id IS UNIQUE;

// Workflow Stages
CREATE CONSTRAINT workflow_stage_id IF NOT EXISTS
FOR (ws:WorkflowStage) REQUIRE ws.stage_id IS UNIQUE;

// Verifications
CREATE CONSTRAINT verification_id IF NOT EXISTS
FOR (v:Verification) REQUIRE v.verification_id IS UNIQUE;

// --- Phase 3: Advanced Operations ---

// QC Reviews
CREATE CONSTRAINT qc_review_id IF NOT EXISTS
FOR (qc:QCReview) REQUIRE qc.qc_review_id IS UNIQUE;

// Compliance Rules
CREATE CONSTRAINT compliance_rule_id IF NOT EXISTS
FOR (cr:ComplianceRule) REQUIRE cr.rule_id IS UNIQUE;

// Rule Executions
CREATE CONSTRAINT rule_execution_id IF NOT EXISTS
FOR (re:RuleExecution) REQUIRE re.execution_id IS UNIQUE;

// --- Phase 4: Cost Centers & Profitability ---

// Organizational Structure
CREATE CONSTRAINT business_unit_id IF NOT EXISTS
FOR (bu:BusinessUnit) REQUIRE bu.unit_id IS UNIQUE;

CREATE CONSTRAINT cost_center_id IF NOT EXISTS
FOR (cc:CostCenter) REQUIRE cc.cost_center_id IS UNIQUE;

CREATE CONSTRAINT office_id IF NOT EXISTS
FOR (o:Office) REQUIRE o.office_id IS UNIQUE;

CREATE CONSTRAINT region_id IF NOT EXISTS
FOR (r:Region) REQUIRE r.region_id IS UNIQUE;

CREATE CONSTRAINT division_id IF NOT EXISTS
FOR (d:Division) REQUIRE d.division_id IS UNIQUE;

// Financial Tracking
CREATE CONSTRAINT expense_item_id IF NOT EXISTS
FOR (ei:ExpenseItem) REQUIRE ei.expense_id IS UNIQUE;

CREATE CONSTRAINT allocation_rule_id IF NOT EXISTS
FOR (ar:AllocationRule) REQUIRE ar.rule_id IS UNIQUE;

CREATE CONSTRAINT cost_pool_id IF NOT EXISTS
FOR (cp:CostPool) REQUIRE cp.pool_id IS UNIQUE;

CREATE CONSTRAINT revenue_item_id IF NOT EXISTS
FOR (ri:RevenueItem) REQUIRE ri.revenue_id IS UNIQUE;

// --- Phase 5: Risk Management ---

// Risk Assessments & Mitigations
CREATE CONSTRAINT risk_assessment_id IF NOT EXISTS
FOR (ra:RiskAssessment) REQUIRE ra.assessment_id IS UNIQUE;

CREATE CONSTRAINT risk_mitigation_id IF NOT EXISTS
FOR (rm:RiskMitigation) REQUIRE rm.mitigation_id IS UNIQUE;

CREATE CONSTRAINT risk_policy_id IF NOT EXISTS
FOR (rp:RiskPolicy) REQUIRE rp.policy_id IS UNIQUE;

CREATE CONSTRAINT risk_limit_id IF NOT EXISTS
FOR (rl:RiskLimit) REQUIRE rl.limit_id IS UNIQUE;

CREATE CONSTRAINT concentration_risk_id IF NOT EXISTS
FOR (cr:ConcentrationRisk) REQUIRE cr.risk_id IS UNIQUE;

CREATE CONSTRAINT repurchase_risk_id IF NOT EXISTS
FOR (rr:RepurchaseRisk) REQUIRE rr.risk_id IS UNIQUE;

CREATE CONSTRAINT epd_risk_id IF NOT EXISTS
FOR (er:EPDRisk) REQUIRE er.risk_id IS UNIQUE;

CREATE CONSTRAINT rw_breach_id IF NOT EXISTS
FOR (rw:RWBreach) REQUIRE rw.breach_id IS UNIQUE;

// --- Phase 6: Regulatory Compliance (REDS) ---

// Regulatory Entities
CREATE CONSTRAINT regulatory_agency_id IF NOT EXISTS
FOR (ra:RegulatoryAgency) REQUIRE ra.agency_id IS UNIQUE;

CREATE CONSTRAINT regulatory_requirement_id IF NOT EXISTS
FOR (rr:RegulatoryRequirement) REQUIRE rr.requirement_id IS UNIQUE;

CREATE CONSTRAINT regulatory_report_id IF NOT EXISTS
FOR (rr:RegulatoryReport) REQUIRE rr.report_id IS UNIQUE;

CREATE CONSTRAINT report_submission_id IF NOT EXISTS
FOR (rs:ReportSubmission) REQUIRE rs.submission_id IS UNIQUE;

CREATE CONSTRAINT compliance_violation_id IF NOT EXISTS
FOR (cv:ComplianceViolation) REQUIRE cv.violation_id IS UNIQUE;

CREATE CONSTRAINT regulatory_examination_id IF NOT EXISTS
FOR (re:RegulatoryExamination) REQUIRE re.exam_id IS UNIQUE;

CREATE CONSTRAINT state_regulator_id IF NOT EXISTS
FOR (sr:StateRegulator) REQUIRE sr.regulator_id IS UNIQUE;

CREATE CONSTRAINT regulation_id IF NOT EXISTS
FOR (reg:Regulation) REQUIRE reg.regulation_code IS UNIQUE;

CREATE CONSTRAINT udaap_review_id IF NOT EXISTS
FOR (ur:UDAAPReview) REQUIRE ur.review_id IS UNIQUE;

CREATE CONSTRAINT redlining_analysis_id IF NOT EXISTS
FOR (rl:RedliningAnalysis) REQUIRE rl.analysis_id IS UNIQUE;

CREATE CONSTRAINT fair_lending_test_id IF NOT EXISTS
FOR (fl:FairLendingTest) REQUIRE fl.test_id IS UNIQUE;

// --- Phase 7: Capital Markets ---

// Treasury & Funding
CREATE CONSTRAINT treasury_account_id IF NOT EXISTS
FOR (ta:TreasuryAccount) REQUIRE ta.account_id IS UNIQUE;

CREATE CONSTRAINT funding_source_id IF NOT EXISTS
FOR (fs:FundingSource) REQUIRE fs.source_id IS UNIQUE;

CREATE CONSTRAINT warehouse_line_id IF NOT EXISTS
FOR (wl:WarehouseLine) REQUIRE wl.line_id IS UNIQUE;

CREATE CONSTRAINT loan_funding_id IF NOT EXISTS
FOR (lf:LoanFunding) REQUIRE lf.funding_id IS UNIQUE;

CREATE CONSTRAINT liquidity_snapshot_id IF NOT EXISTS
FOR (ls:LiquiditySnapshot) REQUIRE ls.snapshot_id IS UNIQUE;

CREATE CONSTRAINT capital_adequacy_id IF NOT EXISTS
FOR (ca:CapitalAdequacy) REQUIRE ca.snapshot_id IS UNIQUE;

CREATE CONSTRAINT secondary_market_sale_id IF NOT EXISTS
FOR (sms:SecondaryMarketSale) REQUIRE sms.sale_id IS UNIQUE;

// MSR & Hedging
CREATE CONSTRAINT msr_asset_id IF NOT EXISTS
FOR (msr:MSRAsset) REQUIRE msr.msr_id IS UNIQUE;

CREATE CONSTRAINT hedging_instrument_id IF NOT EXISTS
FOR (hi:HedgingInstrument) REQUIRE hi.instrument_id IS UNIQUE;

CREATE CONSTRAINT loan_pipeline_id IF NOT EXISTS
FOR (lp:LoanPipeline) REQUIRE lp.pipeline_id IS UNIQUE;

CREATE CONSTRAINT rate_lock_id IF NOT EXISTS
FOR (rlock:RateLock) REQUIRE rlock.lock_id IS UNIQUE;

CREATE CONSTRAINT msr_asset_id IF NOT EXISTS
FOR (ma:MSRAsset) REQUIRE ma.msr_id IS UNIQUE;

CREATE CONSTRAINT investor_commitment_id IF NOT EXISTS
FOR (ic:InvestorCommitment) REQUIRE ic.commitment_id IS UNIQUE;



// ==============================================================================
// INDEXES - Home Lending Knowledge Graph
// ==============================================================================
// Purpose: Create performance indexes for frequently queried properties
// Note: Unique constraints automatically create indexes, so those are excluded
// ==============================================================================

// --- Borrower Indexes ---
CREATE INDEX borrower_ssn IF NOT EXISTS
FOR (b:Borrower) ON (b.ssn);

CREATE INDEX borrower_email IF NOT EXISTS
FOR (b:Borrower) ON (b.email);

CREATE INDEX borrower_name IF NOT EXISTS
FOR (b:Borrower) ON (b.last_name, b.first_name);

// --- Loan Indexes ---
CREATE INDEX loan_status IF NOT EXISTS
FOR (ml:MortgageLoan) ON (ml.loan_status);

CREATE INDEX loan_origination_date IF NOT EXISTS
FOR (ml:MortgageLoan) ON (ml.origination_date);

CREATE INDEX loan_product_type IF NOT EXISTS
FOR (ml:MortgageLoan) ON (ml.product_type);

CREATE INDEX loan_purpose IF NOT EXISTS
FOR (ml:MortgageLoan) ON (ml.loan_purpose);

// --- Property Indexes ---
CREATE INDEX property_address IF NOT EXISTS
FOR (p:Property) ON (p.address);

CREATE INDEX property_type IF NOT EXISTS
FOR (p:Property) ON (p.property_type);

// --- Event Indexes ---
CREATE INDEX event_timestamp IF NOT EXISTS
FOR (e:Event) ON (e.event_ts);

CREATE INDEX event_type IF NOT EXISTS
FOR (e:Event) ON (e.event_type);

CREATE INDEX event_business_date IF NOT EXISTS
FOR (e:Event) ON (e.business_dt);

CREATE INDEX event_source IF NOT EXISTS
FOR (e:Event) ON (e.source_system);

// --- Origination Event Indexes ---
CREATE INDEX origination_event_type IF NOT EXISTS
FOR (oe:OriginationEvent) ON (oe.event_type);

CREATE INDEX origination_event_ts IF NOT EXISTS
FOR (oe:OriginationEvent) ON (oe.event_ts);

// --- Servicing Event Indexes ---
CREATE INDEX servicing_event_type IF NOT EXISTS
FOR (se:ServicingEvent) ON (se.event_type);

CREATE INDEX servicing_event_ts IF NOT EXISTS
FOR (se:ServicingEvent) ON (se.event_ts);

// --- Marketing Event Indexes ---
CREATE INDEX marketing_event_type IF NOT EXISTS
FOR (me:MarketingEvent) ON (me.event_type);

CREATE INDEX marketing_event_ts IF NOT EXISTS
FOR (me:MarketingEvent) ON (me.event_ts);

// --- Campaign Indexes ---
CREATE INDEX campaign_status IF NOT EXISTS
FOR (c:Campaign) ON (c.status);

CREATE INDEX campaign_start_date IF NOT EXISTS
FOR (c:Campaign) ON (c.start_date);

// --- Lead Indexes ---
CREATE INDEX lead_status IF NOT EXISTS
FOR (l:Lead) ON (l.status);

CREATE INDEX lead_created_date IF NOT EXISTS
FOR (l:Lead) ON (l.created_date);

// --- Geography Indexes ---
CREATE INDEX zip_state IF NOT EXISTS
FOR (z:Zip) ON (z.state);

CREATE INDEX county_state IF NOT EXISTS
FOR (c:County) ON (c.state);

// --- Composite Indexes for Common Queries ---
CREATE INDEX loan_status_date IF NOT EXISTS
FOR (ml:MortgageLoan) ON (ml.loan_status, ml.origination_date);

CREATE INDEX event_type_timestamp IF NOT EXISTS
FOR (e:Event) ON (e.event_type, e.event_ts);

// --- Phase 1: Core Operations Indexes ---

// Fee Indexes
CREATE INDEX fee_type IF NOT EXISTS
FOR (f:Fee) ON (f.fee_type);

CREATE INDEX fee_collected_date IF NOT EXISTS
FOR (f:Fee) ON (f.collected_date);

// Document Indexes
CREATE INDEX document_type IF NOT EXISTS
FOR (d:Document) ON (d.document_type);

CREATE INDEX document_status IF NOT EXISTS
FOR (d:Document) ON (d.status);

CREATE INDEX document_upload_date IF NOT EXISTS
FOR (d:Document) ON (d.upload_date);

// Communication Indexes
CREATE INDEX communication_type IF NOT EXISTS
FOR (c:Communication) ON (c.communication_type);

CREATE INDEX communication_sent_datetime IF NOT EXISTS
FOR (c:Communication) ON (c.sent_datetime);

// Condition Indexes
CREATE INDEX condition_status IF NOT EXISTS
FOR (c:Condition) ON (c.status);

CREATE INDEX condition_type IF NOT EXISTS
FOR (c:Condition) ON (c.condition_type);

// --- Phase 2: AI Workflow Indexes ---

// AI Agent Indexes
CREATE INDEX ai_agent_type IF NOT EXISTS
FOR (a:AIAgent) ON (a.agent_type);

CREATE INDEX ai_agent_status IF NOT EXISTS
FOR (a:AIAgent) ON (a.status);

// AI Interaction Indexes
CREATE INDEX ai_interaction_start_datetime IF NOT EXISTS
FOR (ai:AIInteraction) ON (ai.start_datetime);

CREATE INDEX ai_interaction_agent IF NOT EXISTS
FOR (ai:AIInteraction) ON (ai.agent_id);

// Workflow Stage Indexes
CREATE INDEX workflow_stage_name IF NOT EXISTS
FOR (ws:WorkflowStage) ON (ws.stage_name);

CREATE INDEX workflow_stage_status IF NOT EXISTS
FOR (ws:WorkflowStage) ON (ws.status);

// HELOC Indexes
CREATE INDEX heloc_status IF NOT EXISTS
FOR (h:HELOC) ON (h.heloc_status);

// Reverse Mortgage Indexes
CREATE INDEX reverse_mortgage_status IF NOT EXISTS
FOR (rm:ReverseMortgage) ON (rm.status);

// --- Phase 3: Advanced Operations Indexes ---

// QC Review Indexes
CREATE INDEX qc_review_type IF NOT EXISTS
FOR (qc:QCReview) ON (qc.review_type);

CREATE INDEX qc_review_date IF NOT EXISTS
FOR (qc:QCReview) ON (qc.review_date);

// Compliance Rule Indexes
CREATE INDEX compliance_rule_category IF NOT EXISTS
FOR (cr:ComplianceRule) ON (cr.rule_category);

CREATE INDEX compliance_rule_status IF NOT EXISTS
FOR (cr:ComplianceRule) ON (cr.status);

// Rule Execution Indexes
CREATE INDEX rule_execution_datetime IF NOT EXISTS
FOR (re:RuleExecution) ON (re.executed_datetime);

CREATE INDEX rule_execution_result IF NOT EXISTS
FOR (re:RuleExecution) ON (re.result);

// --- Phase 4: Cost Centers & Profitability Indexes ---

// Business Unit Indexes
CREATE INDEX business_unit_name IF NOT EXISTS
FOR (bu:BusinessUnit) ON (bu.unit_name);

CREATE INDEX business_unit_type IF NOT EXISTS
FOR (bu:BusinessUnit) ON (bu.unit_type);

// Cost Center Indexes
CREATE INDEX cost_center_name IF NOT EXISTS
FOR (cc:CostCenter) ON (cc.cost_center_name);

CREATE INDEX cost_center_type IF NOT EXISTS
FOR (cc:CostCenter) ON (cc.cost_center_type);

CREATE INDEX cost_center_status IF NOT EXISTS
FOR (cc:CostCenter) ON (cc.status);

// Office Indexes
CREATE INDEX office_name IF NOT EXISTS
FOR (o:Office) ON (o.office_name);

CREATE INDEX office_type IF NOT EXISTS
FOR (o:Office) ON (o.office_type);

CREATE INDEX office_status IF NOT EXISTS
FOR (o:Office) ON (o.status);

// Region Indexes
CREATE INDEX region_name IF NOT EXISTS
FOR (r:Region) ON (r.region_name);

// Division Indexes
CREATE INDEX division_name IF NOT EXISTS
FOR (d:Division) ON (d.division_name);

// Expense Item Indexes
CREATE INDEX expense_date IF NOT EXISTS
FOR (ei:ExpenseItem) ON (ei.expense_date);

CREATE INDEX expense_category IF NOT EXISTS
FOR (ei:ExpenseItem) ON (ei.expense_category);

CREATE INDEX expense_type IF NOT EXISTS
FOR (ei:ExpenseItem) ON (ei.expense_type);

// Allocation Rule Indexes
CREATE INDEX allocation_rule_type IF NOT EXISTS
FOR (ar:AllocationRule) ON (ar.allocation_type);

CREATE INDEX allocation_rule_status IF NOT EXISTS
FOR (ar:AllocationRule) ON (ar.status);

// Cost Pool Indexes
CREATE INDEX cost_pool_name IF NOT EXISTS
FOR (cp:CostPool) ON (cp.pool_name);

CREATE INDEX cost_pool_period IF NOT EXISTS
FOR (cp:CostPool) ON (cp.period);

// Revenue Item Indexes
CREATE INDEX revenue_date IF NOT EXISTS
FOR (ri:RevenueItem) ON (ri.revenue_date);

CREATE INDEX revenue_type IF NOT EXISTS
FOR (ri:RevenueItem) ON (ri.revenue_type);

CREATE INDEX revenue_category IF NOT EXISTS
FOR (ri:RevenueItem) ON (ri.revenue_category);

// Composite Indexes for Cost Analysis
CREATE INDEX expense_date_category IF NOT EXISTS
FOR (ei:ExpenseItem) ON (ei.expense_date, ei.expense_category);

CREATE INDEX revenue_date_category IF NOT EXISTS
FOR (ri:RevenueItem) ON (ri.revenue_date, ri.revenue_category);

// --- Phase 5: Risk Management Indexes ---

// Risk Assessment Indexes
CREATE INDEX risk_assessment_category IF NOT EXISTS
FOR (ra:RiskAssessment) ON (ra.risk_category);

CREATE INDEX risk_assessment_level IF NOT EXISTS
FOR (ra:RiskAssessment) ON (ra.risk_level);

CREATE INDEX risk_assessment_date IF NOT EXISTS
FOR (ra:RiskAssessment) ON (ra.assessment_date);

CREATE INDEX risk_assessment_status IF NOT EXISTS
FOR (ra:RiskAssessment) ON (ra.risk_status);

// Risk Mitigation Indexes
CREATE INDEX risk_mitigation_status IF NOT EXISTS
FOR (rm:RiskMitigation) ON (rm.status);

CREATE INDEX risk_mitigation_date IF NOT EXISTS
FOR (rm:RiskMitigation) ON (rm.implementation_date);

// Risk Policy Indexes
CREATE INDEX risk_policy_type IF NOT EXISTS
FOR (rp:RiskPolicy) ON (rp.policy_type);

CREATE INDEX risk_policy_status IF NOT EXISTS
FOR (rp:RiskPolicy) ON (rp.status);

// Concentration Risk Indexes
CREATE INDEX concentration_risk_type IF NOT EXISTS
FOR (cr:ConcentrationRisk) ON (cr.concentration_type);

// EPD Risk Indexes
CREATE INDEX epd_risk_days IF NOT EXISTS
FOR (er:EPDRisk) ON (er.days_since_origination);

// --- Phase 6: Regulatory Compliance Indexes ---

// Regulatory Agency Indexes
CREATE INDEX regulatory_agency_code IF NOT EXISTS
FOR (ra:RegulatoryAgency) ON (ra.agency_code);

CREATE INDEX regulatory_agency_type IF NOT EXISTS
FOR (ra:RegulatoryAgency) ON (ra.agency_type);

// Regulatory Requirement Indexes
CREATE INDEX regulatory_requirement_code IF NOT EXISTS
FOR (rr:RegulatoryRequirement) ON (rr.requirement_code);

CREATE INDEX regulatory_requirement_frequency IF NOT EXISTS
FOR (rr:RegulatoryRequirement) ON (rr.compliance_frequency);

// Regulatory Report Indexes
CREATE INDEX regulatory_report_type IF NOT EXISTS
FOR (rr:RegulatoryReport) ON (rr.report_type);

CREATE INDEX regulatory_report_period IF NOT EXISTS
FOR (rr:RegulatoryReport) ON (rr.reporting_period);

CREATE INDEX regulatory_report_status IF NOT EXISTS
FOR (rr:RegulatoryReport) ON (rr.status);

// Report Submission Indexes
CREATE INDEX report_submission_date IF NOT EXISTS
FOR (rs:ReportSubmission) ON (rs.submission_date);

CREATE INDEX report_submission_period IF NOT EXISTS
FOR (rs:ReportSubmission) ON (rs.reporting_period);

CREATE INDEX report_submission_status IF NOT EXISTS
FOR (rs:ReportSubmission) ON (rs.status);

// Compliance Violation Indexes
CREATE INDEX compliance_violation_type IF NOT EXISTS
FOR (cv:ComplianceViolation) ON (cv.violation_type);

CREATE INDEX compliance_violation_severity IF NOT EXISTS
FOR (cv:ComplianceViolation) ON (cv.severity);

CREATE INDEX compliance_violation_status IF NOT EXISTS
FOR (cv:ComplianceViolation) ON (cv.status);

// Regulatory Examination Indexes
CREATE INDEX regulatory_exam_type IF NOT EXISTS
FOR (re:RegulatoryExamination) ON (re.exam_type);

CREATE INDEX regulatory_exam_date IF NOT EXISTS
FOR (re:RegulatoryExamination) ON (re.exam_start_date);

// State Regulator Indexes
CREATE INDEX state_regulator_state IF NOT EXISTS
FOR (sr:StateRegulator) ON (sr.state_code);

CREATE INDEX state_regulator_type IF NOT EXISTS
FOR (sr:StateRegulator) ON (sr.licensing_type);

// Fair Lending Test Indexes
CREATE INDEX fair_lending_test_type IF NOT EXISTS
FOR (fl:FairLendingTest) ON (fl.test_type);

CREATE INDEX fair_lending_protected_class IF NOT EXISTS
FOR (fl:FairLendingTest) ON (fl.protected_class);

// --- Phase 7: Capital Markets Indexes ---

// Treasury Account Indexes
CREATE INDEX treasury_account_type IF NOT EXISTS
FOR (ta:TreasuryAccount) ON (ta.account_type);

CREATE INDEX treasury_account_status IF NOT EXISTS
FOR (ta:TreasuryAccount) ON (ta.status);

// Funding Source Indexes
CREATE INDEX funding_source_type IF NOT EXISTS
FOR (fs:FundingSource) ON (fs.source_type);

CREATE INDEX funding_source_status IF NOT EXISTS
FOR (fs:FundingSource) ON (fs.status);

// Warehouse Line Indexes
CREATE INDEX warehouse_line_lender IF NOT EXISTS
FOR (wl:WarehouseLine) ON (wl.lender_name);

CREATE INDEX warehouse_line_status IF NOT EXISTS
FOR (wl:WarehouseLine) ON (wl.status);

CREATE INDEX warehouse_line_maturity IF NOT EXISTS
FOR (wl:WarehouseLine) ON (wl.maturity_date);

// Loan Funding Indexes
CREATE INDEX loan_funding_date IF NOT EXISTS
FOR (lf:LoanFunding) ON (lf.funding_date);

CREATE INDEX loan_funding_type IF NOT EXISTS
FOR (lf:LoanFunding) ON (lf.funding_type);

// Liquidity Snapshot Indexes
CREATE INDEX liquidity_snapshot_date IF NOT EXISTS
FOR (ls:LiquiditySnapshot) ON (ls.snapshot_date);

CREATE INDEX liquidity_snapshot_status IF NOT EXISTS
FOR (ls:LiquiditySnapshot) ON (ls.status);

// Capital Adequacy Indexes
CREATE INDEX capital_adequacy_date IF NOT EXISTS
FOR (ca:CapitalAdequacy) ON (ca.reporting_date);

CREATE INDEX capital_adequacy_status IF NOT EXISTS
FOR (ca:CapitalAdequacy) ON (ca.status);

// Secondary Market Sale Indexes
CREATE INDEX secondary_sale_date IF NOT EXISTS
FOR (sms:SecondaryMarketSale) ON (sms.sale_date);

CREATE INDEX secondary_sale_type IF NOT EXISTS
FOR (sms:SecondaryMarketSale) ON (sms.sale_type);

CREATE INDEX secondary_sale_status IF NOT EXISTS
FOR (sms:SecondaryMarketSale) ON (sms.status);

// MSR Asset Indexes
CREATE INDEX msr_valuation_date IF NOT EXISTS
FOR (msr:MSRAsset) ON (msr.valuation_date);

// Hedging Instrument Indexes
CREATE INDEX hedging_instrument_type IF NOT EXISTS
FOR (hi:HedgingInstrument) ON (hi.instrument_type);

CREATE INDEX hedging_expiration IF NOT EXISTS
FOR (hi:HedgingInstrument) ON (hi.expiration_date);

// Loan Pipeline Indexes
CREATE INDEX loan_pipeline_stage IF NOT EXISTS
FOR (lp:LoanPipeline) ON (lp.pipeline_stage);

CREATE INDEX loan_pipeline_date IF NOT EXISTS
FOR (lp:LoanPipeline) ON (lp.snapshot_date);

// Rate Lock Indexes
CREATE INDEX rate_lock_date IF NOT EXISTS
FOR (rlock:RateLock) ON (rlock.lock_date);

CREATE INDEX rate_lock_expiration IF NOT EXISTS
FOR (rlock:RateLock) ON (rlock.lock_expiration);

// Investor Commitment Indexes
CREATE INDEX investor_commitment_type IF NOT EXISTS
FOR (ic:InvestorCommitment) ON (ic.commitment_type);

CREATE INDEX investor_commitment_status IF NOT EXISTS
FOR (ic:InvestorCommitment) ON (ic.status);

// Composite Indexes for Analysis
CREATE INDEX risk_assessment_category_level IF NOT EXISTS
FOR (ra:RiskAssessment) ON (ra.risk_category, ra.risk_level);

CREATE INDEX compliance_violation_type_severity IF NOT EXISTS
FOR (cv:ComplianceViolation) ON (cv.violation_type, cv.severity);


// ---------------------------------------------------------------
// Record this migration
// ---------------------------------------------------------------

MERGE (m:SchemaMigration {migration_id: '003_ontology_bootstrap'})
ON CREATE SET m.applied_at = datetime(),
              m.description = 'Bootstrap home-lending business ontology constraints and indexes (ADR 0007)';
