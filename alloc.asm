include "hram.asm"
include "longcalc.asm"
include "macros.asm"

SECTION "Dynamic memory", WRAMX, BANK[1]

; all of bank is used as memory
Memory:
	ds 4096


SECTION "Allocator functions", ROM0


AllocInit::
	ld A, LOW(Memory)
	ld [AllocNext], A
	ld A, HIGH(Memory)
	ld [AllocNext+1], A
	ret


; Allocate B bytes, returning the start of the section in HL
; Preserves BC, DE
AllocBytes::
	ld A, [AllocNext]
	ld L, A
	ld A, [AllocNext+1]
	ld H, A

	push HL
	ld A, B
	LongAddToA HL, HL
	; HL = new AllocNext

	ld A, L
	ld [AllocNext], A
	ld A, H
	ld [AllocNext+1], A
	pop HL

	; if new next high byte > df, we're out of space
	cp $df ; set c if > df
	ret c

	; Allocation failure!
	Crash "!OOM!"
