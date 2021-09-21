;Memory allocation functions

;struct PAGE {
;   uint16_t nextPage; //zero if last page
;   uint16_t ownerPID; //0xffff if page is free
;}

PAGE_SIZE = 256
MEMORY_PAGES = RAM_SIZE / PAGE_SIZE
RESERVED_MEMORY = (PAGE_BASE - RAM_BASE) + (MEMORY_PAGES * 4)

if ((RESERVED_MEMORY & (PAGE_SIZE - 1)) != 0)
RESERVED_PAGES = (MEMORY_PAGES / PAGE_SIZE) + 1
elseif
RESERVED_PAGES = (MEMORY_PAGES / PAGE_SIZE)
endif

print "MEMORY_PAGES: ", /d MEMORY_PAGES
print "RESERVED_MEMORY: ", /d RESERVED_MEMORY
print "RESERVED_PAGES: ", /d RESERVED_PAGES

;Initinalizes the allocation table and allocates reserved pages with the kernel PID
MallocInit: ;void MallocInit()
        clr.l D0
        move.l #PAGE_BASE, A0
        ;prepare alloc table
    .loop:
        move.w #$0000, ($00, A0, D0.w*4)
        move.w #$ffff, ($02, A0, D0.w*4)
        addq.w #1, D0
        cmp.w #RAM_PAGES, D0
        bne .loop

        clr.l D0
        ;allocate reserved pages to PID 0 (should not get cleared so its safe)
    .loop2:
        move.w D0, ($00, A0, D0.w*4)
        addq.w #1, ($00, A0, D0.w*4)
        move.w #$0000, ($02, A0, D0.w*4)
        addq.w #1, D0
        cmp.w #RESERVED_PAGES
        bne .loop2
        subq.w #1, D0
        move.w #$0000, ($00, A0, D0.w*4)
        rts

;Allocates nPages amount of pages with the owner PID of PID
;in theory up to 4 billion pages could be allocated but due to internal limits only 65536 pages can be allocated
;trying to allocate more then 65536 pages will most likely cause halting or crashing of the os/task
MallocPage: ;void* MallocPage(uint32_t nPages, uint16_t PID)
        ;PID: ($04, A7)
        ;nPages: ($06, A7)
        move.l #PAGE_BASE, A0
        move.w #RESERVED_PAGES, D0
        clr.l D1
        ;find enough empty pages in a row
    .loop:
        addq.l #1, D1
        cmpi.l #MEMORY_PAGES, D1
        beq .errorExit ;gets called if not enough pages were found
        cmpi.w #$ffff, ($02, A0, D0.w*4)
        beq .skip
        clr.l D1 ;encountered a valid PID value -> reset empty pages found to 0
    .skip:
        cmp.l D1, ($06, A7) ;test if enough empty pages where found
        bne .loop
        ;allocate found memory
        subq.l #1, D1 ;subtract 1 because the code below is 0 index based
        sub.l D1, D0
        move.l D0, -(A7)
    .loop2:
        move.w D0, ($00, A0, D0.w*4)
        addq.w #1, ($00, A0, D0.w*4)
        move.w ($08, A7), ($02, A0, D0.w*4)
        addq.l #1, D0
        dbra D1, .loop2
        subq.l #1, D0
        move.w #$0000, ($00, A0, D0.w*4)
        ;calculate base address
        move.l (A7)+, D0
        mulu.l #PAGE_SIZE, D0
        addi.l #RAM_BASE, D0
        move.l D0, A0
        rts
    .errorExit:
        move.l #$00, D0
        move.l D0, A0
        rts ;return a null pointer if MallocPage fails

;Allocates enough memory to fit length bytes with the owner PID of PID
;In theory up to 4gb of memory could be allocated but due to internal limitations this is limited to 16mb
;Trying to allocate more then 16mb will most likely cause halting or crashing of the os/task
Malloc: ;void* Malloc(uint32_t length, uint16_t PID)
        ;PID: ($04, A7)
        ;nPages: ($06, A7)
        ;calculate number of pages needed to fit length
        move.l ($06, A7), D0
        clr.l D1
        divul.l #PAGE_SIZE, D1:D0
        cmpi.l #$00, D1
        beq .skip ;if remainder is 0 skip
        addq.l #1, D0
    .skip:
        
        move.w ($04, A7), D1
        move.l D0, -(A7)
        move.w D1, -(A7)
        bsr MallocPage
        addq.l #6, A7
        rts

;Frees all pages belonging to that page entry
;Warning: only pages that have been allocated by Malloc or MallocPage should be given to this function
FreePage: ;uint32_t FreePage(uint32_t pageNumber)
        ;pageNumber: ($04, A7)
        move.l ($04, A7), D0
        move.l #PAGE_BASE, A0
        move.l D2, -(A7)
        clr.l D2
    .loop:
        addq.l #1, D2
        move.w ($00, A0, D0.w*4), D1
        move.w #$0000, ($00, A0, D0.w*4)
        move.w #$ffff, ($02, A0, D0.w*4)
        move.l D1, D0
        cmpi.w #$0000, D1
        bne .loop

        move.l D2, D0
        move.l (A7)+, D2
        rts

;Frees all pages belonging to that pointer
;Warning: only pointers returned by Malloc or MallocPage should be given to this function
Free: ;uint32_t Free(void* base)
        ;base: ($04, A7)
        move.l ($04, A7), D0
        subi.l #PAGE_BASE, D0
        divu.l #PAGE_SIZE, D0
        move.l D0, -(A7)
        bsr FreePage
        addq.l #4, A7
        rts

;Frees all pages with the owner PID PID
FreePid: ;uint32_t FreePid(uint16_t PID)
        ;PID: ($04, A7)
        move.l #PAGE_BASE, A0
        clr.l D0
        move.w ($04, A7), D1
        move.l D2, -(A7)
        clr.l D2
    .loop:
        cmp.w ($02, A0, D0.w*4), D1
        bne .skip
        move.w #$0000, ($00, A0, D0.w*4)
        move.w #$ffff, ($02, A0, D0.w*4)
        addq.l #1, D2
    .skip:
        addq.l #1, D0
        cmp.l D0, RAM_PAGES
        bne .loop
        
        move.l D2, D0
        move.l (A7)+, D2
        rts

GetTotal: ;uint32_t GetTotal()
        move.l #MEMORY_PAGES - RESERVED_PAGES, D0
        rts

GetFree: ;uint32_t GetFree()
        move.l #PAGE_BASE, A0
        clr.l D0
        clr.l D1
    .loop:
        cmpi.w #$ffff, ($02, A0, D0.w*4)
        bne .skip
        addq.l #1, D1
    .skip:
        addq.l #1, D0
        cmpi.l #RAM_PAGES, D0
        bne .loop

        move.l D1, D0
        rts

GetPageSize: ;uint32_t GetPageSize()
        move.l #PAGE_SIZE, D0
        rts

