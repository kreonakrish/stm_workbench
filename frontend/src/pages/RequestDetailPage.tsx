import { useParams } from "react-router-dom";
import { useQuery } from "@tanstack/react-query";
import { WorkflowSwimlane } from "../components/WorkflowSwimlane";
import { ClassificationBadge } from "../components/ClassificationBadge";

type Classification = "exists" | "net_new" | "needs_change" | "invalid";

interface ChangeLine {
  id: string;
  type: string;
  entity: string;
  attribute: string | null;
  table: string | null;
  source_system: string | null;
  source_table: string | null;
  source_column: string | null;
  new_logic: string | null;
  business_definition: string | null;
  data_type: string | null;
  classification: Classification;
  classification_reason: string | null;
  catalog_verified: boolean | null;
  existing_sources: string[];
}

interface Request {
  id: string;
  title: string;
  business_question: string;
  usage_context: string;
  consumption_pattern: string;
  current_stage_id: string;
  current_stage_name: string;
  created_at: string;
  items: ChangeLine[];
}

async function fetchRequest(id: string): Promise<Request> {
  const res = await fetch(`/api/v1/requests/${id}`);
  if (!res.ok) throw new Error(`Failed to fetch request: ${res.status}`);
  return res.json();
}

function describe(item: ChangeLine): string {
  if (item.type === "add_attribute" || item.type === "change_logic") {
    return item.attribute
      ? `${item.entity}.${item.attribute}`
      : item.entity;
  }
  if (item.type === "add_table" || item.type === "delete_table") {
    return item.table ? `${item.entity} :: ${item.table}` : item.entity;
  }
  return item.entity;
}

const TYPE_LABEL: Record<string, string> = {
  add_attribute: "Add attribute",
  change_logic: "Change logic",
  add_table: "Add table",
  delete_table: "Delete table",
};

export function RequestDetailPage() {
  const { id } = useParams<{ id: string }>();
  const { data, isLoading, error } = useQuery({
    queryKey: ["request", id],
    queryFn: () => fetchRequest(id!),
    enabled: Boolean(id),
  });

  if (isLoading) return <div className="text-sm text-gray-500">Loading...</div>;
  if (error) return <div className="text-sm text-red-600">Error: {String(error)}</div>;
  if (!data) return <div className="text-sm text-gray-500">Not found.</div>;

  return (
    <div className="mx-auto max-w-5xl space-y-6">
      <div>
        <div className="mb-2 text-xs uppercase tracking-wide text-gray-500">
          Stage: {data.current_stage_name}
        </div>
        <h1 className="text-2xl font-medium text-gray-900">{data.title}</h1>
      </div>

      <section className="rounded-lg border bg-white p-6">
        <h2 className="mb-4 text-sm font-medium text-gray-700">Workflow</h2>
        <WorkflowSwimlane
          templateId="default"
          currentStageId={data.current_stage_id}
        />
      </section>

      <section className="rounded-lg border bg-white p-6">
        <h2 className="mb-2 text-sm font-medium text-gray-700">Business question</h2>
        <p className="mb-6 text-sm text-gray-900">{data.business_question}</p>

        <div className="grid grid-cols-2 gap-4 text-sm">
          <div>
            <div className="text-gray-500">Usage context</div>
            <div className="text-gray-900">{data.usage_context}</div>
          </div>
          <div>
            <div className="text-gray-500">Consumption pattern</div>
            <div className="text-gray-900">{data.consumption_pattern}</div>
          </div>
        </div>
      </section>

      <section className="rounded-lg border bg-white p-6">
        <h2 className="mb-4 text-sm font-medium text-gray-700">
          Change items ({data.items.length})
        </h2>
        {data.items.length === 0 ? (
          <p className="text-sm text-gray-500">No structured items submitted.</p>
        ) : (
          <ul className="divide-y divide-gray-100">
            {data.items.map((item) => (
              <li key={item.id} className="py-3">
                <div className="flex flex-wrap items-center gap-2">
                  <span className="text-xs uppercase tracking-wide text-gray-500">
                    {TYPE_LABEL[item.type] ?? item.type}
                  </span>
                  <span className="font-mono text-sm text-gray-900">
                    {describe(item)}
                  </span>
                  <ClassificationBadge
                    classification={item.classification}
                    reason={item.classification_reason}
                  />
                  {item.catalog_verified === true && (
                    <span className="rounded-full bg-green-50 px-2 py-0.5 text-xs text-green-700">
                      Catalog verified
                    </span>
                  )}
                  {item.catalog_verified === false && (
                    <span className="rounded-full bg-red-50 px-2 py-0.5 text-xs text-red-700">
                      Catalog mismatch
                    </span>
                  )}
                </div>
                {item.classification_reason && (
                  <div className="mt-1 text-xs text-gray-600">
                    {item.classification_reason}
                  </div>
                )}
                {item.new_logic && (
                  <div className="mt-1 rounded-md bg-gray-50 px-3 py-2 text-xs text-gray-700">
                    <span className="font-medium">Proposed logic:</span>{" "}
                    {item.new_logic}
                  </div>
                )}
                {item.existing_sources.length > 0 && (
                  <div className="mt-1 text-xs text-gray-500">
                    Sources:{" "}
                    <span className="font-mono">
                      {item.existing_sources.join(", ")}
                    </span>
                  </div>
                )}
              </li>
            ))}
          </ul>
        )}
      </section>
    </div>
  );
}
