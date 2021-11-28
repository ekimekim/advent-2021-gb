
include "macros.asm"

SECTION "Input", ROMX, BANK[1]

Input:
include "inputs/test.asm"
EndInput:

INPUT_LENGTH = EndInput - Input

SECTION "Test", ROM0

Main::
	LoadLiteral "Test number: "
	call Print
	ld D, HIGH(1234)
	ld E, LOW(1234)
	call U16ToStr
	call Print
	call PrintLine

	ld B, INPUT_LENGTH
	call AllocBytes
	push BC
	push HL
	ld D, H
	ld E, L
	ld HL, Input
	Copy
	pop HL
	pop BC
	call Print
	call PrintLine

	ret
