(** Portfolio risk calculator demo.

    Inputs: prices, positions, fee rate.
    Derived: notionals, gross exposure, transaction cost, portfolio value.

    Changing one price recomputes only the quantities that depend on it. *)

type instrument = { name : string; price : float Pulse.t; position : float }

let fmt f = Printf.sprintf "%.2f" f

let () =
  print_endline "=== Pulse Portfolio Risk Demo ===";
  print_endline "";

  let fee_rate = Pulse.Var.create ~name:"fee_rate" 0.001 in

  let aapl_px = Pulse.Var.create ~name:"AAPL.price" 180. in
  let msft_px = Pulse.Var.create ~name:"MSFT.price" 420. in
  let googl_px = Pulse.Var.create ~name:"GOOGL.price" 140. in

  let instruments =
    [
      { name = "AAPL"; price = aapl_px; position = 100. };
      { name = "MSFT"; price = msft_px; position = 50. };
      { name = "GOOGL"; price = googl_px; position = 75. };
    ]
  in

  let notionals =
    List.map
      (fun inst ->
        let n =
          Pulse.map ~name:(inst.name ^ ".notional") inst.price ~f:(fun px ->
              px *. inst.position)
        in
        (inst.name, n, Pulse.observe n))
      instruments
  in

  let notional_nodes = List.map (fun (_, n, _) -> n) notionals in

  (* Fold notionals into gross exposure with successive map2. *)
  let gross =
    match notional_nodes with
    | [] -> Pulse.const 0.
    | hd :: tl ->
        List.fold_left
          (fun acc n ->
            Pulse.map2 ~name:"gross" acc n ~f:(fun a b -> a +. abs_float b))
          (Pulse.map ~name:"gross0" hd ~f:abs_float)
          tl
  in
  let o_gross = Pulse.observe gross in

  let txn_cost =
    Pulse.map2 ~name:"txn_cost" gross fee_rate ~f:(fun g fee -> g *. fee)
  in
  let o_cost = Pulse.observe txn_cost in

  let portfolio_value =
    match notional_nodes with
    | [] -> Pulse.const 0.
    | hd :: tl ->
        List.fold_left
          (fun acc n -> Pulse.map2 ~name:"pv" acc n ~f:( +. ))
          hd tl
  in
  let o_pv = Pulse.observe portfolio_value in

  let print_state label =
    print_endline label;
    List.iter
      (fun (name, _, o) ->
        Printf.printf "  %s notional = %s\n" name
          (fmt (Pulse.Observer.value o)))
      notionals;
    Printf.printf "  gross exposure  = %s\n" (fmt (Pulse.Observer.value o_gross));
    Printf.printf "  transaction cost = %s\n" (fmt (Pulse.Observer.value o_cost));
    Printf.printf "  portfolio value  = %s\n" (fmt (Pulse.Observer.value o_pv))
  in

  ignore (Pulse.stabilize ());
  print_state "Initial portfolio:";

  print_endline "";
  print_endline "Bump AAPL price 180 → 185 ...";
  print_endline "Recomputation order:";

  Pulse.set_on_recompute (fun ~name ~id ->
      Printf.printf "  recompute %s (id=%d)\n" name id);

  Pulse.Var.set aapl_px 185.;
  let n = Pulse.stabilize () in
  Pulse.clear_on_recompute ();

  print_endline "";
  Printf.printf "Recomputed %d node(s).\n" n;
  print_state "Updated portfolio:";

  print_endline "";
  print_endline
    "MSFT and GOOGL notionals were untouched — only the AAPL-dependent path \
     ran.";
