(** Core node representation for the dependency graph.

    Each node caches a value, tracks a dirty flag, and maintains parent/child
    edges. Parents are dependencies; children are dependents. *)

type 'a t

(** Existential wrapper so heterogeneous nodes can share a graph. *)
type packed = Pack : 'a t -> packed

val create :
  name:string ->
  height:int ->
  value:'a ->
  dirty:bool ->
  compute:(unit -> 'a) ->
  'a t

val id : _ t -> int
val name : _ t -> string
val height : _ t -> int
val is_dirty : _ t -> bool
val set_dirty : _ t -> bool -> unit

(** Return the cached value without recomputing. *)
val get : 'a t -> 'a

val set_value : 'a t -> 'a -> unit

(** Replace the recomputation function (used during node construction). *)
val set_compute : 'a t -> (unit -> 'a) -> unit

val parents : _ t -> packed list
val children : _ t -> packed list

(** Add a dependency edge: [child] depends on [parent]. *)
val add_child : parent:_ t -> child:_ t -> unit

val pack : 'a t -> packed
val packed_id : packed -> int
val packed_height : packed -> int
val packed_is_dirty : packed -> bool
val packed_set_dirty : packed -> bool -> unit
val packed_children : packed -> packed list
val packed_name : packed -> string

(** Run the node's compute function and store the result. Clears dirty. *)
val recompute : packed -> unit
