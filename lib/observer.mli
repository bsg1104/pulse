(** Handles that keep a node's value readable after stabilization. *)

type 'a t

val observe : ?name:string -> 'a Node.t -> 'a t

(** Read the observed value. Call [Pulse.stabilize] first when inputs may have
    changed. *)
val value : 'a t -> 'a

val node : 'a t -> 'a Node.t
