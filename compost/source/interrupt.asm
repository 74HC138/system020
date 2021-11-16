;interrupt API
			

InterruptInit: ;void InterruptInit (void* ResetRoutine, void* StackInit)
		;StackInit: ($04, A7)
		;ResetRoutine: ($08, A7)
		;create vector table
		move.l #$0400, -(A7)
		move.w #0, -(A7)
		bsr Malloc
		addq.l #6, A7
		cmpi.l #0, D0
		beq .error
		move.l D0, I_RAM_VBR
		move.l ($04, A7), (A0)+
		move.l ($08, A7), (A0)+
		move.w #253, D0
	.loop:
		move.l (#__IgnoreInterrupt, PC), (A0)+
		dbra D0, .loop

		rts

	.error:
		clr.l I_RAM_VBR ;I_RAM_VBR points to zero if error
		rts

__IgnoreInterrupt: ;dummy function to ignore an interrupt
		rte

InterruptAlloc: ;void* InterruptAlloc(void* interruptHandler, uint16_t interruptVector)
		;interruptVector: ($04, A7)
		;interruptHandler: ($06, A7)
		clr.l D0
		move.w ($04, A7), D0
		andi.w #$00ff, D0
		move.l ($06, A7), A1
		move.l I_RAM_VBR, A0
		move.l (A0, D0.w*4), D1
		move.l A1, (A0, D0.w*4)
		move.l D1, D0
		rts

InterruptGet: ;void* InterruptGet(uint16_t interruptVector)
		;interruptVector: ($04, A7)
		clr.l D0
		move.w ($04, A7), D0
		andi.w #$00ff, D0
		move.l I_RAM_VBR, A0
		move.l (A0, D0.w*4), D0
		rts

InterruptClear: ;void InterruptClear(uint16_t interruptVector)
		;interruptVector: ($04, A7)
		clr.l D0
		move.w ($04, A7), D0
		andi.w #$00ff, D0
		move.l I_RAM_VBR, A0
		move.l (#__IgnoreInterrupt, PC), (A0, D0.w*4)
		rts