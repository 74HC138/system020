StringCompare: ;int (char* a, char* b)
        move.l ($04, A7), A0 ;a
        move.l ($08, A7), A1 ;b
        clr.w D0
    .loop:
        move.b (A0), D0
        add.b (A1), D0
        cmpi.w #$0000, D0
        beq .exit
        cmp.b (A0)+, (A1)+
        beq .loop

        ;string equal up to position in D0 
        suba.l ($08, A7), A1
        move.l A1, D0
        rts
    
        ;strings are equal
    .exit:
        clr.l D0
        rts
