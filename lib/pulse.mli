(** Pulse — an incremental computation engine.

    Track dependencies between computations and recompute only the values
    affected when an input changes. *)

type 'a t

module Var : sig
  type nonrec 'a t = 'a t

  val create : ?name:string -> 'a -> 'a t
  val set : 'a t -> 'a -> unit
  val value : 'a t -> 'a
end

module Observer : sig
  type 'a t

  val value : 'a t -> 'a
end

val const : ?name:string -> 'a -> 'a t
val map : ?name:string -> 'a t -> f:('a -> 'b) -> 'b t
val map2 : ?name:string -> 'a t -> 'b t -> f:('a -> 'b -> 'c) -> 'c t

val map3 :
  ?name:string -> 'a t -> 'b t -> 'c t -> f:('a -> 'b -> 'c -> 'd) -> 'd t

val observe : ?name:string -> 'a t -> 'a Observer.t

(** Propagate pending changes. Returns the number of nodes recomputed. *)
val stabilize : unit -> int

val last_recomputed : unit -> int
val set_on_recompute : (name:string -> id:int -> unit) -> unit
val clear_on_recompute : unit -> unit

exception Cycle of string

(**/**)
module For_testing : sig
  val check_edge : parent:'a t -> child:'b t -> unit
end
(**/**)
