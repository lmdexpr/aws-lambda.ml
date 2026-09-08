module Error = Error
module Response = Response
module Invocation = Invocation
module Context = Context
module Request = Request
module Transport = Transport

let api_version = Request.api_version

type handler = Invocation.t -> (string, Error.t) result

type fatal =
  | Container_error
  | Malformed_invocation of Invocation.parse_error
  | Unexpected_status of { request : Request.t; status : int }

let fatal_to_string = function
  | Container_error -> "Runtime API answered 500: the execution environment is unrecoverable"
  | Malformed_invocation e -> "malformed /next response: " ^ Invocation.parse_error_to_string e
  | Unexpected_status { request; status } ->
    let meth = match request.meth with `GET -> "GET" | `POST -> "POST" in
    Printf.sprintf "%s %s: unexpected status %d" meth request.path status

let next () =
  let response = Transport.call Request.next in
  match response.status with
  | 200 -> Invocation.of_response response |> Result.map_error (fun e -> Malformed_invocation e)
  | 500 -> Error Container_error
  | status -> Error (Unexpected_status { request = Request.next; status })

let post request =
  match (Transport.call request).status with
  | 202 -> Ok ()
  | 500 -> Error Container_error
  | status -> Error (Unexpected_status { request; status })

let respond invocation = function
  | Ok payload -> post (Request.response invocation payload)
  | Error error -> post (Request.error invocation error)

let report_init_error error = post (Request.init_error error)

let step ?(propagate = fun _ -> false) (handler : handler) =
  let ( let* ) = Result.bind in
  let* invocation = next () in
  let outcome =
    match handler invocation with
    | outcome -> outcome
    | exception exn when propagate exn -> raise exn
    | exception exn -> Error (Error.of_exn ~backtrace:(Printexc.get_raw_backtrace ()) exn)
  in
  respond invocation outcome

let rec run ?propagate handler =
  match step ?propagate handler with Ok () -> run ?propagate handler | Error fatal -> fatal
