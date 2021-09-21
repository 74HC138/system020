RAM_BASE        = $10000000
RAM_SIZE        = $00100000
RAM_TOP         = RAM_BASE + RAM_SIZE
RAM_PAGES       = RAM_SIZE / 1024

MFP_BASE        = $40000000

IDE0_BASE	= $20000000
IDE1_BASE	= $30000000
;-----------------------------------------------------------------------------
;MFP registers
MFP_GPDR        = MFP_BASE + $00
MFP_AER         = MFP_BASE + $01
MFP_DDR         = MFP_BASE + $02
MFP_IERA        = MFP_BASE + $03
MFP_IERB        = MFP_BASE + $04
MFP_IPRA        = MFP_BASE + $05
MFP_IPRB        = MFP_BASE + $06
MFP_ISRA        = MFP_BASE + $07
MFP_ISRB        = MFP_BASE + $08
MFP_IMRA        = MFP_BASE + $09
MFP_IMRB        = MFP_BASE + $0A
MFP_VR          = MFP_BASE + $0B
MFP_TACR        = MFP_BASE + $0C
MFP_TBCR        = MFP_BASE + $0D
MFP_TCDCR       = MFP_BASE + $0E
MFP_TADR        = MFP_BASE + $0F
MFP_TBDR        = MFP_BASE + $10
MFP_TCDR        = MFP_BASE + $11
MFP_TDDR        = MFP_BASE + $12
MFP_SCR         = MFP_BASE + $13
MFP_UCR         = MFP_BASE + $14
MFP_RSR         = MFP_BASE + $15
MFP_TSR         = MFP_BASE + $16
MFP_UDR         = MFP_BASE + $17
;-----------------------------------------------------------------------------
;IDE registers
IDE_D		= IDE0_BASE + $00
IDE_E		= IDE0_BASE + $02 ;read only
IDE_SC		= IDE0_BASE + $04
IDE_SN		= IDE0_BASE + $06
IDE_CL		= IDE0_BASE + $08
IDE_CH		= IDE0_BASE + $0A
IDE_SDH		= IDE0_BASE + $0C
IDE_STAT	= IDE0_BASE + $0E ;read only
IDE_WP		= IDE0_BASE + $02 ;write only
IDE_CMD		= IDE0_BASE + $0E ;write only

IDE_ASTAT	= IDE1_BASE + $0C ;read only
IDE_DIGO	= IDE1_BASE + $0C ;write only
IDE_DRVA	= IDE1_BASE + $0E ;read only

IDE_LBAL	= IDE0_BASE + $06
IDE_LBAM	= IDE0_BASE + $08
IDE_LBAH	= IDE0_BASE + $0A