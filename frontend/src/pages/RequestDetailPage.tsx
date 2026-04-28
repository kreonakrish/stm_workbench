import { useParams } from "react-router-dom";
import { useQuery } from "@tanstack/react-query";

interface Request {
  id: string;
  title: string;
  business_question: string;
  usage_context: string;
  consumption_pattern: string;
  current_stage_name: string;
  created_at: string;
}

async function fetchRequest(id: string): Promise<Request> {
  const res = await fetch(`/api/v1/requests/${id}`);
  if (!res.ok) throw new Error(`Failed to fetch request: ${res.status}`);
  return res.json();
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
    <div className="mx-auto max-w-3xl">
      <div className="mb-2 text-xs uppercase tracking-wide text-gray-500">
        Stage: {data.current_stage_name}
      </div>
      <h1 className="mb-4 text-2xl font-medium text-gray-900">{data.title}</h1>

      <div className="rounded-lg border bg-white p-6">
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
      </div>

      {/* TODO(T-032): Discovery candidates. T-027: cascade results. T-034: comments. */}
    </div>
  );
}
