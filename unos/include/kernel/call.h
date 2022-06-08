//includes

//defines

//enumerations
enum KERNELCALL {
    NOP = 0, //no parameters
    ForceTaskSwitch, //no parameters
    TaskEnd, //parameter uint32_t exitCode
    TaskSleep, //parameters uint32_t* wakeCondition, uint32_t bitmask, uint32_t value
};
//structures

//constants

//variables

//functions
uint32_t kernelCall(enum KERNELCALL, ...);