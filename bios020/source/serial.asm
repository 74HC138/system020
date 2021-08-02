;initializes serial interface and timer D for 9600 baud
SerialInit:
		andi.b #$f0, MFP_TCDCR
        	ori.b #$01, MFP_TCDCR
        	move.b #$04, MFP_TDDR ;TDO at 115200

        	move.b #$08, MFP_UCR ;CLK / 1, 8bit char, no parity
	        move.b #$04, MFP_TSR ;set h flag
	        move.b #$05, MFP_TSR ;enable transmitter

	        move.b #$01, MFP_RSR ;enable receiver

	        move.b #$40, MFP_VR ;MFP interrupt vector base at $40, Automatic end of interrupt mode
	        bset.b #4, MFP_IERA ;enable receive buffer full interrupt
	        bset.b #4, MFP_IMRA ;unmask receive buffer full interrupt
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
		move.l __SerialHexTable, A0
	.loop0:
		btst.b #7, MFP_TSR
		beq.w .loop0

		move.w (4, A7), D0
		andi.w #$00f0, D0
		lsr.b #4, D0
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
		lsr.b #8, D0
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
		move.w (6, A7), D0
		move.w D0, -(A7)
		bsr.w SerialWriteHex16
		addq.l #2, A7

		move.w (4, A7), D0
		move.w D0, -(A7)
		bsr.w SerialWriteHex16
		addq.l #2, A7

		rts

;writes 32 bit int to serial as decimal
SerialWriteDec32: ;void (long number)
		move.l (4, A7), D0
		move.l D2, -(A7)
		clr.l D2
		move.l __SerialHexTable, A0

	.divLoop:
		cmpi.l #0, D0
		beq .display
		divul.l #10, D1:D0
		move.w D1, -(A7)
		addq.w #1, D2
		bra.w .divLoop

	.display:
		cmpi.w #0, D2
		beq.w .return
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
		;move.w IDE1_BASE, D0
		;bra.w SerialRXHandler


		move.l D0, -(A7)
		move.l D1, -(A7)
		move.l A0, -(A7)

		move.l __SerialRingbuffer, A0
		move.w (__SerialRBWrite), D0
		move.b MFP_UDR, D1
		move.b D1, MFP_UDR
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
		move.w (__SerialRBWrite), D0
		move.w (__SerialRBRead), D1
		sub.w D1, D0
		andi.w #$00ff, D0
		rts

;read a character from the ringbuffer, returns zero if buffer empty
SerialRead: ;int ()
		bsr SerialAvailable
		cmp.w #0, D0
		beq .return ;no data in the buffer, return

		move.w (__SerialRBRead), D0
		move.l __SerialRingbuffer, A0
		move.w (0, A0, D0.w*2), D0

	.return:
		rts
