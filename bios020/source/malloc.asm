;memory allocator

MallocInit:
        lea.l (__MemoryAllocationTable, PC), A0
        move.l RAM_SIZE / 1024, D0
        .loop0:
            move.l #$00, (A0)+
            subq.l #1, D0
            bne .loop0
        lea.l (__MemoryAllocationTable, PC), A0
        move.l RAM_DEFS_END - RAM_BASE, D0
        ror.l #8, D0
        ror.l #2, D0
        swap D0
        cmpi.w #$0000, D0
        beq .skip
            addi.l #$00010000, D0
        .skip:
        swap D0
        move.w #$01, D1
        .loop1:
            move.w D1, (A0)+
            move.w #$00, (A0)+
            addq.w #1, D1
            subq.w #1, D0
            bne .loop1
        subq.w #1, D1
        subq.l #4, A0
        move.w D1, (A0)
        rts

Malloc:
    ;desciption: allocates memory
    ;parameters: uint32_t size
    ;returns: void* allocMem
    ;preserves registers
    move.l ($04, A7), D0
    divu.w #1024, D0
    swap D0
    cmpi.w #$00, D0
    beq .skip
        addi.l #$00010000, D0
    .skip:
    swap D0
    move.w D0, -(A7)
    bsr MallocPage
    addq.l #2, A7
    rts

MallocPage:
    ;desciption: allocates memory pages
    ;parameters: uint16_t nPages
    ;returns: void* allocMem
    ;preserves registers
        lea (__MemoryAllocationTable, PC), A0
        clr.l D1
        .loop1:
            cmpi.w #$0000, (A0)
            beq .pageFree
                clr.l D1
            .continue:
            addq.l #4, A0
            cmpa.l #__MemoryAllocationTableEnd, A0
            beq .exitFail
            bra .loop1
            .pageFree:
                cmpi.w #$0000, D1
                bne .skip
                    move.l A0, D0
                    subi.l #__MemoryAllocationTable, D0
                    mulu.w #256, D0
                    addi.l #RAM_BASE, D0
                    move.l D0, A1
                .skip:
                addq.w #1, D1
                cmp.w ($04, A7), D1
                beq .exitSucces
                bra .continue
    .exitFail:
        move.l #0, A1
    .exitSucces:
        move.l A1, D0
        rts
