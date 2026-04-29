import { useRef, useState } from "react";
import { useNavigate } from "react-router-dom";
import {
  ChangeLineRow,
  type ChangeLineClassified,
  type ChangeLineDraft,
} from "../components/ChangeLineRow";
import { ClassificationBadge } from "../components/ClassificationBadge";

interface ClassifyResponse extends ChangeLineClassified {
  classification: "exists" | "net_new" | "needs_change" | "invalid";
}

async function previewClassification(
  items: ChangeLineDraft[],
): Promise<ClassifyResponse[]> {
  const res = await fetch("/api/v1/intake/preview", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(items),
  });
  if (!res.ok) throw new Error(`Preview failed: ${res.status}`);
  return res.json();
}

async function parseExcel(file: File): Promise<ClassifyResponse[]> {
  const fd = new FormData();
  fd.append("file", file);
  const res = await fetch("/api/v1/intake/parse-excel", {
    method: "POST",
    body: fd,
  });
  if (!res.ok) {
    const detail = await res
      .json()
      .then((j) => j.detail)
      .catch(() => null);
    throw new Error(detail ?? `Excel parse failed: ${res.status}`);
  }
  return res.json();
}

interface CreatePayload {
  title: FormDataEntryValue | null;
  business_question: FormDataEntryValue | null;
  usage_context: FormDataEntryValue | null;
  consumption_pattern: FormDataEntryValue | null;
  template_id: string;
  items: ChangeLineDraft[];
}

async function createRequest(payload: CreatePayload) {
  const res = await fetch("/api/v1/requests", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(payload),
  });
  if (!res.ok) throw new Error(`Submit failed: ${res.status}`);
  return res.json();
}

const EMPTY_LINE: ChangeLineDraft = {
  type: "add_attribute",
  entity: "",
  attribute: "",
};

