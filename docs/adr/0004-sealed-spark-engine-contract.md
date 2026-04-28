# ADR 0004: Sealed Spark transformation engine contract

## Status
Accepted

## Context
The HL data platform runs a sealed Spark transformation engine that
accepts only specific partition shapes and does not perform certain
operations (notably first-occurrence detection) inside the engine. STMs
that violate this contract cannot be executed and must be detected before
code generation, not after deployment failure.

## Decision
The sealed engine contract is encoded as conformance rules checked during
the Discovery → DRB conformance pre-check stage. Violations are reported
as `:ConformanceFinding` nodes with severity `red` and block the request
from advancing to STM authoring.

Specific contract rules (V1):
- Transformations accept only `business_date` and `operational_date`
  partition columns. Other partition schemes are rejected.
- First-occurrence detection (e.g. "first time this loan appeared") must
  be implemented in a derived registry layer outside the engine, not
  inside the STM transformation. STMs requesting this pattern are flagged.
- All target tables must declare partition columns at conformance check
  time; partition-less targets are rejected.

Code generation templates encode these constraints; an STM that somehow
reaches code generation while violating them produces a generation error
rather than invalid code.

## Consequences
- Conformance pre-check service must encode and maintain the contract
  rules; this is a living module updated as the engine evolves.
- The contract rules themselves are graph data (`:ContractRule` nodes)
  so they can be queried, versioned, and updated without redeploying
  the conformance service.
- Code generation templates have a contract-validation step; templates
  cannot emit code that violates the contract.
- Engine team owns the contract; platform team owns enforcement.
