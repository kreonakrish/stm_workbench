import { lazy, Suspense } from "react";
import { Route, Routes, Link } from "react-router-dom";
import { IntakePage } from "./pages/IntakePage";
import { JADBoardPage } from "./pages/JADBoardPage";
import { RequestDetailPage } from "./pages/RequestDetailPage";

// Lazy-load the ontology page so @xyflow/react bundles only on /ontology.
const OntologyPage = lazy(() =>
  import("./pages/OntologyPage").then((m) => ({ default: m.OntologyPage })),
);

export function App() {
  return (
    <div className="min-h-screen bg-gray-50">
      <header className="border-b bg-white">
        <nav className="mx-auto flex max-w-7xl items-center justify-between px-4 py-3">
          <Link to="/" className="text-lg font-medium text-gray-900">
            STM Workbench
          </Link>
          <div className="flex gap-6 text-sm text-gray-600">
            <Link to="/intake" className="hover:text-gray-900">New request</Link>
            <Link to="/ontology" className="hover:text-gray-900">Ontology</Link>
            <Link to="/board" className="hover:text-gray-900">Board</Link>
          </div>
        </nav>
      </header>
      <main className="mx-auto max-w-7xl px-4 py-6">
        <Routes>
          <Route path="/" element={<JADBoardPage />} />
          <Route path="/intake" element={<IntakePage />} />
          <Route path="/board" element={<JADBoardPage />} />
          <Route
            path="/ontology"
            element={
              <Suspense fallback={<div className="text-sm text-gray-500">Loading…</div>}>
                <OntologyPage />
              </Suspense>
            }
          />
          <Route path="/requests/:id" element={<RequestDetailPage />} />
        </Routes>
      </main>
    </div>
  );
}
