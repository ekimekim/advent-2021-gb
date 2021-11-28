
include "macros.asm"

SECTION "Input", ROMX, BANK[1]

Input:
include "inputs/test.asm"
EndInput:

INPUT_LENGTH = EndInput - Input

SECTION "Test", ROM0

Main::
	LoadLiteral HL, "Test number: "
	call Print
	ld D, HIGH(1234)
	ld E, LOW(1234)
	call U16ToStr
	call Print
	call PrintLine

	ld A, INPUT_LENGTH
	call NewString
	ld B, INPUT_LENGTH
	push HL
	inc HL
	ld D, H
	ld E, L
	ld HL, Input
	Copy
	pop HL
	call Print
	call PrintLine

	ret
