.include "system.asm"

org ROM_BASE

.include "vector.asm"
.include "serial.asm"
.include "ide.asm"
.include "updater.asm"
.include "compostfetch.asm"
.include "string.asm"

Main:
		bsr SerialInit

		bclr #2, MFP_DDR
		btst #2, MFP_GPDR ;test if userinterrupt button is pressed
		beq UpdaterInit ;if pressed jump to updater

		move.l #CompostFetch, -(A7)
		bsr SerialWrite
		addq.l #4, A7

		move.l #.text0, -(A7)
		bsr SerialWrite
		addq.l #4, A7

		move.l #.text2, -(A7)
		bsr SerialWrite
		addq.l #4, A7

		andi.w #$f8ff, SR

		bsr getBootblockCount
		move.l D0, D2 ;move bootblock count to trash proof register
		move.l D0, -(A7)
		bsr SerialWriteDec32
		addq.l #4, A7

		move.l #__CommandBuffer, A2
		clr.l D2

	.cmdLoop:
		bsr SerialAvailable
		cmpi.b #0, D0
		beq .cmdLoop
		bsr SerialRead
		move.w D0, -(A7)
		bsr SerialWriteChar
		move.w (A7)+, D0
		cmp.w '\n', D0
		beq .cmdInterpret
		move.w D0, (A2, D2.w*2)
		addq.w #1, D2
		bra .cmdLoop

	.cmdInterpret:
		move.w #0, (A2, D2.w*2) ;add null termination to string

		move.l #__CommandBuffer, A2
		move.l A2, -(A7)
		move.l #.textCommandTest, -(A7)
		bsr StringCompare
		addq.l #8, A7
		cmpi.l #0, D0
		beq .commandTest

		move.l #__CommandBuffer, A2
		move.l A2, -(A7)
		move.l #.textCommandIntro, -(A7)
		bsr StringCompare
		addq.l #8, A7
		cmpi.l #0, D0
		beq .commandIntro

		move.l #.textCommandnotfound, -(A7)
		bsr SerialWrite
		addq.l #4, A7
		move.l #__CommandBuffer, A2
		clr.l D2
		bsr .cmdLoop

	.commandTest:
		move.l #.text1, -(A7)
		bsr SerialWrite
		addq.l #4, A7
		move.l #__CommandBuffer, A2
		clr.l D2
		bsr .cmdLoop

	.commandIntro:
		move.l #.text0, -(A7)
		bsr SerialWrite
		addq.l #4, A7
		move.l #__CommandBuffer, A2
		clr.l D2
		bsr .cmdLoop


	.text0:
	;ascii text font Doom (www.coolgenerator.com/ascii-text-generator)
		dc.b "\n\n"
		dc.b "\e[91m", "______ _____ _____ _____  _____  _____  _____\n"
		dc.b "\e[92m", "| ___ \\_   _|  _  /  ___||  _  |/ __  \\|  _  |\n"
		dc.b "\e[93m", "| |_/ / | | | | | \\ `--. | |/' |`' / /'| |/' |\n"
		dc.b "\e[94m", "| ___ \\ | | | | | |`--. \\|  /| |  / /  |  /| |\n"
		dc.b "\e[95m", "| |_/ /_| |_\\ \\_/ /\\__/ /\\ |_/ /./ /___\\ |_/ /\n"
		dc.b "\e[96m", "\\____/ \\___/ \\___/\\____/  \\___/ \\_____/ \\___/"
		dc.b "\e[0m\n\n", $00
	.text2:
		dc.b "\e[1m", "Bootblocks found:", "\e[0m", $00
	.text1:
		dc.b "This is test. Hello world!\n", $00

	.textCommandTest:
		dc.b "test", $00
	.textCommandIntro:
		dc.b "intro", $00
	.textCommandnotfound:
		dc.b "Error: not a valid command!\n", $00

	even



getBootblockCount:
		move.l #12345, D0
		rts


BIOS_END:
;Alignment hack because madmac does not support alignment to an arbitary size
;This align is needed because right after the bios follows the first bootblock but that has to be aligned to 256 bytes because the eeprom has 256 bytes per page
;(actually 128 bytes per page but because we use two eeproms (29ee010) in tandem the page size is twice as large)
;If the target to compile to has a different page size this has to be changed
if ((BIOS_END & $ff) != 0) ;check if alligned to 256 byte boundry
	ds.b 256 - (BIOS_END & $ff) ;if not alligned then add filler
endif
print "BIOS_END: ", /d/l BIOS_END

FIRST_BOOTBLOCK:
;the first bootblock starts here
print "FIRST_BOOTBLOCK: ", /d/l FIRST_BOOTBLOCK
print "Filled bytes: ", /d FIRST_BOOTBLOCK - BIOS_END

.include "ramdefs.asm"
