include "hram.asm"


SECTION "Math Methods", ROM0

; Multiply BC and HL as u16, returning the u32 result in HLDE.
; Preserves BC.
U16Mul::
	; 16-bit adding BC to HL is the fastest kind of add we can do,
	; so instead of storing the running total in HLDE and shifting BC left
	; to add higher powers of two, we do the reverse and shift HLDE right over time.
	; Note this means we don't need to zero DE, because by the time we've done 16 iterations
	; we have shifted all the original bits out.
	; And since this leaves A unused, we store the other operand there to pull bits from.
	; Of course A only fits half an operand so we stash the other half and swap out halfway.
	; This leaves us nowhere to put a loop var so we'll need to unroll.

	ld A, H
	ld [Scratch], A ; top half of second operand is used later
	ld A, L ; bottom half of second operand is set

	ld HL, 0

_MulPart: MACRO
	rra ; shift A right, put bottom bit in carry
	jr nc, .noadd\@ ; only add if bottom bit of A was 1
	add HL, BC ; HL += BC, possibly set carry
.noadd\@
	; Shift HLDE right
	; At this point, either:
	;  carry is 0, as we skipped the add
	;  carry is result of the add
	; so as we shift right, we can safely unconditionally pull down the carry into the top of HL
	rr H
	rr L
	rr D
	rr E
ENDM

	; Do 8 rounds, then pull in the top half of the second operand, and do another 8
REPT 8
	_MulPart
ENDR
	ld A, [Scratch]
REPT 8
	_MulPart
ENDR
	ret
