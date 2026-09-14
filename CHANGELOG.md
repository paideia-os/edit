# edit — CHANGELOG

Every edit release follows semver. The 0.5.0 line closes R71.M1 (edit#1
through edit#5): repo bootstrap, raw-mode alt-screen TTY, the gap-buffer
model, dirty-line rendering, and basic modeless editing. The 0.6.0 line
adds the modal command line and connection/save fingerprints (edit#6,
edit#7).

---

## v0.6.0 — 2026-09-13 (Wave HHH: edit#6, edit#7)

### Closed

- **edit#6 (R71.M1-006) — modal command line.** `src/editor.pdx`: ESC
  followed by `:` now enters a colon-command line (the deferred bare-ESC
  hook edit#5 reserved). Reads bytes into `_edit_cmd_buf` (256-byte cap)
  until Enter; ESC while collecting cancels. Recognizes `w` (save),
  `q` (quit), `wq` (save then quit), and `e <path>` (retarget the
  editor's working file to `<path>` and load it, discarding unsaved
  changes — same best-effort missing-file posture as startup/Ctrl+O).
  The Ctrl+S and Ctrl+O keybindings are refactored into two new
  callables, `edit_do_save` and `edit_do_load_current`, shared by both
  the control-key and colon-command paths. **caps.decl**: `KIND_PDXFS_
  FILE (read/write)` narrowing dropped from `<arg-path>` to unnarrowed —
  `:e <path>` lets the editor open any path chosen interactively at
  runtime, not just argv[1] (see caps.decl's own note on why this is
  the right shape for an interactive tool vs. cat/cp's batch-argv
  narrowing).

- **edit#7 (R71.M1-007) — save/quit fingerprints.** `edit_do_save` emits
  `edit ok -- file=<path> bytes=<N>\n` to fd 2 on a successful save
  (Ctrl+S or `:w`/`:wq`), reusing `TtyRaw::ttyr_emit_dec` for the
  decimal byte count. `edit_quit` emits `edit exit -- unsaved-
  changes=<0|1>\n` to fd 2 on every quit path (Ctrl+Q, `:q`, `:wq`),
  reflecting a new `edit_dirty` flag set by every successful
  insert/enter/backspace and cleared by a successful save or load.

## v0.5.0 — 2026-09-13 (Wave KK: edit#1, edit#2, edit#3, edit#4, edit#5 — M1 close)

First release. Five-issue cohort landing the whole R71.M1 milestone in one
commit.

### Closed

- **edit#1 (R71.M1-001) — repo bootstrap.** `README.md`, `LICENSE` (MIT),
  this `CHANGELOG.md`, `caps.decl` (`KIND_USER` + `KIND_TTY(write)` +
  `KIND_PDXFS_FILE`), `tools/build.sh`, `manifest.pdxsig` (source form,
  signatures `PENDING` — the ML-DSA-65 signing substrate is not live in
  any repo yet, same posture cat/rm/mv/mkdir's own manifests document).

- **edit#2 (R71.M1-002) — raw-mode TTY.** `src/tty_raw.pdx` (`Module
  TtyRaw`): `edit_tty_raw_enter()` / `edit_tty_raw_exit()` write the
  alternate-screen `ESC[?1049h` / `ESC[?1049l` sequences to fd 1;
  `tty_raw_cursor_to(row, col)` composes and writes `ESC[<row>;<col>H`;
  `tty_raw_erase_line()` writes `ESC[2K`. All four are plain sys_write —
  no KIND_TTY cap, no kernel-side ICANON/ECHO toggle (that gap is still
  open project-wide; see shell's own `lr_tty_set_raw` scaffolding).

- **edit#3 (R71.M1-003) — buffer model.** `src/buffer.pdx` (`Module
  Buffer`): a 64 KiB gap buffer (`_edit_buf`, `gap_start`, `gap_end`,
  `total_len`) with `buf_insert(pos, byte)`, `buf_delete(pos, count)`,
  `buf_read(pos, out, count)`, plus the `buf_move_gap` / `buf_normalize`
  primitives the other four modules build on.

- **edit#4 (R71.M1-004) — rendering.** `src/render.pdx` (`Module
  Render`): a 4096-line dirty bitmap (`_dirty_lines`) and
  `render_frame()`, which walks the fixed 24x80 viewport and redraws
  only dirty lines (cursor-to-row + erase-line + content), clearing each
  bit as it goes.

- **edit#5 (R71.M1-005) — basic editing.** `src/editor.pdx` (`Module
  Editor`): the `_start` REPL — printable insert, Backspace/DEL,
  Enter, arrow-key cursor motion (`edit_cursor_move`), Ctrl+S save /
  Ctrl+O reload against the path given on argv, and an ESC handler that
  recognizes the 3-byte arrow-key CSI shape inline while leaving bare-ESC
  command mode deferred to a later milestone. Ctrl+Q (an M1-only
  addition, see `README.md`) is the only way to quit until `:q` lands.

### Known limitations (tracked for a later milestone)

- No scrolling (files over 24 lines only show their first 24).
- No command-mode / ex-commands (`:w`, `:q`, `:wq`, `:e`).
- Up/Down cursor motion resets to column 0 rather than preserving it.
- Manifest signatures are `PENDING` (crypto substrate not live).
