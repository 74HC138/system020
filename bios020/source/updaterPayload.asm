.include "system.asm"

UPDATER_BEGIN:

main:
        ;set stack pointer to allocated stack space
        move.l #StackTop, A7
        ;initialice the serial interface and the poly table
		bsr SerialInit
        bsr CRC32MakeLookup

    .cmdLoop:
        ;move return address to stack
        move.l (.cmdLoop, PC), -(A7)

        bsr SerialRead
        cmpi.b #'i', D0
        beq SendInfo
        cmpi.b #'v', D0
        beq SendVersion
        cmpi.b #'d', D0
        beq ReceiveData
        cmpi.b #'b', D0
        beq ReceiveBufferoffset
        cmpi.b #'c', D0
        beq SendChecksum
        cmpi.b #'w', D0
        beq WriteToFlash
        cmpi.b #'s', D0
        beq SendStatus
        cmpi.b #'a', D0
        beq ReceiveAddress

        move.l (.textCNF, PC), -(A7)
        bsr SerialWrite
        addq.l #4, A7
        rts

    .textCNF:
        dc.b $18, "ERROR: Command not found\n", $06,  $00
        ;0x18 -> cancel ascii control character
        ;0x06 -> acknowlage ascii control character


SendInfo:
    ;desciption: send a json formated string containing system information to the host
    ;parameters: none
    ;returns: null
    ;preserves registers
        bsr SerialSendACK

        move.w #'{', -(A7)
        bsr SerialWriteChar
        addq.l #2, A7

        lea.l (.textField0, PC), A0
        move.l A0, -(A7)
        move.l #RAM_SIZE, -(A7)
        bsr SerialSendJSONHex
        addq.l #8, A7

        lea.l (.textField1, PC), A0
        move.l A0, -(A7)
        move.l #(RAM_SIZE - (UPDATER_END - UPDATER_BEGIN)), -(A7)
        bsr SerialSendJSONHex
        addq.l #8, A7

        lea.l (.textField2, PC), A0
        move.l A0, -(A7)
        move.l #ROM_BASE, -(A7)
        bsr SerialSendJSONHex
        addq.l #8, A7

        lea.l (.textField3, PC), A0
        move.l A0, -(A7)
        move.l #ROM_SIZE, -(A7)
        bsr SerialSendJSONHex
        addq.l #8, A7

        lea.l (.textField4, PC), A0
        move.l A0, -(A7)
        move.l (UpdaterVersion, PC), -(A7)
        bsr SerialSendJSONString
        addq.l #8, A7

        move.w #'}', -(A7)
        bsr SerialWriteChar
        addq.l #2, A7

        bsr SerialSendACK

        rts
    .textField0:
        dc.b "ramsize", $00
    .textField1:
        dc.b "ramfree", $00
    .textField2:
        dc.b "rombase", $00
    .textField3:
        dc.b "romsize", $00
    .textField4:
        dc.b "version", $00
        even
SendVersion:
    ;description: send the plain text version number of the updater
    ;parameters: none
    ;returns: null
    ;preserves registers
        bsr SerialSendACK
        
        move.l (UpdaterVersion, PC), -(A7)
        bsr SerialWrite
        addq.l #4, A7

        bsr SerialSendACK

        rts
ReceiveData:
    ;description: receives a 1024 byte chunk of plain data and writes it to the buffer according to the current buffer position and advances the buffer position
    ;parameters: none
    ;returns: null
    ;preserves registers
        move.l D2, -(A7)
        move.l D3, -(A7)
        move.l D4, -(A7)
        move.l D5, -(A7)

        move.l #DataBuffer, A0
        move.l BufferOffset, D2
        move.l BufferLength, D3
        move.w #1024, D5

        ;send acknowlage that the command has been received
        bsr SerialSendACK

        .loop:
            ;read two bytes into a single word
            bsr SerialRead
            clr.l D4
            move.b D0, D4
            lsl #8, D4
            bsr SerialRead
            move.b D0, D4

            ;write that word into the buffer
            move.w D4, (A0, D2)
            ;advance the buffer offset by 2 bytes
            addq.l #2, D2
            ;when the length of the buffer is smaller then the offset
            ;set the length to the current offset (buffer grows as more data is transmitted)
            cmp.l D2, D3
            bhs .skipMove
                move.l D2, D3
            .skipMove:
            
            ;decrement the number of bytes to receive
            ;and loop as long as it is over 0
            subq.l #2, D5
            bne .loop

        ;send acknowlage that the command has finished executing
        bsr SerialSendACK

        ;store the modified offset and length
        lea.l (BufferOffset, PC), A1
        move.l D2, (A1)+
        move.l D3, (A1)

        ;restore registers
        move.l (A7)+, D5
        move.l (A7)+, D4
        move.l (A7)+, D3
        move.l (A7)+, D2

        rts
