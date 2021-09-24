;functions for allocating timers

;struct TIMER_BASE {
;   uint16_t TimerFree[4];
;   uint32_t TimerCallback[4];
;   uint16_t TimerPredivider[4];
;   uint16_t TimerOverflow[4];
;}

TimerInit: ;void TimerInit()
        move.l #40, -(A7)
		move.w #0, -(A7)
		bsr Malloc
		addq.l #6, A7
		cmpi.l #0, D0
		beq .error
        move.l D0, I_TIMER_BASE
        move.l D0, A0

        clr.l (A0)+
        clr.l (A0)+

        rts
    .error:
        clr.l I_TIMER_BASE
        move.l #$ffffffff, D0
        rts

TimerAlloc: ;int TimerAlloc(uint32_t callback, uint16_t predivider, uint16_t overflow)
        ;overflow: ($04, A7)
        ;predivider: ($06, A7)
        ;callback: ($08, A7)
        move.l #__TimerExceptionText, A0
        cmpi.l #0, I_TIMER_BASE
        trapeq ;cause null pointer exception
        move.l I_TIMER_BASE, A0
        clr.l D0
        clr.l D1
    .loop:
        move.w ($00, A0, D0.w*2), D1
        cmpi.w #$0000, D1
        beq .continue
        addq.w #1, D0
        cmpi.w #$04, D0
        bne .loop
        move.l #$ffffffff, D0
        rts ;error exit, no free timer
    .continue:
        move.w #$ffff, ($00, A0, D0.w*2)
        move.l ($08, A7), ($08, A0, D0.w*2)
        move.w ($06, A7), ($18, A0, D0.w*2)
        move.w ($04, A7), ($20, A0, D0.w*2)

        move.w D0, -(A7)
        bsr TimerUpdate
        move.w (A7)+, D0

        rts

TimerHardAlloc: ;int TimerHardAlloc(uint32_t callback, uint16_t predivider, uint16_t overflow, uint16_t timerNumber)
        ;timerNumber: ($04, A7)
        ;overflow: ($06, A7)
        ;predivider: ($08, A7)
        ;callback: ($0a, A7)
        move.l #__TimerExceptionText, A0
		cmpi.l #0, I_TIMER_BASE
		trapeq
		move.l I_TIMER_BASE, A0
        move.w ($04, A7), D0
		move.w #$ffff, ($00, A0, D0.w*2)
        move.l ($0a, A7), ($08, A0, D0.w*2)
        move.w ($08, A7), ($18, A0, D0.w*2)
        move.w ($06, A7), ($20, A0, D0.w*2)

        move.w D0, -(A7)
        bsr TimerUpdate
        move.w (A7)+, D0
        rts

TimerUpdate: ;void TimerUpdate(uint16_t timerNumber)
        ;timerNUmber: ($04, A7)
        move.l #__TimerExceptionText, A0
        cmpi.l #0, I_TIMER_BASE
        trapeq

        ;-----------------------------
        ;TODO: add mfp timer code here
        ;-----------------------------

        rts

__TimerExceptionText:
        dc.b "I_TIMER_BASE not allocated", $00
        even