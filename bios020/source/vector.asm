;-----------------------------------------------------------------------------
;exception vector table
dc.l MSP_STACK                  ;Reset Initial Interrupt Stack Pointer
dc.l Main                       ;Reset Initial Program Counter
dc.l FatalError                 ;Bus error
dc.l FatalError                 ;Address error

dc.l IllegalInterrupt           ;Illigal Instruction
dc.l FatalError                 ;Zero Divide
dc.l FatalError                 ;CHK, CHK2 Instruction
dc.l FatalError                 ;cpTRAPcc, TRAPcc, TRAPV Instructions

dc.l FatalError                 ;Privilege Violation
dc.l TraceInterrupt             ;Trace
dc.l IgnoreInterrupt            ;Line 1010 Emulator
dc.l IgnoreInterrupt            ;Line 1111 Emulator

dc.l IgnoreInterrupt            ;(Reserved)
dc.l FatalError                 ;Coprocessor Protocol Violation
dc.l FatalError                 ;Format error
dc.l FatalError                 ;Uninitialized Interrupt

dc.l IgnoreInterrupt            ;(Unasigned)
dc.l IgnoreInterrupt            ;(Unasigned)
dc.l IgnoreInterrupt            ;(Unasigned)
dc.l IgnoreInterrupt            ;(Unasigned)
dc.l IgnoreInterrupt            ;(Unasigned)
dc.l IgnoreInterrupt            ;(Unasigned)
dc.l IgnoreInterrupt            ;(Unasigned)
dc.l IgnoreInterrupt            ;(Unasigned)

dc.l IgnoreInterrupt            ;Spurious Interrupt
dc.l IgnoreInterrupt            ;Level 1 Interrupt Autovector
dc.l IgnoreInterrupt            ;Level 2 Interrupt Autovector
dc.l IgnoreInterrupt            ;Level 3 Interrupt Autovector

dc.l IgnoreInterrupt            ;Level 4 Interrupt Autovector
dc.l IgnoreInterrupt            ;Level 5 Interrupt Autovector
dc.l IgnoreInterrupt            ;Level 6 Interrupt Autovector
dc.l IgnoreInterrupt            ;Level 7 Interrupt Autovector

dc.l IgnoreInterrupt            ;TRAP #0
dc.l IgnoreInterrupt            ;TRAP #1
dc.l IgnoreInterrupt            ;TRAP #2
dc.l IgnoreInterrupt            ;TRAP #3
dc.l IgnoreInterrupt            ;TRAP #4
dc.l IgnoreInterrupt            ;TRAP #5
dc.l IgnoreInterrupt            ;TRAP #6
dc.l IgnoreInterrupt            ;TRAP #7
dc.l IgnoreInterrupt            ;TRAP #8
dc.l IgnoreInterrupt            ;TRAP #9
dc.l IgnoreInterrupt            ;TRAP #10
dc.l IgnoreInterrupt            ;TRAP #11
dc.l IgnoreInterrupt            ;TRAP #12
dc.l IgnoreInterrupt            ;TRAP #13
dc.l IgnoreInterrupt            ;TRAP #14
dc.l IgnoreInterrupt            ;TRAP #15

dc.l IgnoreInterrupt            ;FPCP Branch or Set on Unordered Condition
dc.l IgnoreInterrupt            ;FPCP Inexact Result
dc.l IgnoreInterrupt            ;FPCP Divide by Zero
dc.l IgnoreInterrupt            ;FPCP Underflow

dc.l IgnoreInterrupt            ;FPCP Operand error
dc.l IgnoreInterrupt            ;FPCP Overflow
dc.l IgnoreInterrupt            ;FPCP Signaling NAN
dc.l IgnoreInterrupt            ;(Unasigned)

dc.l IgnoreInterrupt            ;PMMU Configuration
dc.l IgnoreInterrupt            ;PMMU Illigal Operation
dc.l IgnoreInterrupt            ;PMMU Access Level Violation