ReceiveBufferoffset:
    ;description: receives an eight letter hex string and sets the buffer offset acordingly
    ;note: the least significant bit is ignored and allways 0
    ;parameters: none
    ;returns: null
    ;preserves registers
        bsr SerialSendACK

        ;receive the hex string
        bsr SerialReadHex32
        ;ignore the LSB
        andi.l #$fffffffe, D0
        ;if the received number is 0 then also set the buffer length to zero
        ;this resets the buffer
        bne .skip
            lea.l (BufferLength, PC), A0
            move.l #$00, (A0)
        .skip:
        ;set the buffer offset to the received value
        lea.l (BufferLength, PC), A0
        move.l D0, (A0)

        bsr SerialSendACK
        rts
SendChecksum:
    ;description: Sends the CRC32 checksum of the data being held in the buffer
    ;parameters: none
    ;returns: null
    ;preserves registers
        bsr SerialSendACK

        move.l (DataBuffer, PC), -(A7)
        move.l (BufferLength, PC), -(A7)
        bsr CRC32Calc
        addq.l #8, A7
        move.l D0, -(A7)
        bsr SerialWriteHex32
        addq.l #4, A7

        bsr SerialSendACK
        rts
WriteToFlash:
    ;description: Writes the value of 
    ;parameters: none
    ;returns: null
    ;preserves registers
        bsr SerialSendACK

        move.l WriteAddress, A0
        move.l DataBuffer, A1
        move.l BufferLength, D0

        .loop0:
            ;word count to write per page
            move.w #127, D1
            ;this sets the Flash into programming mode
            move.w #$AAAA, $AAAA + ROM_BASE
            move.w #$5555, $5554 + ROM_BASE
            move.w #$A0A0, $AAAA + ROM_BASE

            ;copy 256 bytes to the flash or until the end of the buffer is reached
            .loop1:
                move.w (A1)+, (A0)+
                subq.l #2, D0
                beq .exitLoop1
                subq.w #1, D1
                bne .loop1
            .exitLoop1:
            ;load the last data word in the buffer
            move.w -(A1), D1
            andi.w #$8080, D1
            move.w D1, -(A7)
            subq.l #2, A0
            .loop2:
                ;compare the written value to the actual value
                ;when the Flash is still programming then bit 7 and/or 15 is flipped
                move.w (A0), ($02, A7)
                andi.w #$8080, ($02, A7)
                eor.w D1, ($02, A7)
                bne .loop2
                ;do test twice to mitigate transient glitches
                ;this is based on the manufactures specifications
                move.w (A0), ($02, A7)
                andi.w #$8080, ($02, A7)
                eor.w D1, ($02, A7)
                bne .loop2
            addq.l #2, A7
            ;test if the reason for the termination of the copy loop was that the buffer is fully written
            cmpi.l #$00, D0
            ;if not then continue the loop 
            bne .loop0
        
        bsr SerialSendACK
        rts
SendStatus:
    ;description: Sends the buffer offset and length 
    ;parameters: none
    ;returns: null
    ;preserves registers
        bsr SerialSendACK

        move.w #'{', -(A7)
        bsr SerialWriteChar
        addq.l #2, A7

        move.l (.textField0, PC), -(A7)
        move.l (BufferLength, PC), -(A7)
        bsr SerialSendJSONHex
        addq.l #8, A7

        lea.l (.textField1, PC), A0
        move.l A0, -(A7)
        move.l (BufferOffset, PC), -(A7)
        bsr SerialSendJSONHex
        addq.l #8, A7

        move.w #'}', -(A7)
        bsr SerialWriteChar
        addq.l #2, A7

        bsr SerialSendACK
        rts

    .textField0:
        dc.b "bufferLength", $00
    .textField1:
        dc.b "bufferOffset", $00
        even

