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


TaskCreate: ;uint32_t TaskCreate(void* PCinit, uint32_t stackSize)
        ;stackSize: ($04, A7)
        ;PCinit: ($08, A7)
        move.l #__TimerExceptionText, A0
        cmpi.l #0, I_TASK_BASE
        trapeq
        move.l D2, -(A7)
        move.l I_TASK_BASE, A0
        ;find free pid
        move.l ($0C, A0), D0
        move.l #1, D1
        move.l ($04, A0), A1
    .loop0:
        move.l #0, D2
    .loop1:
        addq.l #1, D2
        cmp.l  D0, D2
        beq .found
        cmp.w D1, (A1, D2.l*2)
        bne .loop1
        addq.l #1, D1
        cmpi.l #$00010000, D1
        beq .error
        bra .loop0
    .found:
        move.l (A7)+, D2
        move.l D1, D7
        
        move.l ($04, A7), -(A7)
        move.w D7, -(A7)
        bsr Malloc
        addq.l #6, A7
        cmpi.l #0, D0
        beq .error

        move.l I_TASK_BASE, A0
        move.l ($00, A0), A1
        move.l ($08, A0), D1
        subq.l #1, D1
        move.l D0, ($00, A1, D1.l*4)
        
        move.l ($04, A0), A1
        move.l D7, ($00, A1, D1.l*4)



    .error:
        move.l #$ffffffff, D0
        rts

TaskEnd: ;uint32_t TaskEnd(uint16_t pid)

TaskExit: ;void TaskExit(uint32_t exitCode)

TaskSetName: ;uint32_t TaskSetName(uint16_t pid, char* nameString)

TaskGetName: ;char* TaskGetName(uint16_t pid)

TaskGetRunning: ;uint32_t TaskGetRunning(uint16_t* pidList, uint32_t listLength)

TaskGetRunnignCount: ;uint32_t TaskGetRunningCount()

TaskGetCurrent: ;uint16_t TaskGetCurrent()

__TaskExceptionText:
        dc.b "I_TASK_BASE not allocated", $00
        even