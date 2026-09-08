(lang dune 3.23)

(implicit_transitive_deps false)

(generate_opam_files true)

(name aws-lambda)

(source
 (github lmdexpr/aws-lambda.ml))

(license MIT)

(authors "Yuki Tajiri")

(maintainers "Yuki Tajiri")

(package
 (name aws-lambda)
 (synopsis "AWS Lambda Runtime API (2018-06-01) custom-runtime loop, I/O-agnostic")
 (description
  "The AWS Lambda Runtime API loop used by custom runtimes (next invocation,\nresponse, error). The HTTP round trip is an OCaml 5 effect handled by the\ncaller or by an adapter such as aws-lambda-eio; the core performs no I/O. No\nruntime dependencies beyond the OCaml standard library.")
 (depends
  (ocaml
   (>= 5.3.0))
  dune
  (alcotest :with-test)))

(package
 (name aws-lambda-eio)
 (synopsis "Cohttp-eio transport for aws-lambda")
 (description
  "Handles the aws-lambda transport effect with a cohttp-eio client. Kept\nseparate from the core aws-lambda package so that callers that bring their own\nHTTP client do not pull in eio and cohttp.")
 (depends
  (ocaml
   (>= 5.3.0))
  dune
  (aws-lambda
   (= :version))
  eio
  cohttp-eio
  http
  uri
  (alcotest :with-test)
  (eio_main :with-test)))
