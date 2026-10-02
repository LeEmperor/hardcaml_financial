#!/usr/bin/env bash
# University of Florida
# Author: Bohdan Purtell
# Module: "check.sh"
# Regenerate the native Hardcaml board top and run the complete MII-to-UART simulation.
set -euo pipefail
cme_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
output="$cme_root/_build/phase7"
mkdir -p "$output"

cd "$cme_root"
./scripts/with-switch.sh dune exec lib/common/generate.exe -- cme
./scripts/with-switch.sh dune exec lib/common/generate.exe -- cme_feed_parser_validation_harness_arty
./scripts/with-switch.sh dune exec lib/common/generate.exe -- cme_feed_parser_validation_harness_arty_sim
./scripts/with-switch.sh dune runtest validation/phase7
./scripts/with-switch.sh dune runtest test/cme/validation_sink test/cme/validation_core

board_rtl="$cme_root/cme_feed_parser_validation_harness_arty.v"
sim_rtl="$cme_root/cme_feed_parser_validation_harness_arty_sim.v"
iverilog -g2012 -tnull -s cme_feed_parser_validation_harness_arty "$board_rtl"
echo "wrote $(basename "$board_rtl") (self-contained)"

python3 validation/phase7/board_acceptance.py vectors "$output"

iverilog -g2012 -s mii_testbench -o "$output/mii.vvp" \
    "$cme_root/validation/phase7/mii_testbench.sv" \
    "$sim_rtl"
(
    cd "$output"
    vvp mii.vvp | tee simulation.txt
)
sha256sum "$board_rtl" "$sim_rtl" "$cme_root/cme_mdp3_feed_parser.v" \
    "$cme_root/validation/constraints/cme_arty.xdc" > "$output/rtl.sha256"
./scripts/with-switch.sh opam pin list | rg '^hardcaml_networking' \
    > "$output/networking_package.txt"
