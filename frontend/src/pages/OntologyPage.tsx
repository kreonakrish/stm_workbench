import { useMemo, useState } from "react";
import { useQuery } from "@tanstack/react-query";

interface PhysicalSource {
  system_id: string;
  system_name: string | null;
  system_kind: string | null;
  schema: string | null;
  table: string | null;
  column: string | null;
  column_id: string;
  data_type: string | null;
}

interface BusinessAttribute {
  id: string;
  name: string;
  description: string | null;
  data_type: string | null;
  pii_classification: string | null;
  is_key: boolean;
  sources: PhysicalSource[];
}

interface EntityCatalogEntry {
  name: string;
  description: string | null;
  attribute_count: number;
  attributes: BusinessAttribute[];
}

async function fetchCatalog(): Promise<EntityCatalogEntry[]> {
  const res = await fetch("/api/v1/ontology/catalog");
  if (!res.ok) throw new Error(`Failed to fetch catalog: ${res.status}`);
  return res.json();
}

const SYSTEM_KIND_BADGE: Record<string, string> = {
  oracle: "bg-red-50 text-red-800 border-red-200",
  mysql: "bg-orange-50 text-orange-800 border-orange-200",
  snowflake: "bg-sky-50 text-sky-800 border-sky-200",
  sql_server: "bg-indigo-50 text-indigo-800 border-indigo-200",
  glue: "bg-amber-50 text-amber-800 border-amber-200",
  s3: "bg-emerald-50 text-emerald-800 border-emerald-200",
};

function PiiPill({ kind }: { kind: string | null }) {
  if (!kind || kind === "NONE") return null;
  const colour =
    kind === "RESTRICTED"
      ? "bg-red-50 text-red-800"
      : kind === "INTERNAL"
        ? "bg-yellow-50 text-yellow-800"
        : "bg-gray-100 text-gray-700";
  return (
    <span className={`rounded px-1.5 py-0.5 text-[10px] font-medium ${colour}`}>
      {kind}
    </span>
  );
}

function SystemPill({ kind, label }: { kind: string | null; label: string }) {
  const cls = (kind && SYSTEM_KIND_BADGE[kind]) ?? "bg-gray-50 text-gray-700 border-gray-200";
  return (
    <span className={`inline-flex items-center rounded border px-1.5 py-0.5 text-[10px] font-medium ${cls}`}>
      {label}
    </span>
  );
}

