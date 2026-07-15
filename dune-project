(lang dune 3.16)

(name pulse)

(generate_opam_files true)

(license MIT)

(authors "Bright Senyo Gadzo")

(maintainers "Bright Senyo Gadzo")

(source
 (github brightsenyogadzo/pulse))

(package
 (name pulse)
 (synopsis "An incremental computation engine for OCaml")
 (description
  "Pulse tracks dependencies between computations and recomputes only the \
   values affected when an input changes - like a spreadsheet evaluator for \
   OCaml.")
 (depends
  (ocaml
   (>= 4.14))
  (alcotest
   :with-test)
  (dune
   (>= 3.16))))
