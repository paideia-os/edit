# edit

paideia-os modeless, full-screen `vi`-like TUI text editor.

## Synopsis

```
edit [<path>]
```

With a path argument, `edit` loads that file at startup (a missing file
starts an empty buffer targeting that path for save) and every save/reload
below acts on it. With no argument, `edit` starts on an empty, unnamed
buffer; Ctrl+S and Ctrl+O are no-ops until a path exists.

## Description

`edit` is the R71 daily-use replacement for `line`: a modeless, full-screen
editor built directly on raw ANSI/CSI terminal control (no curses/ncurses
equivalent exists in paideia-os yet) and a 64 KiB gap buffer (the R71.M1
"small file" cap; a piece-table for larger files is out of scope for this
milestone).

**Screen.** `edit` switches the terminal to its alternate screen buffer on
startup (`ESC[?1049h`) and restores the primary buffer on exit (`ESC[?1049l`),
so quitting `edit` leaves the invoking shell's scrollback untouched
(`src/tty_raw.pdx`, `Module TtyRaw`).

**Buffer.** Content lives in a single 64 KiB gap buffer (`src/buffer.pdx`,
`Module Buffer`): `buf_insert(pos, byte)`, `buf_delete(pos, count)`, and
`buf_read(pos, out, count)` are the only three mutating/reading primitives;
the gap slides to the edit position on every insert/delete and to the very
end (making content contiguous) whenever something needs to scan raw bytes
(rendering, cursor motion, save).

**Rendering.** `src/render.pdx` (`Module Render`) tracks a 4096-line dirty
bitmap and redraws only the lines a given keystroke actually changed —
inserting or deleting a character marks just that one line; inserting or
deleting a newline marks every subsequent visible line, since a structural
edit shifts everything after it. The viewport is fixed at 24 rows x 80
columns with no scrolling at R71.M1 — a file with more than 24 lines only
shows its first 24; scrolling is future work.

**Editing.** `src/editor.pdx` (`Module Editor`) is the REPL: it reads one
raw keystroke at a time from fd 0 and dispatches on it —

| Key | Action |
|---|---|
| printable (0x20-0x7E) | insert at cursor |
| Backspace / DEL | delete the byte before the cursor |
| Enter (CR/LF) | insert a newline |
| Arrow keys | move the cursor (see below) |
| Ctrl+S | save to the current path |
| Ctrl+O | discard changes, reload the current path |
| Ctrl+Q | quit (restores the primary screen first) |
| ESC | reserved for command mode — **deferred to a later milestone** |

Arrow keys arrive as the 3-byte ANSI sequence `ESC [ <A/B/C/D>`; `edit`
recognizes that shape inline in its ESC handler and dispatches to
`Editor::edit_cursor_move`. Left/Right move the cursor by one byte, clamped
to the buffer's extent. Up/Down jump to the **start** of the previous/next
logical line — a deliberate M1 simplification; they do not yet preserve the
visual column.

A bare ESC (not followed by `[`) is meant to open a `:`-style command line
(`:w`, `:q`, `:wq`, `:e <file>`) — that mode is explicitly out of scope for
this cohort and is a no-op today. Because of that deferral, **Ctrl+Q is an
M1-only addition** so the process has some way to exit and restore the
terminal; it is not part of the eventual command-mode design and may be
retired once `:q` lands.

## Known M1 limitations

- 64 KiB buffer cap (gap buffer, not a piece-table).
- No scrolling — only the first 24 lines of a file are ever shown.
- No command-mode / ex-commands (`:w`, `:q`, `:wq`, `:e`) — Ctrl+S / Ctrl+O
  stand in for save/reload against the one path set at startup.
- Up/Down cursor motion does not preserve the visual column.
- No raw-mode ICANON/ECHO toggle at the kernel side — `edit` writes ANSI
  control sequences to fd 1 but relies on the terminal's own line
  discipline for fd 0 reads, same open substrate gap shell's own line
  editor documents (see `design/` in the paideia-os monorepo).

## Build

```
tools/build.sh
```

Produces `build-out/edit.elf`. See `tools/build.sh` for the `paideia-as`
resolution order and minimum version.

## License

MIT. See `LICENSE`.
