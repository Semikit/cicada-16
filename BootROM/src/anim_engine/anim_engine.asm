; ==============================================================================
; anim_engine.asm - Boot Animation Engine for Cicada-16
; ==============================================================================
; A lightweight animation engine for the boot logo animation.
; BG0 (slot 1, all tile 0) supplies the solid background colour; BG1 (slots
; 2-3) holds the logo and is moved with the 16-bit SCX1/SCY1 scroll registers.
; BG1 is a 32x64 map for vertical moves and a 64x32 map for horizontal moves,
; so the logo can start fully off-screen without wrapping (see mem_layout.asm
; for the placement arithmetic). Per-scanline effects rewrite one BG1 scroll
; register from a table in the LYC interrupt (anim_isr.asm).
; ==============================================================================

; ==============================================================================
; Cartridge Animation ID Addresses (mapped at 0x4000 during boot)
; ==============================================================================
.define CART_ANIM_ENTRANCE  0x4000      ; Entrance animation ID
.define CART_ANIM_PALETTE   0x4001      ; Palette ID (combined bg/logo colors)
.define CART_ANIM_RESERVED  0x4002      ; Reserved (must be 0x00)
.define CART_ANIM_AUDIO     0x4003      ; Audio ID (reserved)

.include "./anim_engine/mem_layout.asm"
.include "./anim_engine/color_table.asm"
.include "./anim_engine/tile_data.asm"

; ==============================================================================
; Code Section - Animation Engine Functions
; ==============================================================================

.include "./anim_engine/entrance_anims.asm"
.include "./anim_engine/anim_isr.asm"
.include "./anim_engine/anim_util.asm"
.include "./anim_engine/boot_audio.asm"

; ==============================================================================
; run_boot_animation
; Main entry point for the boot animation
; Called from boot main after hardware init and syslib DMA
; ==============================================================================
run_boot_animation:
    CALL read_animation_ids
    CALL init_animation
    CALL init_colors
    CALL init_entrance_animation    ; sets shape, start scroll, scanline effect
    CALL init_tiles                 ; needs the shape
    CALL apply_scroll
    CALL audio_init

    ; Enable PPU with BG0 (background) and BG1 (logo)
    LDI R0, LCDC_PPU_ENABLE
    ORI R0, LCDC_BG0_ENABLE
    ORI R0, LCDC_BG1_ENABLE
    ST.b (LCDC), R0

    ; STAT: V-Blank always, LYC while a scanline effect is active
    CALL update_lyc_enable
    LDI R0, INT_VBLANK
    ORI R0, INT_LYC
    ST.b (IE), R0
    EI

rba_anim_loop:
    HALT                            ; wait for an interrupt (V-Blank or LYC)
    NOP                             ; the instruction after HALT may run before
                                    ; the waking interrupt is serviced, so keep
                                    ; the flag read after the ISR has run

    LD.b R0, (ANIM_VBLANK_FLAG)
    CMPI R0, 0
    JRZ rba_anim_loop               ; not V-Blank yet

    LDI R0, 0
    ST.b (ANIM_VBLANK_FLAG), R0

    ; apply this frame's scroll, then compute the next frame
    CALL apply_scroll
    CALL animation_tick
    CALL update_lyc_enable

    LD.b R0, (ANIM_COMPLETE)
    CMPI R0, 0
    JRZ rba_anim_loop

    DI
    CALL audio_shutdown
    RET

; ==============================================================================
; apply_scroll
; Write the BG1 scroll variables to the hardware registers (BG0 stays at 0,0)
; ==============================================================================
apply_scroll:
    LD R0, (ANIM_SCROLL_X_L)
    ST (SCX1_L), R0
    LD R0, (ANIM_SCROLL_Y_L)
    ST (SCY1_L), R0
    RET

; ==============================================================================
; read_animation_ids
; Read animation IDs from cartridge header
; ==============================================================================
read_animation_ids:
    LD.b R0, (CART_ANIM_ENTRANCE)
    ST.b (ANIM_ENTRANCE_ID), R0
    LD.b R0, (CART_ANIM_PALETTE)
    ST.b (ANIM_PALETTE_ID), R0
    LD.b R0, (CART_ANIM_AUDIO)
    ST.b (ANIM_AUDIO_ID), R0
    RET

