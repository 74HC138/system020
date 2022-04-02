#ifndef TASK_H
#define TASK_H

#include "glue.h"

#define MAX_TASK 128
#define STACK_SIZE 16384 //16 Kibibytes of stack

enum TaskPriv {
    superuser = 1, //when task has supervisor privilege then all other flags are ignored. it can EVERYTHING
    tty = 2, //task can acces tty devices (excluding the terminal the task is running in because this is allways allowed)
    blockdevice = 4, //task can RWM unprivileged blockdevices (removable media eg. USB flash drives, floppys)
    privBlockdevice = 8, //RMW privileges blockdevices (eg. bootdrive, flashrom)
    blockdeviceRead = 16, //like 4 but only for reading
    privBlockdeviceRead = 32 //like 8 but only for reading
};
enum TaskState {
    running = 0, //normal task opperation
    paused = 1, //task is not getting called by sceduler
    waiting = 2, //task is waiting for signal
    suspended = 3, //task is done, cant be startet again. Parrent can force suspend or wait for suspend to get the return code
    invalid = 0xFFFF //task is not valid
};
struct Task {
    int PID; //process ID of task ID
    int UID; //user ID of the task owner
    int parrentPID; //PID of the creator of the task
    void* stackBase;
    long stackSize;
    void* stackPointer; //current stack pointer of task
    enum TaskPriv privileges; //what the task can do
    enum TaskState state; //what the task is doing
};

int TaskInit();
struct Task* TaskReserve();
struct Task* TaskFindbyPID(int pid);
int TaskPauseSwitch();
int TaskResumeSwitch();

struct Task GlobalTaskList[MAX_TASK];

#endif