VDPInit:
        move.l D2, -(A7)

        move.l #VDPStandartRegs, A0
        clr.l D2
    .loop:
        move.b (A0)+, D0
        move.w D0, -(A7)
        move.w D2, -(A7)
        bsr VDPWriteReg
        addq.l #4, A7
        addq.w #1, D2
        cmpi.b #$08, D2
        bne .loop

        move.l (A7)+, D2
        rts

VDPStandartRegs:
        dc.b $00, $02, $01, $08, $01, $06, $00, $07

;mirrors data (MSB to LSB)
VDPDataMirror: ;char(char)
        move.w ($04, A7), D1
        
        lsr.b #1, D1
        roxl.b #1, D0
        lsr.b #1, D1
        roxl.b #1, D0
        lsr.b #1, D1
        roxl.b #1, D0
        lsr.b #1, D1
        roxl.b #1, D0
        lsr.b #1, D1
        roxl.b #1, D0
        lsr.b #1, D1
        roxl.b #1, D0
        lsr.b #1, D1
        roxl.b #1, D0
        lsr.b #1, D1
        roxl.b #1, D0

        rts

VDPWriteReg: ;void(char data, char register)
        move.w ($06, A7), -(A7)
        bsr VDPDataMirror
        addq.l #2, A7
        move.b D0, VDP_REG ;send mirrored data to VDP

        move.w ($04, A7), D0
        andi.b #$07, D0
        ori.b #$80, D0
        move.w D0, -(A7)
        bsr VDPDataMirror
        addq.l #2, A7
        move.b D0, VDP_REG ;send mirrored register address to VDP

        rts

VDPReadStatus: ;char()
        move.b VDP_STATUS, D0
        move.w D0, -(A7)
        bsr VDPDataMirror
        addq.l #2, A7
        rts

VDPVramSetup: ;void(int address)
        move.w ($04, A7), D0
        lsr.w #6, D0
        move.w D0, -(A7)
        bsr VDPDataMirror
        addq.l #2, A7
        move.b D0, VDP_REG

        move.w ($04, A7), D0
        andi.b #$7f, D0
        ori.b #$40, D0
        move.w D0, -(A7)
        bsr VDPDataMirror
        addq.l #2, A7
        move.b D0, VDP_REG

        rts

VDPVramWrite: ;void(char data)
        move.w ($04, A7), -(A7)
        bsr VDPDataMirror
        addq.l #2, A7
        move.b D0, VDP_VRAM
        rts

VDPVramRead: ;char()
        move.b VDP_VRAM, D0
        move.w D0, -(A7)
        bsr VDPDataMirror
        addq.l #2, A7
        rts