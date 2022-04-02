#include "task.h"

int TaskInit() {
    char* ptr = (char*) &GlobalTaskList[0];
    for (int i = 0; i < sizeof(struct Task) * MAX_TASK; i++) ptr[i] = 0;
    for (int i = 0; i < MAX_TASK; i++) GlobalTaskList[i].state = invalid;
    return 0;
}

struct Task* TaskReserve() {
    TaskPauseSwitch();
    for (int i = 0; i < MAX_TASK; i++) {
        if (GlobalTaskList[i].state == invalid) {
            GlobalTaskList[i].state = paused;
            TaskResumeSwitch();
            return &GlobalTaskList[i];
        }
    }
    TaskResumeSwitch();
    return NULL;
}
struct Task* TaskFindbyPID(int pid) {
    for (int i = 0; i < MAX_TASK; i++) {
        if (GlobalTaskList[i].PID == pid) {
            return &GlobalTaskList[i];
        }
    }
    return NULL;
}
void* TaskSet(struct Task* task, void* PCInit, void* SPInit) {
    volatile inline asm(   "move.w 0x0000, -(SPInit)\n"\
                    "move.l PCInit, -(SPInit)\n"\
                    "move.l 0, -(SPInit)\n"\
                    "move.l 0, -(SPInit)\n"\
                    "move.l 0, -(SPInit)\n"\
                    "move.l 0, -(SPInit)\n"\
                    "move.l 0, -(SPInit)\n"\
                    "move.l 0, -(SPInit)\n"\
                    "move.l 0, -(SPInit)\n"\
                    "move.l 0, -(SPInit)\n"\
                    "move.l 0, -(SPInit)\n"\
                    "move.l 0, -(SPInit)\n"\
                    "move.l 0, -(SPInit)\n"\
                    "move.l 0, -(SPInit)\n"\
                    "move.l 0, -(SPInit)\n"\
                    "move.l 0, -(SPInit)\n"\
                    "move.l PID, -(SPInit)");
    
    
    
    (int*) SPInit[0] = 0x0000; //status register
    SPInit += 2;
    (long*) SPInit[0] = (long) PCInit; //programm counter
    SPInit += 4;
    for (int i = 0; i < 14; i++) {
        (long*) SPInit[0] = (long) 0;
        SPInit += 4;
    }
    (long*) SPInit[0] = task->PID; //D0 contains PID
    SPInit += 4;
    return SPInit;
}