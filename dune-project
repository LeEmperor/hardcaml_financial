(lang dune 3.17)

(name hardcaml_financial)

(generate_opam_files true)

(formatting
 (enabled_for ocaml))

(package
 (name hardcaml_financial)
 (allow_empty)
 (synopsis
  "FPGA market-data feed parsers (CME, NASDAQ, ...) written in Hardcaml")
 (depends
  (ocaml
   (>= 5.1))
  (dune
   (>= 3.15))
  core
  hardcaml
  hardcaml_xilinx_reports
  ppx_hardcaml
  ppx_jane
  hardcaml_circuits
  hardcaml_waveterm
  hardcaml_step_testbench
  hardcaml_networking
  ppx_expect
  base_quickcheck
  async
  core_unix
  xmlm
  (ppx_js_style :with-dev-setup)
  (ocamlformat :with-dev-setup)
  (ocaml-lsp-server :with-dev-setup)))
