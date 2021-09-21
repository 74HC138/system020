UpdaterInit:
        move.l #.text0, -(A7)
        bsr SerialWrite
        addq.l #4, A7
        move.l #.payload_start, A0
        move.l #RAM_BASE, A1
    .loop:
        move.l (A0)+, (A1)+
        cmpa.l #.payload_end, A0
        bls.w .loop

        move.l #.text1, -(A7)
        bsr SerialWrite
        addq.l #4, A7

        jmp RAM_BASE

    .text0:
        dc.b "loading payload to RAM\n", $00
    .text1:
        dc.b "calling payload\n", $00

        even
    .payload_start:
        .incbin "../build/updaterPayload.bin"
    .payload_end: