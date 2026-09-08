(** Cohttp-eio transport for [Aws_lambda]. *)

val endpoint_from_env : unit -> string option
(** [AWS_LAMBDA_RUNTIME_API] *)

val transport :
  ?max_payload:int ->
  client:Cohttp_eio.Client.t ->
  endpoint:string ->
  Aws_lambda.Request.t ->
  Aws_lambda.Response.t
(** [max_payload] bounds response bodies; default fits Lambda's 6 MB limit. *)

val handle : ?max_payload:int -> client:Cohttp_eio.Client.t -> endpoint:string -> (unit -> 'a) -> 'a
(** Handles {!Aws_lambda.Transport.Call} with {!transport}. *)

val run :
  ?max_payload:int ->
  client:Cohttp_eio.Client.t ->
  endpoint:string ->
  Aws_lambda.handler ->
  Aws_lambda.fatal
(** {!Aws_lambda.run} under {!handle}. Sets [_X_AMZN_TRACE_ID] per invocation; lets
    [Eio.Cancel.Cancelled] through. *)
