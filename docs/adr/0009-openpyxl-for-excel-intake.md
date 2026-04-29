# ADR 0009: Use openpyxl for Excel intake parsing

## Status
Accepted

## Context
S5 of the structured-intake plan (see project memory `intake_scope.md`)
requires accepting `.xlsx` uploads as a bulk-entry path for change lines.
The parsing happens server-side: client uploads the workbook, server
parses rows into `ChangeLineInput` records, validation runs, and the
classification preview returns to the user.

Two viable Python libraries:

| Lib       | Bundle | Read-only mode | Active                |
|-----------|--------|----------------|------------------------|
| openpyxl  | small  | yes (`read_only=True` is streaming) | yes |
| pandas + openpyxl | huge | yes via `read_excel` | yes, but pandas is ~50× the install size |

We don't need DataFrames — we want one row at a time, mapped to a
Pydantic model. openpyxl directly is the right primitive.

## Decision
Add `openpyxl >= 3.1` as a backend dependency.

Use `load_workbook(..., read_only=True, data_only=True)` so we stream
rows (low memory) and read formula values (not the formulas themselves).

## Consequences
**Easier**
- Modest dep footprint; no transitive C-extension surprises beyond what
  comes with openpyxl itself.
- Streaming reads — large workbooks won't OOM the API.

**Harder**
- We accept openpyxl's bug surface (well-known and stable, but not zero).
- If the team later needs cross-sheet aggregation or pivot reads, we'll
  reach for pandas; this ADR doesn't preclude that.
