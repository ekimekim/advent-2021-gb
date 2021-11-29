
include "macros.asm"
include "hram.asm"
include "longcalc.asm"


SECTION "Input", ROMX, BANK[1]

Input:
include "inputs/test.asm"
EndInput:
INPUT_LENGTH = EndInput - Input


SECTION "Test", ROM0


Main::
	LoadLiteral "Number: "
	call Print
	; print 1234 * 4321 (should be 5332114)
	ld BC, 1234
	ld HL, 4321
	call U16Mul
	call U32ToStr
	call Print
	call PrintLine

	ld B, INPUT_LENGTH
	ld HL, Input
	ld C, "\n"
	call StringSplit

	ld D, H
	ld E, L
	ld HL, PrintEach
	call ListMap

	ret


PrintEach:
	; length
	ld A, [DE]
	ld B, A
	; addr
	inc DE
	ld A, [DE]
	ld L, A
	inc DE
	ld A, [DE]
	ld H, A
	call Print
	call PrintLine
	xor A
	ret
