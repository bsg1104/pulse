(** Dependency-graph utilities: heights and cycle detection. *)

exception Cycle of string

(** [true] if [target] is reachable from [start] by following children
    (dependents). Used when adding an edge [parent -> child]. *)
val depends_on : start:Node.packed -> target:Node.packed -> bool

(** Reject the edge if it would introduce a cycle. *)
val check_edge : parent:_ Node.t -> child:_ Node.t -> unit

(** Height must be strictly greater than every parent. *)
val height_for : parents:Node.packed list -> int
