(** HTTP response from the Runtime API. *)

type t = {
  status : int;
  headers : string -> string option;  (** Case-insensitive lookup. *)
  body : string;
}
