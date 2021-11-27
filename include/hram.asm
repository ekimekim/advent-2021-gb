IF !DEF(_G_HRAM)
_G_HRAM EQU "true"

RSSET $ff80

; uint32 - Number of 2^13 Hz ticks elapsed since computation start
; Only the middle 2 bytes are kept up to date, the bottom byte should be copied from TimerCounter
; before outputting.
Ticks rb 4

; ptr - Points to next available byte in allocator
AllocNext rb 2

ENDC