function SourcesTable({ sources }: { sources: PhysicalSource[] }) {
  if (sources.length === 0) {
    return (
      <div className="px-4 py-3 text-xs text-gray-500">
        No physical sources mapped yet. Run the crawler to discover columns.
      </div>
    );
  }
  return (
    <div className="overflow-hidden">
      <table className="w-full text-xs">
        <thead>
          <tr className="bg-gray-50 text-gray-600">
            <th className="px-4 py-1.5 text-left font-medium">System</th>
            <th className="px-4 py-1.5 text-left font-medium">Schema</th>
            <th className="px-4 py-1.5 text-left font-medium">Table</th>
            <th className="px-4 py-1.5 text-left font-medium">Column</th>
            <th className="px-4 py-1.5 text-left font-medium">Type</th>
          </tr>
        </thead>
        <tbody>
          {sources.map((s) => (
            <tr key={s.column_id} className="border-t border-gray-100">
              <td className="px-4 py-1.5">
                <SystemPill kind={s.system_kind} label={s.system_name ?? s.system_id} />
              </td>
              <td className="px-4 py-1.5 font-mono text-gray-700">{s.schema ?? "—"}</td>
              <td className="px-4 py-1.5 font-mono text-gray-700">{s.table ?? "—"}</td>
              <td className="px-4 py-1.5 font-mono text-gray-900">{s.column ?? "—"}</td>
              <td className="px-4 py-1.5 font-mono text-gray-600">{s.data_type ?? "—"}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

function AttributeRow({ attr }: { attr: BusinessAttribute }) {
  const [open, setOpen] = useState(false);
  const sourceCount = attr.sources.length;
  const systems = useMemo(
    () => Array.from(new Set(attr.sources.map((s) => s.system_id))),
    [attr.sources],
  );

  return (
    <>
      <tr
        className="cursor-pointer border-t border-gray-100 hover:bg-gray-50"
        onClick={() => setOpen((o) => !o)}
      >
        <td className="px-4 py-2 align-top">
          <span className="text-gray-400">{open ? "▾" : "▸"}</span>
        </td>
        <td className="px-4 py-2 align-top font-mono text-sm text-gray-900">
          {attr.name}
          {attr.is_key && (
            <span className="ml-2 rounded bg-blue-50 px-1.5 py-0.5 text-[10px] font-medium text-blue-700">
              key
            </span>
          )}
        </td>
        <td className="px-4 py-2 align-top">
          <span className="font-mono text-xs text-gray-600">{attr.data_type ?? "—"}</span>
        </td>
        <td className="px-4 py-2 align-top">
          <PiiPill kind={attr.pii_classification} />
        </td>
        <td className="px-4 py-2 align-top">
          <div className="flex flex-wrap items-center gap-1">
            {sourceCount === 0 ? (
              <span className="text-xs text-gray-400">— no sources</span>
            ) : (
              <>
                <span className="text-xs text-gray-600">
                  {sourceCount} in {systems.length} system{systems.length === 1 ? "" : "s"}
                </span>
                {systems.slice(0, 3).map((sid) => (
                  <SystemPill key={sid} kind={null} label={sid} />
                ))}
              </>
            )}
          </div>
        </td>
        <td className="px-4 py-2 align-top text-xs text-gray-600">
          {attr.description ?? ""}
        </td>
      </tr>
      {open && (
        <tr>
          <td colSpan={6} className="bg-gray-50 px-0 py-0">
            <SourcesTable sources={attr.sources} />
          </td>
        </tr>
      )}
    </>
  );
}

export function OntologyPage() {
  const { data, isLoading, error } = useQuery({
    queryKey: ["ontology-catalog"],
    queryFn: fetchCatalog,
  });
  const [filter, setFilter] = useState("");
  const [selected, setSelected] = useState<string | null>(null);

  if (isLoading) return <div className="text-sm text-gray-500">Loading catalog…</div>;
  if (error) return <div className="text-sm text-red-600">Error: {String(error)}</div>;
  if (!data) return <div className="text-sm text-gray-500">No data.</div>;

  const term = filter.trim().toLowerCase();

  // Filter entities by name or any attribute match
  const filtered = data.filter((entity) => {
    if (!term) return true;
    if (entity.name.toLowerCase().includes(term)) return true;
    return entity.attributes.some(
      (a) =>
        a.name.toLowerCase().includes(term) ||
        (a.description && a.description.toLowerCase().includes(term)),
    );
  });

  const activeEntity =
    filtered.find((e) => e.name === selected) ?? filtered[0] ?? null;

  // When filtering, narrow the attributes inside the active entity too.
  const visibleAttributes = activeEntity
    ? activeEntity.attributes.filter(
        (a) =>
          !term ||
          a.name.toLowerCase().includes(term) ||
          (a.description && a.description.toLowerCase().includes(term)) ||
          activeEntity.name.toLowerCase().includes(term),
      )
    : [];

  const totalAttributes = data.reduce((acc, e) => acc + e.attribute_count, 0);
  const totalEntities = data.length;

  return (
    <div className="space-y-4">
      <div>
        <h1 className="text-2xl font-medium text-gray-900">Business ontology</h1>
        <p className="text-sm text-gray-600">
          {totalEntities} entities, {totalAttributes} curated attributes. Each
          attribute lists every physical source — across Oracle / Snowflake /
          MySQL / S3 / Glue / SQL Server — the catalog has discovered.
        </p>
      </div>

      <input
        type="search"
        placeholder="Filter by entity, attribute name, or description…"
        value={filter}
        onChange={(e) => setFilter(e.target.value)}
        className="w-full max-w-lg rounded-md border border-gray-300 px-3 py-2 text-sm"
      />

      <div className="grid grid-cols-1 gap-4 lg:grid-cols-[260px_1fr]">
        <aside className="rounded-lg border bg-white">
          <div className="border-b px-3 py-2 text-xs font-medium uppercase tracking-wide text-gray-500">
            Entities ({filtered.length})
          </div>
          <ul className="max-h-[70vh] overflow-y-auto">
            {filtered.map((e) => {
              const isActive = activeEntity && e.name === activeEntity.name;
              return (
                <li key={e.name}>
                  <button
                    type="button"
                    onClick={() => setSelected(e.name)}
                    className={`flex w-full items-center justify-between px-3 py-2 text-left text-sm hover:bg-gray-50 ${
                      isActive ? "bg-blue-50 text-blue-900" : "text-gray-800"
                    }`}
                  >
                    <span className="truncate">{e.name}</span>
                    <span className="text-xs text-gray-500">{e.attribute_count}</span>
                  </button>
                </li>
              );
            })}
            {filtered.length === 0 && (
              <li className="px-3 py-2 text-xs text-gray-500">No matches.</li>
            )}
          </ul>
        </aside>

        <main className="rounded-lg border bg-white">
          {!activeEntity ? (
            <div className="px-4 py-6 text-sm text-gray-500">
              Select an entity to see its attributes.
            </div>
          ) : (
            <>
              <div className="border-b px-4 py-3">
                <h2 className="text-base font-medium text-gray-900">
                  {activeEntity.name}
                </h2>
                {activeEntity.description && (
                  <p className="text-xs text-gray-600">{activeEntity.description}</p>
                )}
                <p className="mt-1 text-xs text-gray-500">
                  {visibleAttributes.length} attribute
                  {visibleAttributes.length === 1 ? "" : "s"} shown
                  {term && visibleAttributes.length !== activeEntity.attribute_count
                    ? ` of ${activeEntity.attribute_count}`
                    : ""}
                </p>
              </div>
              <div className="overflow-x-auto">
                <table className="w-full text-sm">
                  <thead>
                    <tr className="bg-gray-50 text-xs uppercase tracking-wide text-gray-500">
                      <th className="w-8 px-4 py-2"></th>
                      <th className="px-4 py-2 text-left font-medium">Attribute</th>
                      <th className="px-4 py-2 text-left font-medium">Type</th>
                      <th className="px-4 py-2 text-left font-medium">PII</th>
                      <th className="px-4 py-2 text-left font-medium">Sources</th>
                      <th className="px-4 py-2 text-left font-medium">Description</th>
                    </tr>
                  </thead>
                  <tbody>
                    {visibleAttributes.length === 0 ? (
                      <tr>
                        <td
                          colSpan={6}
                          className="px-4 py-6 text-center text-xs text-gray-500"
                        >
                          No attributes match the current filter.
                        </td>
                      </tr>
                    ) : (
                      visibleAttributes.map((a) => (
                        <AttributeRow key={a.id} attr={a} />
                      ))
                    )}
                  </tbody>
                </table>
              </div>
            </>
          )}
        </main>
      </div>
    </div>
  );
}
