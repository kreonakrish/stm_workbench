# ADR 0008: Use react-flow for graph visualization

## Status
Accepted

## Context
The intake reviewer needs to see the business-ontology schema as a graph
to understand what entities exist and how they connect — analogous to
`CALL db.schema.visualization()` in Neo4j Browser. Subsequent features
(F3 field search, F4 workflow swimlane viewer) will also benefit from
diagram-style UI components.

Three viable libraries for in-browser graph rendering:

| Lib              | Bundle (gz) | DX with React          | Layouts            |
|------------------|-------------|------------------------|--------------------|
| react-flow / @xyflow/react | ~30 kB | First-class React API, hooks | Force, dagre, manual |
| cytoscape.js     | ~80 kB      | Imperative, wrap in React | Many built-in       |
| d3-force + custom SVG | ~10 kB | Bring-your-own-everything | DIY                  |

react-flow integrates with React patterns (controlled state, refs,
hooks), is actively maintained, and has built-in support for the
interactions we need (pan/zoom, node click, side-panel, custom node
renderers). Bundle cost is acceptable when lazy-loaded per route.

cytoscape is heavier, more powerful for analytical graph operations we
do not need. d3-force is lighter but everything beyond the layout
(rendering, interaction, accessibility) becomes hand-rolled.

## Decision
Use `@xyflow/react` (the maintained successor to `react-flow`) for all
graph-style visualizations in the workbench.

- Routes that render diagrams (e.g. `/ontology`, request detail's
  workflow swimlane) lazy-load the component so the bundle penalty is
  only paid when the user navigates there.
- Custom node renderers compose shadcn/ui primitives so the look matches
  the rest of the app (see ADR's pending UI direction memo on Soda
  Cloud as visual reference).

## Consequences
**Easier**
- Schema viz, workflow swimlane, and lineage views share one library.
- Built-in support for our must-haves (pan/zoom, custom nodes, edge
  labels, node selection) — no DIY interaction layer.

**Harder**
- One more frontend dependency to keep current.
- ~30 kB gzipped bundle on routes that load it.
- Force-directed layouts are non-deterministic; we will pin layout
  behaviour explicitly where stable position matters (e.g. swimlane).

## Notes
- This ADR satisfies the "no new dependency without an ADR" rule from
  CLAUDE.md.
- Layout decision (force vs dagre vs manual) is per-feature and not
  fixed here.
