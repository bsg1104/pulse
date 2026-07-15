(* Dirty-node worklist. Nodes are inserted at most once per contamination. *)
let dirty_nodes : Node.packed list ref = ref []

let last_count = ref 0

let on_recompute : (name:string -> id:int -> unit) ref =
  ref (fun ~name:_ ~id:_ -> ())

let set_on_recompute f = on_recompute := f
let clear_on_recompute () = on_recompute := fun ~name:_ ~id:_ -> ()
let last_recomputed () = !last_count

let mark_dirty_descendants node =
  let rec mark n =
    if not (Node.packed_is_dirty n) then (
      Node.packed_set_dirty n true;
      dirty_nodes := n :: !dirty_nodes;
      List.iter mark (Node.packed_children n))
  in
  mark node

(* Recompute dirty nodes parents-before-children via height ordering.
   Heights are assigned at construction so a single sort yields a valid
   topological order for the DAG. *)
let stabilize () =
  let pending = !dirty_nodes in
  dirty_nodes := [];
  let ordered =
    List.sort
      (fun a b ->
        let ha = Node.packed_height a and hb = Node.packed_height b in
        let c = Int.compare ha hb in
        if c <> 0 then c else Int.compare (Node.packed_id a) (Node.packed_id b))
      pending
  in
  let count = ref 0 in
  List.iter
    (fun packed ->
      if Node.packed_is_dirty packed then (
        incr count;
        !on_recompute ~name:(Node.packed_name packed) ~id:(Node.packed_id packed);
        Node.recompute packed))
    ordered;
  last_count := !count;
  !count
