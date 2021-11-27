include "macros.asm"
include "longcalc.asm"

SECTION "List methods", ROM0

; These methods operate on Lists.
; A List is made up of an address, a length, and a stride. Length and stride are u8.
; Starting at <address>, it expects <length> items of <stride> bytes each.
; Most methods take the address in HL, the length in B and the stride in C.
; Note a list may not have a unique backing, it is more like a slice in other languages.

; This function expects the list address in DE.
; For each item in list, call function specified in HL.
; The function will be called with DE pointing at the current item.
; If A is non-zero after returning, no further items will be processed.
; The A value of the final function called is preserved back to the caller
; (this means that it will always be 0 if the list ran to completion).
; The address, length and stride on output will be a valid list, representing all unprocessed items
; (eg. if the list ran to completion, it is an empty list).
ListMap::
	; short circuit B=0 case
	xor A
	or B
	ret z
.loop
	; call function (assume it clobbers all)
	push BC
	push DE
	push HL
	CallHL
	pop HL
	pop DE
	pop BC

	; check return value
	and A
	ret nz

	; addr += stride
	ld A, C
	LongAddToA DE, DE

	; length -= 1 and loop
	dec B
	jr nz, .loop

	ret
