// TODO(T-033): full Kanban implementation with SSE, drag-and-drop, saved views.
// V1 placeholder: a simple stage-grouped list.

export function JADBoardPage() {
  return (
    <div>
      <h1 className="mb-6 text-2xl font-medium text-gray-900">Board</h1>
      <div className="grid grid-cols-5 gap-4">
        {["Intake", "Discovery", "JAD", "DRB", "STM"].map((stage) => (
          <div key={stage} className="rounded-lg border bg-white p-4">
            <h2 className="mb-3 text-sm font-medium text-gray-700">{stage}</h2>
            <p className="text-xs text-gray-500">No requests yet.</p>
          </div>
        ))}
      </div>
    </div>
  );
}
