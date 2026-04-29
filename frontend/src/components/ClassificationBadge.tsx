type Classification = "exists" | "net_new" | "needs_change" | "invalid";

const STYLES: Record<Classification, { label: string; cls: string }> = {
  exists: { label: "Exists", cls: "bg-green-50 text-green-800 border-green-200" },
  net_new: { label: "Net new", cls: "bg-blue-50 text-blue-800 border-blue-200" },
  needs_change: {
    label: "Needs change",
    cls: "bg-amber-50 text-amber-800 border-amber-200",
  },
  invalid: { label: "Invalid", cls: "bg-red-50 text-red-800 border-red-200" },
};

export function ClassificationBadge({
  classification,
  reason,
}: {
  classification: Classification;
  reason?: string | null;
}) {
  const meta = STYLES[classification];
  return (
    <span
      title={reason ?? undefined}
      className={`inline-flex items-center gap-1 rounded-full border px-2.5 py-0.5 text-xs font-medium ${meta.cls}`}
    >
      {meta.label}
    </span>
  );
}
