# ADR 0005: Idempotent downstream sync to Erwin and Catalog

## Status
Accepted (V2 implementation; V1 designs the contracts only)

## Context
After DRB approval, STM changes must propagate to:
- Erwin Mart (logical/physical data model)
- The enterprise Catalog (Collibra, Alation, or equivalent)

Both downstream systems may be temporarily unavailable, may reject changes
due to their own validation, and must not be corrupted by partial writes.

## Decision
Sync is one-way: graph → downstream. The graph is canonical; downstream
systems are reconciled to it.

Sync operations are idempotent: re-running a sync for a given
`:MappingVersion` produces the same downstream state, regardless of how
many times it runs. This is achieved by:
- Including the `:MappingVersion` ID and `content_hash` in every
  downstream write.
- Checking downstream state before writing; if the target state already
  matches, skip.
- Using downstream system idempotency keys where supported.

Failed sync operations are queued and retried with exponential backoff.
Operations that fail repeatedly are escalated to a human-attention queue,
not silently dropped.

A nightly reconciliation job compares graph state against downstream
state and reports drift. Drift is investigated; auto-correction is not
performed in V1 or V2.

## Consequences
- Sync clients must be designed to read downstream state before writing.
- The graph carries `last_synced_at` and `last_synced_version` properties
  on synced nodes for visibility.
- Downstream system credentials and rate limits are operational concerns
  managed via the Celery worker configuration.
- Reconciliation reports are surfaced as a daily Slack/email digest to
  the operations team.
