(** Spreadsheet demo — Excel-style formula chains.

    Cells:
      A1 = 10          (input)
      A2 = A1 * 2
      A3 = A2 + 5
      A4 = A3 * 8

    Changing A1 recomputes only A2, A3, and A4. *)

let print_sheet ~a1 ~a2 ~a3 ~a4 =
  Printf.printf "  A1 = %d\n" (Pulse.Var.value a1);
  Printf.printf "  A2 = %d   (= A1 * 2)\n" a2;
  Printf.printf "  A3 = %d   (= A2 + 5)\n" a3;
  Printf.printf "  A4 = %d   (= A3 * 8)\n" a4

let () =
  print_endline "=== Pulse Spreadsheet Demo ===";
  print_endline "";

  let a1 = Pulse.Var.create ~name:"A1" 10 in
  let a2_n = Pulse.map ~name:"A2" a1 ~f:(fun x -> x * 2) in
  let a3_n = Pulse.map ~name:"A3" a2_n ~f:(fun x -> x + 5) in
  let a4_n = Pulse.map ~name:"A4" a3_n ~f:(fun x -> x * 8) in
  let o2 = Pulse.observe a2_n in
  let o3 = Pulse.observe a3_n in
  let o4 = Pulse.observe a4_n in

  ignore (Pulse.stabilize ());
  print_endline "Initial sheet:";
  print_sheet ~a1
    ~a2:(Pulse.Observer.value o2)
    ~a3:(Pulse.Observer.value o3)
    ~a4:(Pulse.Observer.value o4);

  print_endline "";
  print_endline "Setting A1 := 11 ...";
  print_endline "Recomputation order:";

  Pulse.set_on_recompute (fun ~name ~id ->
      Printf.printf "  recompute %s (id=%d)\n" name id);

  Pulse.Var.set a1 11;
  let n = Pulse.stabilize () in
  Pulse.clear_on_recompute ();

  print_endline "";
  Printf.printf "Recomputed %d node(s).\n" n;
  print_endline "Updated sheet:";
  print_sheet ~a1
    ~a2:(Pulse.Observer.value o2)
    ~a3:(Pulse.Observer.value o3)
    ~a4:(Pulse.Observer.value o4);

  print_endline "";
  print_endline
    "Only A2, A3, and A4 were recomputed — A1 is an input and was not.";
