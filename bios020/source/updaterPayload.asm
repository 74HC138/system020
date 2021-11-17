.include "system.asm"

UpdaterMain:
		bsr UpdaterSerialInit

        move.l #.text, A0
        move.l A0, -(A7)
        bsr UpdaterSerialWrite
        addq #4, A7
    .commandLoop:
        clr.l D0
        bsr.w UpdaterSerialRead
        move.w D0, -(A7)
        bsr.w UpdaterSerialWriteChar
        move.w (A7)+, D0

        cmpi.b #'v', D0
        beq.w .commandVersion ;displays version information
        cmpi.b #'b', D0
        beq.w .commandBoot ;resets the computer and boots normaly
        cmpi.b #'p', D0
        beq.w .commandPut ;loads 256 bytes over serial into data buffer
        cmpi.b #'g', D0
        beq.w .commandGet ;sends 256 bytes over serial from data buffer
        cmpi.b #'w', D0
        beq.w .commandWrite ;get base address over serial and tries to write the data buffer to that address
        cmpi.b #'r', D0
        beq.w .commandRead ;get base address over serial and load data to data buffer
        cmpi.b #'t', D0
        beq.w .commandTest ;test if device is alive
        bra.w .commandLoop ;ignore byte
    
    .commandTest:
            move.w #'k', -(A7)
            bsr.w UpdaterSerialWriteChar ;sends ok back
            addq.l #2, A7
            bra.w .commandLoop

    .commandRead:
            bsr SerialReadHex32
            move.l D0, A0
            move.l #UpdaterDataBuffer, A1
            move.l #128, D1
        .commandReadLoop:
            move.w (A0)+, (A1)+
            dbra D1, .commandReadLoop
            bra.w .commandTest ;terminate command and return to command receive loop       

    .commandWrite:
            bsr SerialReadHex32
			move.l D0, D2
			move.l D2, D0
			andi.l #$ffffff00, D0
            move.l D0, A0
			andi.l #$ff000000, D0
			move.l D0, A1
            move.l #UpdaterDataBuffer, A2
            move.w #127, D0

            ;there be ghosts beyond here
            ;brief: set eeprom into programm mode and set the right page address, load data into internal buffer, wait until done
            ;enter programm mode
            move.w #$AAAA, ($AAAA, A1)
            move.w #$5555, ($5554, A1)
            move.w #$A0A0, ($AAAA, A1)
            ;fill up internal buffer
        .commandWriteLoop:
            move.w (A2)+, (A0)+
            dbra D0, .commandWriteLoop
			
            ;wait until programming is done
            move.w -(A2), D0
            andi.w #$8080, D0
            subq.l #2, A0
        .commandWriteWait: ;test for inverted data bit 7. If inverted then the write operation is not finished
            move.w (A0), D1
            andi.w #$8080, D1
            eor.w D0, D1
            cmpi.w #$0000, D1
            bne.w .commandWriteWait
            ;repeat test twice
            move.w (A0), D1
            andi.w #$8080, D1
            eor.w D0, D1
            cmpi.w #$0000, D1
            bne.w .commandWriteWait
            ;the data is written and writing is done
            bra.w .commandTest ;terminate command and return to command receive loop

    .commandGet:
            move.l #UpdaterDataBuffer, A3
            move.w #127, D3
        .commandGetLoop:
            move.w (A3)+, -(A7)
			bsr.w SerialWriteHex16
			addq.l #2, A7
            dbra D3, .commandGetLoop

            bra.w .commandLoop
    .commandPut:
            move.l #UpdaterDataBuffer, A3
            move.w #127, D3
        .commandPutLoop:
			bsr SerialReadHex16
            move.w D0, (A3)+
			move.w #'.', -(A7)
			bsr UpdaterSerialWriteChar
			addq.l #2, A7
            dbra D3, .commandPutLoop

            bra.w .commandTest
    .commandBoot:
			move.l #ROM_BASE, D0
			movec.l D0, VBR ;reset to initial VBR location
            move.l ROM_BASE, A7 ;vector for SP init
            ;reset external devices
            reset
            ;clear all registers for good measure
            clr.l D0
            clr.l D1
            clr.l D2
            clr.l D3
            clr.l D4
            clr.l D5
            clr.l D6
            clr.l D7
            suba.l A0, A0
            suba.l A1, A1
            suba.l A2, A2
            suba.l A3, A3
            suba.l A4, A4
            suba.l A5, A5
            suba.l A6, A6
            ;jump to reset routine
            jmp (ROM_BASE + 4).l ;vector for PC init
    .commandVersion:
            move.l #.versionString, A0
            move.l A0, -(A7)
            bsr UpdaterSerialWrite
            addq #4, A7

            bra.w .commandTest

    .text:
            dc.b "BIOS020 Updater V0.01", $00
    .versionString:
            dc.b "[V0.01]", $00
    even

