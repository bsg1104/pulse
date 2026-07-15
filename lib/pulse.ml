module Var = Var
module Observer = Observer

type 'a t = 'a Node.t

exception Cycle = Graph.Cycle

let attach ~parents child =
  List.iter
    (fun (Node.Pack parent) ->
      Graph.check_edge ~parent ~child;
      Node.add_child ~parent ~child)
    parents

let make ~name ~parents ~compute ~value ~needs_recompute =
  let height = Graph.height_for ~parents in
  (* Always start clean so mark_dirty_descendants can enqueue us. *)
  let node = Node.create ~name ~height ~value ~dirty:false ~compute in
  attach ~parents node;
  if needs_recompute then Scheduler.mark_dirty_descendants (Node.pack node);
  node

let any_parent_dirty parents = List.exists Node.packed_is_dirty parents

let const ?(name = "const") x =
  Node.create ~name ~height:0 ~value:x ~dirty:false ~compute:(fun () -> x)

let map ?(name = "map") t ~f =
  let parents = [ Node.pack t ] in
  let compute () = f (Node.get t) in
  (* Seed from current caches; stabilize refreshes if parents are dirty. *)
  make ~name ~parents ~compute ~value:(compute ())
    ~needs_recompute:(Node.is_dirty t)

let map2 ?(name = "map2") a b ~f =
  let parents = [ Node.pack a; Node.pack b ] in
  let compute () = f (Node.get a) (Node.get b) in
  make ~name ~parents ~compute ~value:(compute ())
    ~needs_recompute:(any_parent_dirty parents)

let map3 ?(name = "map3") a b c ~f =
  let parents = [ Node.pack a; Node.pack b; Node.pack c ] in
  let compute () = f (Node.get a) (Node.get b) (Node.get c) in
  make ~name ~parents ~compute ~value:(compute ())
    ~needs_recompute:(any_parent_dirty parents)

let observe ?name t = Observer.observe ?name t
let stabilize = Scheduler.stabilize
let last_recomputed = Scheduler.last_recomputed
let set_on_recompute = Scheduler.set_on_recompute
let clear_on_recompute = Scheduler.clear_on_recompute

module For_testing = struct
  let check_edge ~parent ~child = Graph.check_edge ~parent ~child
end
