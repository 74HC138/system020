KbInit: ;void (*fnpt(int char))
        ;clear the __KbLast buffer
        move.l #__KbLast, A0
        clr.l (A0)+
        clr.l (A0)+
        ;set callback function
        move.l ($04, A7), __KbCallback

        rts

KbRead:
        move.l A2, -(A7)

        ;read all keys
        move.b KB_BASE + $01, D0
        rol.w #8, D0
        move.b KB_BASE + $02, D0
        move.w D0, -(A7)
        move.b KB_BASE + $04, D0
        rol.w #8, D0
        move.b KB_BASE + $08, D0
        move.w D0, -(A7)
        move.b KB_BASE + $10, D0
        rol.w #8, D0
        move.b KB_BASE + $20, D0
        move.w D0, -(A7)
        move.b KB_BASE + $40, D0
        rol.w #8, D0
        move.b KB_BASE + $80, D0
        move.w D0, -(A7)

        move.l #KbLayout, A0
        ;test if shift is pressed
        btst.b #5, ($07, A7)
        beq .skip
        ;when shift is pressed add $40 to the layout pointer to change to uppercase
        add.l #$40, A0
    .skip:
        move.l #__KbLast, A1
        move.l A7, A2
        add.l #$07, A2
        ;A0 contains: pointer to layout
        ;A1 contains: pointer to last keypresses
        ;A2 contains: pointer to current keypresses

    .loop0:
        move.b (A1)+, D0
        not.b D0
        and.b -(A2), D0 ;D0 contains bit mask to new pressed keys
        moveq.l #$08, D1
    .loop1:
        btst #0, D0 ;test LSB
        bne .skipCallback
        move.l D0, -(A7)
        move.l D1, -(A7)
        move.l A0, -(A7)
        move.l A1, -(A7)
        clr.l D0
        move.b (A0), D0
        move.w D0, -(A7)
        jsr __KbCallback
        addq.l #2, A7
        move.l (A7)+, A1
        move.l (A7)+, A0
        move.l (A7)+, D1
        move.l (A7)+, D0
    .skipCallback:
        ;advance to next char
        ror.b #1, D0
        adda.l #1, A0
        ;loop until D1 is 0
        subq.b #1, D1
        bne .loop1
        ;loop until we reached the top of the stack
        cmpa A2, A7
        bne .loop0
    .exit:
        ;move current keypresses to last keypresses
        move.w ($06, A7), D0
        rol.w #8, D0
        move.w D0, __KbLast + $00
        move.w ($04, A7), D0
        rol.w #8, D0
        move.w D0, __KbLast + $02
        move.w ($02, A7), D0
        rol.w #8, D0
        move.w D0, __KbLast + $04
        move.w ($00, A7), D0
        rol.w #8, D0
        move.w D0, __KbLast + $06
        
        ;clean up stack
        adda.l #$08, A7
        move.l (A7)+, A2
        rts




KbLayout:
        ;non shift
        dc.b "1     q2"
        dc.b "3wa zse4"
        dc.b "5rdxcft6"
        dc.b "7ygvbhu8"
        dc.b "9ijnmko0"
        dc.b " pl,.:- "
        dc.b " *;/ =+ "
        dc.b "\b\n€@    "
        ;shift
        dc.b "!     Q\""
        dc.b "§WA ZSE$"
        dc.b "%RDXCFT&"
        dc.b "/YGVBHU("
        dc.b ")IJNMKO="
        dc.b " PL<>[_ "
        dc.b " *]? =+ "
        dc.b "\b\n€@    "
    even