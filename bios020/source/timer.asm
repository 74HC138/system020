TimerInit: ;void (void)
        move.l #0, __TimerCount
        move.b #0, __TimerDiv3
        move.b #184, MFP_TCDR
        andi.b #$0f, MFP_TCDCR
        ori.b #$70, MFP_TCDCR
        ori.b #$20, MFP_IERB
        ori.b #$20, MFP_IMRB
        rts

TimerInterrupthandler:
        addq.l #1, __TimerCount
        addq.b #1, __TimerDiv3
        move.b #184, MFP_TCDR
        cmpi.b #3, __TimerDiv3
        beq .skip
        move.b #185, MFP_TCDR
        move.b #0, __TimerDiv3
    .skip:
        rte

;sleep for n cycles (10 ms per cycle)
TimerSleep: ;void (uint32_t n)
        move.l ($04, A7), D0
		cmpi.l #0, D0
		beq .exit
		add.l __TimerCount, D0
	.loop:
		cmp.l __TimerCount, D0
		bne .loop ;if D0 <= __TimerCount then loop
	.exit:
		rts

;sleeps for t millisecond (rounded down to 10ms increments)
TimerSleepMs: ;void (uint32_t t)
		move.l ($04, A7), D0
		divu.l #10, D0 ;divide by 10
		move.l D0, -(A7)
		bsr TimerSleep
		addq.l #4, A7
		rts
