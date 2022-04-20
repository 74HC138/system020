DebugInit:
		andi.b #$fb, MFP_AER
		ori.b #$04, MFP_IMRB
		ori.b #$04, MFP_IERB
		rts

DebugerEnter:
		move.l 

		pea.l (.text0, PC), (-A7)
		bsr SerialWrite
		addq.l #4, A7
		move.l ($02, A7), -(A7)
		bsr SerialWriteHex32

	.text0:
		.db "-------------------\nDEBUGER\nreturn address: 0x", $00
