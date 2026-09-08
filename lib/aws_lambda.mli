(** AWS Lambda Runtime API (2018-06-01). HTTP is performed through {!Transport.Call}; nothing else
    does I/O. *)

module Error = Error
module Response = Response
module Invocation = Invocation
module Context = Context
module Request = Request
module Transport = Transport

val api_version : string

type handler = Invocation.t -> (string, Error.t) result
(** [Ok] is posted to [/response], [Error] to [/error]. *)

type fatal =
  | Container_error  (** 500: exit the process. *)
  | Malformed_invocation of Invocation.parse_error
  | Unexpected_status of { request : Request.t; status : int }

val fatal_to_string : fatal -> string
val next : unit -> (Invocation.t, fatal) result
val respond : Invocation.t -> (string, Error.t) result -> (unit, fatal) result

val step : ?propagate:(exn -> bool) -> handler -> (unit, fatal) result
(** {!next}, handler, {!respond}. Exceptions from the handler become [/error] posts unless
    [propagate] returns [true]. *)

val run : ?propagate:(exn -> bool) -> handler -> fatal
(** {!step} until it fails. *)

val report_init_error : Error.t -> (unit, fatal) result
