IF !DEF(_G_MACROS)
_G_MACROS EQU "true"


; Copy BC bytes (non-zero) from [HL] to [DE]. Clobbers A.
LongCopy: MACRO
	; adjust for an off-by-one issue in the outer loop exit condition, unless ALSO affected
	; by an error in the inner loop exit condition that adds an extra round when C = 0
	xor A
	cp C
	jr z, .loop\@
	inc B
.loop\@
	ld A, [HL+]
	ld [DE], A
	inc DE
	dec C
	jr nz, .loop\@
	dec B
	jr nz, .loop\@
	ENDM

; Copy B bytes (non-zero) from [HL] to [DE]. Clobbers A.
Copy: MACRO
.loop\@
	ld A, [HL+]
	ld [DE], A
	inc DE
	dec B
	jr nz, .loop\@
	ENDM

; Shift unsigned \1 to the right \2 times, effectively dividing by 2^N
ShiftRN: MACRO
	IF (\2) >= 4
	swap \1
	and $0f
	N SET (\2) + (-4)
	ELSE
	N SET \2
	ENDC
	REPT N
	srl \1
	ENDR
	PURGE N
	ENDM

; More efficient (for N > 1) version of ShiftRN for reg A only.
; Shifts A right \1 times.
ShiftRN_A: MACRO
	IF (\1) >= 4
	swap A
	N SET (\1) + (-4)
	ELSE
	N SET (\1)
	ENDC
	REPT N
	rra ; note this is a rotate, hence the AND below
	ENDR
	and $ff >> (\1)
	ENDM

; Set the ROM bank number to A
SetROMBank: MACRO
	ld [$2100], A ; I'm not entirely sure how to set the MBC type, and MBC2 doesn't like $2000
	ENDM

; Set the RAM bank number to A
SetRAMBank: MACRO
	ld [$4000], A
	ENDM

; Halts compilation if condition \1 is true with message \2
FailIf: MACRO
IF (\1)
FAIL (\2)
ENDC
ENDM

; Wait for \1 cycles (nops)
; Note that in some cases you may want to use a higher-density (cycles/space) instruction,
; but you need to pick one with side-effects you are ok with.
; push/pop pairs are a good one that average 7 cycles per 2 bytes, but has side effects if SP
; is not a valid stack.
Wait: MACRO
REPT (\1)
	nop
ENDR
ENDM

; Wait for \1 cycles by looping. Takes much, much less space than Wait, but clobbers A and F.
WaitLong: MACRO
; a full 256-loop is 256*4+1-1 = 1024 cycles
REPT (\1) / 1024
	xor A
.loop\@
	dec A
	jr nz, .loop\@
ENDR
; a partial loop is 4*n+2-1 cycles, min 5
_remainder = (\1) % 1024
IF _remainder >= 5
	ld A, (_remainder - 1) / 4
.r_loop\@
	dec A
	jr nz, .r_loop\@
	Wait (_remainder + (-1)) % 4
ELSE
	Wait _remainder
ENDC
ENDM

; Calculate the absolute difference |\1 - \2|
; \1 may be anything you can load into A (immediate, indirect immediate, [HL+], etc)
; \2 must be a non-A register or [HL]
; Outputs in A
AbsDiff: MACRO
	ld A, \1
	sub \2 ; A = \1 - \2, set c if negative
	jr nc, .positive\@
	cpl
	inc A ; A = ~A + 1 = -A
.positive\@
ENDM

; Define a variable in WRAM0 named \1 with size \2.
; This is intended to be used inline, eg.
;   Declare Foo, 2
;   xor A
;   ld [Foo], A
;   ld [Foo+1], A
Declare: MACRO
	PUSHS
	SECTION "Inline Variable \@", WRAM0
\1:
	ds \2
	POPS
ENDM

; As Declare but initialize all bytes to 8-bit immediate or non-A reg in \3.
; Clobbers A.
DeclareSet: MACRO
	Declare \1, \2
	ld A, \3
_declareset_idx = 0
REPT \2
	ld [\1 + _declareset_idx], A
_declareset_idx = _declareset_idx + 1
ENDR
ENDM

; Define a string literal named \1 with content \2. This should be called in a ROM section, eg.
;   Literal MyHello "hello"
; Also defines \1_len (eg. MyHello_len above) as a constant.
Literal: MACRO
\1:
	db \2
\1_len EQU STRLEN(\2)
ENDM

; Define a string litreral with content \2 in ROM, and place its address
; in HL and length in B. This is intended to be used inline, eg.
;   push HL
;   LoadLiteral "foobar"
;   ; HL now points to the "foobar" string, and B is 6
;   ; use it
;   pop HL
LoadLiteral: MACRO
	PUSHS
	SECTION "Inline Literal \@", ROM0
	Literal inline_lit\@, \1
	POPS
	ld HL, inline_lit\@
	ld B, inline_lit\@_len
ENDM

; Prints \1 and halts execution
Crash: MACRO
	LoadLiteral \1
	call Print
	jp HaltForever
ENDM

; If jump condition \1 is not met, print \2 and halt execution
; eg. CrashIfNot nc, "Overflow"
; will crash with "Overflow" if carry flag is set
CrashIfNot: MACRO
	jr \1, .nocrash\@
	Crash \2
.nocrash\@
ENDM

; calls the function at address in HL
; uses rst 7 which we have set up as a trampoline
CallHL: MACRO
	rst $38
ENDM

; LoadAll ADDR, REG{, REG}
; Loads value at ADDR, ADDR+1, ADDR+2, etc into each reg given.
; REG cannot be A. Clobbers A.
LoadAll: MACRO
_loadall_idx = 0
_loadall_base EQUS "\1"
SHIFT
REPT _NARG
	ld A, [(_loadall_base)+_loadall_idx]
	ld \1, A
SHIFT
_loadall_idx = _loadall_idx + 1
ENDR
PURGE _loadall_base
ENDM

; StoreAll ADDR, REG{, REG}
; Stores value into ADDR, ADDR+1, ADDR+2, etc from each reg given.
; REG cannot be A. Clobbers A.
StoreAll: MACRO
_storeall_idx = 0
_storeall_base EQUS "\1"
SHIFT
REPT _NARG
	ld A, \1
	ld [(_storeall_base)+_storeall_idx], A
SHIFT
_storeall_idx = _storeall_idx + 1
ENDR
PURGE _storeall_base
ENDM


ENDC