export function IntakePage() {
  const nav = useNavigate();
  const [items, setItems] = useState<ChangeLineClassified[]>([
    { ...EMPTY_LINE },
  ]);
  const [submitting, setSubmitting] = useState(false);
  const [validating, setValidating] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);

  function setItem(i: number, next: ChangeLineClassified) {
    setItems((prev) => prev.map((it, idx) => (idx === i ? next : it)));
  }
  function removeItem(i: number) {
    setItems((prev) => prev.filter((_, idx) => idx !== i));
  }
  function addItem() {
    setItems((prev) => [...prev, { ...EMPTY_LINE }]);
  }

  async function handleValidate() {
    setError(null);
    setValidating(true);
    try {
      const drafts = items.map(stripClassification);
      const classified = await previewClassification(drafts);
      setItems(classified);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Unknown error");
    } finally {
      setValidating(false);
    }
  }

  async function handleExcelChange(e: React.ChangeEvent<HTMLInputElement>) {
    setError(null);
    const file = e.target.files?.[0];
    if (!file) return;
    setValidating(true);
    try {
      const classified = await parseExcel(file);
      setItems(classified.length > 0 ? classified : [{ ...EMPTY_LINE }]);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Excel parse failed");
    } finally {
      setValidating(false);
      if (fileInputRef.current) fileInputRef.current.value = "";
    }
  }

  async function handleSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    setSubmitting(true);
    setError(null);
    const formData = new FormData(e.currentTarget);
    try {
      const payload: CreatePayload = {
        title: formData.get("title"),
        business_question: formData.get("business_question"),
        usage_context: formData.get("usage_context"),
        consumption_pattern: formData.get("consumption_pattern"),
        template_id: "default",
        items: items
          .filter((it) => it.entity)
          .map(stripClassification),
      };
      const result = await createRequest(payload);
      nav(`/requests/${result.id}`);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Unknown error");
    } finally {
      setSubmitting(false);
    }
  }

  const anyClassified = items.some((it) => it.classification);
  const invalidCount = items.filter(
    (it) => it.classification === "invalid",
  ).length;

  return (
    <div className="mx-auto max-w-4xl">
      <h1 className="mb-1 text-2xl font-medium text-gray-900">New request</h1>
      <p className="mb-6 text-sm text-gray-600">
        Submit a structured change set. Each row is a typed change against the
        business ontology; validation classifies each line as
        <em> exists / net-new / needs-change / invalid</em> before submission.
      </p>

      <form onSubmit={handleSubmit} className="space-y-6">
        <section className="space-y-4 rounded-lg border bg-white p-6">
          <h2 className="text-sm font-medium text-gray-700">Request</h2>
          <div>
            <label className="mb-1 block text-xs font-medium text-gray-600">
              Title
            </label>
            <input
              name="title"
              required
              minLength={3}
              className="w-full rounded-md border border-gray-300 px-3 py-2 text-sm"
              placeholder="Short summary"
            />
          </div>
          <div>
            <label className="mb-1 block text-xs font-medium text-gray-600">
              Business question
            </label>
            <textarea
              name="business_question"
              required
              minLength={10}
              rows={3}
              className="w-full rounded-md border border-gray-300 px-3 py-2 text-sm"
              placeholder="What question are you trying to answer? What decision will this support?"
            />
          </div>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="mb-1 block text-xs font-medium text-gray-600">
                Usage context
              </label>
              <select
                name="usage_context"
                required
                className="w-full rounded-md border border-gray-300 px-3 py-2 text-sm"
              >
                <option value="regulatory">Regulatory</option>
                <option value="management">Management</option>
                <option value="analytics">Analytics</option>
                <option value="adhoc">Ad hoc</option>
              </select>
            </div>
            <div>
              <label className="mb-1 block text-xs font-medium text-gray-600">
                Consumption pattern
              </label>
              <select
                name="consumption_pattern"
                required
                className="w-full rounded-md border border-gray-300 px-3 py-2 text-sm"
              >
                <option value="report">Report</option>
                <option value="feed">Feed</option>
                <option value="model">Model</option>
                <option value="dashboard">Dashboard</option>
              </select>
            </div>
          </div>
        </section>

        <section className="space-y-3 rounded-lg border bg-white p-6">
          <div className="flex items-start justify-between">
            <div>
              <h2 className="text-sm font-medium text-gray-700">Change items</h2>
              <p className="text-xs text-gray-500">
                Each item is one of: add attribute, change logic, add table,
                delete table.
              </p>
            </div>
            <div className="flex gap-2">
              <label className="cursor-pointer rounded-md border border-gray-300 px-3 py-1.5 text-xs font-medium text-gray-700 hover:bg-gray-50">
                Upload .xlsx
                <input
                  ref={fileInputRef}
                  type="file"
                  accept=".xlsx"
                  onChange={handleExcelChange}
                  className="hidden"
                />
              </label>
              <button
                type="button"
                onClick={handleValidate}
                disabled={validating || items.length === 0}
                className="rounded-md border border-gray-300 px-3 py-1.5 text-xs font-medium text-gray-700 hover:bg-gray-50 disabled:opacity-50"
              >
                {validating ? "Validating…" : "Validate"}
              </button>
            </div>
          </div>

          {items.map((item, i) => (
            <div key={i} className="space-y-2">
              <ChangeLineRow
                index={i}
                value={item}
                onChange={(next) => setItem(i, next)}
                onRemove={() => removeItem(i)}
              />
              {item.classification && (
                <div className="flex flex-wrap items-center gap-2 px-1 text-xs">
                  <ClassificationBadge
                    classification={item.classification}
                    reason={item.classification_reason}
                  />
                  {item.classification_reason && (
                    <span className="text-gray-600">
                      {item.classification_reason}
                    </span>
                  )}
                  {item.existing_sources && item.existing_sources.length > 0 && (
                    <span className="text-gray-500">
                      Sources:{" "}
                      <span className="font-mono">
                        {item.existing_sources.join(", ")}
                      </span>
                    </span>
                  )}
                </div>
              )}
            </div>
          ))}

          <button
            type="button"
            onClick={addItem}
            className="rounded-md border border-dashed border-gray-300 px-3 py-2 text-sm text-gray-600 hover:bg-gray-50"
          >
            + Add change line
          </button>
        </section>

        {error && (
          <div className="rounded-md bg-red-50 p-3 text-sm text-red-800">
            {error}
          </div>
        )}

        {anyClassified && invalidCount > 0 && (
          <div className="rounded-md bg-amber-50 p-3 text-sm text-amber-900">
            {invalidCount} change line{invalidCount === 1 ? "" : "s"} marked
            invalid — fix or remove before submitting.
          </div>
        )}

        <button
          type="submit"
          disabled={submitting}
          className="rounded-md bg-gray-900 px-4 py-2 text-sm font-medium text-white hover:bg-gray-800 disabled:opacity-50"
        >
          {submitting ? "Submitting…" : "Submit request"}
        </button>
      </form>
    </div>
  );
}

function stripClassification(it: ChangeLineClassified): ChangeLineDraft {
  return {
    type: it.type,
    entity: it.entity,
    attribute: it.attribute ?? null,
    table: it.table ?? null,
    source_system: it.source_system ?? null,
    source_table: it.source_table ?? null,
    source_column: it.source_column ?? null,
    new_logic: it.new_logic ?? null,
    business_definition: it.business_definition ?? null,
    data_type: it.data_type ?? null,
  };
}
