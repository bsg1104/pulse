type 'a t = 'a Node.t

let create ?(name = "var") x =
  Node.create ~name ~height:0 ~value:x ~dirty:false ~compute:(fun () -> x)

let node t = t
let value t = Node.get t

let set t x =
  let old = Node.get t in
  if old != x then (
    Node.set_value t x;
    Node.set_compute t (fun () -> x);
    List.iter Scheduler.mark_dirty_descendants (Node.children t))
