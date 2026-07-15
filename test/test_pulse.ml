open Alcotest

let stabilize_ok () = ignore (Pulse.stabilize ())

let test_chain () =
  let a1 = Pulse.Var.create ~name:"A1" 10 in
  let a2 = Pulse.map ~name:"A2" a1 ~f:(fun x -> x * 2) in
  let a3 = Pulse.map ~name:"A3" a2 ~f:(fun x -> x + 5) in
  let a4 = Pulse.map ~name:"A4" a3 ~f:(fun x -> x * 8) in
  let o = Pulse.observe a4 in
  stabilize_ok ();
  check int "initial A4" 200 (Pulse.Observer.value o);
  Pulse.Var.set a1 11;
  let n = Pulse.stabilize () in
  check int "recomputed 3 derived nodes" 3 n;
  check int "updated A4" 216 (Pulse.Observer.value o)

let test_branching () =
  let src = Pulse.Var.create ~name:"src" 2 in
  let left = Pulse.map ~name:"left" src ~f:(fun x -> x + 1) in
  let right = Pulse.map ~name:"right" src ~f:(fun x -> x * 10) in
  let o_l = Pulse.observe left in
  let o_r = Pulse.observe right in
  stabilize_ok ();
  check int "left" 3 (Pulse.Observer.value o_l);
  check int "right" 20 (Pulse.Observer.value o_r);
  Pulse.Var.set src 5;
  let n = Pulse.stabilize () in
  check int "both branches" 2 n;
  check int "left'" 6 (Pulse.Observer.value o_l);
  check int "right'" 50 (Pulse.Observer.value o_r)

let test_diamond () =
  let x = Pulse.Var.create ~name:"x" 3 in
  let a = Pulse.map ~name:"a" x ~f:(fun v -> v + 1) in
  let b = Pulse.map ~name:"b" x ~f:(fun v -> v * 2) in
  let d = Pulse.map2 ~name:"d" a b ~f:( + ) in
  let o = Pulse.observe d in
  stabilize_ok ();
  check int "diamond init" 10 (Pulse.Observer.value o);
  Pulse.Var.set x 4;
  let n = Pulse.stabilize () in
  check int "no duplicate recompute" 3 n;
  check int "diamond after" 13 (Pulse.Observer.value o)

let test_multiple_updates () =
  let a = Pulse.Var.create 1 in
  let b = Pulse.Var.create 10 in
  let c = Pulse.map2 a b ~f:( + ) in
  let o = Pulse.observe c in
  stabilize_ok ();
  Pulse.Var.set a 2;
  Pulse.Var.set b 20;
  let n = Pulse.stabilize () in
  check int "single stabilize after two sets" 1 n;
  check int "sum" 22 (Pulse.Observer.value o)

let test_disconnected () =
  let a = Pulse.Var.create ~name:"a" 1 in
  let b = Pulse.Var.create ~name:"b" 100 in
  let da = Pulse.map ~name:"da" a ~f:(fun x -> x + 1) in
  let db = Pulse.map ~name:"db" b ~f:(fun x -> x + 1) in
  let oa = Pulse.observe da in
  let ob = Pulse.observe db in
  stabilize_ok ();
  Pulse.Var.set a 5;
  let n = Pulse.stabilize () in
  check int "only connected component" 1 n;
  check int "da" 6 (Pulse.Observer.value oa);
  check int "db untouched" 101 (Pulse.Observer.value ob)

let test_cycle_detection () =
  let a = Pulse.Var.create ~name:"a" 1 in
  let b = Pulse.map ~name:"b" a ~f:(fun x -> x + 1) in
  check_raises "rejects backward edge"
    (Pulse.Cycle "cycle: \"b\" already depends on \"a\" (transitively)")
    (fun () -> Pulse.For_testing.check_edge ~parent:b ~child:a);
  check_raises "rejects self-loop"
    (Pulse.Cycle "self-loop at node \"a\"")
    (fun () -> Pulse.For_testing.check_edge ~parent:a ~child:a)

let test_caching () =
  let x = Pulse.Var.create 7 in
  let y = Pulse.map ~name:"y" x ~f:(fun v -> v * 3) in
  let o = Pulse.observe y in
  stabilize_ok ();
  check int "cached" 21 (Pulse.Observer.value o);
  let n = Pulse.stabilize () in
  check int "idle stabilize" 0 n;
  check int "still cached" 21 (Pulse.Observer.value o)

let test_observer () =
  let x = Pulse.Var.create 1. in
  let y = Pulse.map x ~f:(fun v -> v +. 0.5) in
  let o = Pulse.observe y in
  stabilize_ok ();
  check (float 1e-9) "obs" 1.5 (Pulse.Observer.value o);
  Pulse.Var.set x 2.;
  ignore (Pulse.stabilize ());
  check (float 1e-9) "obs'" 2.5 (Pulse.Observer.value o)

let test_map3 () =
  let a = Pulse.Var.create 1 in
  let b = Pulse.Var.create 2 in
  let c = Pulse.Var.create 3 in
  let d = Pulse.map3 a b c ~f:(fun x y z -> x + y + z) in
  let o = Pulse.observe d in
  stabilize_ok ();
  check int "map3" 6 (Pulse.Observer.value o);
  Pulse.Var.set c 10;
  ignore (Pulse.stabilize ());
  check int "map3'" 13 (Pulse.Observer.value o)

let test_const () =
  let c = Pulse.const 42 in
  let d = Pulse.map c ~f:(fun x -> x + 1) in
  let o = Pulse.observe d in
  stabilize_ok ();
  check int "const chain" 43 (Pulse.Observer.value o)

let test_phys_equal_skip () =
  let x = Pulse.Var.create ~name:"x" 5 in
  let y = Pulse.map ~name:"y" x ~f:(fun v -> v + 1) in
  let o = Pulse.observe y in
  stabilize_ok ();
  let v = Pulse.Var.value x in
  Pulse.Var.set x v;
  let n = Pulse.stabilize () in
  check int "phys_equal set is a no-op" 0 n;
  check int "unchanged" 6 (Pulse.Observer.value o)

let () =
  run "pulse"
    [
      ( "correctness",
        [
          test_case "chain" `Quick test_chain;
          test_case "branching" `Quick test_branching;
          test_case "diamond" `Quick test_diamond;
          test_case "multiple updates" `Quick test_multiple_updates;
          test_case "disconnected" `Quick test_disconnected;
          test_case "cycle detection" `Quick test_cycle_detection;
          test_case "caching" `Quick test_caching;
          test_case "observers" `Quick test_observer;
          test_case "map3" `Quick test_map3;
          test_case "const" `Quick test_const;
          test_case "phys_equal skip" `Quick test_phys_equal_skip;
        ] );
    ]
