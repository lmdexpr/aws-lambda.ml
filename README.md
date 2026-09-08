# aws-lambda.ml

OCaml libraries for AWS Lambda custom runtimes.

- `aws-lambda`: the Runtime API loop. HTTP is an OCaml 5 effect (`Transport.Call`); depends on the stdlib only.
- `aws-lambda-eio`: a transport backed by cohttp-eio.

## Install

```sh
opam pin add aws-lambda https://github.com/lmdexpr/aws-lambda.ml.git
opam pin add aws-lambda-eio https://github.com/lmdexpr/aws-lambda.ml.git
```

## Usage

```ocaml
let () =
  Eio_main.run @@ fun env ->
  let client = Cohttp_eio.Client.make ~https:None env#net in
  let endpoint = Option.get (Aws_lambda_eio.endpoint_from_env ()) in
  let fatal =
    Aws_lambda_eio.run ~client ~endpoint @@ fun invocation ->
    Ok (Printf.sprintf {|{"echo":%s}|} invocation.payload)
  in
  prerr_endline (Aws_lambda.fatal_to_string fatal);
  exit 1
```

A handler returns `Ok payload` or `Error (Aws_lambda.Error.v ~error_type msg)`; exceptions are reported as errors.
`run` returns when the loop cannot continue.
`Aws_lambda.Context.of_env Sys.getenv_opt` reads the function configuration; `Aws_lambda.report_init_error` reports start-up failures.

With another HTTP client, handle the effect yourself:

```ocaml
try Aws_lambda.run handler
with effect Aws_lambda.Transport.Call request, k ->
  Effect.Deep.continue k (send request)
```

Ship the binary as `bootstrap` (zip, `provided.al2023`) or as a container image.

## License

MIT
