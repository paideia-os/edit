# edit — CHANGELOG

Every edit release follows semver. The 0.5.0 line closes R71.M1 (edit#1
through edit#5): repo bootstrap, raw-mode alt-screen TTY, the gap-buffer
model, dirty-line rendering, and basic modeless editing.

---

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
