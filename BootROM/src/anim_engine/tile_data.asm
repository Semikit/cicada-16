; ==============================================================================
; tile_data.asm - Logo graphics loading
; ==============================================================================

; ==============================================================================
; load_logo_tiles
; Load logo tile graphics to VRAM slot 0 via DMA.
; The tile data is 96 bytes (3 tiles: blank, half block, diagonal); the DMA
; copies a full 2 KiB slot, so the bytes that follow logo_tiles in ROM land in
; tiles 3-63. Nothing references those tiles.
; ==============================================================================
load_logo_tiles:
    LDI R0, logo_tiles
    LDI R1, 0                       ; destination VRAM slot 0
    LDI R2, 1                       ; one slot
    CALL dma_vram
    RET

; ==============================================================================
; copy_logo_tilemap
; Copies the 32x32 logo tilemap into VRAM slot LOGO_SLOT (3). Slot 2, the
; other half of the BG1 map, is left as the VRAM clear produced it (all
; tile 0, i.e. transparent) unless build_mirror_tilemap fills it.
;
; Clobbers: R0, R1, R2
; ==============================================================================
copy_logo_tilemap:
    LDI R0, logo_tilemap
    LDI R1, LOGO_SLOT
    LDI R2, 1
    CALL dma_vram
    RET

; ==============================================================================
; build_mirror_tilemap
; Writes a vertically mirrored copy of the logo tilemap into VRAM slot 2:
; source row r goes to destination row 31-r with the V-flip bit toggled.
; Used by the spin entrance for the "back side" of the logo. Only valid with
; the TALL shape (slot 2 = map rows 0-31).
;
; Clobbers: R0, R1, R2, R3, R4
; ==============================================================================
build_mirror_tilemap:
    LDI R1, logo_tilemap            ; source entry pointer
    LDI R2, 0xA7C0                  ; LOGO_MIRROR_SLOT_ADDR + 31 * 64 (last row)
    LDI R4, 32                      ; rows
bmt_row:
    LDI R3, 32                      ; entries per row
bmt_entry:
    LD R0, (R1)
    XORI R0, 0x4000                 ; toggle V-flip
    ST (R2), R0
    ADDI R1, 2
    ADDI R2, 2
    DEC R3
    JRNZ bmt_entry
    SUBI R2, 128                    ; back up two rows (64 written + 64 up)
    DEC R4
    JRNZ bmt_row
    RET

.align 2
logo_tiles:
.incbin "./anim_engine/c-16_logo/tiles.bin"

.align 2
logo_tilemap:
.incbin "./anim_engine/c-16_logo/tilemap_0.bin"
