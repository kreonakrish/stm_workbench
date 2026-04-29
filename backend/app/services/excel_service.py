"""Excel intake parser.

Parses an uploaded .xlsx file into a list of `ChangeLineInput` records the
intake validator can score. The expected sheet shape is one row per change,
with the following columns (header row required, case-insensitive):

    type | entity | attribute | table | source_system | source_table |
    source_column | new_logic | business_definition | data_type

Any column missing from the spreadsheet is treated as None for every row.
Rows with empty type or empty entity are silently skipped — the user is
expected to clean those up before submitting.
"""
from __future__ import annotations

from io import BytesIO

import structlog
from openpyxl import load_workbook

from app.domain.requests import ChangeLineInput, ChangeType

logger = structlog.get_logger(__name__)

_SUPPORTED_COLUMNS = {
    "type",
    "entity",
    "attribute",
    "table",
    "source_system",
    "source_table",
    "source_column",
    "new_logic",
    "business_definition",
    "data_type",
}


class ExcelParseError(ValueError):
    """Raised when the workbook is missing required headers or unreadable."""


def parse_excel(content: bytes) -> list[ChangeLineInput]:
    try:
        wb = load_workbook(BytesIO(content), read_only=True, data_only=True)
    except Exception as exc:
        raise ExcelParseError(f"Cannot read uploaded file as .xlsx: {exc}") from exc

    sheet = wb.worksheets[0]
    rows = sheet.iter_rows(values_only=True)
    try:
        header_row = next(rows)
    except StopIteration:
        raise ExcelParseError("Workbook has no rows")

    headers = [
        (str(h).strip().lower() if h is not None else "") for h in header_row
    ]
    if "type" not in headers or "entity" not in headers:
        raise ExcelParseError(
            "Header row must include at minimum 'type' and 'entity' columns"
        )

    valid_types = {t.value for t in ChangeType}
    items: list[ChangeLineInput] = []

    for raw in rows:
        record: dict[str, str | None] = {}
        for idx, header in enumerate(headers):
            if header not in _SUPPORTED_COLUMNS:
                continue
            value = raw[idx] if idx < len(raw) else None
            if value is None or (isinstance(value, str) and not value.strip()):
                record[header] = None
            else:
                record[header] = str(value).strip()

        if not record.get("type") or not record.get("entity"):
            continue
        if record["type"] not in valid_types:
            # Skip rather than error — we'll surface invalid rows in
            # validation if/when we extend this to return per-row diagnostics.
            continue

        items.append(
            ChangeLineInput(
                type=ChangeType(record["type"]),
                entity=record["entity"] or "",
                attribute=record.get("attribute"),
                table=record.get("table"),
                source_system=record.get("source_system"),
                source_table=record.get("source_table"),
                source_column=record.get("source_column"),
                new_logic=record.get("new_logic"),
                business_definition=record.get("business_definition"),
                data_type=record.get("data_type"),
            )
        )

    logger.info("excel_parsed", row_count=len(items))
    return items