dc.l IgnoreInterrupt            ;(Unasigned)
dc.l IgnoreInterrupt            ;(Unasigned)
dc.l IgnoreInterrupt            ;(Unasigned)
dc.l IgnoreInterrupt            ;(Unasigned)
dc.l IgnoreInterrupt            ;(Unasigned)

dc.l IgnoreInterrupt            ;MFP General Purpose Interrupt 0
dc.l IgnoreInterrupt            ;MFP General Purpose Interrupt 1
dc.l DebugerEnter            	;MFP General Purpose Interrupt 2
dc.l IgnoreInterrupt            ;MFP General Purpose Interrupt 3
dc.l IgnoreInterrupt            ;MFP Timer D
dc.l TimerInterrupthandler      ;MFP Timer C
dc.l IgnoreInterrupt            ;MFP General Purpose Interrupt 4
dc.l IgnoreInterrupt            ;MFP General Purpose Interrupt 5
dc.l IgnoreInterrupt            ;MFP Timer B
dc.l IgnoreInterrupt            ;MFP Transmit Error
dc.l IgnoreInterrupt            ;MFP Transmit Buffer Empty
dc.l IgnoreInterrupt            ;MFP Receive Error
dc.l SerialRXHandler            ;MFP Receive Buffer Full
dc.l IgnoreInterrupt            ;MFP Timer A
dc.l IgnoreInterrupt            ;MFP General Purpose Interrupt 6
dc.l IgnoreInterrupt            ;MFP General Purpose Interrupt 7

dcb.l 176, IgnoreInterrupt      ;User defined Interrupts
;-----------------------------------------------------------------------------
;Basic exception handling function
FatalError:			;locks up cpu completely until reset
		move.w IDE0_BASE, D0
		bra FatalError

IgnoreInterrupt:		;just returns without doing anything
        rte




