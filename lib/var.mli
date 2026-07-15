(** Mutable input cells. Setting a variable contaminates its dependents. *)

type 'a t = 'a Node.t

val create : ?name:string -> 'a -> 'a t

(** Update the variable. If the new value is physically distinct from the old
    one, mark all transitive dependents dirty. *)
val set : 'a t -> 'a -> unit

val value : 'a t -> 'a
val node : 'a t -> 'a Node.t
