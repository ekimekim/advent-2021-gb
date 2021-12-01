
include "macros.asm"
include "hram.asm"
include "longcalc.asm"
include "debug.asm"


SECTION "Input", ROMX, BANK[1]

Input:
include "inputs/1.asm"
EndInput:
INPUT_LENGTH = EndInput - Input


SECTION "Main", ROM0


Main::
	DeclareSet Count, 2, 0

	; by initializing prev value to $ffff, we ensure first comparision isn't "increases"
	DeclareSet PrevValue, 2, $ff

IF DEBUG > 0
	ld DE, EndInput
	call U16ToStr
	call Print
	call PrintLine
ENDC

	ld DE, Input

.mainloop
	; count chars to next newline
	ld B, 0
	ld H, D
	ld L, E
.seekloop
	ld A, [DE]
	inc DE
	cp "\n"
	jr z, .seekloopbreak
	inc B
	jr .seekloop
.seekloopbreak

	; now (B, HL) is a single line
	push DE
	call StrToU16
	CrashIfNot nz, "Bad Int"
	ld H, D
	ld L, E
	pop DE
	; HL = parsed int

	; set c if PrevValue < HL
	LoadAll PrevValue, C,B
	LongLT BC, HL
	Debug "%DE%: %BC% < %HL%? %CARRY%"
	jr nc, .nocount

	LoadAll Count, C,B
	inc BC
	StoreAll Count, C,B

.nocount
	StoreAll PrevValue, L,H

IF DEBUG > 0
	; Print progress
	push DE
	call AllocMark
	push HL
	call U16ToStr
	call Print
	call ResetLine
	pop HL
	call AllocFree
	pop DE
ENDC

	; Check if we're at EOF
	ld BC, EndInput
	LongEQ BC, DE ; set z if EOF

	jr nz, .mainloop

	LoadLiteral "Result: "
	call Print
	LoadAll Count, E,D
	call U16ToStr
	call Print
	call PrintLine

	ret
