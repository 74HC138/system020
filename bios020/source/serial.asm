;initializes serial interface and timer D for 9600 baud
SerialInit:
		andi.b #$f0, MFP_TCDCR
		ori.b #$01, MFP_TCDCR
		move.b #$3, MFP_TDDR ;TDO clock divider for 9600 baud serial
		;move.b #$04, MFP_TDDR ;TDO clock divider for 115200 baus

		move.b #$88, MFP_UCR ;CLK / 16, 8bit char, no parity
		move.b #$04, MFP_TSR ;set h flag
		move.b #$05, MFP_TSR ;enable transmitter

		move.b #$01, MFP_RSR ;enable receiver

		move.b #$40, MFP_VR ;MFP interrupt vector base at $40, Automatic end of interrupt mode
		bset.b #4, MFP_IERA ;enable receive buffer full interrupt
		bset.b #4, MFP_IMRA ;unmask receive buffer full interrupt

		rts

;writes formated string to serial
SerialPrintf:
		illegal
		move.l A7, A0
		move.l (A0)+, A1
		move.l (A0)+, A1

		;move A1, -(A7)
		;bsr SerialWriteHex32
		;add.l #4, A7
		;rts

	.loop:
		move.b (A1)+, D0

		cmpi.b #0, D0
		beq .exit
		cmpi.b #'%', D0
		beq .format
		move.w D0, -(A7)
		bsr SerialWriteChar
		addq.l #2, A7
		bra .loop

	.exit:
		illegal
		rts

	.format:
		move.b (A1)+, D0
		cmpi.b #'%', D0
		beq .percent
		cmpi.b #'c', D0
		beq .char
		cmpi.b #'d', D0
		beq .integerSigned
		cmpi.b #'i', D0
		beq .integerSigned
		cmpi.b #'u', D0
		beq .integerUnsigned
		cmpi.b #'x', D0
		beq .intHex
		cmpi.b #'s', D0
		beq .string

		cmpi.b #'l', D0
		bne .loop

		move.b (A1)+, D0
		cmpi.b #'d', D0
		beq .longSigned
		cmpi.b #'u', D0
		beq .longUnsigned
		cmpi.b #'x', D0
		beq .longHex
		bra .longSigned

	.percent:
		move.w #'%', -(A7)
		bsr SerialWriteChar
		addq.l #2, A7
		bra .loop

	.char:
		move.w (A0)+, -(A7)
		bsr SerialWriteChar
		add.l #2, A7
		bra .loop
	
	.integerSigned:
		move.w (A0)+, D0
		btst #15, D0
		beq .integer_skip ;highest bit is 0 -> number is positive
		neg.w D0
		move.w #'-', -(A7)
		bsr SerialWriteChar
		addq.l #2, A7
	.integer_skip:
		move.w D0, -(A7)
		bsr SerialWriteDec16
		addq.l #2, A7
		bra .loop
	
	.integerUnsigned:
		move.w (A0)+, D0
		move.w D0, -(A7)
		bsr SerialWriteDec16
		addq.l #2, A7
		bra .loop
	
	.intHex:
		move.w (A0)+, -(A7)
		bsr SerialWriteHex16
		addq.l #2, A7
		bra .loop
	
	.string:
		move.l (A0)+, -(A7)
		bsr SerialWrite
		addq.l #4, A7
		bra .loop

	.longSigned:
		move.l (A0)+, D0
		btst #31, D0
		beq .long_skip
		neg.l D0
		move.w #'-', -(A7)
		bsr SerialWriteChar
		addq.l #2, A7
	.long_skip:
		move.l D0, -(A7)
		bsr SerialWriteDec32
		addq.l #4, A7
		bra .loop

	.longUnsigned:
		move.l (A0)+, -(A7)
		bsr SerialWriteDec32
		addq.l #4, A7
		bra .loop

	.longHex:
		move.l (A0)+, -(A7)
		bsr SerialWriteHex32
		addq.l #4, A7
		bra .loop


SerialFlush:
		btst.b #7, MFP_TSR
		beq.w SerialFlush
		rts

;writes string to serial
SerialWrite: ;void (char* string)
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

;writes char to serial
SerialWriteChar: ;void (int char)
		btst #7, MFP_TSR
		beq.w SerialWriteChar

		move.w (4, A7), D0
		move.b D0, MFP_UDR
		rts

__SerialHexTable:
		dc.b "0123456789ABCDEF"

;writes 8 bit int to serial as hexadecimal
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

;writes 16 bit int to serial as hexadecimal
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

