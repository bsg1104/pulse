type 'a t = {
  id : int;
  name : string;
  height : int;
  mutable dirty : bool;
  mutable value : 'a;
  mutable compute : unit -> 'a;
  mutable parents : packed list;
  mutable children : packed list;
}

and packed = Pack : 'a t -> packed

let next_id =
  let c = ref 0 in
  fun () ->
    incr c;
    !c

let create ~name ~height ~value ~dirty ~compute =
  {
    id = next_id ();
    name;
    height;
    dirty;
    value;
    compute;
    parents = [];
    children = [];
  }

let id t = t.id
let name t = t.name
let height t = t.height
let is_dirty t = t.dirty
let set_dirty t d = t.dirty <- d
let get t = t.value
let set_value t v = t.value <- v
let set_compute t f = t.compute <- f
let parents t = t.parents
let children t = t.children

let add_child ~parent ~child =
  parent.children <- Pack child :: parent.children;
  child.parents <- Pack parent :: child.parents

let pack t = Pack t
let packed_id (Pack n) = n.id
let packed_height (Pack n) = n.height
let packed_is_dirty (Pack n) = n.dirty
let packed_set_dirty (Pack n) d = n.dirty <- d
let packed_children (Pack n) = n.children
let packed_name (Pack n) = n.name

let recompute (Pack n) =
  if n.dirty then (
    n.value <- n.compute ();
    n.dirty <- false)
