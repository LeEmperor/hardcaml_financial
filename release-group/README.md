# release-group — release candidate staging

Staging area for GitHub release assets. Each candidate is assembled here, checked, then
zipped and uploaded. Nothing here is authoritative: every file is a **copy** of something
produced elsewhere in the repo, and the whole directory can be deleted and rebuilt from
scratch.

`.gitignore` ignores `release-group/*` except this README, so candidates never land in the
repo history.

## Why copies

`lib/common/generate.ml` writes each target to a fixed repo-relative path
(`uart_test_top.v`, `validation/uart_loopback_validation_harness.v`, and so on). Those
paths are baked into the generator, referenced by the top-level README, and are where
Vivado picks the RTL up. Moving the originals in here would break regeneration and the
board project. Always copy.

## Layout

One directory per zip, named `hardcaml-financial-<version>-<bundle>`:

```
release-group/
  MANIFEST.txt                              provenance for the whole candidate
  hardcaml-financial-v0.1-rtl/              the generated Verilog
    uart_test_top.v
    hardcaml_cme_feed_parser.v
    hardcaml_uart_frame_parser.v
    validation/uart_loopback_validation_harness.v
    MANIFEST.txt
    SHA256SUMS
  hardcaml-financial-v0.1-arty-a7/          flash-and-run bundle
    uart_loopback_validation_harness.bit    xc7a100tcsg324-1 ONLY
    unified_tx_rx.xdc
    uart_app.py                             host-side companion
    test_uart_app_echo.py                   offline classifier check
    RUNBOOK.md                              copy of validation/README.md
    MANIFEST.txt
    SHA256SUMS
  hardcaml-financial-v0.1-reports/          evidence the RTL closes timing
    board-routed/                           full Vivado board run
    ooc-uart-loopback-harness/              out-of-context synth estimates
    MANIFEST.txt
    SHA256SUMS
```

The RTL bundle deliberately **mirrors the repo's directory structure** (`validation/`
subdir preserved) so the repo-relative paths in `MANIFEST.txt` resolve correctly from
inside the bundle.

## MANIFEST.txt vs SHA256SUMS

Two different jobs; both are needed.

- **`MANIFEST.txt`** answers *what produced this* — git SHA, tag, branch, tree state, opam
  switch, OCaml/dune/hardcaml versions, plus hashes with repo-relative paths. It is written
  by `scripts/generate_rtl.py` in the same pass that emits the RTL, so it cannot disagree
  with the files. Identical copies go in all three bundles, so someone who downloads only
  one zip still gets full provenance.
- **`SHA256SUMS`** answers *did this download intact* — bundle-relative paths, one per
  bundle, so `sha256sum -c SHA256SUMS` works from inside an unzipped bundle with no
  knowledge of the repo.

## Rebuilding a candidate

One command does everything below — generate, stage, checksum, verify, zip:

```sh
./scripts/make-release.sh --version v0.1 --require-clean
```

`--require-clean` refuses to run against uncommitted tracked changes, so the manifest names
a published commit. Drop it while iterating; the script warns loudly instead, and stamps the
dirty state into `MANIFEST.txt`.

Useful flags:

| flag | effect |
| --- | --- |
| `--skip-generate` | stage from RTL already on disk (requires an existing `MANIFEST.txt`) |
| `--no-zip` | stage and verify only |
| `--bitstream <path>` | override the board bundle's `.bit` |
| `--ooc <dir>` | stage an out-of-context report directory; repeatable |
| `--output <dir>` | staging directory (default `release-group`) |

It re-clears only the three bundle directories for the given `--version`, so re-running is
safe and idempotent. `--version` has no default on purpose: the script will not guess your
release number.

Two things it refuses to do quietly. It dies rather than staging a partial bundle if any
target is missing, and it skips any `--ooc` directory with no `post_synth_*` outputs —
`hardcaml_xilinx_reports` generates a project directory per circuit whether or not Vivado
ever ran, so a populated-looking directory is not evidence of a run. The RTL file list comes
from `generate_rtl.py --list`, so the two scripts cannot drift on which targets exist or
where they land.

Doing it by hand instead:

```sh
cd release-group/<bundle>
find . -type f ! -name SHA256SUMS -printf '%P\n' | sort | xargs sha256sum > SHA256SUMS
sha256sum -c SHA256SUMS
```

## The known gap

Nothing here verifies that the bitstream was built from the RTL being shipped. Regenerate
the `.v`, skip Vivado, run the script, and it will ship fresh RTL beside a stale `.bit`:
`MANIFEST.txt` records the hash of both without complaint rather than catching the
mismatch. If the RTL changed, re-run implementation in the board project **before**
assembling.

## Before the first candidate

No release has been cut from this repository yet, and two of the three bundles have nothing
to put in them:

- [ ] **A bitstream.** `make-release.sh` expects
      `validation/vivado25_proj/pre_synth_validation_run.runs/impl_1/uart_loopback_validation_harness.bit`.
      Until a Vivado board project exists, the arty-a7 bundle stages the host scripts and
      the XDC and warns about the missing `.bit`.
- [ ] **Reports.** `synthesis/README.md` has the `-run` invocation. Nothing has been run
      against these blocks; the reports bundle is empty until something has.
- [ ] **A version.** There are no tags. `v0.1` is used as the example above and is not a
      decision.

## Not shipped, deliberately

`generate.exe` — large, unstripped, dynamically linked against the `5.2.0+ox` switch.
Anyone who can run it can build it; anyone who cannot gets a paperweight. Its entire output
is the RTL bundle above, which is the thing worth shipping.

Also excluded: `_build/`, `validation/vivado25_proj/` (the Vivado project itself, large and
machine-specific), `__pycache__/`, `.Xil/`, and
`validation/constraints/arty_master_DO_NOT_EDIT.xdc` (Digilent's vendor master, already in
the source tarball).
