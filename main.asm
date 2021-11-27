include "debug.asm"
include "ioregs.asm"

Section "Core Stack", WRAM0

CoreStackBase:
	ds 64
CoreStack::


Section "Core Functions", ROM0


Start::

	; Disable LCD and audio.
	; Disabling LCD must be done in VBlank.
	; On hardware start, we have about half a normal vblank, but this may depend on the hardware variant.
	; So this has to be done quick!
	xor A
	ld [SoundControl], A
	ld [LCDControl], A

	Debug "Debug messages enabled"

	; Enable double speed
	ld A, 1
	ld [CGBSpeedSwitch], A
	stop

	; Use core stack
	ld SP, CoreStack

	; Init font map
	call GraphicsInit

	; Basic graphics: background on, unsigned tilemap
	ld A, %10010001
	ld [LCDControl], A

	; Timer and vblank interrupts on
	ld A, IntEnableVBlank | IntEnableTimer
	ld [InterruptsEnabled], A

	; Init timer to fire every 2^16 cycles = 2^5 Hz
	xor A
	ld [TimerModulo], A
	ld [TimerCounter], A
	ld A, TimerEnable | TimerFreq12
	ld [TimerControl], A

	ei
	call Main
	di

	; Save timer last digit
	ld A, [TimerCounter]
	ld [Ticks], A
	; Print timer
	Literal HL, "Done. Ticks: "
	call Print
	ld HL, Ticks
	call U32ToStr
	call Print

	jp HaltForever


TimerHandler::
	; increment 16-bit Ticks
	push AF
	ld A, [Ticks+1]
	inc A
	ld [Ticks+1], A
	ld A, [Ticks+2]
	adc 0
	ld [Ticks+2], A
	pop AF
	reti
