import { useState } from "react";
import { useNavigate } from "react-router-dom";

// TODO(T-030): replace with generated API client (T-008) once available.
async function createRequest(payload: object) {
  const res = await fetch("/api/v1/requests", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(payload),
  });
  if (!res.ok) throw new Error(`Request failed: ${res.status}`);
  return res.json();
}

export function IntakePage() {
  const nav = useNavigate();
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function handleSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    setSubmitting(true);
    setError(null);
    const formData = new FormData(e.currentTarget);
    try {
      const result = await createRequest({
        title: formData.get("title"),
        business_question: formData.get("business_question"),
        usage_context: formData.get("usage_context"),
        consumption_pattern: formData.get("consumption_pattern"),
        template_id: "default",
      });
      nav(`/requests/${result.id}`);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Unknown error");
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <div className="mx-auto max-w-2xl">
      <h1 className="mb-1 text-2xl font-medium text-gray-900">New request</h1>
      <p className="mb-6 text-sm text-gray-600">
        Tell us what data you need and what you're trying to do with it.
      </p>

      <form onSubmit={handleSubmit} className="space-y-4 rounded-lg border bg-white p-6">
        <div>
          <label className="mb-1 block text-sm font-medium text-gray-700">Title</label>
          <input
            name="title"
            required
            minLength={3}
            className="w-full rounded-md border border-gray-300 px-3 py-2 text-sm"
            placeholder="Short summary of what you need"
          />
        </div>

        <div>
          <label className="mb-1 block text-sm font-medium text-gray-700">Business question</label>
          <textarea
            name="business_question"
            required
            minLength={10}
            rows={4}
            className="w-full rounded-md border border-gray-300 px-3 py-2 text-sm"
            placeholder="What question are you trying to answer? What decision will this support?"
          />
        </div>

        <div className="grid grid-cols-2 gap-4">
          <div>
            <label className="mb-1 block text-sm font-medium text-gray-700">Usage context</label>
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
            <label className="mb-1 block text-sm font-medium text-gray-700">Consumption pattern</label>
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

        {error && (
          <div className="rounded-md bg-red-50 p-3 text-sm text-red-800">{error}</div>
        )}

        <button
          type="submit"
          disabled={submitting}
          className="rounded-md bg-gray-900 px-4 py-2 text-sm font-medium text-white hover:bg-gray-800 disabled:opacity-50"
        >
          {submitting ? "Submitting..." : "Submit request"}
        </button>
      </form>
    </div>
  );
}