UpdaterSerialInit:
        andi.b #$f0, MFP_TCDCR
        ori.b #$01, MFP_TCDCR
        move.b #$3, MFP_TDDR ;TDO clock divider for 9600 baud serial

        move.b #$88, MFP_UCR ;CLK / 16, 8bit char, no parity
        move.b #$04, MFP_TSR ;set h flag
        move.b #$05, MFP_TSR ;enable transmitter

        move.b #$01, MFP_RSR ;enable receiver

        rts
UpdaterSerialWrite:
        move.l (4, A7), A0
    .loop:
        btst.b #7, MFP_TSR
        beq.w .loop ;as long as the BE flag is clear loop

        cmpi.b #$00, (A0)
        beq.w .return
        move.b (A0)+, MFP_UDR
        bra.w .loop
    .return:
        rts
UpdaterSerialWriteChar:
        btst.b #7, MFP_TSR
        beq.w UpdaterSerialWriteChar

        move.w (4, A7), D0
        move.b D0, MFP_UDR
        rts
UpdaterSerialRead:
        btst.b #7, MFP_RSR ;wait until a char is received
        beq.w UpdaterSerialRead

        move.b MFP_UDR, D0
        rts
__SerialHexTable:
		dc.b "0123456789ABCDEF"
SerialWriteHex8: ;void (int number)
		move.l #__SerialHexTable, A0
	.loop0:
		btst.b #7, MFP_TSR
		beq.w .loop0

		move.w (4, A7), D0
		andi.w #$00f0, D0
		lsr.w #4, D0
		move.b (0,A0,D0), MFP_UDR
	.loop1:
		btst.b #7, MFP_TSR
		beq.w .loop1

		move.w (4, A7), D0
		andi.w #$000f, D0
		move.b (0,A0,D0), MFP_UDR

		rts
SerialWriteHex16: ;void (int number)
		move.w (4, A7), D0
		andi.w #$ff00, D0
		lsr.w #8, D0
		move.w D0, -(A7)
		bsr.w SerialWriteHex8
		addq.l #2, A7

		move.w (4, A7), D0
		andi.w #$00ff, D0
		move.w D0, -(A7)
		bsr.w SerialWriteHex8
		addq.l #2, A7

		rts
SerialReadHex16:
		move.l D2, -(A7)
		clr.l D1
		move.w #3, D2
	.loop:
		lsl.w #4, D1
		bsr UpdaterSerialRead
		subi.b #48, D0
		cmpi.b #10, D0
		blo .skip
		subi.b #7, D0
	.skip:
		andi.w #$000f, D0
		or.w D0, D1
		dbra D2, .loop

		move.l (A7)+, D2
		move.w D1, D0
		move.w D0, -(A7)
		bsr SerialWriteHex16
		move.w (A7)+, D0
		rts
SerialReadHex32:
		move.l D3, -(A7)
		bsr SerialReadHex16
		swap D0
		andi.l #$ffff0000, D0
		move.l D0, D3
		bsr SerialReadHex16
		andi.l #$0000ffff, D0
		or.l D3, D0
		move.l (A7)+, D3
		rts
SerialXON:
		move.w #$11, -(A7)
		bsr UpdaterSerialWriteChar
		addq.l #2, A7
		rts
SerialXOFF:
		move.w #$11, -(A7)
		bsr UpdaterSerialWriteChar
		addq.l #2, A7
		rts



UpdaterDataBuffer:
        dcb.w 128
