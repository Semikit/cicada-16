
; ==============================================================================
; load_logo_palette
; Load logo palette to CRAM via DMA
; ==============================================================================
load_logo_palette:
    ; set DMA src address
    LDI R0, logo_palette

    ; set destination palette
    LDI R1, 0

    ; set number of palette entries to copy (16 entries)
    LDI R2, 0x10

    CALL dma_cram

    RET

; ==============================================================================
; load_logo_tiles
; Load logo tile graphics to VRAM via DMA
; ==============================================================================
load_logo_tiles:
    ; set DMA src address
    LDI R0, logo_tiles

    ; set destination VRAM slot
    LDI R1, 0

    ; set number of VRAM slots to copy
    LDI R2, 1

    CALL dma_vram

    RET

; ==============================================================================
; build_bg0_tilemap
; Fill BG0 tilemap (slot 1) with solid color tile for background
; Uses DMA Fill Mode (Mode 6) to fill with tile 0 (solid tile)
; ==============================================================================
build_bg0_tilemap:
    LDI R0, 0x0000

    LDI R1, 0x9800

    LDI R2, 1024

    CALL dma_mode_6 ; from boot/util.asm

    RET

; ==============================================================================
; copy_logo_tilemap
; Copies the 32x32 logo tilemap into either slot 2 or slot 3 of VRAM.
; The other slot (either 2 or 3, whichever one the logo is not copied to) should
; be filled with solid transparent tiles.
;
; Input:
; R0 = vram slot number to copy to
;
; Clobbers:
; R0, R1, R2
; ==============================================================================
copy_logo_tilemap:
    ; move slot selection into R1
    LD R1, R0

    ; set DMA source address
    LDI R0, logo_tilemap

    ; set number of slots to copy
    LDI R2, 1

    CALL dma_vram ; from boot/util.asm

    RET

.align 2
logo_palette:
.incbin "./anim_engine/c-16_logo/palette.bin"

.align 2
logo_tiles:
.incbin "./anim_engine/c-16_logo/tiles.bin"

.align 2
logo_tilemap:
.incbin "./anim_engine/untitled_tilemap.bin"
