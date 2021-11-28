include "macros.asm"
include "hram.asm"

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
