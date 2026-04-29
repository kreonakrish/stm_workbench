import { useEffect, useState } from "react";
import { useQuery } from "@tanstack/react-query";

export type ChangeType =
  | "add_attribute"
  | "change_logic"
  | "add_table"
  | "delete_table";

export interface ChangeLineDraft {
  type: ChangeType;
  entity: string;
  attribute?: string | null;
  table?: string | null;
  source_system?: string | null;
  source_table?: string | null;
  source_column?: string | null;
  new_logic?: string | null;
  business_definition?: string | null;
  data_type?: string | null;
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

interface Props {
  index: number;
  value: ChangeLineClassified;
  onChange: (next: ChangeLineClassified) => void;
  onRemove: () => void;
}

export function ChangeLineRow({ index, value, onChange, onRemove }: Props) {
  const [entityQuery, setEntityQuery] = useState(value.entity ?? "");
  useEffect(() => {
    setEntityQuery(value.entity ?? "");
  }, [value.entity]);

  const entitiesQuery = useQuery({
    queryKey: ["ontology-entities"],
    queryFn: fetchEntities,
  });

  const attributesQuery = useQuery({
    queryKey: ["ontology-attributes", value.entity],
    queryFn: () => fetchAttributes(value.entity),
    enabled: Boolean(value.entity),
  });

  function update<K extends keyof ChangeLineClassified>(
    key: K,
    v: ChangeLineClassified[K],
  ) {
    onChange({ ...value, [key]: v });
  }

  const showAttribute =
    value.type === "add_attribute" || value.type === "change_logic";
  const showTable = value.type === "add_table" || value.type === "delete_table";
  const showLogic = value.type === "change_logic";
  const showAddAttrFields = value.type === "add_attribute";

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

      <div className="grid grid-cols-1 gap-3 md:grid-cols-2">
        <div>
          <label className="mb-1 block text-xs font-medium text-gray-600">
            Type
          </label>
          <select
            value={value.type}
            onChange={(e) => update("type", e.target.value as ChangeType)}
            className="w-full rounded-md border border-gray-300 px-3 py-1.5 text-sm"
          >
            <option value="add_attribute">Add attribute</option>
            <option value="change_logic">Change logic</option>
            <option value="add_table">Add table</option>
            <option value="delete_table">Delete table</option>
          </select>
        </div>

        <div>
          <label className="mb-1 block text-xs font-medium text-gray-600">
            Entity
          </label>
          <input
            list={`entity-list-${index}`}
            value={entityQuery}
            onChange={(e) => {
              setEntityQuery(e.target.value);
              update("entity", e.target.value);
            }}
            placeholder="Borrower, MortgageLoan, …"
            className="w-full rounded-md border border-gray-300 px-3 py-1.5 text-sm"
          />
          <datalist id={`entity-list-${index}`}>
            {(entitiesQuery.data ?? []).map((e) => (
              <option key={e.name} value={e.name}>
                {e.description ?? ""}
              </option>
            ))}
          </datalist>
        </div>

        {showAttribute && (
          <div>
            <label className="mb-1 block text-xs font-medium text-gray-600">
              Attribute
            </label>
            <input
              list={`attribute-list-${index}`}
              value={value.attribute ?? ""}
              onChange={(e) => update("attribute", e.target.value)}
              placeholder="ssn, current_fico_score, …"
              className="w-full rounded-md border border-gray-300 px-3 py-1.5 text-sm"
            />
            <datalist id={`attribute-list-${index}`}>
              {(attributesQuery.data ?? []).map((a) => (
                <option key={a.id} value={a.name}>
                  {a.description ?? a.data_type ?? ""}
                </option>
              ))}
            </datalist>
          </div>
        )}

        {showTable && (
          <div>
            <label className="mb-1 block text-xs font-medium text-gray-600">
              Table
            </label>
            <input
              value={value.table ?? ""}
              onChange={(e) => update("table", e.target.value)}
              placeholder="BORROWER, LOAN, …"
              className="w-full rounded-md border border-gray-300 px-3 py-1.5 text-sm"
            />
          </div>
        )}

        {showAddAttrFields && (
          <div>
            <label className="mb-1 block text-xs font-medium text-gray-600">
              Data type
            </label>
            <input
              value={value.data_type ?? ""}
              onChange={(e) => update("data_type", e.target.value)}
              placeholder="string / decimal / integer / date / …"
              className="w-full rounded-md border border-gray-300 px-3 py-1.5 text-sm"
            />
          </div>
        )}
      </div>

      {showAddAttrFields && (
        <div className="mt-3 grid grid-cols-1 gap-3 md:grid-cols-3">
          <div>
            <label className="mb-1 block text-xs font-medium text-gray-600">
              Source system (optional)
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
            <label className="mb-1 block text-xs font-medium text-gray-600">
              Source table (optional)
            </label>
            <input
              value={value.source_table ?? ""}
              onChange={(e) =>
                update("source_table", e.target.value || null)
              }
              placeholder="schema.TABLE"
              className="w-full rounded-md border border-gray-300 px-3 py-1.5 text-sm"
            />
          </div>
          <div>
            <label className="mb-1 block text-xs font-medium text-gray-600">
              Source column (optional)
            </label>
            <input
              value={value.source_column ?? ""}
              onChange={(e) =>
                update("source_column", e.target.value || null)
              }
              placeholder="column name"
              className="w-full rounded-md border border-gray-300 px-3 py-1.5 text-sm"
            />
          </div>
        </div>
      )}

      {showLogic && (
        <div className="mt-3">
          <label className="mb-1 block text-xs font-medium text-gray-600">
            New logic
          </label>
          <textarea
            value={value.new_logic ?? ""}
            onChange={(e) => update("new_logic", e.target.value)}
            rows={2}
            placeholder="Describe the proposed logic change"
            className="w-full rounded-md border border-gray-300 px-3 py-1.5 text-sm"
          />
        </div>
      )}

      {showAddAttrFields && (
        <div className="mt-3">
          <label className="mb-1 block text-xs font-medium text-gray-600">
            Business definition (optional)
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
    </div>
  );
}
