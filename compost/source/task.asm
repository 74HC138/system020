;Task handling functions

;struct REGISTERS {
;   uint32_t DataRegisters[8];      ($00)
;   uint32_t AddressRegisters[8];   ($20)
;}
;struct TASK_FRAME {
;   REGISTERS RegisterBuffer;
;   uint8_t Stack[0x2000 - sizeof(REGISTERS)]; //8122 Bytes of stack, aught to be enough, sizeof(TASK_FRAME) = 8192 (0x2000)    
;}
;struct TASK_BASE {
;   TASK_FRAME** TaskFrameBase;     ($00)
;   uint16_t* PIDBase;              ($04)
;   uint32_t NumberOfTasks;         ($08)
;   uint32_t MaxNumberTasks;        ($0c)
;   uint32_t CurrentTask;           ($10) ;!internal ID not PID
;   char** NameBase                 ($14)
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
        
        ;create NameBase
        move.l ($0C, A2), D0
        asl.l #2, D0
        move.l D0, -(A7)
        move.w #0, -(A7)
        bsr Malloc
        addq.l #6, A7
        cmpi.l #0, D0
        beq .error
        move.l D0, ($14, A2)

        ;create TaskFrame of task#0
        move.l #__TaskDefaultName, ([$14, A2], $00)
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
        
        ;timer allocation code here
        ;set callback to taskwsitch
        ;start timer

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
    

__TaskGetFreePid:
        move.l I_TASK_BASE, A0
        move.l #0, D0
    .loop0:
        addq.l #1, D0
        cmpi.l #$fffe, D0
        bgt .error
        move.l #0, D1
    .loop1:
        cmp.l D1, ($0c, A0)
        beq .foundFree
        cmp.w D0, ([$04, A0], D1)
        beq .loop0
        addq.l #1, D1
        bra .loop1
    
    .foundFree:
        rts
    .error:
        move.l #$ffffffff, D0
        rts

__TaskGetFreeBase:
        move.l I_TASK_BASE, A0
        move.l ($0c, A0), D1
        move.l ($04, A0), A0
        clr.l D0
    .loop:
        cmpi.w #$ffff, (A0, D0.w*2)
        beq .exit
        addq.l #1, D0
        cmp D0, D1
        beq .error
        bra .loop

    .exit:
        rts
    .error:
        move.l #$ffffffff, D0
        rts
        

TaskCreate: ;uint32_t TaskCreate(void* PCinit, uint32_t stackSize)
        move.l D6, -(A7)
        move.l D7, -(A7)

        ;stackSize: ($c0, A7)
        ;PCinit: ($10, A7)
        move.l #__TimerExceptionText, A0
        cmpi.l #0, I_TASK_BASE
        trapeq

        bsr __TaskPause

        bra __TaskGetFreeBase
        cmpi.l #$ffffffff, D0
        beq .error
        move.l D0, D7
        bra __TaskGetFreePid
        cmpi.l #$ffffffff, D0
        beq .error
        move D0, D6

        move.l ($c0, A7), -(A7)
        move.w D6, -(A7)
        bsr Malloc
        addq.l #6, A7
        cmpi.l #0, D0
        beq .error
        move.l I_TASK_BASE, A0
        move.l D0, ([$00, A0], D7.l*4)
        move.l D0, A1
        add.l ($c0, A7), D0
        move.w D6, ([$04, A0], D7.l*2)
        move.l #__TaskDefaultName, ([$14, A0], D7.l*4)
        move.l D0, A0
        move.l ($10, A7), -(A0)
        move.w #0, -(A0)
        move.l A0, ($3c, A1)

        bsr __TaskContinue

        move.l D6, D0
        move.l (A7)+, D7
        move.l (A7)+, D6
        rts

    .error:
        move.l (A7)+, D7
        move.l (A7)+, D6
        move.l #$ffffffff, D0
        rts




;kills the task with the PID pid. Returns the internal number of the task (0 -> maxTasks - 1) or MAX_UINT32 if it fails.
TaskKill: ;uint32_t TaskEnd(uint16_t pid)
        ;($02, A7) -> argument pid
        move.l I_TASK_BASE, A0
        move.l ($04, A0), A1 ;pid base
        clr.l D0
    .findBase: ;search for base of pid
        cmp.w ([$04, A0], D0.l*2), ($02, A7)
        beq .baseFound
        addq.l #1, D0
        cmpi.l #$fffe, D0
        beq .error
    .baseFound: ;base of pid now in D0 as long
        
        bsr __TaskPause
        move.w #$ffff, ([$04, A0], D0.l*2) ;clear pid entry
        move.l #0, ([$00, A0], D0.l*4) ;remove pointer to task base
        subq.l #1, ($08, A0) ;decrement the number of running tasks
        bsr FreePid ;free all memory allocations of pid
        bsr __TaskContinue
        rts

    .error:
        move.l #$ffffffff, D0
        rts

;exits the current task. exitCode currently unused but should be 0 for forwards compatability
TaskExit: ;void TaskExit(uint32_t exitCode)
        move.l I_TASK_BASE, A0
        move.l ($10, A0), D0
        move.w ([$04, A0], D0.w*2), D0
        move.w D0, -(A7)
        bsr TaskKill
        addq.l #2, A7
        ;kinda poetic. The task burns all of their belongings, cleans the house, destroys their passport and waits until the taskswitcher carries them away.
    .waitTillDeath:
        bra .waitTillDeath

TaskSetName: ;uint32_t TaskSetName(uint16_t pid, char* nameString)

TaskGetName: ;char* TaskGetName(uint16_t pid)

TaskGetRunning: ;uint32_t TaskGetRunning(uint16_t* pidList, uint32_t listLength)

TaskGetRunnignCount: ;uint32_t TaskGetRunningCount()

TaskGetCurrent: ;uint16_t TaskGetCurrent()

__TaskExceptionText:
        dc.b "I_TASK_BASE not allocated", $00
        even
__TaskDefaultName:
        dc.b "noname", $00
        even