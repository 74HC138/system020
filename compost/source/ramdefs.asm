;hard coded variables in RAM

abs RAM_BASE

        dcd.l I_TASK_BASE
        dcd.l I_RAM_VBR
        dcd.l I_TIMER_BASE

PAGE_BASE:
        ;variable size buffer gets loaded here by memory.asm