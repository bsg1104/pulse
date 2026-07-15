# Architecture

Pulse is an incremental computation engine. It maintains a directed acyclic
graph of dependent computations and, when an input changes, recomputes only
the affected subgraph.

```
  Var / const          ← inputs (height 0)
       │
       ▼
     Node              ← cached value + dirty flag + edges
       │
       ▼
  Dependency Graph     ← parents / children, cycle checks, heights
       │
       ▼
    Scheduler          ← mark dirty → stabilize in height order
       │
       ▼
    Observer           ← stable handle for reading results
```

## Node

Each node stores:

| Field     | Role                                      |
|-----------|-------------------------------------------|
| `id`      | Unique identity                           |
| `name`    | Human-readable label (demos / debugging)  |
| `height`  | Topological level (1 + max parent height) |
| `dirty`   | Whether the cached value may be stale     |
| `value`   | Last computed result                      |
| `compute` | Closure that produces a fresh value       |
| `parents` | Nodes this depends on                     |
| `children`| Nodes that depend on this                 |

Heterogeneous nodes share the graph through an existential `packed` type.

## Dependency Graph

Edges are created when building `map` / `map2` / `map3`. Before an edge is
added, Pulse checks that it would not introduce a cycle:

1. Reject self-loops.
2. Reject edges where the prospective child already reaches the parent
   through existing dependents (DFS over children).

Heights are assigned at construction time as
`1 + max(parent heights)`. Because the graph is a DAG and heights respect
dependencies, sorting dirty nodes by height yields a valid topological order
without a separate topo-sort pass at stabilize time.

## Scheduler

Stabilization is two phases:

1. **Contamination** — `Var.set` calls `mark_dirty_descendants`, which walks
   children and sets `dirty` on each newly dirty node, enqueueing it once.
2. **Recomputation** — `stabilize` sorts the dirty worklist by
   `(height, id)`, runs each dirty node's `compute`, clears its flag, and
   returns the count of recomputations.

Unaffected nodes stay clean and are never visited during the recompute pass.

Physical equality on `Var.set` skips contamination when the new value is the
same object as the old one (`!=`), avoiding unnecessary work for no-ops.

## Observer

`observe` wraps a node in a handle. After `stabilize`, `Observer.value` reads
the cached result. In this design, observation does not change liveness or
cutoff behaviour; it is the documented way for application code to read
results without reaching into the graph.

## Correctness invariant

> After `stabilize()`, every observed node contains the value that would be
> obtained by evaluating its compute function against the current inputs.

Combined with height-ordered recomputation and single-enqueue dirty marking,
this implies: no stale observed values, and no duplicate recomputation of a
node within one stabilize call.
