StackDumpSize	=	$00ff

DebugInit:
		andi.b #$fb, MFP_AER
		ori.b #$04, MFP_IMRB
		ori.b #$04, MFP_IERB
		rts

DebugerEnter:
	;enters the debuger. Can only be invoked via interrupt
		movem A0-A6/D0-D7, -(A7)
		move.l A7, A5
		;stack offset 60 bytes

	;print return address
		pea.l (.text0, PC)
		bsr SerialWrite
		addq.l #4, A7
		move.l (62, A7), -(A7)
		bsr SerialWriteHex32
		addq.l #4, A7
		move.w #'\n', -(A7)
		bsr SerialWriteChar
		addq.l #2, A7

	;print used stackpointer and mode
		move.w (66, A7), -(A7)
		bsr DebugerGetStack
		addq.l #4, A7
		move.l D0, A6
		move.l D0, -(A7)
		bsr SerialWriteHex32
		addq.l #4, A7
		move.w (66, A7), -(A7)
		bsr DebugerPrintStackmode
		addq.l #4, A7

	;print status registers
		pea.l (.text2, PC)
		bsr SerialWrite
		addq.l #4, A7
		move.w (66, A7), -(A7)
		bsr SerialWriteHex16
		addq.l #2, A7
		move.w #'\n', -(A7)
		bsr SerialWriteChar
		addq.l #2, A7

	;print available commands
		pea.l (.text3, PC)
		bsr SerialWrite
		addq.l #4, A7

	;read command and interpret	
		.cmdLoop:
			bsr SerialReadRaw
			pea.l (.cmdLoop, PC)

			cmpi.b #'d', D0
			beq .stackDump
			cmpi.b #'r', D0
			beq .registerDump
			cmpi.b #'s', D0
			beq .singleStep
			cmpi.b #'m', D0
			beq .memoryView
			cmpi.b #'e', D0
			beq .exit

			pea.l (.text4, PC)
			bsr SerialWrite
			addq.l #4, A7
			rts

	;dump the first 256 bytes of the stack
			.stackDump:
				clr.l D0
				move.l A6, A0
				.stackDumpLoop:
					move.w D0, D1
					andi.w #$000f, D1
					bne .stackDumpLoopSkipHeader
						pea.l (A6, D0.w*1)
						bsr SerialWriteHex32
						addq.l #4, A7
						move.w #':', -(A7)
						bsr SerialWriteChar
						addq.l #2, A7
					.stackDumpLoopSkipHeader:
					
					move.w #' ', -(A7)
					bsr SerialWriteChar
					addq.l #2, A7
					move.w (A6, D0.w*1), -(A7)
					bsr SerialWriteHex16
					addq.w #2, D0

					move.w D0, D1
					andi.w #$000f, D1
					bne .stackDumpLoopSkipNewline
						move.w #'\n', -(A7)
						bsr SerialWriteChar
						addq.l #2, A7
					.stackDumpLoopSkipNewline:

					cmpi.w #StackDumpSize, D0
					bls .stackDumpLoop
				move.w #'\n', -(A7)
				bsr SerialWriteChar
				addq.l #2, A7
				rts
				
	;dump data and address registers
			.registerDump:
				clr.l D0
				move.l A5, A0
				.registerDumpDataLoop:
					move.w #'D', -(A7)
					bsr SerialWriteChar
					move.w D0, -(A7)
					bsr SerialWriteDec16
					pea (.registerDumpText, PC)
					bsr SerialWrite
					addq.l #8, A7
					move.w #'\n', -(A7)
					bsr SerialWriteChar
					addq.l #2, A7
					move.l (A0)+, -(A7)
					bsr SerialWriteHex32
					addq.l #4, A7
					addq.w #1, D0
					cmpi.b #8, D0
					bne .registerDumpDataLoop
				clr.l D0
				.registerDumpAddressLoop:
					move.w #'A', -(A7)
					bsr SerialWriteChar
					move.w D0, -(A7)
					bsr SerialWriteDec16
					pea (.registerDumpText, PC)
					bsr SerialWrite
					addq.l #8, A7
					move.w #'\n', -(A7)
					bsr SerialWriteChar
					addq.l #2, A7
					move.l (A0)+, -(A7)
					bsr SerialWriteHex32
					addq.l #4, A7
					addq.w #1, D0
					cmpi.b #7, D0
					bne .registerDumpAddressLoop
				rts
				.registerDumpText:
					dc.b ": 0x", $00
				even

	;do a single step trace
			.singleStep:
				move.l A5, A7
				move.w (62, A7), D0
				;set T1 and reset T0 to trace on any instruction
				ori.w #$8000, D0
				andi.w #$bfff, D0
				move.w D0, (62, A7)

				;restore all registers
				movem A0-A6/D0-D7, (A7)
				;return aaaaaaaaand come right back
				rte

	;memory monitor
			.memoryView:
				rts

	;exit debuger, disable tracing
			.exit:
				move.l A5, A7
				move.w (62, A7), D0
				;reset T1 and T0 to disable tracing
				andi.w #$3fff, D0
				move.w D0, (62, A7)

				;restore all registers
				movem A0-A6/D0-D7, (A7)
				;and return for good (until summoned again)
				rte

	.text0:
		dc.b "-------------------\nDEBUGER\nPC: 0x", $00
	.text1:
		dc.b "SP: 0x", $00
	.text2:
		dc.b "SR: 0x", $00
	.text3:
		dc.b "stack[d]ump [r]egisterdump [s]inglestep [m]emoryview [e]xit\n", $00
	.text4:
		dc.b "ERROR command not found\n", $00
	even

DebugerGetStack:
		move.w ($04, A7), D0
		andi.w #$2000, D0
		beq .getUser
		move.w ($04, A7), D0
		andi.w #$1000, D0
		beq .getInterrupt
		;get Master
			movec.l MSP, D0
			rts

		.getInterrupt:
			movec.l ISP, D0
			rts

		.getUser:
			movec.l USP, D0
			rts

DebugerPrintStackmode:
		move.w ($04, A7), D0
		andi.w #$2000, D0
		beq .printUser
		move.w ($04, A7), D0
		andi.w #$1000, D0
		beq .printInterrupt
		;print Master
			pea (.textMSP, PC)
			bra .exit
		.printInterrupt:
			pea (.textISP, PC)
			bra .exit
		.printUser:
			pea (.textUSP, PC)
			bra .exit

		.exit:
			bsr SerialWrite
			addq.l #4, A7
			rts

		.textMSP:
			dc.b " [MSP]\n", $00
		.textISP:
			dc.b " [ISP]\n", $00
		.textUSP:
			dc.b " [USP]\n", $00
		even