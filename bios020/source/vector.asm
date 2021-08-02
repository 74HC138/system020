;-----------------------------------------------------------------------------
;exception vector table
dc.l STACK_INIT                 ;Reset Initial Interrupt Stack Pointer
dc.l Main                       ;Reset Initial Program Counter
dc.l FatalError                 ;Bus error
dc.l FatalError                 ;Address error

dc.l FatalError                 ;Illigal Instruction
dc.l FatalError                 ;Zero Divide
dc.l FatalError                 ;CHK, CHK2 Instruction
dc.l FatalError                 ;cpTRAPcc, TRAPcc, TRAPV Instructions

dc.l FatalError                 ;Privilege Violation
dc.l IgnoreInterrupt            ;Trace
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
dc.l IgnoreInterrupt            ;MFP General Purpose Interrupt 2
dc.l IgnoreInterrupt            ;MFP General Purpose Interrupt 3
dc.l IgnoreInterrupt            ;MFP Timer D
dc.l IgnoreInterrupt            ;MFP Timer C
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
		move.l #.text, A0
	.mfpWait:
		btst.b #7, MFP_TSR
		beq.w .mfpWait

		cmpi.b #$00, (A0)
		beq .stop

		move.b (A0)+, MFP_UDR
		bra.w .mfpWait
	.stop:
		stop #$ffff

	.text:
		dc.b "\n\nFatal error!\nReset computer to continue\n\n", $00
		even
IgnoreInterrupt:		;just returns without doing anything
        rte
