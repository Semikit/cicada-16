.include "./hardware.asm"

.define INTERRUPT_TABLE_ADDR 0x3FE0
.define CART_START_ADDR 0x0080

start:
	DI ; disable interrupts for the boot process

	; clear WRAM0 (0xB000-0xCFFF) with a DMA mode 6 fill.
	; This must run inline, before any CALL: the boot stack lives at the
	; top of WRAM0 (R7 resets to 0xD000 and grows down), so a CALL/RET
	; based clear would zero its own return addresses. The DMA controller
	; halts the CPU until the fill completes, so nothing else touches the
	; stack while it runs.
	LDI R0, 0x0000          ; fill pattern
	ST (DMA_SRC_L), R0
	LDI R0, WRAM0_START     ; destination 0xB000
	ST (DMA_DST_L), R0
	LDI R0, 0x1000          ; 4096 16-bit words = 8 KiB
	ST (DMA_LEN_L), R0
	LDI R0, 0x31            ; DMA_CTL: mode 6 (bits 5-3), start (bit 0)
	ST.b (DMA_CTL), R0

	; initialize hardware registers
	CALL init_hardware

	; set source address of syslib and run syslib dma
	LDI R0, syslib
	CALL dma_syslib

	; check the interrupt mode in the cartridge
	; header and set the system config register
	CALL set_isr_mode

	; run the boot logo animation (sound: TODO)
	CALL run_boot_animation

	; clear cpu registers again
	CALL clear_regs

	; init stack pointer
	LDI R7, 0xD000

	; boot handoff
handoff:
	LDI R0, 1
	ST.b (BOOT_CTRL), R0
	JMP CART_START_ADDR

.include "./util.asm"
.include "./anim_engine/anim_engine.asm"

init_hardware:
	; PPU: disable and reset the registers the boot ROM uses to their
	; documented power-on defaults (0)
	LDI R0, 0
	ST.b (LCDC), R0
	ST.b (STAT), R0
	ST (SCY0_L), R0
	ST (SCX0_L), R0
	ST (SCY1_L), R0
	ST (SCX1_L), R0
	ST.b (LYC), R0
	ST.b (BG_MODE), R0
	ST.b (BG_TMB), R0

	; APU: master and channel enables off, all channels keyed off, DSP off
	ST.b (APU_MIX_CTRL), R0
	ST.b (APU_MIX_VOL), R0
	ST.b (APU_CH0_CTRL), R0
	ST.b (APU_CH1_CTRL), R0
	ST.b (APU_CH2_CTRL), R0
	ST.b (APU_CH3_CTRL), R0
	ST.b (APU_DSP_CTRL), R0

	; stop timers
	; TAC0 (timer 0 control) enable/disable: 0xF009 bit 5
	; TAC1 (timer 1 control) enable/disable: 0xF025 bit 5
	RES (TAC0), 5
	RES (TAC1), 5

	; disable serial communication
	; SC (serial control) enable/disable: 0xF001 bit 0
	RES (SC), 0

	; clear CPU registers
	CALL clear_regs

	; init switchable banks to 0
	; note: VRAM_BANK is locked to 0 during boot
	ST.b (MPR_BANK), R0
	ST.b (RAM_BANK), R0
	ST.b (WRAM_BANK), R0

	; init 0xFE00-0xFE01 to 0x0000 for the next clearing functions
	ST (0xFE00), R0

	; clear VRAM
	CALL clear_vram

	; note: WRAM0 is cleared inline at 'start' before any CALL, because
	; the boot stack lives at the top of WRAM0 and a CALL-based clear
	; would wipe its own return addresses.

	; clear HRAM
	CALL clear_hram

	; clear OAM
	CALL clear_oam

	; clear CRAM
	CALL clear_cram

	RET

clear_regs:
	; init general purpose registers to 0
	LDI R0, 0x0
	LD R1, R0
	LD R2, R0
	LD R3, R0
	LD R4, R0
	LD R5, R0
	LD R6, R0

	RET

set_isr_mode:
	; read interrupt mode from cartridge header
	; cartridge header start mapped to 0x4000 during boot,
	; interrupt mode flag is bit 7 of byte 0x0028 (mapped
	; to 0x4028) of the cartridge.
	LD.b R0, (0x4028)

	; isolate bit 7 (interrupt mode flag) of the header byte
	ANDI 0x0080

	; SYS_CFG bit 0 (IVT_MODE) selects the interrupt mode:
	; 0 = standard (vectors at 0x0060), 1 = enhanced (vectors at 0xBFE0)
	; standard mode: R0 is already 0, write it as-is
	JRZ sim_write

	; enhanced mode: set IVT_MODE
	LDI R0, 0x01
	ST.b (SYS_CFG), R0

	; copy the 26-byte interrupt vector table template from the cartridge
	; header (0x0060, mapped at 0x4060 during boot) to WRAM at 0xBFE0 with a
	; normal (mode 0) DMA, so the game starts with its ROM vectors in place
	LDI R0, 0x4060
	ST (DMA_SRC_L), R0
	LDI R0, 0xBFE0
	ST (DMA_DST_L), R0
	LDI R0, 26
	ST (DMA_LEN_L), R0
	LDI R0, 0x01            ; DMA_CTL: mode 0, incrementing, start
	ST.b (DMA_CTL), R0
	RET

sim_write:
	; store the value to the system config register
	ST.b (SYS_CFG), R0

	RET

.align 2
syslib:
.include "./syslib.asm"

default_handler:
	RETI

.org INTERRUPT_TABLE_ADDR
.interrupt_table
	.word default_handler
	.word default_handler
	.word default_handler
	.word default_handler
	.word default_handler
	.word vblank_isr       ; animation engine v-blank isr
	.word default_handler  ; h-blank
	.word lyc_isr          ; lyc
	.word default_handler
	.word default_handler
	.word default_handler
	.word default_handler
	.word default_handler
.table_end
