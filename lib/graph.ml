exception Cycle of string

let depends_on ~start ~target =
  let target_id = Node.packed_id target in
  let visited = Hashtbl.create 16 in
  let rec walk node =
    let id = Node.packed_id node in
    if id = target_id then true
    else if Hashtbl.mem visited id then false
    else (
      Hashtbl.add visited id ();
      List.exists walk (Node.packed_children node))
  in
  walk start

let check_edge ~parent ~child =
  if Node.id parent = Node.id child then
    raise (Cycle (Printf.sprintf "self-loop at node %S" (Node.name child)));
  if depends_on ~start:(Node.pack child) ~target:(Node.pack parent) then
    raise
      (Cycle
         (Printf.sprintf "cycle: %S already depends on %S (transitively)"
            (Node.name parent) (Node.name child)))

let height_for ~parents =
  match parents with
  | [] -> 0
  | ps -> 1 + List.fold_left (fun acc p -> max acc (Node.packed_height p)) 0 ps
