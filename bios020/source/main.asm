.include "system.asm"

org ROM_BASE

.include "vector.asm"
.include "serial.asm"
.include "ide.asm"
.include "updater.asm"
.include "compostfetch.asm"
.include "string.asm"
.include "timer.asm"
.include "keyboard.asm"
.include "vdp.asm"

Main:
		move.l #USP_STACK, A0
		movec.l A0, USP
		move.l #ISP_STACK, A0
		movec.l A0, ISP
		move.l #MSP_STACK, A0
		movec.l A0, MSP
		ori.w #$1000, SR

		move.w #1, __TraceDumpRegs

		bsr SerialInit

		bclr #2, MFP_DDR
		btst #2, MFP_GPDR ;test if userinterrupt button is pressed
		beq UpdaterInit ;if pressed jump to updater

		illegal ;cause breakpoint

		move.l #SerialWriteChar, -(A7)
		bsr KbInit
		addq.l #4, A7

		bsr VDPInit

		bsr TimerInit
		andi.w #$f8ff, SR

		move.l #.text0, -(A7)
		bsr SerialWrite
		addq.l #4, A7

	.kb_loop:
		;bsr KbRead
		move.b LED_BASE, D0
		move.l #900, -(A7)
		bsr TimerSleepMs
		addq.l #4, A7

		move.b D0, LED_BASE
		move.l #100, -(A7)
		bsr TimerSleepMs
		addq.l #4, A7

		bra .kb_loop


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

	.text1:
		dc.b "This is a printf test\n"
		dc.b "This is an integer: %d\n"
		dc.b "This is an unsigned integer: %u\n"
		dc.b "This is a long: %ld\n"
		dc.b "This is an unsigned long: %lu\n"
		dc.b "This is a long hex: %lx\n"
		dc.b "And this is a seperate string: %s\n", $00
	.text2:
		dc.b "Im in a seperate string woohoo!", $00
	
	.textTime:
		dc.b "\nTimes Up! Count:", $00

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
