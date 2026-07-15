(** Stabilization: dirty propagation and ordered recomputation. *)

(** Mark [node] and all of its descendants dirty, enqueueing each once. *)
val mark_dirty_descendants : Node.packed -> unit

(** Recompute every dirty node in increasing height order.
    Unaffected (clean) nodes are skipped.

    Returns the number of nodes recomputed. *)
val stabilize : unit -> int

(** Optional hook invoked just before a node is recomputed.
    Useful for demos that print evaluation order. *)
val set_on_recompute : (name:string -> id:int -> unit) -> unit

val clear_on_recompute : unit -> unit

(** Nodes recomputed during the most recent [stabilize]. *)
val last_recomputed : unit -> int