;writes 32 bit int to serial as hexadecimal
SerialWriteHex32: ;void (long number)
		move.w (4, A7), D0
		move.w D0, -(A7)
		bsr.w SerialWriteHex16
		addq.l #2, A7

		move.w (6, A7), D0
		move.w D0, -(A7)
		bsr.w SerialWriteHex16
		addq.l #2, A7

		rts

;writes 32 bit int to serial as decimal
SerialWriteDec32: ;void (long number)
		move.l (4, A7), D0
		move.l D2, -(A7)
		clr.l D2
		clr.l D1

	.divLoop:
		cmpi.l #0, D0
		beq .display
		divul.l #10, D1:D0
		move.w D1, -(A7)
		addq.w #1, D2
		bra .divLoop

	.display:
		cmpi.w #0, D2
		beq .return
		move.w (A7)+, D0
		addi.b #'0', D0
	.waitMfp:
		btst.b #7, MFP_TSR
        beq.w .waitMfp
		move.b D0, MFP_UDR
		subq #1, D2
		bra.w .display

	.return:
		move.l (A7)+, D2
		rts

;writes 16 bit int to serial as decimal
SerialWriteDec16: ;void (int number)
		clr.l D0
		move.w (4, A7), D0
		move.l D0, -(A7)
		bsr.w SerialWriteDec32
		addq.l #4, A7
		rts

;interrupt handler for serial receiver
SerialRXHandler: ;void ()

		move.l D0, -(A7)
		move.l D1, -(A7)
		move.l A0, -(A7)

		move.l #__SerialRingbuffer, A0
		move.w __SerialRBWrite, D0
		move.b MFP_UDR, D1
		move.b D1, MFP_UDR ;echo back the char recived
		andi.w #$00ff, D1
		move.w D1, (0, A0, D0.w*2)
		addq.w #1, D0
		andi.w #$00ff, D0
		move.w D0, __SerialRBWrite

		move.l (A7)+, A0
		move.l (A7)+, D1
		move.l (A7)+, D0
		rte

;returns the number of characters to read from the ringbuffer
SerialAvailable: ;int ()
		move.w __SerialRBWrite, D0
		move.w __SerialRBRead, D1
		sub.w D1, D0
		andi.w #$00ff, D0
		rts

;read a character from the ringbuffer, returns zero if buffer empty
SerialRead: ;int ()
		bsr SerialAvailable
		cmp.w #0, D0
		beq .return ;no data in the buffer, return

		move.w __SerialRBRead, D1
		move.l __SerialRingbuffer, A0
		move.w (0, A0, D1.w*2), D0
		addq.w #1, D1
		andi.w #$00ff, D1
		move.w D1	, __SerialRBRead

	.return:
		rts

SerialReadRaw:
	;read a char dirrectly from the MFP. Will halt until a character has been read. Cant be used in conjunction with interrupt based reading
		ori.b #$01, MFP_RSR
		.loop:
			move.b MFP_RSR, D0
			andi.b #$80, D0
			beq .loop
		move.b MFP_UDR, D0
		rts

SerialHexdump: ;void (char*, int length)
		move.w (4, A7), D0
		move.l (6, A7), A0

		clr.l D1 ;counter
		move.l D2, -(A7)
	.lineLoop:
		cmp.w D0, D1
		beq.w .exit

		move.l D0, -(A7)
		move.l D1, -(A7)
		move.l A0, -(A7)

		move.l #.text+1, -(A7)
		bsr SerialWrite
		addq.l #4, A7
		move.l (A7), A0

		;lea.l (A0, D1), -(A7)
		move.l A0, -(A7)
		add.l D1, (A7)

		bsr SerialWriteHex32
		addq.l #4, A7

		move.w ':', -(A7)
                bsr SerialWriteChar
                addq.l #2, A7

		move.l (A7)+, A0
		move.l (A7)+, D1
		move.l (A7)+, D0

		clr.l D2 ;line counter
	.outLoop:
		cmp.w D0, D1
		beq.w .exit
		move.l A0, -(A7)
		move.l #.text, -(A7)
		bsr SerialWrite
		addq.l #4, A7
		move.l (A7)+, A0

		move.l D2, -(A7)
		clr.w D2
		move.b (A0, D1), D2
		move.w D2, -(A7)
		bsr SerialWriteHex8
		addq.l #2, A7
		move.l (A7)+, D2

		addq.w #1, D1
		addq.w #1, D2

		cmpi.w #$00f0, D2
		bne.w .outLoop

		bra.w .lineLoop
	.exit:
		move.l (A7)+, D2
		rts
	.text:
		dc.b " 0x", $00


