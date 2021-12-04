include "macros.asm"
include "hram.asm"
include "longcalc.asm"

SECTION "String methods", ROM0


; Split string given in (B, HL) on character C.
; Returns a list of strings (length, addr) in (B, C, HL).
; All strings in the list point into the same backing array.
StringSplit::
	push BC
	push HL

	call StringCount
	CrashIfNot nc, "!OF:Split"

	; add 1 to get number of substrings
	inc A
	; save this for later
	ld [Scratch], A

	; multiply by 3 to get total output array length
	ld B, A
	add A
	add B

	ld B, A
	call AllocBytes ; now HL = the output array

	; prepare for main loop:
	; DE = output array cursor
	; HL = input string cursor
	; B = chars remaining in string
	; C = chars since last split (ie. length of substring)
	; A = target char
	ld D, H
	ld E, L
	pop HL
	pop BC

	; save start of array for later
	push DE

	; init first output str
	inc DE
	ld A, L
	ld [DE], A
	inc DE
	ld A, H
	ld [DE], A
	dec DE
	dec DE

	ld A, C
	ld C, 0

.loop
	; compare target to current char
	cp [HL]
	jr nz, .next

	; finish current substr by writing length
	push AF
	ld A, C
	ld [DE], A
	; go to next substr
	inc DE
	inc DE
	inc DE
	; write start of next substring and reset vars
	inc HL
	inc DE
	ld A, L
	ld [DE], A
	inc DE
	ld A, H
	ld [DE], A
	dec DE
	dec DE
	ld C, 0
	pop AF

	dec B
	jr nz, .loop
	jr .done

.next
	inc C
	inc HL
	dec B
	jr nz, .loop

.done
	; Finish out the final substr
	ld A, C
	ld [DE], A

	; Restore start of array
	pop HL
	; Restore length of array
	ld A, [Scratch]
	ld B, A
	; Set stride (always 3)
	ld C, 3

	ret


; counts instances of C in (B, HL), returns in A. If c set, count was > 255.
StringCount::
	; check for empty string
	xor A
	or B
	ret z

	ld D, 0
.loop
	ld A, [HL+]
	cp C
	jr nz, .nomatch
	inc D
	jr z, .overflow
.nomatch
	dec B
	jr nz, .loop

	xor A ; clear carry
	ld A, D
	ret

.overflow
	scf ; set carry
	ret


; Removes leading or trailing instances of character C from string (B, HL),
; returning the new string in (B, HL). Preserves C.
StringTrim::
	; TODO
	Crash "!Unimp:Trim"


; For a long string (with 16-bit length) in (DE, HL),
; find the next instance of character C and return how many characters preceeded it in B.
; (DE, HL) points to the remaining long string (starting after the C character).
; Sets z if the string does not contain C. Sets c if B would be > 255.
; In other words, if the caller saves HL before calling, then after calling (B, old HL) is the
; string up to C, and (DE, HL) is the long string following C.
LongStringNext::
	; fast exit if DE == 0
	LongEQ DE, 0
	ret z
	ld B, 0
.loop
	ld A, [HL+]
	cp C
	jr z, .found
	; inc B and check overflow
	inc B
	jr z, .overflow
	; dec DE and check zero
	dec DE
	xor A
	or E
	jr nz, .loop
	or D
	jr nz, .loop
	; DE == 0, z is already set
	ret
.overflow
	scf ; set carry
	ret
.found
	xor A ; clear z
	ret
