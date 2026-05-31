(lang dune 3.17)

(name feed_parser_of_hardcaml)

(generate_opam_files true)

(package
 (name feed_parser_of_hardcaml)
 (synopsis "FPGA market-data feed parsers (CME, NASDAQ, ...) written in Hardcaml")
 (depends
  (ocaml (>= 5.1))
  (dune (>= 3.17))
  hardcaml
  ppx_hardcaml
  hardcaml_waveterm
  core))
