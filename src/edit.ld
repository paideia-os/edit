/* src/edit.ld — edit linker script (edit#1, paideia-os/edit).
 *
 * Mirrors the paideia-os/cat repo's src/cat.ld byte-for-byte layout
 * convention (itself mirroring the monorepo's src/user/*.ld family):
 * text at 0x00400000, data at 0x00600000, bss contiguous with data
 * (the R31.M2-1595 rule — no `. = 0x00700000;` between .data and
 * .bss).
 *
 * edit is four modules (TtyRaw, Buffer, Render, Editor) plus the
 * Editor module's own _start — tools/build.sh links every src/*.o
 * produced by `paideia-as build --emit elf64` against this script.
 * `*(.text .text.*)` and `*(.rodata .rodata.*)` fold in every
 * object's sections regardless of module count.
 */

OUTPUT_FORMAT(elf64-x86-64)
OUTPUT_ARCH(i386:x86-64)
ENTRY(_start)

PHDRS
{
    text PT_LOAD FLAGS(5);
    data PT_LOAD FLAGS(6);
}

SECTIONS
{
    . = 0x00400000;

    .text : ALIGN(4K) {
        KEEP(*(.text._start))
        *(.text .text.*)
    } :text

    .rodata : ALIGN(8) {
        *(.rodata .rodata.*)
    } :text

    . = 0x00600000;

    .data : ALIGN(4K) {
        *(.data .data.*)
    } :data

    /* R31.M2-1595 (#1595): .bss follows .data CONTIGUOUSLY -- no
     * `. = 0x00700000;` here. Buffer::_edit_buf (64 KiB) is the
     * dominant .bss footprint, plus Editor's smaller _edit_io_buf
     * (4 KiB) / _edit_filename (256 B) and Render's _dirty_lines
     * (512 B) -- the contiguity rule keeps that from opening a
     * multi-hundred-KiB PT_LOAD hole.
     */
    .bss (NOLOAD) : ALIGN(4K) {
        *(COMMON)
        *(.bss .bss.*)
        . = ALIGN(4K);
    } :data

    /DISCARD/ : {
        *(.comment)
        *(.eh_frame*)
        *(.note.*)
    }
}
