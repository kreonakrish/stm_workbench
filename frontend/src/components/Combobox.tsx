import { useEffect, useMemo, useRef, useState } from "react";

export interface ComboboxOption {
  value: string;
  label?: string;
  description?: string | null;
  badge?: string;
}

interface Props {
  value: string;
  onChange: (value: string) => void;
  options: ComboboxOption[];
  placeholder?: string;
  allowAddNew?: boolean;
  emptyMessage?: string;
  disabled?: boolean;
}

/**
 * A typeahead picker with the existing options listed first and a
 * `+ Add new …` option pinned at the top once the user types something
 * that does not match any existing value. Mirrors a Soda Cloud-style
 * combobox without a heavy dependency.
 */
export function Combobox({
  value,
  onChange,
  options,
  placeholder,
  allowAddNew = true,
  emptyMessage,
  disabled = false,
}: Props) {
  const [open, setOpen] = useState(false);
  const [query, setQuery] = useState("");
  const wrapperRef = useRef<HTMLDivElement>(null);
  const inputRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    if (!open) {
      setQuery("");
      return;
    }
    const handler = (e: MouseEvent) => {
      if (wrapperRef.current && !wrapperRef.current.contains(e.target as Node)) {
        setOpen(false);
      }
    };
    document.addEventListener("mousedown", handler);
    setTimeout(() => inputRef.current?.focus(), 0);
    return () => document.removeEventListener("mousedown", handler);
  }, [open]);

  const trimmedQuery = query.trim();
  const filtered = useMemo(() => {
    if (!trimmedQuery) return options;
    const q = trimmedQuery.toLowerCase();
    return options.filter(
      (o) =>
        o.value.toLowerCase().includes(q) ||
        (o.label && o.label.toLowerCase().includes(q)) ||
        (o.description && o.description.toLowerCase().includes(q)),
    );
  }, [options, trimmedQuery]);

  const exactMatch = useMemo(
    () => options.some((o) => o.value === trimmedQuery),
    [options, trimmedQuery],
  );
  const showAddNew = allowAddNew && trimmedQuery.length > 0 && !exactMatch;

  function pick(v: string) {
    onChange(v);
    setOpen(false);
    setQuery("");
  }

  function onKeyDown(e: React.KeyboardEvent<HTMLInputElement>) {
    if (e.key === "Escape") {
      setOpen(false);
    } else if (e.key === "Enter") {
      e.preventDefault();
      if (showAddNew) pick(trimmedQuery);
      else if (filtered.length > 0) pick(filtered[0].value);
    }
  }

  return (
    <div className="relative" ref={wrapperRef}>
      <button
        type="button"
        disabled={disabled}
        onClick={() => !disabled && setOpen((o) => !o)}
        className="flex w-full items-center justify-between rounded-md border border-gray-300 bg-white px-3 py-1.5 text-left text-sm hover:border-gray-400 disabled:cursor-not-allowed disabled:bg-gray-50 disabled:text-gray-400"
      >
        <span className="truncate">
          {value || (
            <span className="text-gray-400">{placeholder ?? "Select…"}</span>
          )}
        </span>
        <span className="ml-2 text-gray-400">▾</span>
      </button>
      {open && !disabled && (
        <div className="absolute left-0 right-0 z-20 mt-1 max-h-80 overflow-hidden rounded-md border border-gray-200 bg-white shadow-lg">
          <div className="border-b border-gray-100 p-2">
            <input
              ref={inputRef}
              type="text"
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              onKeyDown={onKeyDown}
              placeholder="Type to filter or add new…"
              className="w-full rounded-md border border-gray-300 px-2 py-1 text-sm focus:border-blue-400 focus:outline-none"
            />
          </div>
          <div className="max-h-60 overflow-y-auto py-1">
            {showAddNew && (
              <button
                type="button"
                onClick={() => pick(trimmedQuery)}
                className="flex w-full items-center justify-between border-b border-gray-100 px-3 py-2 text-left text-sm hover:bg-blue-50"
              >
                <span className="text-blue-700">
                  + Add new: <span className="font-mono">{trimmedQuery}</span>
                </span>
                <span className="text-[10px] uppercase tracking-wide text-blue-500">
                  Net new
                </span>
              </button>
            )}
            {filtered.length === 0 && !showAddNew && (
              <div className="px-3 py-3 text-xs text-gray-500">
                {emptyMessage ?? "No matches."}
              </div>
            )}
            {filtered.map((o) => (
              <button
                key={o.value}
                type="button"
                onClick={() => pick(o.value)}
                className="flex w-full items-start justify-between gap-2 px-3 py-1.5 text-left text-sm hover:bg-gray-50"
              >
                <span className="min-w-0">
                  <span className="block font-mono text-gray-900">
                    {o.label ?? o.value}
                  </span>
                  {o.description && (
                    <span className="block text-xs text-gray-500">
                      {o.description}
                    </span>
                  )}
                </span>
                {o.badge && (
                  <span className="rounded bg-blue-50 px-1.5 py-0.5 text-[10px] font-medium text-blue-700">
                    {o.badge}
                  </span>
                )}
              </button>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
