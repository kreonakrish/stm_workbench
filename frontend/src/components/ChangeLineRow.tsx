import { useMemo } from "react";
import { useQuery } from "@tanstack/react-query";
import { Combobox, type ComboboxOption } from "./Combobox";

export type ChangeCategory = "ddl" | "dml" | "etl_logic";
export type PipelineLayer = "ingestion" | "transformation" | "provisioning";
export type ChangeAction =
  // DDL
  | "add_table"
  | "drop_table"
  | "add_column"
  | "drop_column"
  | "modify_column"
  // DML
  | "backfill"
  | "data_correction"
  | "delete_historical"
  // ETL Logic
  | "new_mapping"
  | "modify_mapping"
  | "modify_transformation"
  | "modify_filter"
  | "modify_aggregation"
  | "modify_join";

export interface ChangeLineDraft {
  category: ChangeCategory;
  action: ChangeAction;
  pipeline_layer: PipelineLayer;
  entity: string;

  target_attribute?: string | null;
  target_dataset?: string | null;
  target_table?: string | null;
  target_column?: string | null;
  target_data_type?: string | null;
  target_nullable?: boolean | null;

  source_system?: string | null;
  source_dataset?: string | null;
  source_table?: string | null;
  source_column?: string | null;

  transformation_logic?: string | null;
  business_definition?: string | null;
  rationale?: string | null;
  impact_notes?: string | null;
}

export interface ChangeLineClassified extends ChangeLineDraft {
  id?: string;
  classification?: "exists" | "net_new" | "needs_change" | "invalid";
  classification_reason?: string | null;
  catalog_verified?: boolean | null;
  existing_sources?: string[];
}

interface EntityOption {
  name: string;
  description: string | null;
  attribute_count: number;
}

interface AttributeOption {
  id: string;
  name: string;
  description: string | null;
  data_type: string | null;
  pii_classification: string | null;
  is_key: boolean;
}

async function fetchEntities(): Promise<EntityOption[]> {
  const res = await fetch("/api/v1/ontology/entities");
  if (!res.ok) throw new Error("Failed to fetch entities");
  return res.json();
}

async function fetchAttributes(entity: string): Promise<AttributeOption[]> {
  const res = await fetch(
    `/api/v1/ontology/entities/${encodeURIComponent(entity)}/attributes`,
  );
  if (!res.ok) throw new Error("Failed to fetch attributes");
  return res.json();
}

const SOURCE_SYSTEMS = [
  { id: "oracle_loan_prod", label: "Oracle Loan Prod" },
  { id: "snowflake_analytics", label: "Snowflake Analytics" },
  { id: "mysql_servicing", label: "MySQL Servicing" },
  { id: "s3_loan_lake", label: "S3 Loan Lake" },
  { id: "glue_catalog_prod", label: "AWS Glue (Prod)" },
  { id: "sql_server_origination", label: "SQL Server Origination" },
];

const ACTIONS_BY_CATEGORY: Record<ChangeCategory, ChangeAction[]> = {
  ddl: ["add_table", "drop_table", "add_column", "drop_column", "modify_column"],
  dml: ["backfill", "data_correction", "delete_historical"],
  etl_logic: [
    "new_mapping",
    "modify_mapping",
    "modify_transformation",
    "modify_filter",
    "modify_aggregation",
    "modify_join",
  ],
};

