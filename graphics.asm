include "macros.asm"
include "vram.asm"
include "ioregs.asm"
include "longcalc.asm"
include "hram.asm"

SECTION "Graphics textures", ROM0

GraphicsTextures:

; First 32 chars are blank (non-printing)
REPT 32
REPT 8
	dw `00000000
ENDR
ENDR

; printable ascii
include "assets/font.asm"

EndGraphicsTextures:

TEXTURES_SIZE EQU EndGraphicsTextures - GraphicsTextures

SECTION "Graphics methods", ROM0


GraphicsInit::
	; Identity palette
    ld A, %11100100
    ld [TileGridPalette], A
    ld [SpritePalette0], A

    ; Textures into unsigned tilemap
    ld HL, GraphicsTextures
    ld BC, TEXTURES_SIZE
    ld DE, BaseTileMap
    LongCopy

	; Set PrintNext to (0,0)
	xor A
	ld [PrintNext], A
	ld A, HIGH(TileGrid)
	ld [PrintNext+1], A

	ret


; Go to next line on screen. There is no overrun protection.
PrintLine::
	; Find next line by adding 32 then truncate
	LongAdd PrintNext, 32, HL
	ld A, %11100000
	and L ; A = L rounded down to 32
	ld [PrintNext], A
	ld A, H
	ld [PrintNext+1], A
	ret


; Print string pointed to by HL, and move print head by that far.
; Blocks until next vblank.
; There is no overrun protection or line wrapping.
Print::
	; Block until next frame
	ld A, 1
	ld [WaitingForFrame], A
.waitloop
	halt
	ld A, [WaitingForFrame]
	and A
	jr nz, .waitloop

	; DE = print head
	ld A, [PrintNext]
	ld E, A
	ld A, [PrintNext+1]
	ld D, A

	; B = str length and set HL to str start. early exit if len=0
	ld A, [HL+]
	and A
	ret z
	ld B, A

.loop
	ld A, [HL+]
	ld [DE], A
	inc DE
	dec B
	jr nz, .loop

	ld A, E
	ld [PrintNext], A
	ld A, D
	ld [PrintNext+1], A

	ret
