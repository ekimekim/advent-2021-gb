
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
