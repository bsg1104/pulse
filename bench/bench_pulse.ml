(** Benchmarks for Pulse.

    Measures graph creation, stabilization, nodes recomputed, and incremental
    vs naïve full recomputation on graphs of size 100 / 1k / 10k / 100k. *)

let time_ms f =
  let t0 = Unix.gettimeofday () in
  let result = f () in
  let t1 = Unix.gettimeofday () in
  (result, (t1 -. t0) *. 1000.)

(* Linear chain: root → … → tip (n derived nodes). A root change dirties all. *)
let build_chain n =
  let root = Pulse.Var.create ~name:"root" 1 in
  let rec loop i prev =
    if i >= n then prev
    else
      let next =
        Pulse.map ~name:(Printf.sprintf "n%d" i) prev ~f:(fun x -> x + 1)
      in
      loop (i + 1) next
  in
  let tip = loop 0 root in
  (root, Pulse.observe tip)

(* n independent var→map pairs. Mutating one var dirties a single node. *)
let build_independent n =
  let vars = Array.init n (fun _ -> Pulse.Var.create 0) in
  let obs =
    Array.map
      (fun v -> Pulse.observe (Pulse.map v ~f:(fun x -> x + 1)))
      vars
  in
  (vars, obs)

(* Naïve baseline: recompute all n independent maps from current inputs. *)
let full_recompute_independent vars =
  let sum = ref 0 in
  Array.iter
    (fun v ->
      let x = Pulse.Var.value v in
      sum := !sum + (x + 1))
    vars;
  !sum

let run_chain n =
  Printf.printf "── chain of %d nodes (root change dirties all) ──\n" n;
  let (root, obs), create_ms = time_ms (fun () -> build_chain n) in
  ignore (Pulse.stabilize ());
  let before = Pulse.Observer.value obs in
  Pulse.Var.set root 2;
  let (recomputed, after), stab_ms =
    time_ms (fun () ->
        let k = Pulse.stabilize () in
        (k, Pulse.Observer.value obs))
  in
  assert (after = before + 1);
  assert (recomputed = n);
  Printf.printf "  create:    %8.2f ms\n" create_ms;
  Printf.printf "  stabilize: %8.2f ms  (%d recomputed)\n\n" stab_ms recomputed;
  (n, create_ms, stab_ms, recomputed)

let run_selective n =
  Printf.printf
    "── %d independent nodes (change 1 — incremental vs full) ──\n" n;
  let (vars, obs), create_ms = time_ms (fun () -> build_independent n) in
  ignore (Pulse.stabilize ());

  Pulse.Var.set vars.(0) 1;
  let (recomputed, _), stab_ms =
    time_ms (fun () ->
        let k = Pulse.stabilize () in
        (k, Pulse.Observer.value obs.(0)))
  in

  let _, full_ms = time_ms (fun () -> full_recompute_independent vars) in

  assert (recomputed = 1);
  assert (Pulse.Observer.value obs.(0) = 2);
  (* Floor stabilize time so sub-timer-resolution runs don't report infx. *)
  let stab_ms' = max stab_ms 1e-6 in
  let speedup = full_ms /. stab_ms' in
  Printf.printf "  create:      %8.2f ms\n" create_ms;
  Printf.printf "  stabilize:   %8.4f ms  (%d recomputed)\n" stab_ms recomputed;
  Printf.printf "  full recompute all %d: %8.2f ms\n" n full_ms;
  Printf.printf "  speedup (full / incremental): %.1fx\n\n" speedup;
  (n, create_ms, stab_ms, recomputed, full_ms, speedup)

let () =
  print_endline "=== Pulse Benchmarks ===";
  print_endline "";

  let sizes = [ 100; 1_000; 10_000; 100_000 ] in
  print_endline "Chain propagation (affected = all):";
  let chain_results = List.map run_chain sizes in

  print_endline "Selective updates (affected = 1):";
  let sel_results = List.map run_selective sizes in

  print_endline "Summary — chain (CSV):";
  print_endline "nodes,create_ms,stabilize_ms,recomputed";
  List.iter
    (fun (n, c, s, r) -> Printf.printf "%d,%.3f,%.3f,%d\n" n c s r)
    chain_results;

  print_endline "";
  print_endline "Summary — selective (CSV):";
  print_endline "nodes,create_ms,stabilize_ms,recomputed,full_ms,speedup";
  List.iter
    (fun (n, c, s, r, f, sp) ->
      Printf.printf "%d,%.3f,%.3f,%d,%.3f,%.1f\n" n c s r f sp)
    sel_results
