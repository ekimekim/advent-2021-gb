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
	; B/W palette in tile palette 0
    ld A, $80
	ld [TileGridPaletteIndex], A
	ld A, $ff
	ld [TileGridPaletteData], A
	ld [TileGridPaletteData], A
	ld [TileGridPaletteData], A
	ld [TileGridPaletteData], A
	xor A
	ld [TileGridPaletteData], A
	ld [TileGridPaletteData], A
	ld [TileGridPaletteData], A
	ld [TileGridPaletteData], A

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
	LongAddParts [PrintNext+1],[PrintNext], 0,32, H,L ; HL = [PrintNext] + 32
	ld A, %11100000
	and L ; A = L rounded down to 32
	ld [PrintNext], A
	ld A, H
	ld [PrintNext+1], A
	ret


; Go to start of current line on screen. Old chars will still be there unless overwritten.
ResetLine::
	; Truncate to mod 32
	ld A, [PrintNext]
	and %11100000
	ld [PrintNext], A
	ret


; Print string with length B and addr HL, and move print head by that far.
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

	; early exit if empty string
	xor A
	or B
	ret z

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
