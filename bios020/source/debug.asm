include "system.asm"

org ROM_BASE

include "vector.asm"

Main:
		move.w RAM_BASE, D0
		move.w IDE0_BASE, D0
		move.w IDE1_BASE, D0
		move.b MFP_BASE, D0
		jmp Main.l
