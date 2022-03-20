.include "system.asm"

UPDATER_BEGIN:

main:
		bsr SerialInit
    .cmdLoop:
        bsr SerialRead
        cmpi.b 'i', D0
        beq SendInfo
        cmpi.b 'v', D0
        beq SendVersion


        move.l #.textCNF, -(A7)
        bsr SerialWrite
        addq.l #4, A7
        bra .cmdLoop

    .textCNF:
        dc.b "ERROR: Command not found\n", $00


SendInfo:

    .textInfo:
        dc.b "{\n"
        dc.b "\"ramsize\": ", /u RAM_SIZE, ",\n"
        dc.b "\"ramfree\": ", /u (RAM_SIZE - (UPDATER_END - UPDATER_BEGIN)), ",\n"
        dc.b "\"rombase\": ", /u ROM_BASE, ",\n"
        dc.b "\"romsize\": ", /u ROM_SIZE, ",\n"
        dc.b "\"version\": \"2.00A\"\n"
        dc.b "}", $00



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



;----------------------------------------------------------
;Serial Functions
;----------------------------------------------------------
SerialInit:
        andi.b #$f0, MFP_TCDCR
        ori.b #$01, MFP_TCDCR
        move.b #$3, MFP_TDDR ;TDO clock divider for 9600 baud serial

        move.b #$88, MFP_UCR ;CLK / 16, 8bit char, no parity
        move.b #$04, MFP_TSR ;set h flag
        move.b #$05, MFP_TSR ;enable transmitter

        move.b #$01, MFP_RSR ;enable receiver

        rts
SerialWrite:
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
SerialWriteChar:
        btst.b #7, MFP_TSR
        beq.w SerialWriteChar

        move.w (4, A7), D0
        move.b D0, MFP_UDR
        rts
SerialRead:
        btst.b #7, MFP_RSR ;wait until a char is received
        beq.w SerialRead

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
SerialWriteHex32: ;void (long number)
        move.l D2, -(A7)

        move.l ($08, A7), D2
        swap D2
        move.w D2, -(A7)
        bsr SerialWriteHex16
        addq.l #2, A7
        swap D2
        move.w D2, -(A7)
        bsr SerialWriteHex16
        addq.l #2, A7

        move.l (A7)+, D2
        rts
SerialReadHex16:
		move.l D2, -(A7)
		clr.l D1
		move.w #3, D2
	.loop:
		lsl.w #4, D1
		bsr SerialRead
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

SerialSendJSONString:
        ;sends a string json entry
        ;paramters:
        ;  String object_name (pointer)
        ;  String object_value (pointer)
        ;returns:
        ;  null
        move.w #'\"', -(A7)
        bsr SerialWriteChar
        addq.l #2, A7

        move.l ($08, A7), -(A7)
        bsr SerialWrite
        addq.l #4, A7

        move.l #.seperator, -(A7)
        bsr SerialWrite
        addq.l #4, A7

        move.l ($04, A7), -(A7)
        bsr SerialWrite
        addq.l #4, A7

        move.w #'\"', -(A7)
        bsr SerialWriteChar
        move.w #',', -(A7)
        bsr SerialWriteChar
        addq.l #4, A7

        rts
    .seperator:
        dc.b "\": \"", $00
SerialSendJSONHex:
        ;sends a hexadecial string json entry
        ;paramters:
        ;  String object_name (pointer)
        ;  Long object_value
        ;returns:
        ;  null
        move.w #'\"', -(A7)
        bsr SerialWriteChar
        addq.l #2, A7

        move.l ($08, A7), -(A7)
        bsr SerialWrite
        addq.l #4, A7

        move.l #.seperator, -(A7)
        bsr SerialWrite
        addq.l #4, A7

        move.l ($04, A7), -(A7)
        bsr SerialWriteHex32
        addq.l #4, A7

        move.w #'\"', -(A7)
        bsr SerialWriteChar
        move.w #',', -(A7)
        bsr SerialWriteChar
        addq.l #4, A7

        rts
    .seperator:
        dc.b "\": \"", $00
;----------------------------------------------------------
;Global variables
;----------------------------------------------------------
UpdaterVersion:
        dc.b "2.00A", $00
;----------------------------------------------------------

UPDATER_END:

UpdaterDataBuffer:
