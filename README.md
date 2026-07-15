# Pulse

**An incremental computation engine for OCaml.**

Pulse tracks dependencies between computations and automatically recomputes
only the values affected when an input changes — the same idea as a
spreadsheet: edit one cell, and only dependent formulas refresh.

```ocaml
open Pulse

let price = Var.create 100.
let quantity = Var.create 20.
let notional = map2 price quantity ~f:( *. )
let fee = map notional ~f:(fun x -> x *. 0.001)
let total = map2 notional fee ~f:( +. )
let obs = observe total

let () =
  ignore (stabilize ());
  Printf.printf "total = %.2f\n" (Observer.value obs);
  (* 100 * 20 + fee = 2000. + 2. *)

  Var.set price 105.;
  ignore (stabilize ());
  (* recomputes notional, fee, total — nothing else *)
  Printf.printf "total = %.2f\n" (Observer.value obs)
```

## What is Pulse?

Build systems, UI frameworks, and spreadsheets all share a pattern: a graph
of dependent calculations where most inputs are stable most of the time.
Pulse implements that pattern as a small OCaml library.

- Change an input with `Var.set`
- Call `stabilize ()`
- Only dirty dependents recompute, in dependency order
- Cache hits skip work when nothing changed

## Install / build

Requires OCaml ≥ 4.14 and Dune ≥ 3.16.

```bash
opam install alcotest   # for tests
dune build
dune runtest
```

Demos and benchmarks:

```bash
dune exec pulse-spreadsheet
dune exec pulse-portfolio
dune exec pulse-bench
```

## API overview

| Function | Purpose |
|----------|---------|
| `Var.create` / `Var.set` / `Var.value` | Mutable inputs |
| `const` | Constant node |
| `map` / `map2` / `map3` | Derived computations |
| `observe` | Handle for reading a node's value |
| `stabilize ()` | Propagate dirty nodes; returns count recomputed |

Cycles in the dependency graph are rejected with `Pulse.Cycle`.

## Architecture

```
Node  →  Dependency Graph  →  Scheduler  →  Observer
```

- **Node** — cached value, dirty flag, parent/child edges, unique id
- **Graph** — height assignment and cycle detection (arbitrary DAGs)
- **Scheduler** — mark descendants dirty, recompute in height order once
- **Observer** — application-facing handle after stabilization

See [docs/architecture.md](docs/architecture.md) for algorithms and invariants.

## Performance

Benchmarks on an Apple Silicon machine (representative; re-run with
`dune exec pulse-bench`):

**Chain propagation** — changing the root dirties every node:

| Nodes   | Create    | Stabilize |
|---------|-----------|-----------|
| 100     | ~0.02 ms  | ~0.003 ms |
| 1,000   | ~0.16 ms  | ~0.05 ms  |
| 10,000  | ~2.3 ms   | ~0.8 ms   |
| 100,000 | ~26 ms    | ~12 ms    |

**Selective update** — 1 of N independent nodes dirty:

| Nodes   | Stabilize (1 dirty) | Full recompute all N |
|---------|---------------------|----------------------|
| 100     | ~0.00 ms            | ~0.001 ms            |
| 1,000   | ~0.00 ms            | ~0.003 ms            |
| 10,000  | ~0.00 ms            | ~0.02 ms             |
| 100,000 | ~0.00 ms            | ~0.25 ms             |

The headline property: **unaffected nodes are never recomputed**. On a
disconnected forest, mutating one input stays O(affected), not O(N).

## Demo applications

**Spreadsheet** (`bin/spreadsheet_demo.ml`) — `A1 → A2 → A3 → A4`. Setting
`A1` prints the recomputation order `A2`, `A3`, `A4`.

**Portfolio risk** (`bin/portfolio_demo.ml`) — prices, positions, fees;
derived notionals, gross exposure, transaction cost, and portfolio value.
Changing one price only walks that asset's dependent path.

## Testing

```bash
dune runtest
```

Coverage includes chains, branching graphs, diamonds, batched updates,
disconnected components, cycle detection, caching, observers, and
`map3` / `const`.

## Future work

- Dynamic dependencies (dependents that change which nodes they read)
- Parallel stabilization across independent subgraphs
- Async / push-based observers
- Graph visualization tooling

## License

MIT