ReceiveAddress:
    ;description: Receives the base Flash address to write to 
    ;parameters: none
    ;returns: null
    ;preserves registers
    bsr SerialSendACK

    bsr SerialReadHex32
    lea.l (WriteAddress, PC), A0
    move.l D0, (A0)

    bsr SerialSendACK
    rts

;----------------------------------------------------------
;Serial Functions
;----------------------------------------------------------
SerialInit:
        andi.b #$f0, MFP_TCDCR
        ori.b #$01, MFP_TCDCR
        move.b #$3, MFP_TDDR ;TDO clock divider for 9600 baud serial

        move.b #$88, MFP_UCR ;CLK / 16, 8bit char, no parity
        move.b #$04, MFP_TSR ;set h flag
        move.b #$05, MFP_TSR ;enable transmitter

        move.b #$01, MFP_RSR ;enable receiver

        rts
SerialWrite:
        move.l (4, A7), A0
    .loop:
        btst.b #7, MFP_TSR
        beq.w .loop ;as long as the BE flag is clear loop

        cmpi.b #$00, (A0)
        beq.w .return
        move.b (A0)+, MFP_UDR
        bra.w .loop
    .return:
        rts
SerialWriteChar:
        btst.b #7, MFP_TSR
        beq.w SerialWriteChar

        move.w (4, A7), D0
        move.b D0, MFP_UDR
        rts
SerialRead:
        btst.b #7, MFP_RSR ;wait until a char is received
        beq.w SerialRead

        move.b MFP_UDR, D0
        rts
__SerialHexTable:
		dc.b "0123456789ABCDEF"
SerialWriteHex8: ;void (int number)
		move.l #__SerialHexTable, A0
	.loop0:
		btst.b #7, MFP_TSR
		beq.w .loop0

		move.w (4, A7), D0
		andi.w #$00f0, D0
		lsr.w #4, D0
		move.b (0,A0,D0), MFP_UDR
	.loop1:
		btst.b #7, MFP_TSR
		beq.w .loop1

		move.w (4, A7), D0
		andi.w #$000f, D0
		move.b (0,A0,D0), MFP_UDR

		rts
SerialWriteHex16: ;void (int number)
		move.w (4, A7), D0
		andi.w #$ff00, D0
		lsr.w #8, D0
		move.w D0, -(A7)
		bsr.w SerialWriteHex8
		addq.l #2, A7

		move.w (4, A7), D0
		andi.w #$00ff, D0
		move.w D0, -(A7)
		bsr.w SerialWriteHex8
		addq.l #2, A7

		rts
SerialWriteHex32: ;void (long number)
        move.l D2, -(A7)

        move.l ($08, A7), D2
        swap D2
        move.w D2, -(A7)
        bsr SerialWriteHex16
        addq.l #2, A7
        swap D2
        move.w D2, -(A7)
        bsr SerialWriteHex16
        addq.l #2, A7

        move.l (A7)+, D2
        rts
SerialReadHex16:
		move.l D2, -(A7)
		clr.l D1
		move.w #3, D2
	.loop:
		lsl.w #4, D1
		bsr SerialRead
		subi.b #48, D0
		cmpi.b #10, D0
		blo .skip
		subi.b #7, D0
	.skip:
		andi.w #$000f, D0
		or.w D0, D1
		dbra D2, .loop

		move.l (A7)+, D2
		move.w D1, D0
		rts
SerialReadHex32:
		move.l D3, -(A7)
		bsr SerialReadHex16
		swap D0
		andi.l #$ffff0000, D0
		move.l D0, D3
		bsr SerialReadHex16
		andi.l #$0000ffff, D0
		or.l D3, D0
		move.l (A7)+, D3
		rts

SerialSendJSONString:
        ;sends a string json entry
        ;paramters:
        ;  String object_name (pointer)
        ;  String object_value (pointer)
        ;returns:
        ;  null
        move.w #'\"', -(A7)
        bsr SerialWriteChar
        addq.l #2, A7

        move.l ($08, A7), -(A7)
        bsr SerialWrite
        addq.l #4, A7

        lea.l (.seperator, PC), A0
        move.l A0, -(A7)
        bsr SerialWrite
        addq.l #4, A7

        move.l ($04, A7), -(A7)
        bsr SerialWrite
        addq.l #4, A7

        move.w #'\"', -(A7)
        bsr SerialWriteChar
        move.w #',', -(A7)
        bsr SerialWriteChar
        addq.l #4, A7

        rts
    .seperator:
        dc.b "\": \"", $00
        even
