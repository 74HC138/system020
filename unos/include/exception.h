#ifndef EXCEPTION_H
#define EXCEPTION_H
//includes
#include <stdint.h>
//defines
#define returnExeption() volatile asm("rte")
#define pushRegisters() volatile asm("movem D0-D7/A0-A6, -(A7)")
#define popRegisters() volatile asm("movem (A7)+, D0-D7/A0-A6")
//enumerations
enum ExceptionList {
    ResetSP = 0,
    ResetPC = 1,
    AccessFault = 2,
    AddressError = 3,
    IllegalInstruction = 4,
    DivZero = 5,
    CHK = 6,
    Trapcc = 7,
    PrivilegeViolation = 8,
    Trace = 9,
    Line1010 = 10,
    Line1111 = 11,
    CopProtocolViolation = 13,
    FormatError = 14,
    UnintInterrupt = 15,
    SpuriousInterrupt = 24,
    Autovector1 = 25,
    Autovector2 = 26,
    Autovector3 = 27,
    Autovector4 = 28,
    Autovector5 = 29,
    Autovector6 = 30,
    Autovector7 = 31,
    Trap0 = 32,
    Trap1 = 33,
    Trap2 = 34,
    Trap3 = 35,
    Trap4 = 36,
    Trap5 = 37,
    Trap6 = 38,
    Trap7 = 39,
    Trap8 = 40,
    Trap9 = 41,
    Trap10 = 42,
    Trap11 = 43,
    Trap12 = 44,
    Trap13 = 45,
    Trap14 = 46,
    Trap15 = 47,
    FPUnordertCondition = 48,
    FPInexactResult = 49,
    FPDivZero = 50,
    FPUnderflow = 51,
    FPOperandError = 52,
    FPOverflow = 53,
    FPSignalNAN = 54,
    FPUnimplementedType = 55,
    MMUConfigError = 56,
    MMUIllegalOpError = 57,
    MMUAccesLevelViolation = 58
};
//functions
int initException();
int addException(ExceptionList vector, void (*handler)(void))


#endif