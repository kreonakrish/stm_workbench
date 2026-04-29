import { useEffect, useRef, useState } from "react";
import { useQuery } from "@tanstack/react-query";

export interface SearchHit {
  label: string;
  property: string | null;
  display: string;
  unique: boolean;
}

interface SearchResponse {
  hits: SearchHit[];
  next_cursor: string | null;
}

async function searchOntology(q: string): Promise<SearchResponse> {
  const res = await fetch(
    `/api/v1/ontology/search?q=${encodeURIComponent(q)}&limit=10`,
  );
  if (!res.ok) throw new Error(`Search failed: ${res.status}`);
  return res.json();
}

function useDebounced<T>(value: T, delay = 200): T {
  const [debounced, setDebounced] = useState(value);
  useEffect(() => {
    const t = setTimeout(() => setDebounced(value), delay);
    return () => clearTimeout(t);
  }, [value, delay]);
  return debounced;
}

interface Props {
  onSelect?: (hit: SearchHit) => void;
  placeholder?: string;
}

export function ExistingFieldPicker({ onSelect, placeholder }: Props) {
  const [q, setQ] = useState("");
  const [open, setOpen] = useState(false);
  const dq = useDebounced(q);
  const blurTimer = useRef<ReturnType<typeof setTimeout>>();

  const { data, isFetching } = useQuery({
    queryKey: ["ontology-search", dq],
    queryFn: () => searchOntology(dq),
    enabled: dq.trim().length > 0,
  });

  const showPanel = open && q.trim().length > 0;
  const hits = data?.hits ?? [];

  return (
    <div className="relative">
      <input
        type="search"
        value={q}
        onChange={(e) => setQ(e.target.value)}
        onFocus={() => setOpen(true)}
        onBlur={() => {
          // Delay blur so a click on a result still registers.
          blurTimer.current = setTimeout(() => setOpen(false), 120);
        }}
        placeholder={placeholder ?? "Search existing fields (e.g. borrower_id, ssn)"}
        className="w-full rounded-md border border-gray-300 px-3 py-2 text-sm"
      />
      {showPanel && (
        <div className="absolute left-0 right-0 top-full z-10 mt-1 max-h-72 overflow-y-auto rounded-md border border-gray-200 bg-white shadow-lg">
          {isFetching && hits.length === 0 ? (
            <div className="px-3 py-2 text-xs text-gray-500">Searching…</div>
          ) : hits.length === 0 ? (
            <div className="px-3 py-2 text-xs text-gray-500">No matches.</div>
          ) : (
            hits.map((hit) => (
              <button
                key={hit.display}
                type="button"
                onMouseDown={(e) => {
                  // onMouseDown fires before blur, so the click registers.
                  e.preventDefault();
                  if (blurTimer.current) clearTimeout(blurTimer.current);
                  onSelect?.(hit);
                  setQ("");
                  setOpen(false);
                }}
                className="flex w-full items-center justify-between px-3 py-2 text-left text-sm hover:bg-gray-50"
              >
                <span className="font-mono text-gray-900">{hit.display}</span>
                <span className="flex gap-1">
                  {hit.unique && (
                    <span className="rounded bg-blue-50 px-1.5 py-0.5 text-xs text-blue-700">
                      unique
                    </span>
                  )}
                  {hit.property === null && (
                    <span className="rounded bg-gray-100 px-1.5 py-0.5 text-xs text-gray-600">
                      entity
                    </span>
                  )}
                </span>
              </button>
            ))
          )}
        </div>
      )}
    </div>
  );
}
