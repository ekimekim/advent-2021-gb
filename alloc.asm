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


; Allocate A bytes, returning the start of the section in HL
; Preserves DE
AllocBytes::
	ld B, A

	ld A, [AllocNext]
	ld L, A
	ld A, [AllocNext+1]
	ld H, A

	ld A, B
	LongAddToA HL, BC
	; BC = new AllocNext

	ld A, C
	ld [AllocNext], A
	ld A, B
	ld [AllocNext+1], A

	; if new next high byte > df, we're out of space
	cp $df ; set c if > df
	ret nc

	; Allocation failure!
	LoadLiteral HL, "Out of Cheese!"
	call Print
	jp HaltForever


; Allocate a string of length A, and set the length
NewString::
	ld D, A
	inc A
	call AllocBytes ; alloc length+1 for prefix byte
	ld [HL], D ; set prefix byte
	ret