SerialSendJSONHex:
        ;sends a hexadecial string json entry
        ;paramters:
        ;  String object_name (pointer)
        ;  Long object_value
        ;returns:
        ;  null
        move.w #'\"', -(A7)
        bsr SerialWriteChar
        addq.l #2, A7

        move.l ($08, A7), -(A7)
        bsr SerialWrite
        addq.l #4, A7

        lea.l (.seperator, PC), A0
        move.l A0, -(A7)
        bsr SerialWrite
        addq.l #4, A7

        move.l ($04, A7), -(A7)
        bsr SerialWriteHex32
        addq.l #4, A7

        move.w #'\"', -(A7)
        bsr SerialWriteChar
        move.w #',', -(A7)
        bsr SerialWriteChar
        addq.l #4, A7

        rts
    .seperator:
        dc.b "\": \"", $00
        even

SerialSendACK:
    ;description: sends the acknowlage control character (0x06)
    ;paramters: none
    ;returns: null
        move.w #$06, -(A7)
        bsr SerialWriteChar
        addq.l #2, A7
        rts
;----------------------------------------------------------
;CRC32 Functions
;----------------------------------------------------------
CRC32MakeLookup:
    ;description: fills the polynominal loopup table
    ;paramters: none
    ;returns: none
    ;preserves registers
        move.l D2, -(A7)
        
        move.l #$00, D0 ;table index
        move.l #PolyLookup, A0 ;base pointer
        ;loop over every table entry
        .loop0:
            ;set initial value of entry to its own index
            move.l D0, (A0, D0.l*4)
            ;iterate over entry
            move.b #$08, D1
            .loop1:
                move.l (A0, D0.l*4), D2
                ;shift entry right by one
                lsr.w ($00, A0, D0.l*4)
                roxr.w ($02, A0, D0.l*4)
                ;if the lowest bit (before the shift) is set then xor the entry with the magic value
                ;if not skip it
                andi.l #$01, D2
                beq .skip
                    eori.l #$EDB88320, (A0, D0.l*4)
                .skip:
                subq.l #1, D1
                bne .loop1
            ;increment index and test if we looped over all table entrys
            addq.l #1, D0
            cmpi.l #$0100, D0
            bne .loop0
        ;poly table is finished
        ;restore used registers and return
        move.l (A7)+, D2
        rts
CRC32Calc:
    ;description: calculates the CRC32 value of a given number of bytes
    ;parameters: char* base, long length
    ;   base: pointer to base of byte array
    ;   length: length of array
    ;returns: long CRC32 Checksum in D0
    ;preserves registers
        move.l ($04, A7), D0 ;length
        move.l ($08, A7), A0 ;base
        move.l #PolyLookup, A1 ;lookup table
        move.l #$ffffffff, D1 ;CRC checksum

        move.l D2, -(A7)

        .loop:
            clr.w D2
            ;use lowest byte of current CRC value as the index
            move.b D1, D2
            ;xor it with the current data
            eor.b D2, (A0)
            ;use that as an index into the poly lookup table
            move.l (A1, D2.w*4), D2
            ;shift the current CRC value right by 8
            lsr.l #8, D1
            ;xor the result from the poly table onto the current CRC value
            eor.l D1, D2

            ;rins and repeat until we reach the end of the buffer
            addq.l #1, A0
            subq.l #1, D0
            bne .loop

        ;move result to return register, restore used registers and exit
        move.l D1, D0
        move.l (A7)+, D2
        rts
;----------------------------------------------------------
;Global constants
;----------------------------------------------------------
UpdaterVersion:
        dc.b "2.00A", $00
        even
;----------------------------------------------------------
;Global variables
;----------------------------------------------------------
    ;current Buffer offset
BufferOffset:
        ds.l 1
    ;absolute length of buffer
BufferLength:
        ds.l 1
    ;base address of flash write
WriteAddress:
        ds.l 1
    ;polynominal lookup table for crc32 calculation
PolyLookup:
        ds.l 256
;----------------------------------------------------------
;Stack
;----------------------------------------------------------
Stack:
    ;4kb RAM allocation for stack
        ds.l 1024
StackTop:
;----------------------------------------------------------

UPDATER_END:

DataBuffer:
