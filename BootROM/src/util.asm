; ===========================
; DMA mode 1 (syslib copy) helper function
;
; Copies syslib data using DMA mode 1
; ===========================

dma_syslib:
	; set dma source
	ST (DMA_SRC_L), R0
	
	; set dma mode to mode 1 and start transfer
	; dma mode = 0xF010 bits 3-5
	; dma start = 0xF010 bit 0
	; 0x9 = 0b00001001
	LDI R0, 0x9
	ST.b (DMA_CTL), R0

	RET

; ===========================
; DMA mode 6 helper function
; 
; input:
; R0 - DMA_SRC, dma fill pattern
; R1 - DMA_DST, dma destination starting address
; R2 - DMA_LEN, number of 16-bit words to write
;
; clobbers:
; R0
; ===========================

dma_mode_6:
	; set dma fill pattern
	ST (DMA_SRC_L), R0

	; set dma destination
	ST (DMA_DST_L), R1

	; set dma length
	ST (DMA_LEN_L), R2

	; set dma mode to mode 6 and start transfer
	; dma mode = 0xF010 bits 3-5
	; dma start = 0xF010 bit 0
	; 0x31 = 0b00110001
	LDI R0, 0x31
	ST.b (DMA_CTL), R0

	RET

; ===========================
; DMA mode 3 helper function
; 
; input:
; R0 - DMA_SRC, palette data starting source address
; R1 - DMA_DST, starting destination palette slot
; R2 - DMA_LEN, number of palette entries to copy
;
; clobbers:
; R0
; ===========================

dma_cram:
	; set dma source
	ST (DMA_SRC_L), R0

	; set dma destination
	ST (DMA_DST_L), R1

	; set dma length
	ST (DMA_LEN_L), R2

	; set dma mode to mode 3 and start transfer
	; dma mode = 0xF010 bits 3-5
	; dma start = 0xF010 bit 0
	; 0x19 = 0b00011001
	LDI R0, 0x19
	ST.b (DMA_CTL), R0

	RET

; ===========================
; DMA mode 2 helper function
; 
; input:
; R0 - DMA_SRC, tile/tilemap data starting address
; R1 - DMA_DST, starting destination VRAM slot
; R2 - DMA_LEN, number of VRAM slots to copy
;
; clobbers:
; R0
; ===========================

dma_vram:
	; set dma source
	ST (DMA_SRC_L), R0

	; set dma destination
	ST (DMA_DST_L), R1

	; set dma length
	ST (DMA_LEN_L), R2

	; set dma mode to mode 2 and start transfer
	; dma mode = 0xF010 bits 3-5
	; dma start = 0xF010 bit 0
	; 0x11 = 0b00010001
	LDI R0, 0x11
	ST.b (DMA_CTL), R0

	RET

; ===========================
; Clear VRAM
;
; Clears the currently selected VRAM bank using DMA mode 6.
; Assumes that 0xFE00-0xFE01 has been set to 0x0000
;
; clobbers:
; R0, R1, R2
; ===========================

clear_vram:
	; set dma mode 6 values
	; DMA_SRC: 0xFE00
	; DMA_DEST: 0x9000 (VRAM_START)
	; DMA_LEN: 0x1000 (8KiB, 4096 16-bit words)
	LDI R0, 0x0000
	LDI R1, VRAM_START
	LDI R2, 0x1000

	CALL dma_mode_6

	RET

; ===========================
; Clear WRAM0
;
; Clears the currently selected WRAM bank using DMA mode 6.
; Assumes that 0xFE00-0xFE01 has been set to 0x0000
;
; clobbers:
; R0, R1, R2
; ===========================

clear_wram0:
	; set dma mode 6 values
	; DMA_SRC: 0xFE00
	; DMA_DEST: 0xB000 (WRAM0_START)
	; DMA_LEN: 0x1000 (8KiB, 4096 16-bit words)
	LDI R0, 0x0000
	LDI R1, WRAM0_START
	LDI R2, 0x1000

	CALL dma_mode_6

	RET

; ===========================
; Clear HRAM
;
; Clears HRAM using DMA mode 6.
; Assumes that 0xFE00-0xFE01 has been set to 0x0000
;
; clobbers:
; R0, R1, R2
; ===========================

clear_hram:
	; set dma mode 6 values
	; DMA_SRC: 0x0000
	; DMA_DEST: 0xFE00
	; DMA_LEN: 0x1000 (4096 16-bit words)
	LDI R0, 0x0000
	LDI R1, HRAM_START
	LDI R2, 0x1000

	CALL dma_mode_6

	RET

; ===========================
; Clear OAM
;
; Clears OAM using DMA mode 6.
; Assumes that 0xFE00-0xFE01 has been set to 0x0000
;
; clobbers:
; R0, R1, R2
; ===========================

clear_oam:
	; set dma mode 6 values
	; DMA_SRC: 0xFE00
	; DMA_DEST: 0xF400 (OAM_START)
	; DMA_LEN: 0x0100 (256 16-bit words)
	LDI R0, 0x0000
	LDI R1, OAM_START
	LDI R2, 0x0100

	CALL dma_mode_6

	RET

; ===========================
; Clear CRAM
;
; Clears CRAM using DMA mode 6.
; Assumes that 0xFE00-0xFE01 has been set to 0x0000
;
; clobbers:
; R0, R1, R2
; ===========================

clear_cram:
	; set dma mode 6 values
	; DMA_SRC: 0xFE00
	; DMA_DEST: 0xF200 (CRAM_START)
	; DMA_LEN: 0x0100 (256 16-bit words)
	LDI R0, 0x0000
	LDI R1, CRAM_START
	LDI R2, 0x0100

	CALL dma_mode_6

	RET