IllegalInterrupt:
		move.l D0, -(A7)
		move.l A0, -(A7)

		move.l ($0a, A7), A0 ;address of illegal instruction
		move.w (A0), D0 ;get the first 16 instruction bits
		andi.w #$fff8, D0 ;mask bottom 3 bits off
		cmpi.w #$4848, D0 ;BKPT instruction
		beq .handleBreakpoint
		cmpi.w #$4af8, D0 ;ILLEGAL instruction, handled like a breakpoint bacause the 020/030 incists on a BERR terminated bus cycle to trigger the Illegal interrupt when executing a BKPT instruction (dont ask me why)
		beq .handleBreakpoint

		;illegal instruction is not a breakpoint
		move.l #.text0, -(A7)
		bsr SerialWrite
		addq.l #4, A7
		move.l ($0a, A7), A0
		move.l (A0), -(A7)
		bsr SerialWriteHex32
		addq.l #4, A7
		move.w #'\n', -(A7)
		bsr SerialWriteChar
		addq.l #2, A7
		bra .exit

	.exit:
		move.l #.text7, -(A7)
		bsr SerialWrite
		addq.l #4, A7

		move.l (A7)+, A0
		move.l (A7)+, D0
		addq.l #2, ($02, A7) ;advance program counter by 1 word

		;wait for user button to be pressed and released
		bclr #2, MFP_DDR
	.exitLoopLow:
		btst #2, MFP_GPDR ;test if userinterrupt button is pressed
		bne .exitLoopLow
	.exitLoopHigh:
		btst #2, MFP_GPDR
		beq .exitLoopHigh

		bsr SerialFlush

		rte

	.handleBreakpoint:
		move.l #.text1, -(A7)
		bsr SerialWrite
		addq.l #4, A7
		move.l ($0a, A7), A0
		move.w (A0), D0
		andi.w #$0007, D0 ;get the breakpoint vector
		move.w D0, -(A7)
		bsr SerialWriteHex8
		addq.l #2, A7

	.dumpDataRegs:
		move.l #.text2, -(A7)
		bsr SerialWrite
		addq.l #4, A7

		move.l ($04, A7), -(A7)
		bsr SerialWriteHex32 ;dump D0
		addq.l #4, A7
		move.w #'\t', -(A7)
		bsr SerialWriteChar
		addq.l #2, A7

		move.l D1, -(A7)
		bsr SerialWriteHex32 ;dump D1
		addq.l #4, A7
		move.w #'\t', -(A7)
		bsr SerialWriteChar
		addq.l #2, A7

		move.l D2, -(A7)
		bsr SerialWriteHex32 ;dump D2
		addq.l #4, A7
		move.w #'\t', -(A7)
		bsr SerialWriteChar
		addq.l #2, A7

		move.l D3, -(A7)
		bsr SerialWriteHex32 ;dump D3
		addq.l #4, A7
		move.w #'\t', -(A7)
		bsr SerialWriteChar
		addq.l #2, A7

		move.l D4, -(A7)
		bsr SerialWriteHex32 ;dump D4
		addq.l #4, A7
		move.w #'\t', -(A7)
		bsr SerialWriteChar
		addq.l #2, A7

		move.l D5, -(A7)
		bsr SerialWriteHex32 ;dump D5
		addq.l #4, A7
		move.w #'\t', -(A7)
		bsr SerialWriteChar
		addq.l #2, A7

		move.l D6, -(A7)
		bsr SerialWriteHex32 ;dump D6
		addq.l #4, A7
		move.w #'\t', -(A7)
		bsr SerialWriteChar
		addq.l #2, A7

		move.l D7, -(A7)
		bsr SerialWriteHex32 ;dump D7
		addq.l #4, A7
		move.w #'\n', -(A7)
		bsr SerialWriteChar
		addq.l #2, A7

	.dumpAddrRegs:
		move.l #.text3, -(A7)
		bsr SerialWrite
		addq.l #4, A7

		move.l ($00, A7), -(A7)
		bsr SerialWriteHex32 ;dump A0
		addq.l #4, A7
		move.w #'\t', -(A7)
		bsr SerialWriteChar
		addq.l #2, A7

		move.l A1, -(A7)
		bsr SerialWriteHex32 ;dump A1
		addq.l #4, A7
		move.w #'\t', -(A7)
		bsr SerialWriteChar
		addq.l #2, A7

		move.l A2, -(A7)
		bsr SerialWriteHex32 ;dump A2
		addq.l #4, A7
		move.w #'\t', -(A7)
		bsr SerialWriteChar
		addq.l #2, A7

		move.l A3, -(A7)
		bsr SerialWriteHex32 ;dump A3
		addq.l #4, A7
		move.w #'\t', -(A7)
		bsr SerialWriteChar
		addq.l #2, A7

		move.l A4, -(A7)
		bsr SerialWriteHex32 ;dump A4
		addq.l #4, A7
		move.w #'\t', -(A7)
		bsr SerialWriteChar
		addq.l #2, A7

		move.l A5, -(A7)
		bsr SerialWriteHex32 ;dump A5
		addq.l #4, A7
		move.w #'\t', -(A7)
		bsr SerialWriteChar
		addq.l #2, A7

		move.l A6, -(A7)
		bsr SerialWriteHex32 ;dump A6
		addq.l #4, A7
		move.w #'\t', -(A7)
		bsr SerialWriteChar
		addq.l #2, A7

		move.l A7, -(A7)
		bsr SerialWriteHex32 ;dump A7
		addq.l #4, A7
		move.w #'\n', -(A7)
		bsr SerialWriteChar
		addq.l #2, A7

	.dumpSpecial:
		move.l #.text4, -(A7)
		bsr SerialWrite
		addq.l #4, A7

		move.w ($08, A7), -(A7)
		bsr SerialWriteHex16
		addq.l #2, A7
		move.w #'\t', -(A7)
		bsr SerialWriteChar
		addq.l #2, A7

		movec.l USP, A0
		move.l A0, -(A7)
		bsr SerialWriteHex32
		addq.l #4, A7
		move.w #'\t', -(A7)
		bsr SerialWriteChar
		addq.l #2, A7

		movec.l MSP, A0
		move.l A0, -(A7)
		bsr SerialWriteHex32
		addq.l #4, A7
		move.w #'\t', -(A7)
		bsr SerialWriteChar
		addq.l #2, A7

		movec.l ISP, A0
		move.l A0, -(A7)
		bsr SerialWriteHex32
		addq.l #4, A7
		move.w #'\n', -(A7)
		bsr SerialWriteChar
		addq.l #2, A7

	.dumpStack:
		move.l #.text5, -(A7)
		bsr SerialWrite
		addq.l #4, A7

		;load the correct stack based on the supervisor bit in SR
		movec.l MSP, A0
		move.w ($08, A7), D0
		andi.w #$2000, D0
		bne .dumpStackSkipUSP
		movec.l USP, A0
	.dumpStackSkipUSP:

		;test if the stack is in the bounds of RAM
		;if not error out and halt
		cmp.l #RAM_BASE, A0
		blo .stackError
		cmp.l #RAM_TOP, A0
		bhi .stackError

		move.l D1, -(A7)
		move.l A1, -(A7)
		move.l A0, A1
		clr.l D1
	.dumpStackLoop:
		move.w (A1)+, -(A7)
		bsr SerialWriteHex16
		addq.l #2, A7
		move.w #'\t', -(A7)
		bsr SerialWriteChar
		addq.l #2, A7

		addq.l #1, D1
		move.b D1, D0
		andi.b #$07, D0
		cmpi.b #$00, D0
		bne .dumpStackSkipNL
		move.w #'\n', -(A7)
		bsr SerialWriteChar
		addq.l #2, A7
	.dumpStackSkipNL:
		cmp.l #RAM_TOP, A1
		bhi .dumpStackExitLoop
		cmpi.l #$0100, D1
		bne .dumpStackLoop
	.dumpStackExitLoop:
		move.l (A7)+, A1
		move.l (A7)+, D1
		;done dumping stack
		bra .exit
	.stackError:
		move.l #.text6, -(A7)
		bsr SerialWrite
		addq.l #4, A7
		rte

	.text0:
		dc.b "\nILLEGAL INSTRUCTION 0x", $00
	.text1:
		dc.b "\nBREAK POINT 0x", $00
	.text2:
		dc.b "\nRegister dump\n"
		dc.b "D0\t\tD1\t\tD2\t\tD3\t\tD4\t\tD5\t\tD6\t\tD7\n", $00
	.text3:
		dc.b "A0\t\tA1\t\tA2\t\tA3\t\tA4\t\tA5\t\tA6\t\tA7\n", $00
	.text4:
		dc.b "SR\tUSP\t\tMSP\t\tISP\n", $00
	.text5:
		dc.b "Stack trace\n", $00
	.text6:
		dc.b "ERROR: Stack is out of bounds\n", $00
	.text7:
		dc.b "Press USER INT to continue\n", $00
	even

