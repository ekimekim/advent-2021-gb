include "debug.asm"
include "longcalc.asm"

SECTION "Conversion temp buffers", WRAM0

IntBuffer:
ds 4 ; store up to uint32, little endian as normal

SECTION "Conversion functions", ROM0

; *PtrToStr: Convert pointed-to value in HL to str, put str in (B, HL)

U8PtrToStr::
	ld A, [HL]
	jp U8ToStr

U16PtrToStr::
	ld A, [HL+]
	ld E, A
	ld D, [HL]
	jp U16ToStr

U32PtrToStr::
	ld A, [HL+]
	ld E, A
	ld A, [HL+]
	ld D, A
	ld A, [HL+]
	ld H, [HL]
	ld L, A
	jp U32ToStr

; *ToStr: Convert value from regs into str, put str in (B, HL)
; 8: A, 16: DE, 32: HLDE
U8ToStr::
	ld A, E
	xor A
	ld D, A
	ld L, A
	ld H, A
	jp U32ToStr

U16ToStr::
	xor A
	ld L, A
	ld H, A
	jp U32ToStr

U32ToStr::
	ld A, E
	ld [IntBuffer], A
	ld A, D
	ld [IntBuffer+1], A
	ld A, L
	ld [IntBuffer+2], A
	ld A, H
	ld [IntBuffer+3], A
	call _U32ToBCD
	jp _BCDToStr


; Convert IntBuffer into 5-byte BCD value in CDEHL
_U32ToBCD:
	; repeat 32 times:
	;  for each digit
	;   if digit >= 5, digit += 3
	;  shift the entire composite value (BCD, Int) left one

	; we store loop count in B, and the 5-byte BCD value in CDEHL
	ld B, 32
	xor A
	ld C, A
	ld D, A
	ld E, A
	ld H, A
	ld L, A

_Check5: MACRO
    ld A, \1
    and $0f << \2
    cp 5 << \2
    jr c, .lessThan5\@
    add 3 << \2
	push BC
    ld B, A
    ld A, \1
    and $0f << (4 - \2) ; get opposite half
    or B ; combine with new value for this half
	pop BC
    ld \1, A
.lessThan5\@
    ENDM

.loop
	_Check5 C, 0
	_Check5 C, 4
	_Check5 D, 0
	_Check5 D, 4
	_Check5 E, 0
	_Check5 E, 4
	_Check5 H, 0
	_Check5 H, 4
	_Check5 L, 0
	_Check5 L, 4

	ld A, [IntBuffer]
	rla
	ld [IntBuffer], A
	ld A, [IntBuffer+1]
	rla
	ld [IntBuffer+1], A
	ld A, [IntBuffer+2]
	rla
	ld [IntBuffer+2], A
	ld A, [IntBuffer+3]
	rla
	ld [IntBuffer+3], A
	rl L
	rl H
	rl E
	rl D
	rl C

	dec B
	jp nz, .loop

	ret


; Convert BCD from CDEHL into newly allocated str without leading zeroes,
; return str len in B, addr in HL
_BCDToStr:
	; Determine length, put in B
	ld B, 10

_CheckZero: MACRO
	ld A, $f0
	and \1
	jr nz, .nonzerofound
	dec B
	ld A, $0f
	and \1
	jr nz, .nonzerofound
	dec B
ENDM

	_CheckZero C
	_CheckZero D
	_CheckZero E
	_CheckZero H
	_CheckZero L

.nonzerofound
	; if length is 0, length should be 1 for "0"
	xor A
	or B
	jr nz, .nonzerolen
	inc B
.nonzerolen

	push BC
	push DE
	push HL
	call AllocBytes ; allocate str of length B, returns into HL

	; move HL to last char of str (add length-1)
	ld A, B
	dec A
	LongAddToA HL, HL

; \1 = source reg, \2 = whether to use high half, \3 = where to break to
_WriteDigit: MACRO
	ld A, \1
IF \2 == 1
	swap A
ENDC
	and $0f
	add 48
	ld [HL-], A
	dec B
	jr z, \3
ENDM

	pop DE ; pop old HL into DE
	_WriteDigit E, 0, .pop2
	_WriteDigit E, 1, .pop2
	_WriteDigit D, 0, .pop2
	_WriteDigit D, 1, .pop2
	pop DE ; pop old DE into DE
	_WriteDigit E, 0, .pop1
	_WriteDigit E, 1, .pop1
	_WriteDigit D, 0, .pop1
	_WriteDigit D, 1, .pop1
	pop DE ; pop old BC into DE. Note D is now original length.
	_WriteDigit E, 0, .pop0
	_WriteDigit E, 1, .pop0

	Debug "Unreachable"
	jp HaltForever

.pop0
	ld B, D
	inc HL ; correct HL back to start of string, instead of 1 before
	ret
.pop2
	pop BC
.pop1
	pop BC ; final pop restores original length to B
	inc HL ; correct HL back to start of string, instead of 1 before
	ret
