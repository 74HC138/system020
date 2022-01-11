#include <iostream>
#include <stdint.h>

struct REGISTERS {
	uint32_t DataRegisters[8];
	uint32_t AddressRegisters[8];
};
struct TASK_FRAME {
	REGISTERS RegisterBuffer;
	uint8_t Stack[0x2000 - sizeof(REGISTERS)];
};
struct TASK_BASE {
	TASK_FRAME** TaskFrameBase;
	uint16_t* PidBase;
	uint32_t NumberOfTasks;
	uint32_t MaxNumberTasks;
	uint32_t CurrentTask; //internal offset, not PID
};

TASK_BASE* I_TASK_BASE;

uint32_t TaskCreate(void* PCinit, uint32_t stackSize) {
	if (!I_TASK_BASE) return 0xffffffff;
	TASK_BASE* base = I_TASK_BASE;
	uint16_t freePid = 0;
	for (int pid = 1; pid < 0xfffe, pid++) {
		bool found = false;
		for (int i = 0; i < base->MaxNumberTasks; i++) {
			if (pid == base->PidBase[i]) {
				found = true;
			 	break;
			}
		}
		if (!found) {
			freePid = pid;
			break;
		}
	}
	if (!freePid) return 0xffffffff;
	for (int i = 0; i < base->MaxNumberTasks; i++) {
		if (base->PidBase[i] == 0xffff) {
			//TimeStop(0)
			base->PidBase[i] = freePid;
			base->TaskFrameBase[i] = (TASK_FRAME*) malloc(stackSize); //<-- replace with own function
			uint32_t* stack = &base->TaskFrameBase[i]->RegisterBuffer.AddressRegister[7];
			*stack = (uint32_t) base->TaskFrameBase[i] + sizeof(TASK_FRAME);
			*stack -= 4;
			(uint32_t*) *stack = (uint32_t) PCinit;
			*stack -= 2;
			(uint16_t*) *stack = 0x0000;
			//TimerStart(0);
			return freePid;
		}
	}
	return 0xffffffff;
}
