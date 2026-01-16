.include "./hardware.asm"

.define INTERRUPT_TABLE_ADDR 0x3FE0
.define CART_START_ADDR 0x0080

start:
	DI ; disable interrupts for the boot process

	; initialize hardware registers
	CALL init_hardware

	; set source address of syslib and run syslib dma
	LDI R0, syslib
	CALL dma_syslib

	; check the interrupt mode in the cartridge
	; header and set the system config register
	CALL set_isr_mode

	; TODO: run boot animation and sound
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
	; Disable PPU
	; LCDC enable/disable: 0xF040 bit 7
	RES (LCDC), 7

	; Disable APU
	; APU enable/disable: 0xF096 bit 7
	RES (APU_MIX_CTRL), 7

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

	; clear WRAM0
	CALL clear_wram0

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
	LD R6, R0

	RET

set_isr_mode:
	; read interrupt mode from cartridge header
	; cartridge header start mapped to 0x4000 during boot,
	; interrupt mode flag is bit 7 of byte 0x0028 (mapped
	; to 0x4028) of the cartridge.
	LD.b R0, (0x4028)

	; mask off bit 7 of the value from the cartridge header
	ANDI 0x0080

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