const ACTION_LABEL: Record<ChangeAction, string> = {
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

// --- Conditional-display helpers per action ---
function showsTargetAttribute(a: ChangeAction): boolean {
  return a !== "add_table" && a !== "drop_table";
}
function showsTargetTable(a: ChangeAction): boolean {
  return a !== "new_mapping" && a !== "modify_mapping";
}
function showsTargetDataType(a: ChangeAction): boolean {
  return a === "add_column" || a === "modify_column";
}
function showsTransformationLogic(a: ChangeAction): boolean {
  return (
    a === "new_mapping" ||
    a === "modify_mapping" ||
    a === "modify_transformation" ||
    a === "modify_filter" ||
    a === "modify_aggregation" ||
    a === "modify_join"
  );
}
function showsSourceSide(a: ChangeAction): boolean {
  return (
    a === "add_column" ||
    a === "modify_column" ||
    a === "add_table" ||
    a === "new_mapping" ||
    a === "modify_mapping" ||
    a === "modify_transformation" ||
    a === "modify_filter" ||
    a === "modify_aggregation" ||
    a === "modify_join" ||
    a === "backfill" ||
    a === "data_correction"
  );
}
function showsBusinessDefinition(a: ChangeAction): boolean {
  return a === "add_column" || a === "new_mapping";
}

interface Props {
  index: number;
  value: ChangeLineClassified;
  onChange: (next: ChangeLineClassified) => void;
  onRemove: () => void;
}

export function ChangeLineRow({ index, value, onChange, onRemove }: Props) {
  const entitiesQuery = useQuery({
    queryKey: ["ontology-entities"],
    queryFn: fetchEntities,
  });
  const attributesQuery = useQuery({
    queryKey: ["ontology-attributes", value.entity],
    queryFn: () => fetchAttributes(value.entity),
    enabled: Boolean(value.entity),
  });

  const entityOptions = useMemo<ComboboxOption[]>(
    () =>
      (entitiesQuery.data ?? []).map((e) => ({
        value: e.name,
        description: e.description ?? `${e.attribute_count} attributes`,
        badge: `${e.attribute_count}`,
      })),
    [entitiesQuery.data],
  );
  const attributeOptions = useMemo<ComboboxOption[]>(
    () =>
      (attributesQuery.data ?? []).map((a) => ({
        value: a.name,
        description:
          a.description ?? a.data_type ?? a.pii_classification ?? null,
        badge: a.is_key ? "key" : (a.data_type ?? undefined),
      })),
    [attributesQuery.data],
  );

  function update<K extends keyof ChangeLineClassified>(
    key: K,
    v: ChangeLineClassified[K],
  ) {
    onChange({ ...value, [key]: v });
  }

  function changeCategory(next: ChangeCategory) {
    // Auto-pick the first valid action for the new category if the
    // current action would be inconsistent.
    const validActions = ACTIONS_BY_CATEGORY[next];
    const action = validActions.includes(value.action)
      ? value.action
      : validActions[0];
    onChange({ ...value, category: next, action });
  }

  return (
    <div className="rounded-lg border border-gray-200 bg-white p-4">
      <div className="mb-3 flex items-center justify-between">
        <span className="text-xs font-medium uppercase tracking-wide text-gray-500">
          Change line #{index + 1}
        </span>
        <button
          type="button"
          onClick={onRemove}
          className="text-xs text-gray-400 hover:text-red-600"
        >
          Remove
        </button>
      </div>

      <div className="grid grid-cols-1 gap-3 md:grid-cols-3">
        <div>
          <label className="mb-1 block text-xs font-medium text-gray-600">
            Category
          </label>
          <select
            value={value.category}
            onChange={(e) => changeCategory(e.target.value as ChangeCategory)}
            className="w-full rounded-md border border-gray-300 px-3 py-1.5 text-sm"
          >
            <option value="ddl">DDL — Schema</option>
            <option value="dml">DML — Data</option>
            <option value="etl_logic">ETL Logic</option>
          </select>
        </div>
        <div>
          <label className="mb-1 block text-xs font-medium text-gray-600">
            Action
          </label>
          <select
            value={value.action}
            onChange={(e) => update("action", e.target.value as ChangeAction)}
            className="w-full rounded-md border border-gray-300 px-3 py-1.5 text-sm"
          >
            {ACTIONS_BY_CATEGORY[value.category].map((a) => (
              <option key={a} value={a}>
                {ACTION_LABEL[a]}
              </option>
            ))}
          </select>
        </div>
        <div>
          <label className="mb-1 block text-xs font-medium text-gray-600">
            Pipeline layer
          </label>
          <select
            value={value.pipeline_layer}
            onChange={(e) =>
              update("pipeline_layer", e.target.value as PipelineLayer)
            }
            className="w-full rounded-md border border-gray-300 px-3 py-1.5 text-sm"
          >
            <option value="ingestion">Ingestion</option>
            <option value="transformation">Transformation</option>
            <option value="provisioning">Provisioning</option>
          </select>
        </div>
      </div>

      <div className="mt-3 grid grid-cols-1 gap-3 md:grid-cols-2">
        <div>
          <label className="mb-1 block text-xs font-medium text-gray-600">
            Business entity
          </label>
          <Combobox
            value={value.entity}
            onChange={(v) => update("entity", v)}
            options={entityOptions}
            placeholder="Pick an entity (Borrower, MortgageLoan, …) or add new"
            emptyMessage="No matching entity"
          />
        </div>

        {showsTargetAttribute(value.action) && (
          <div>
            <label className="mb-1 block text-xs font-medium text-gray-600">
              Target attribute (business)
            </label>
            <Combobox
              value={value.target_attribute ?? ""}
              onChange={(v) => update("target_attribute", v || null)}
              options={attributeOptions}
              placeholder={
                value.entity
                  ? `Pick a ${value.entity} attribute or add new`
                  : "Pick the entity first"
              }
              emptyMessage={
                value.entity
                  ? `No attributes seeded for ${value.entity} yet`
                  : "Pick the entity first"
              }
              disabled={!value.entity}
            />
          </div>
        )}
      </div>

      {/* TARGET (physical) */}
      <fieldset className="mt-4 rounded-md border border-gray-200 p-3">
        <legend className="px-1 text-xs font-medium uppercase tracking-wide text-gray-500">
          Target (physical)
        </legend>
        <div className="grid grid-cols-1 gap-3 md:grid-cols-3">
          <div>
            <label className="mb-1 block text-xs text-gray-600">
              Target dataset
            </label>
            <input
              value={value.target_dataset ?? ""}
              onChange={(e) =>
                update("target_dataset", e.target.value || null)
              }
              placeholder="curated.borrower"
              className="w-full rounded-md border border-gray-300 px-3 py-1.5 text-sm"
            />
          </div>
          {showsTargetTable(value.action) && (
            <div>
              <label className="mb-1 block text-xs text-gray-600">
                Target table
              </label>
              <input
                value={value.target_table ?? ""}
                onChange={(e) =>
                  update("target_table", e.target.value || null)
                }
                placeholder="BORROWER"
                className="w-full rounded-md border border-gray-300 px-3 py-1.5 text-sm"
              />
            </div>
          )}
          {(value.action === "add_column" ||
            value.action === "drop_column" ||
            value.action === "modify_column") && (
            <div>
              <label className="mb-1 block text-xs text-gray-600">
                Target column
              </label>
              <input
                value={value.target_column ?? ""}
                onChange={(e) =>
                  update("target_column", e.target.value || null)
                }
                placeholder="CURRENT_FICO_SCORE"
                className="w-full rounded-md border border-gray-300 px-3 py-1.5 text-sm"
              />
            </div>
          )}
          {showsTargetDataType(value.action) && (
            <>
              <div>
                <label className="mb-1 block text-xs text-gray-600">
                  Target data type
                </label>
                <input
                  value={value.target_data_type ?? ""}
                  onChange={(e) =>
                    update("target_data_type", e.target.value || null)
                  }
                  placeholder="VARCHAR(120) / NUMBER(3) / DECIMAL(12,2) / DATE / …"
                  className="w-full rounded-md border border-gray-300 px-3 py-1.5 text-sm"
                />
              </div>
              <div>
                <label className="mb-1 flex items-center gap-2 text-xs text-gray-600">
                  <input
                    type="checkbox"
                    checked={value.target_nullable === true}
                    onChange={(e) =>
                      update("target_nullable", e.target.checked)
                    }
                  />
                  Nullable
                </label>
              </div>
            </>
          )}
        </div>
      </fieldset>

      {/* SOURCE (physical) */}
      {showsSourceSide(value.action) && (
        <fieldset className="mt-3 rounded-md border border-gray-200 p-3">
          <legend className="px-1 text-xs font-medium uppercase tracking-wide text-gray-500">
            Source (physical)
          </legend>
          <div className="grid grid-cols-1 gap-3 md:grid-cols-2">
            <div>
              <label className="mb-1 block text-xs text-gray-600">
                Source system
              </label>
              <select
                value={value.source_system ?? ""}
                onChange={(e) =>
                  update("source_system", e.target.value || null)
                }
                className="w-full rounded-md border border-gray-300 px-3 py-1.5 text-sm"
              >
                <option value="">—</option>
                {SOURCE_SYSTEMS.map((s) => (
                  <option key={s.id} value={s.id}>
                    {s.label}
                  </option>
                ))}
              </select>
            </div>
            <div>
              <label className="mb-1 block text-xs text-gray-600">
                Source dataset / schema
              </label>
              <input
                value={value.source_dataset ?? ""}
                onChange={(e) =>
                  update("source_dataset", e.target.value || null)
                }
                placeholder="LOAN_DB / ANALYTICS"
                className="w-full rounded-md border border-gray-300 px-3 py-1.5 text-sm"
              />
            </div>
            <div>
              <label className="mb-1 block text-xs text-gray-600">
                Source table
              </label>
              <input
                value={value.source_table ?? ""}
                onChange={(e) =>
                  update("source_table", e.target.value || null)
                }
                placeholder="BORROWER"
                className="w-full rounded-md border border-gray-300 px-3 py-1.5 text-sm"
              />
            </div>
            <div>
              <label className="mb-1 block text-xs text-gray-600">
                Source column
              </label>
              <input
                value={value.source_column ?? ""}
                onChange={(e) =>
                  update("source_column", e.target.value || null)
                }
                placeholder="FICO_SCORE"
                className="w-full rounded-md border border-gray-300 px-3 py-1.5 text-sm"
              />
            </div>
          </div>
        </fieldset>
      )}

      {/* LOGIC */}
      {showsTransformationLogic(value.action) && (
        <div className="mt-3">
          <label className="mb-1 block text-xs font-medium text-gray-600">
            Transformation logic
          </label>
          <textarea
            value={value.transformation_logic ?? ""}
            onChange={(e) =>
              update("transformation_logic", e.target.value || null)
            }
            rows={3}
            placeholder="Pseudo-SQL or business rule, e.g. CASE WHEN fico < 620 THEN 'subprime' ELSE 'prime' END"
            className="w-full rounded-md border border-gray-300 px-3 py-1.5 font-mono text-sm"
          />
        </div>
      )}

      {showsBusinessDefinition(value.action) && (
        <div className="mt-3">
          <label className="mb-1 block text-xs font-medium text-gray-600">
            Business definition
          </label>
          <textarea
            value={value.business_definition ?? ""}
            onChange={(e) =>
              update("business_definition", e.target.value || null)
            }
            rows={2}
            placeholder="What does this attribute mean to the business?"
            className="w-full rounded-md border border-gray-300 px-3 py-1.5 text-sm"
          />
        </div>
      )}

      {/* RATIONALE + IMPACT */}
      <div className="mt-3 grid grid-cols-1 gap-3 md:grid-cols-2">
        <div>
          <label className="mb-1 block text-xs font-medium text-gray-600">
            Rationale
            {(value.action === "backfill" ||
              value.action === "data_correction" ||
              value.action === "delete_historical") && (
              <span className="ml-1 text-red-600">*</span>
            )}
          </label>
          <textarea
            value={value.rationale ?? ""}
            onChange={(e) => update("rationale", e.target.value || null)}
            rows={2}
            placeholder="Why is this change needed?"
            className="w-full rounded-md border border-gray-300 px-3 py-1.5 text-sm"
          />
        </div>
        <div>
          <label className="mb-1 block text-xs font-medium text-gray-600">
            Impact notes
          </label>
          <textarea
            value={value.impact_notes ?? ""}
            onChange={(e) =>
              update("impact_notes", e.target.value || null)
            }
            rows={2}
            placeholder="Downstream consumers, dashboards, models affected"
            className="w-full rounded-md border border-gray-300 px-3 py-1.5 text-sm"
          />
        </div>
      </div>
    </div>
  );
}
