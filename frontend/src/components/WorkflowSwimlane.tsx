import { useQuery } from "@tanstack/react-query";

interface StageDefinition {
  id: string;
  name: string;
  is_initial: boolean;
  is_terminal: boolean;
  allowed_actors: string[];
  order: number;
}

interface TransitionDefinition {
  id: string;
  from_stage_id: string;
  to_stage_id: string;
}

interface WorkflowTemplate {
  id: string;
  name: string;
  version: number;
  stages: StageDefinition[];
  transitions: TransitionDefinition[];
}

async function fetchTemplate(templateId: string): Promise<WorkflowTemplate> {
  const res = await fetch(`/api/v1/templates/${templateId}`);
  if (!res.ok) throw new Error(`Failed to fetch template: ${res.status}`);
  return res.json();
}

type StageStatus = "completed" | "current" | "pending";

function classFor(status: StageStatus): string {
  if (status === "current")
    return "bg-blue-50 border-blue-300 ring-2 ring-blue-200";
  if (status === "completed")
    return "bg-green-50 border-green-200";
  return "bg-gray-50 border-gray-200 opacity-60";
}

function connectorClass(left: StageStatus, right: StageStatus): string {
  const active = left !== "pending" && right !== "pending";
  return active ? "bg-green-300" : "bg-gray-200";
}

interface Props {
  templateId: string;
  currentStageId: string;
}

export function WorkflowSwimlane({ templateId, currentStageId }: Props) {
  const { data, isLoading, error } = useQuery({
    queryKey: ["workflow-template", templateId],
    queryFn: () => fetchTemplate(templateId),
  });

  if (isLoading) return <div className="text-sm text-gray-500">Loading workflow…</div>;
  if (error)
    return <div className="text-sm text-red-600">Workflow error: {String(error)}</div>;
  if (!data) return null;

  const stages = [...data.stages].sort((a, b) => a.order - b.order);
  const currentStage = stages.find((s) => s.id === currentStageId);
  const currentOrder = currentStage?.order ?? 0;

  const statuses: StageStatus[] = stages.map((s) => {
    if (s.order === currentOrder) return "current";
    if (s.order < currentOrder) return "completed";
    return "pending";
  });

  const nextStageIds = data.transitions
    .filter((t) => t.from_stage_id === currentStageId)
    .map((t) => t.to_stage_id);
  const nextStages = stages.filter((s) => nextStageIds.includes(s.id));

  return (
    <div className="space-y-4">
      <div className="flex items-stretch overflow-x-auto pb-2">
        {stages.map((stage, i) => (
          <div key={stage.id} className="flex items-center">
            <div
              className={`flex min-w-[140px] flex-col items-center rounded-lg border px-3 py-2 ${classFor(statuses[i])}`}
            >
              <div className="text-xs uppercase tracking-wide text-gray-500">
                Step {stage.order}
              </div>
              <div className="text-sm font-medium text-gray-900">{stage.name}</div>
              <div className="mt-1 text-center text-xs text-gray-600">
                {stage.allowed_actors.length > 0
                  ? stage.allowed_actors.join(", ")
                  : "—"}
              </div>
            </div>
            {i < stages.length - 1 && (
              <div
                className={`mx-1 h-0.5 w-6 ${connectorClass(statuses[i], statuses[i + 1])}`}
              />
            )}
          </div>
        ))}
      </div>

      <div className="rounded-md bg-gray-50 px-4 py-3 text-sm">
        {currentStage ? (
          <div className="flex flex-col gap-1">
            <span>
              <span className="font-medium text-gray-900">Currently in:</span>{" "}
              <span className="text-gray-700">{currentStage.name}</span>
            </span>
            <span>
              <span className="font-medium text-gray-900">Acting role(s):</span>{" "}
              <span className="text-gray-700">
                {currentStage.allowed_actors.length > 0
                  ? currentStage.allowed_actors.join(", ")
                  : "none — terminal stage"}
              </span>
            </span>
            <span>
              <span className="font-medium text-gray-900">Next:</span>{" "}
              <span className="text-gray-700">
                {nextStages.length > 0
                  ? nextStages.map((s) => s.name).join(" or ")
                  : "—"}
              </span>
            </span>
          </div>
        ) : (
          <span className="text-gray-500">
            Stage <code>{currentStageId}</code> is not part of template{" "}
            <code>{templateId}</code>.
          </span>
        )}
      </div>
    </div>
  );
}
