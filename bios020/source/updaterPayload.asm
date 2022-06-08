.include "system.asm"

UPDATER_BEGIN:

main:
        ;set stack pointer to allocated stack space
        lea.l (StackTop, PC), A7
        ;initialice the serial interface and the poly table
		bsr SerialInit

        pea.l (.textIntro, PC)
        bsr SerialWrite
        addq.l #4, A7

    .cmdLoop:
        pea (.cmdLoop, PC)

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
        beq SendChecksum ;BORKED
        cmpi.b #'w', D0
        beq WriteToFlash
        cmpi.b #'s', D0
        beq SendStatus ;BORKED
        cmpi.b #'a', D0
        beq ReceiveAddress

        pea.l (.textCNF, PC)
        bsr SerialWrite
        addq.l #4, A7
        rts

    .textCNF:
        dc.b $18, "ERROR: Command not found\n", $06,  $00
        ;0x18 -> cancel ascii control character
        ;0x06 -> acknowlage ascii control character
    .textIntro:
        dc.b "Ready!\n", $00
        even

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
        pea.l (UpdaterVersion, PC)
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
        
        pea.l (UpdaterVersion, PC)
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

        lea.l (DataBuffer, PC), A0
        move.l (BufferOffset, PC), D2
        move.l (BufferLength, PC), D3
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
            subq.w #2, D5
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

        move.l (WriteAddress, PC), A0
        move.l (DataBuffer, PC), A1
        move.l (BufferLength, PC), D0

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

        ;print test string
        pea.l (.testText, PC)
        bsr SerialWrite
        addq.l #4, A7

        rts
    .testText:
        dc.b "Serial Inited\n", $00
        even
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
        beq SerialRead

        move.b MFP_UDR, D0
        move.b D0, MFP_UDR
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
CRC32Calc:
    ;description: calculates the CRC32 value of a given number of bytes
    ;parameters: char* base, long length
    ;   base: pointer to base of byte array
    ;   length: length of array
    ;returns: long CRC32 Checksum in D0
    ;preserves registers
        move.l ($04, A7), D0 ;length
        move.l ($08, A7), A0 ;base
        lea.l (PolyLookup, PC), A1 ;lookup table
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
    ;polynominal lookup table for crc32 calculation
