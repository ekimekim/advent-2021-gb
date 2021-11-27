
include "macros.asm"

SECTION "Test", ROM0

Main::
	LoadLiteral HL, "Test number: "
	call Print
	ld D, HIGH(1234)
	ld E, LOW(1234)
	call U16ToStr
	call Print
	call PrintLine
	ret