; ==============================================================================
; init_animation
; Initialize all HRAM animation state variables to defaults
; ==============================================================================
init_animation:
    LDI R0, 0
    ST (ANIM_FRAME_L), R0
    ST.b (ANIM_PHASE), R0           ; PHASE_ENTRY
    ST.b (ANIM_COMPLETE), R0
    ST.b (ANIM_VBLANK_FLAG), R0

    ST.b (ANIM_RAINBOW_MODE), R0
    ST.b (ANIM_RAINBOW_IDX), R0
    ST.b (ANIM_RAINBOW_TIMER), R0
    ST.b (ANIM_PALETTE_PHASE), R0
    ST.b (ANIM_FADE_MODE), R0

    ST.b (ANIM_SCANLINE_EFFECT), R0 ; SCANLINE_NONE
    ST.b (ANIM_WAVE_PHASE), R0
    ST (ANIM_EFFECT_PARAM_L), R0
    ST.b (ANIM_EFFECT_TIMER), R0
    ST.b (ANIM_BOUNCE_COUNT), R0
    ST.b (ANIM_BOUNCE_VEL), R0
    ST.b (ANIM_SPIN_ANGLE), R0
    ST.b (ANIM_SPIN_STEP), R0
    ST.b (ANIM_SPIN_TURNS), R0

    LDI R0, SCY1_L
    ST (ANIM_SCANLINE_REG), R0
    LDI R0, LOGO_CENTER_Y
    ST (ANIM_SCANLINE_BASE), R0

    ; centred logo on the tall map (entrances override as needed)
    LDI R0, LOGO_SHAPE_TALL
    ST.b (ANIM_LOGO_SHAPE), R0
    LDI R0, LOGO_CENTER_X
    ST (ANIM_SCROLL_X_L), R0
    ST (ANIM_SCROLL_X_TGT_L), R0
    LDI R0, LOGO_CENTER_Y
    ST (ANIM_SCROLL_Y_L), R0
    ST (ANIM_SCROLL_Y_TGT_L), R0

    RET

; ==============================================================================
; init_colors
; Resolve the palette ID to one of the 16 curated palettes, remember its ROM
; address in ANIM_PALETTE_PTR, and DMA it into CRAM sub-palette 0.
; Rainbow IDs use palette 0 (dark) or 1 (light) and turn rainbow mode on.
; ==============================================================================
init_colors:
    LD.b R0, (ANIM_PALETTE_ID)

    CMPI R0, RAINBOW_DARK_ID
    JRNZ ic_check_rainbow_light
    LDI R0, 0                       ; Classic as base
    LDI R1, 1
    ST.b (ANIM_RAINBOW_MODE), R1
    JR ic_copy_palette

ic_check_rainbow_light:
    CMPI R0, RAINBOW_LIGHT_ID
    JRNZ ic_not_rainbow
    LDI R0, 1                       ; Inverted as base
    LDI R1, 1
    ST.b (ANIM_RAINBOW_MODE), R1
    JR ic_copy_palette

ic_not_rainbow:
    CMPI R0, PALETTE_COUNT
    JRC ic_valid_id
    LDI R0, 0                       ; out of range: Classic

ic_valid_id:
    LDI R1, 0
    ST.b (ANIM_RAINBOW_MODE), R1

ic_copy_palette:
    ; palette_table is a table of 16 pointers: fetch entry R0
    SHL R0                          ; word offset
    LDI R1, palette_table
    ADD R0, R1
    LD R0, (R0)                     ; R0 = address of the 32-byte palette
    ST (ANIM_PALETTE_PTR), R0

    ; DMA 16 colours into CRAM sub-palette 0
    LDI R1, 0                       ; destination palette index 0
    LDI R2, 16                      ; 16 entries
    LDI R3, 0x1D                    ; mode 3 (CRAM), VRAM_SAFE, start
    ST (DMA_SRC_L), R0
    ST (DMA_DST_L), R1
    ST (DMA_LEN_L), R2
    ST.b (DMA_CTL), R3
    RET