PolyLookup:
        dc.l $00000000, $77073096, $EE0E612C, $990951BA
        dc.l $076DC419, $706AF48F, $E963A535, $9E6495A3
        dc.l $0EDB8832, $79DCB8A4, $E0D5E91E, $97D2D988
        dc.l $09B64C2B, $7EB17CBD, $E7B82D07, $90BF1D91
        dc.l $1DB71064, $6AB020F2, $F3B97148, $84BE41DE
        dc.l $1ADAD47D, $6DDDE4EB, $F4D4B551, $83D385C7
        dc.l $136C9856, $646BA8C0, $FD62F97A, $8A65C9EC
        dc.l $14015C4F, $63066CD9, $FA0F3D63, $8D080DF5
        dc.l $3B6E20C8, $4C69105E, $D56041E4, $A2677172
        dc.l $3C03E4D1, $4B04D447, $D20D85FD, $A50AB56B
        dc.l $35B5A8FA, $42B2986C, $DBBBC9D6, $ACBCF940
        dc.l $32D86CE3, $45DF5C75, $DCD60DCF, $ABD13D59
        dc.l $26D930AC, $51DE003A, $C8D75180, $BFD06116
        dc.l $21B4F4B5, $56B3C423, $CFBA9599, $B8BDA50F
        dc.l $2802B89E, $5F058808, $C60CD9B2, $B10BE924
        dc.l $2F6F7C87, $58684C11, $C1611DAB, $B6662D3D
        dc.l $76DC4190, $01DB7106, $98D220BC, $EFD5102A
        dc.l $71B18589, $06B6B51F, $9FBFE4A5, $E8B8D433
        dc.l $7807C9A2, $0F00F934, $9609A88E, $E10E9818
        dc.l $7F6A0DBB, $086D3D2D, $91646C97, $E6635C01
        dc.l $6B6B51F4, $1C6C6162, $856530D8, $F262004E
        dc.l $6C0695ED, $1B01A57B, $8208F4C1, $F50FC457
        dc.l $65B0D9C6, $12B7E950, $8BBEB8EA, $FCB9887C
        dc.l $62DD1DDF, $15DA2D49, $8CD37CF3, $FBD44C65
        dc.l $4DB26158, $3AB551CE, $A3BC0074, $D4BB30E2
        dc.l $4ADFA541, $3DD895D7, $A4D1C46D, $D3D6F4FB
        dc.l $4369E96A, $346ED9FC, $AD678846, $DA60B8D0
        dc.l $44042D73, $33031DE5, $AA0A4C5F, $DD0D7CC9
        dc.l $5005713C, $270241AA, $BE0B1010, $C90C2086
        dc.l $5768B525, $206F85B3, $B966D409, $CE61E49F
        dc.l $5EDEF90E, $29D9C998, $B0D09822, $C7D7A8B4
        dc.l $59B33D17, $2EB40D81, $B7BD5C3B, $C0BA6CAD
        dc.l $EDB88320, $9ABFB3B6, $03B6E20C, $74B1D29A
        dc.l $EAD54739, $9DD277AF, $04DB2615, $73DC1683
        dc.l $E3630B12, $94643B84, $0D6D6A3E, $7A6A5AA8
        dc.l $E40ECF0B, $9309FF9D, $0A00AE27, $7D079EB1
        dc.l $F00F9344, $8708A3D2, $1E01F268, $6906C2FE
        dc.l $F762575D, $806567CB, $196C3671, $6E6B06E7
        dc.l $FED41B76, $89D32BE0, $10DA7A5A, $67DD4ACC
        dc.l $F9B9DF6F, $8EBEEFF9, $17B7BE43, $60B08ED5
        dc.l $D6D6A3E8, $A1D1937E, $38D8C2C4, $4FDFF252
        dc.l $D1BB67F1, $A6BC5767, $3FB506DD, $48B2364B
        dc.l $D80D2BDA, $AF0A1B4C, $36034AF6, $41047A60
        dc.l $DF60EFC3, $A867DF55, $316E8EEF, $4669BE79
        dc.l $CB61B38C, $BC66831A, $256FD2A0, $5268E236
        dc.l $CC0C7795, $BB0B4703, $220216B9, $5505262F
        dc.l $C5BA3BBE, $B2BD0B28, $2BB45A92, $5CB36A04
        dc.l $C2D7FFA7, $B5D0CF31, $2CD99E8B, $5BDEAE1D
        dc.l $9B64C2B0, $EC63F226, $756AA39C, $026D930A
        dc.l $9C0906A9, $EB0E363F, $72076785, $05005713
        dc.l $95BF4A82, $E2B87A14, $7BB12BAE, $0CB61B38
        dc.l $92D28E9B, $E5D5BE0D, $7CDCEFB7, $0BDBDF21
        dc.l $86D3D2D4, $F1D4E242, $68DDB3F8, $1FDA836E
        dc.l $81BE16CD, $F6B9265B, $6FB077E1, $18B74777
        dc.l $88085AE6, $FF0F6A70, $66063BCA, $11010B5C
        dc.l $8F659EFF, $F862AE69, $616BFFD3, $166CCF45
        dc.l $A00AE278, $D70DD2EE, $4E048354, $3903B3C2
        dc.l $A7672661, $D06016F7, $4969474D, $3E6E77DB
        dc.l $AED16A4A, $D9D65ADC, $40DF0B66, $37D83BF0
        dc.l $A9BCAE53, $DEBB9EC5, $47B2CF7F, $30B5FFE9
        dc.l $BDBDF21C, $CABAC28A, $53B39330, $24B4A3A6
        dc.l $BAD03605, $CDD70693, $54DE5729, $23D967BF
        dc.l $B3667A2E, $C4614AB8, $5D681B02, $2A6F2B94
        dc.l $B40BBE37, $C30C8EA1, $5A05DF1B, $2D02EF8D
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
