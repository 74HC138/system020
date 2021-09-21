;Task handling functions

;struct REGISTERS {
;   uint32_t DataRegisters[8];
;   uint32_t AddressRegisters[8];
;   uint32_t ReturnAddress;
;   uint16_t StatusRegister;
;}
;struct TASK_FRAME {
;   REGISTERS RegisterBuffer;
;   uint8_t Stack[0x2000 - sizeof(REGISTERS)]; //8122 Bytes of stack, aught to be enough, sizeof(TASK_FRAME) = 8192 (0x2000)    
;}
;struct TASK_BASE {
;   TASK_FRAME** TaskFrameBase;
;   uint16_t* PIDBase;
;   uint32_t NumberOfTasks;
;   uint32_t MaxNumberTasks;
;   uint32_t CurrentTask;
;}

TaskInit: ;void TaskInit(void* initPC)
        ;initPC: ($04, A7)
        ;create task base
        move.l #20, -(A7)
        move.w #0, -(A7)
        bsr Malloc
        addq.l #6, A7
        cmpi.l #0, D0
        beq .error
        move.l D0, I_TASK_BASE
        move.l D0, A2

        ;create TaskFrameBase
        move.l #$0100, -(A7)
        move.w #0, -(A7)
        bsr Malloc
        addq.l #6, A7
        cmpi.l #0, D0
        beq .error
        move.l D0, ($00, A2)

        ;create PIDBase
        move.l #$0100, -(A7)
        move.w #0, -(A7)
        bsr Malloc
        addq.l #6, A7
        cmpi.l #0, D0
        beq .error
        move.l D0, ($04, A2)
        move.l #1, ($08, A2)
        move.l #64, ($0C, A2)
        move.l #0, ($10, A2)

        ;create TaskFrame of task#0
        move.l #$2000, -(A7)
        move.w #1, -(A7)
        bsr Malloc
        addq.l #6
        cmpi.l #0, D0
        beq .error
        move.l D0, ([$00, A2], $00)
        ;set PID of task#0 to 1
        move.w #1, ([$04, A2], $00)
        addi.l #$2000, D0
        move.l ($04, A7), A6
        ;set stack pointer to end of TaskFrame#0
        move.l D0, A7
        
        ;and jump to the code
        jsr A6

        ;if master task return then stop the cpu
        stop #$ffff
        ;infinite loop in case of fall through
    .infiniteLoop:
        bra .infiniteLoop

        ;if this gets executet we are in deep shit
        ;i.e. the allocation table is dead
        ;in case of that the only possible solution is to reset the cpu
    .error:
        reset
        move.l #0, VBR
        move.l $00, A7
        jmp ($04)