; ==============================================================================
; init_tiles
; Load the logo tiles and tilemap and configure BG0/BG1
; ==============================================================================
init_tiles:
    CALL load_logo_tiles
    CALL copy_logo_tilemap

    ; BG_MODE: BG0 = 32x32 (bits 1-0 = 00), BG1 = shape chosen by the entrance
    LD.b R0, (ANIM_LOGO_SHAPE)
    ST.b (BG_MODE), R0

    ; BG_TMB: BG0 = slot 1 (bits 3-0), BG1 = slot 2 (bits 7-4)
    LDI R0, 0x21
    ST.b (BG_TMB), R0
    RET

; ==============================================================================
; init_entrance_animation
; Validate the entrance ID (resolving 0xFF to a random one) and call its init
; ==============================================================================
init_entrance_animation:
    LD.b R0, (ANIM_ENTRANCE_ID)

    CMPI R0, ENTRANCE_RANDOM_ID
    JRNZ iea_not_random

    LD.b R0, (DIV0)                 ; pseudo-random seed
    ANDI R0, 0x0F
iea_clamp_loop:
    CMPI R0, ENTRANCE_COUNT
    JRC iea_not_random
    SUBI R0, ENTRANCE_COUNT
    JR iea_clamp_loop

iea_not_random:
    CMPI R0, ENTRANCE_COUNT
    JRC iea_valid_id
    LDI R0, 0                       ; invalid: none

iea_valid_id:
    ST.b (ANIM_ENTRANCE_ID), R0

    SHL R0
    LDI R1, entrance_table
    ADD R1, R0
    LD R2, (R1)
    CALL (R2)
    RET

; ==============================================================================
; animation_tick
; Called once per frame (during V-Blank) to update animation state
; ==============================================================================
animation_tick:
    LD R0, (ANIM_FRAME_L)
    ADDI R0, 1
    ST (ANIM_FRAME_L), R0

    CALL update_rainbow_colors

    LD.b R0, (ANIM_PHASE)
    CMPI R0, PHASE_ENTRY
    JRZ at_phase_entry
    CMPI R0, PHASE_DISPLAY
    JRZ at_phase_display
    CMPI R0, PHASE_EXIT
    JRZ at_phase_exit
    JR at_mark_complete             ; unknown phase

at_phase_entry:
    CALL animate_logo_entry
    JR at_audio

at_phase_display:
    CALL animate_logo_display
    JR at_audio

at_phase_exit:
    CALL animate_logo_exit

at_audio:
    CALL audio_tick
    RET

at_mark_complete:
    LDI R0, 1
    ST.b (ANIM_COMPLETE), R0
    RET

; ==============================================================================
; animate_logo_entry
; Dispatch to the current entrance's tick function
; ==============================================================================
animate_logo_entry:
    LD.b R0, (ANIM_ENTRANCE_ID)
    SHL R0
    LDI R1, entrance_tick_table
    ADD R1, R0
    LD R2, (R1)
    CALL (R2)
    RET

; ==============================================================================
; animate_logo_display
; Hold the logo for DISPLAY_DURATION frames, then start the exit phase
; ==============================================================================
animate_logo_display:
    LD R0, (ANIM_FRAME_L)
    LDI R1, DISPLAY_DURATION
    CMP R0, R1
    JRC ald_still_displaying

    LDI R0, PHASE_EXIT
    ST.b (ANIM_PHASE), R0
    LDI R0, 0
    ST (ANIM_FRAME_L), R0
    ST.b (ANIM_PALETTE_PHASE), R0

ald_still_displaying:
    RET

; ==============================================================================
; animate_logo_exit
; Fade sub-palette 0 to black over FADE_STEPS frames (one halving every 4)
; ==============================================================================
animate_logo_exit:
    LD.b R0, (ANIM_PALETTE_PHASE)
    CMPI R0, FADE_STEPS
    JRNC ale_exit_complete

    INC R0
    ST.b (ANIM_PALETTE_PHASE), R0

    ANDI R0, 0x03
    JRNZ ale_no_fade
    CALL fade_palette_to_black

ale_no_fade:
    RET

ale_exit_complete:
    LDI R0, 1
    ST.b (ANIM_COMPLETE), R0
    RET

; ==============================================================================
; End of anim_engine.asm
; ==============================================================================