TraceInterrupt:			;displays trace information
		move.l D0, -(A7)
		move.l D1, -(A7)
		move.l A0, -(A7)

		move.l #.text0, -(A7)
		bsr SerialWrite
		addq.l #4, A7

		move.l ($14, A7), -(A7) ;program counter
		bsr SerialWriteHex32
		addq.l #4, A7

		move.l #.text1, -(A7)
		bsr SerialWrite
		addq.l #4, A7

		move.l ($0E, A7), -(A7) ;instruction address
		bsr SerialWriteHex32
		addq.l #4, A7

		move.l #.text2, -(A7)
		bsr SerialWrite
		addq.l #4, A7

		move.l ($14, A7), A0
		move.l (A0), -(A7)
		bsr SerialWriteHex32
		addq.l #4, A7

		move.l #.text3, -(A7)
		bsr SerialWrite
		addq.l #4, A7

		cmpi.w #0, __TraceDumpRegs
		bne .dumpRegs
	
	.exit:
		move.l (A7)+, A0
		move.l (A7)+, D1
		move.l (A7)+, D0
		bsr SerialFlush
		rte

	.dumpRegs:
		;dump data regs
		move.l #.text4, -(A7)
		bsr SerialWrite
		addq.l #4, A7
		move.l ($08, A7), -(A7)
		bsr SerialWriteHex32
		move.w #'\t', -(A7)
		bsr SerialWriteChar
		addq.l #6, A7
		move.l ($04, A7), -(A7)
		bsr SerialWriteHex32
		move.w #'\t', -(A7)
		bsr SerialWriteChar
		addq.l #6, A7
		move.l D2, -(A7)
		bsr SerialWriteHex32
		move.w #'\t', -(A7)
		bsr SerialWriteChar
		addq.l #6, A7
		move.l D3, -(A7)
		bsr SerialWriteHex32
		move.w #'\t', -(A7)
		bsr SerialWriteChar
		addq.l #6, A7
		move.l D4, -(A7)
		bsr SerialWriteHex32
		move.w #'\t', -(A7)
		bsr SerialWriteChar
		addq.l #6, A7
		move.l D5, -(A7)
		bsr SerialWriteHex32
		move.w #'\t', -(A7)
		bsr SerialWriteChar
		addq.l #6, A7
		move.l D6, -(A7)
		bsr SerialWriteHex32
		move.w #'\t', -(A7)
		bsr SerialWriteChar
		addq.l #6, A7
		move.l D7, -(A7)
		bsr SerialWriteHex32
		move.w #'\n', -(A7)
		bsr SerialWriteChar
		addq.l #6, A7
		;dump address and stack regs
		move.l #.text5, -(A7)
		bsr SerialWrite
		addq.l #4, A7
		move.l ($00, A7), -(A7)
		bsr SerialWriteHex32
		move.w #'\t', -(A7)
		bsr SerialWriteChar
		addq.l #6, A7
		move.l A1, -(A7)
		bsr SerialWriteHex32
		move.w #'\t', -(A7)
		bsr SerialWriteChar
		addq.l #6, A7
		move.l A2, -(A7)
		bsr SerialWriteHex32
		move.w #'\t', -(A7)
		bsr SerialWriteChar
		addq.l #6, A7
		move.l A3, -(A7)
		bsr SerialWriteHex32
		move.w #'\t', -(A7)
		bsr SerialWriteChar
		addq.l #6, A7
		move.l A4, -(A7)
		bsr SerialWriteHex32
		move.w #'\t', -(A7)
		bsr SerialWriteChar
		addq.l #6, A7
		move.l A5, -(A7)
		bsr SerialWriteHex32
		move.w #'\t', -(A7)
		bsr SerialWriteChar
		addq.l #6, A7
		move.l A6, -(A7)
		bsr SerialWriteHex32
		move.w #'\t', -(A7)
		bsr SerialWriteChar
		addq.l #6, A7
		movec.l USP, A0
		move.l A0, -(A7)
		bsr SerialWriteHex32
		move.w #'\t', -(A7)
		bsr SerialWriteChar
		addq.l #6, A7
		movec.l MSP, A0
		move.l A0, -(A7)
		bsr SerialWriteHex32
		move.w #'\n', -(A7)
		bsr SerialWriteChar
		addq.l #6, A7
		bra .exit

	.text0:
		dc.b "\nTRACE: 0x", $00
	.text1:
		dc.b "->0x", $00
	.text2:
		dc.b " [0x", $00
	.text3:
		dc.b "]\n", $00
	.text4:
		dc.b "D0\t\tD1\t\tD2\t\tD3\t\tD4\t\tD5\t\tD6\t\tD7\n", $00
	.text5:
		dc.b "A0\t\tA1\t\tA2\t\tA3\t\tA4\t\tA5\t\tA6\t\tUSP\t\tMSP\n", $00