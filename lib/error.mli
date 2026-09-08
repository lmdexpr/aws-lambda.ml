(** Error reported to Lambda. *)

type t = { error_type : string; error_message : string; stack_trace : string list }

val v : ?stack_trace:string list -> error_type:string -> string -> t
(** [stack_trace] defaults to []. Lambda recommends [<Category.Reason>] for [error_type]. *)

val of_exn : ?backtrace:Printexc.raw_backtrace -> exn -> t
(** [error_type] is the constructor name, [error_message] is [Printexc.to_string]. *)

val to_json : t -> string
(** [{"errorMessage":…,"errorType":…,"stackTrace":[…]}]. *)
