#include "kernel/exception.h"

uint32_t* exceptionTable;

void ExceptionHandlerIgnore(void) {
    pushRegisters();
    popRegisters();
    returnExeption();
}

int initException() {
    exceptionTable = (uint32_t*) malloc(4096);
    if (exceptionTable == (void*) 0) return -1; //panic, cant allocate exception table 
    asm volatile ("movec %1, VBR"
                :
                : "r" (exceptionTable));
    addException(ResetPC, 0);
    addException(ResetSP, 0);
    for (int i = 2; i < 1024; i++) {
        exceptionTable[i] = (uint32_t) &ExceptionHandlerIgnore;
    }
    return 0;
}
int addException(enum ExceptionList vector, void (*handler)(void)) {
    exceptionTable[vector] = (uint32_t) handler;
}