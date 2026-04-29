import { useParams } from "react-router-dom";
import { useQuery } from "@tanstack/react-query";
import { WorkflowSwimlane } from "../components/WorkflowSwimlane";
import { ClassificationBadge } from "../components/ClassificationBadge";

type Classification = "exists" | "net_new" | "needs_change" | "invalid";

interface ChangeLine {
  id: string;
  category: string;
  action: string;
  pipeline_layer: string;
  entity: string;
  target_attribute: string | null;
  target_dataset: string | null;
  target_table: string | null;
  target_column: string | null;
  target_data_type: string | null;
  target_nullable: boolean | null;
  source_system: string | null;
  source_dataset: string | null;
  source_table: string | null;
  source_column: string | null;
  transformation_logic: string | null;
  business_definition: string | null;
  rationale: string | null;
  impact_notes: string | null;
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

const ACTION_LABEL: Record<string, string> = {
  add_table: "Add table",
  drop_table: "Drop table",
  add_column: "Add column",
  drop_column: "Drop column",
  modify_column: "Modify column",
  backfill: "Backfill",
  data_correction: "Data correction",
  delete_historical: "Delete historical",
  new_mapping: "New mapping",
  modify_mapping: "Modify mapping",
  modify_transformation: "Modify transformation",
  modify_filter: "Modify filter",
  modify_aggregation: "Modify aggregation",
  modify_join: "Modify join",
};

const CATEGORY_LABEL: Record<string, string> = {
  ddl: "DDL",
  dml: "DML",
  etl_logic: "ETL Logic",
};

const LAYER_LABEL: Record<string, string> = {
  ingestion: "Ingestion",
  transformation: "Transformation",
  provisioning: "Provisioning",
};

function describe(item: ChangeLine): string {
  const parts: string[] = [item.entity];
  if (item.target_attribute) parts.push(item.target_attribute);
  return parts.join(".");
}

function sourcePath(item: ChangeLine): string | null {
  if (!item.source_system) return null;
  return [
    item.source_system,
    item.source_dataset,
    item.source_table,
    item.source_column,
  ]
    .filter(Boolean)
    .join(".");
}

function targetPath(item: ChangeLine): string | null {
  const parts = [item.target_dataset, item.target_table, item.target_column].filter(
    Boolean,
  );
  return parts.length > 0 ? parts.join(".") : null;
}

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
          <ul className="space-y-4">
            {data.items.map((item) => {
              const src = sourcePath(item);
              const tgt = targetPath(item);
              return (
                <li
                  key={item.id}
                  className="rounded-md border border-gray-200 bg-gray-50 p-4"
                >
                  <div className="flex flex-wrap items-center gap-2">
                    <span className="rounded bg-gray-200 px-1.5 py-0.5 text-xs font-medium text-gray-700">
                      {CATEGORY_LABEL[item.category] ?? item.category}
                    </span>
                    <span className="rounded bg-blue-100 px-1.5 py-0.5 text-xs font-medium text-blue-800">
                      {ACTION_LABEL[item.action] ?? item.action}
                    </span>
                    <span className="rounded bg-purple-100 px-1.5 py-0.5 text-xs font-medium text-purple-800">
                      {LAYER_LABEL[item.pipeline_layer] ?? item.pipeline_layer}
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
                    <div className="mt-2 text-xs text-gray-600">
                      {item.classification_reason}
                    </div>
                  )}

                  <div className="mt-3 grid grid-cols-1 gap-2 text-xs md:grid-cols-2">
                    {tgt && (
                      <div>
                        <span className="text-gray-500">Target: </span>
                        <span className="font-mono text-gray-800">{tgt}</span>
                        {item.target_data_type && (
                          <span className="ml-1 text-gray-600">
                            ({item.target_data_type}
                            {item.target_nullable === false ? " NOT NULL" : ""})
                          </span>
                        )}
                      </div>
                    )}
                    {src && (
                      <div>
                        <span className="text-gray-500">Source: </span>
                        <span className="font-mono text-gray-800">{src}</span>
                      </div>
                    )}
                    {item.existing_sources.length > 0 && (
                      <div className="md:col-span-2">
                        <span className="text-gray-500">Existing sources: </span>
                        <span className="font-mono text-gray-700">
                          {item.existing_sources.join(", ")}
                        </span>
                      </div>
                    )}
                  </div>

                  {item.transformation_logic && (
                    <div className="mt-2 rounded-md border border-gray-200 bg-white px-3 py-2 font-mono text-xs text-gray-800">
                      <span className="font-sans font-medium text-gray-600">
                        Transformation:{" "}
                      </span>
                      {item.transformation_logic}
                    </div>
                  )}
                  {item.business_definition && (
                    <div className="mt-2 text-xs text-gray-700">
                      <span className="font-medium text-gray-600">
                        Business definition:{" "}
                      </span>
                      {item.business_definition}
                    </div>
                  )}
                  {item.rationale && (
                    <div className="mt-1 text-xs text-gray-700">
                      <span className="font-medium text-gray-600">Rationale: </span>
                      {item.rationale}
                    </div>
                  )}
                  {item.impact_notes && (
                    <div className="mt-1 text-xs text-gray-700">
                      <span className="font-medium text-gray-600">Impact: </span>
                      {item.impact_notes}
                    </div>
                  )}
                </li>
              );
            })}
          </ul>
        )}
      </section>
    </div>
  );
}
