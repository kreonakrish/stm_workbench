import { useMemo, useState } from "react";
import { useQuery } from "@tanstack/react-query";
import {
  Background,
  Controls,
  MiniMap,
  ReactFlow,
  type Edge,
  type Node,
} from "@xyflow/react";
import "@xyflow/react/dist/style.css";

interface PropertySchema {
  name: string;
  indexed: boolean;
  unique: boolean;
}

interface LabelSchema {
  name: string;
  count: number;
  properties: PropertySchema[];
}

interface RelationshipSchema {
  type: string;
  count: number;
  start_labels: string[];
  end_labels: string[];
}

interface OntologySchema {
  labels: LabelSchema[];
  relationships: RelationshipSchema[];
}

async function fetchSchema(): Promise<OntologySchema> {
  const res = await fetch("/api/v1/ontology/schema");
  if (!res.ok) throw new Error(`Failed to fetch ontology schema: ${res.status}`);
  return res.json();
}

function buildGraph(
  data: OntologySchema,
  filter: string,
): { nodes: Node[]; edges: Edge[] } {
  const visible = data.labels.filter((l) =>
    l.name.toLowerCase().includes(filter.toLowerCase()),
  );
  const visibleSet = new Set(visible.map((l) => l.name));
  const cols = Math.max(1, Math.ceil(Math.sqrt(visible.length)));
  const cellW = 220;
  const cellH = 110;

  const nodes: Node[] = visible.map((label, i) => ({
    id: label.name,
    type: "default",
    position: { x: (i % cols) * cellW, y: Math.floor(i / cols) * cellH },
    data: { label: `${label.name}\n${label.count} nodes`, schema: label },
    style: {
      borderRadius: 8,
      border: "1px solid #e5e7eb",
      background: label.count > 0 ? "#eff6ff" : "#f9fafb",
      padding: 8,
      fontSize: 12,
      width: 180,
      whiteSpace: "pre-line",
    },
  }));

  const edges: Edge[] = [];
  for (const rel of data.relationships) {
    for (const s of rel.start_labels) {
      for (const e of rel.end_labels) {
        if (!visibleSet.has(s) || !visibleSet.has(e)) continue;
        edges.push({
          id: `${s}-${rel.type}->${e}`,
          source: s,
          target: e,
          label: rel.type,
          labelStyle: { fontSize: 10, fill: "#6b7280" },
          style: { stroke: "#9ca3af", strokeWidth: 1 },
        });
      }
    }
  }

  return { nodes, edges };
}

function PropertyRow({ p }: { p: PropertySchema }) {
  return (
    <div className="flex items-center justify-between border-b border-gray-100 px-3 py-2 text-sm last:border-b-0">
      <span className="font-mono text-gray-900">{p.name}</span>
      <div className="flex gap-1">
        {p.unique && (
          <span className="rounded bg-blue-50 px-1.5 py-0.5 text-xs text-blue-700">
            unique
          </span>
        )}
        {p.indexed && !p.unique && (
          <span className="rounded bg-gray-100 px-1.5 py-0.5 text-xs text-gray-600">
            indexed
          </span>
        )}
      </div>
    </div>
  );
}

function LabelDrawer({
  label,
  onClose,
}: {
  label: LabelSchema;
  onClose: () => void;
}) {
  return (
    <aside className="w-80 shrink-0 overflow-y-auto rounded-lg border bg-white">
      <div className="flex items-start justify-between border-b px-4 py-3">
        <div>
          <h2 className="text-sm font-medium text-gray-900">{label.name}</h2>
          <p className="text-xs text-gray-500">{label.count} nodes</p>
        </div>
        <button
          type="button"
          onClick={onClose}
          className="text-gray-400 hover:text-gray-600"
          aria-label="Close"
        >
          ×
        </button>
      </div>
      <div className="px-1 py-1">
        {label.properties.length === 0 ? (
          <p className="px-3 py-3 text-xs text-gray-500">
            No indexed properties on this label.
          </p>
        ) : (
          label.properties.map((p) => <PropertyRow key={p.name} p={p} />)
        )}
      </div>
    </aside>
  );
}

export function OntologyPage() {
  const { data, isLoading, error } = useQuery({
    queryKey: ["ontology-schema"],
    queryFn: fetchSchema,
  });
  const [selected, setSelected] = useState<LabelSchema | null>(null);
  const [filter, setFilter] = useState("");

  const graph = useMemo(
    () => (data ? buildGraph(data, filter) : { nodes: [], edges: [] }),
    [data, filter],
  );

  if (isLoading) return <div className="text-sm text-gray-500">Loading ontology…</div>;
  if (error) return <div className="text-sm text-red-600">Error: {String(error)}</div>;
  if (!data) return <div className="text-sm text-gray-500">No schema returned.</div>;

  return (
    <div className="space-y-4">
      <div>
        <h1 className="text-2xl font-medium text-gray-900">Business ontology</h1>
        <p className="text-sm text-gray-600">
          {data.labels.length} entity types, {data.relationships.length} relationship types.
          Filled cells indicate labels with instance data.
        </p>
      </div>
      <div className="flex items-center gap-3">
        <input
          type="search"
          placeholder="Filter labels…"
          value={filter}
          onChange={(e) => setFilter(e.target.value)}
          className="w-64 rounded-md border border-gray-300 px-3 py-1.5 text-sm"
        />
        <span className="text-xs text-gray-500">
          {graph.nodes.length} of {data.labels.length} shown
        </span>
      </div>
      <div className="flex h-[calc(100vh-18rem)] min-h-[500px] gap-4">
        <div className="flex-1 overflow-hidden rounded-lg border bg-white">
          <ReactFlow
            nodes={graph.nodes}
            edges={graph.edges}
            fitView
            onNodeClick={(_, node) => {
              const schema = (node.data as { schema?: LabelSchema }).schema;
              if (schema) setSelected(schema);
            }}
            proOptions={{ hideAttribution: true }}
          >
            <Background gap={16} />
            <Controls showInteractive={false} />
            <MiniMap pannable zoomable />
          </ReactFlow>
        </div>
        {selected && (
          <LabelDrawer label={selected} onClose={() => setSelected(null)} />
        )}
      </div>
    </div>
  );
}
