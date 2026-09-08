(* 6 MB payload limit plus headroom. *)
let default_max_payload = (6 * 1024 * 1024) + 65_536
let endpoint_from_env () = Sys.getenv_opt "AWS_LAMBDA_RUNTIME_API"

let transport ?(max_payload = default_max_payload) ~client ~endpoint
  (request : Aws_lambda.Request.t) : Aws_lambda.Response.t =
  let uri = Uri.of_string (Aws_lambda.Request.url ~endpoint request) in
  let headers = Http.Header.of_list request.headers in
  let body = Option.map Cohttp_eio.Body.of_string request.body in
  Eio.Switch.run @@ fun sw ->
  let response, body =
    Cohttp_eio.Client.call ~sw ~headers ?body client (request.meth :> Http.Method.t) uri
  in
  let body = Eio.Buf_read.of_flow ~max_size:max_payload body |> Eio.Buf_read.take_all in
  Aws_lambda.Response.
    {
      status = Http.Response.status response |> Http.Status.to_int;
      headers = Http.Header.get (Http.Response.headers response);
      body;
    }

let export_trace_id (handler : Aws_lambda.handler) (invocation : Aws_lambda.Invocation.t) =
  Option.iter (Unix.putenv "_X_AMZN_TRACE_ID") invocation.trace_id;
  handler invocation

let is_cancelled = function Eio.Cancel.Cancelled _ -> true | _ -> false

let handle ?max_payload ~client ~endpoint k =
  let open Effect.Deep in
  try k ()
  with effect Aws_lambda.Transport.Call request, k -> (
    match transport ?max_payload ~client ~endpoint request with
    | response -> continue k response
    | exception exn -> discontinue k exn)

let run ?max_payload ~client ~endpoint handler =
  handle ?max_payload ~client ~endpoint @@ fun () ->
  Aws_lambda.run ~propagate:is_cancelled (export_trace_id handler)
