;-----------------------------------------------------------------------------
;Base definitions
ROM_BASE        = $00000000
ROM_SIZE        = $00040000
ROM_TOP         =  ROM_BASE + ROM_SIZE

RAM_BASE        = $10000000
RAM_SIZE        = $00100000
RAM_TOP         = RAM_BASE + RAM_SIZE
RAM_PAGES       = RAM_SIZE / 1024

MFP_BASE        = $40000000

IDE0_BASE	= $20000000
IDE1_BASE	= $30000000

STACK_INIT	= RAM_TOP

;-----------------------------------------------------------------------------
;MFP registers
MFP_GPDR        = MFP_BASE + $00
MFP_AER         = MFP_BASE + $01
MFP_DDR         = MFP_BASE + $02
MFP_IERA        = MFP_BASE + $03
MFP_IERB        = MFP_BASE + $04
MFP_IPRA        = MFP_BASE + $05
MFP_IPRB        = MFP_BASE + $06
MFP_ISRA        = MFP_BASE + $07
MFP_ISRB        = MFP_BASE + $08
MFP_IMRA        = MFP_BASE + $09
MFP_IMRB        = MFP_BASE + $0A
MFP_VR          = MFP_BASE + $0B
MFP_TACR        = MFP_BASE + $0C
MFP_TBCR        = MFP_BASE + $0D
MFP_TCDCR       = MFP_BASE + $0E
MFP_TADR        = MFP_BASE + $0F
MFP_TBDR        = MFP_BASE + $10
MFP_TCDR        = MFP_BASE + $11
MFP_TDDR        = MFP_BASE + $12
MFP_SCR         = MFP_BASE + $13
MFP_UCR         = MFP_BASE + $14
MFP_RSR         = MFP_BASE + $15
MFP_TSR         = MFP_BASE + $16
MFP_UDR         = MFP_BASE + $17

;-----------------------------------------------------------------------------
;Assembler directives
org ROM_BASE
text

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
dc.l IgnoreInterrupt            ;MFP Receive Buffer Full
dc.l IgnoreInterrupt            ;MFP Timer A
dc.l IgnoreInterrupt            ;MFP General Purpose Interrupt 6
dc.l IgnoreInterrupt            ;MFP General Purpose Interrupt 7

dcb.l 176, IgnoreInterrupt      ;User defined Interrupts
;-----------------------------------------------------------------------------
;Basic exception handling function
FatalError:			;locks up cpu completely until reset
        move.w IDE0_BASE, D0
        bra.w FatalError
IgnoreInterrupt:		;just returns without doing anything
        rte

;-----------------------------------------------------------------------------
;dummy code
Main:
        bsr SerialInit

        clr.l D2
    .loop:
		move.l #.text, -(A7)
		bsr SerialWrite
		addq.l #4, A7

        move.w D2, -(A7)
		jsr SerialWriteHex16
		addq.l #2, A7
        addq.l #1, D2
		cmpi.w #$0200, D2
        bne .loop

	.stopLoop:
		move.w IDE1_BASE, D0
		jmp .stopLoop

	.text:
		dc.b "\n0x", $00
		even

SerialInit:
		andi.b #$f0, MFP_TCDCR
		ori.b #$01, MFP_TCDCR
		move.b #$30, MFP_TDDR ;TDO clock divider for 9600 baud serial

		move.b #$08, MFP_UCR ;CLK / 1, 8bit char, no parity
		move.b #$04, MFP_TSR ;set h flag
		move.b #$05, MFP_TSR ;enable transmitter
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
		lsr.b #4, D0
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
;-----------------------------------------------------------------------------
;bss section
