
include "macros.asm"
include "hram.asm"
include "longcalc.asm"


SECTION "Input", ROMX, BANK[1]

Input:
include "inputs/4.asm"
EndInput:
INPUT_LENGTH = EndInput - Input
db 0 ; 0 terminator makes some things easier


SECTION "Main", ROM0


Main::

	ld HL, Input

	; advance HL to just after first newline
.findline
	ld A, [HL+]
	cp "\n"
	jr nz, .findline

	Declare NumbersLen, 2
	LongSub HL, Input+1, DE
	StoreAll NumbersLen, E,D ; NumbersLen = (HL - Input - 1) = length of first line not including newline

	Declare Boards, 128*25

	; HL = start of first board.
	; each board is fixed width:
	;  "\n" + 5 * line
	;  where line = 5 * (nn + " ") + "\n"
	;  where nn is 2-digit number or " " + 1-digit number

	; in this loop, HL = parse head
	; B = board number
	; DE = pointer into Boards array
	ld B, 0
	ld DE, Boards
.parseloop
	inc HL ; pass first \n
	inc B ; count board
	ld C, 25 ; C = number of values to parse for board
.boardparse
	push DE
	ld A, " "
	cp [HL] ; check if char is space
	jr z, .onedigit
	; 2-digit number
	ld A, [HL+]
	sub "0" ; A = value of digit
	ld E, A
	push HL
	ld HL, 0
	MultiplyConst16 DE, 10, HL ; HL = 10 * DE (D is garbage, doesn't matter since we only use L)
	ld E, L
	pop HL
	jr .afterdigit
.onedigit
	inc HL
	ld E, 0
.afterdigit
	ld A, [HL+]
	sub "0" ; A = value of digit
	add E ; add tens column if any
	pop DE
	ld [DE], A ; write parsed value to Boards
	inc DE ; advance Boards pointer
	inc HL ; skip next char, either space or newline
	; next loop
	dec C
	jr nz, .boardparse

	xor A
	cp [HL] ; set z if next char is 0 terminator
	jr nz, .parseloop

	DeclareSet NumBoards, 1, B

IF DEBUG > 0
	LoadLiteral "Boards: "
	call Print
	ld A, [NumBoards]
	call U8ToStr
	call Print
	call PrintLine
ENDC

	ret
