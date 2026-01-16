; ==============================================================================
; anim_engine.asm - Boot Animation Engine for Cicada-16
; ==============================================================================
; A lightweight animation engine for the boot logo animation.
; Uses BG0 for solid background color and BG1 for logo with scroll animation.
; BG1 uses a 32x64 tilemap (256x512 pixels) to allow slide animations without
; scroll wrapping issues.
; ==============================================================================

; ==============================================================================
; Cartridge Animation ID Addresses (mapped at 0x4000 during boot)
; ==============================================================================
.define CART_ANIM_ENTRANCE  0x4000      ; Entrance animation ID
.define CART_ANIM_BG_COLOR  0x4001      ; Background color ID
.define CART_ANIM_LOGO_CLR  0x4002      ; Logo color ID
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

; ==============================================================================
; run_boot_animation
; Main entry point for the boot animation
; Called from boot main after hardware init and syslib DMA
; ==============================================================================
run_boot_animation:
    ; Read animation configuration from cartridge header
    CALL read_animation_ids

    ; Initialize animation state
    CALL init_animation

    ; Set up colors based on IDs
    CALL init_colors

    ; Initialize entrance animation based on ID
    CALL init_entrance_animation

    CALL apply_scroll

    ; Load graphics data
    CALL init_tiles


    ; Enable PPU with BG0 (background) and BG1 (logo)
    LDI R0, LCDC_PPU_ENABLE
    ORI R0, LCDC_BG0_ENABLE
    ORI R0, LCDC_BG1_ENABLE
    ST.b (LCDC), R0

    ; Enable V-Blank interrupt (and LYC if using scanline effects)
    LDI R0, STAT_VBLK_INT_EN
    ST.b (STAT), R0
    LD.b R0, (ANIM_SCANLINE_EFFECT)
    CMPI R0, 0
    JRZ rba_no_lyc
    LDI R0, INT_VBLANK
    ORI R0, INT_LYC
    JR rba_set_ie
rba_no_lyc:
    LDI R0, INT_VBLANK
rba_set_ie:
    ST.b (IE), R0
    EI

    ; Animation loop
rba_anim_loop:
    HALT                            ; Wait for V-Blank interrupt

    ; V-Blank ISR sets vblank_flag
    LD.b R0, (ANIM_VBLANK_FLAG)
    CMPI R0, 0
    JRZ rba_anim_loop               ; No V-Blank yet, keep waiting

    ; Clear flag
    LDI R0, 0
    ST.b (ANIM_VBLANK_FLAG), R0

    ; === Apply hardware updates (during V-Blank safe period) ===
    CALL apply_scroll

    ; Run animation tick (computes values for next frame)
    CALL animation_tick

    ; Check if animation complete
    LD.b R0, (ANIM_COMPLETE)
    CMPI R0, 0
    JRZ rba_anim_loop

    ; Cleanup
    DI
    RET

; ==============================================================================
; apply_scroll
; Apply x and y scroll variables to BG1 hardware registers
; BG0 stays at scroll (0,0) for static background
; ==============================================================================
apply_scroll:
    ; Apply scroll values to BG1 hardware registers
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
    ; Read entrance animation ID
    LD.b R0, (CART_ANIM_ENTRANCE)
    ST.b (ANIM_ENTRANCE_ID), R0

    ; Read background color ID
    LD.b R0, (CART_ANIM_BG_COLOR)
    ST.b (ANIM_BG_COLOR_ID), R0

    ; Read logo color ID
    LD.b R0, (CART_ANIM_LOGO_CLR)
    ST.b (ANIM_LOGO_COLOR_ID), R0

    ; Read audio ID
    LD.b R0, (CART_ANIM_AUDIO)
    ST.b (ANIM_AUDIO_ID), R0

    RET

; ==============================================================================
; init_animation
; Initialize all HRAM animation state variables to defaults
; ==============================================================================
init_animation:
    ; Clear frame counter
    LDI R0, 0
    ST (ANIM_FRAME_L), R0

    ; Set phase to entry
    ST.b (ANIM_PHASE), R0

    ; Clear completion flag
    ST.b (ANIM_COMPLETE), R0

    ; Clear V-Blank flag
    ST.b (ANIM_VBLANK_FLAG), R0

    ; Initialize scroll to centered position
    LDI R0, LOGO_CENTER_X
    ST (ANIM_SCROLL_X_L), R0
    ST (ANIM_SCROLL_X_TGT_L), R0

    LDI R0, LOGO_CENTER_Y
    ST (ANIM_SCROLL_Y_L), R0
    ST (ANIM_SCROLL_Y_TGT_L), R0

    ; Clear palette phase
    LDI R0, 0
    ST.b (ANIM_PALETTE_PHASE), R0

    ; Clear scanline effect
    ST.b (ANIM_SCANLINE_EFFECT), R0
    ST.b (ANIM_SCANLINE_IDX), R0
    ST.b (ANIM_WAVE_PHASE), R0

    RET

; ==============================================================================
; init_colors
; Initialize palette colors based on animation IDs
; ==============================================================================
init_colors:
    ; Set background color (CRAM index 0)
    LD.b R0, (ANIM_BG_COLOR_ID)
    CALL get_bg_color
    LDI R1, CRAM_START
    ST (R1), R0

    ; Set logo colors (CRAM indices 1-3)
    LD.b R0, (ANIM_LOGO_COLOR_ID)
    CALL get_logo_color

    ; Store main logo color at index 1
    LDI R1, CRAM_START
    ADDI R1, 2                      ; Index 1
    ST (R1), R0

    ; Create lighter shade for index 2 (simple: OR with 0x4210)
    ORI R0, 0x4210
    ADDI R1, 2                      ; Index 2
    ST (R1), R0

    ; Create darker shade for index 3 (simple: AND with 0x39CE)
    LD.b R0, (ANIM_LOGO_COLOR_ID)
    CALL get_logo_color
    ANDI R0, 0x39CE
    ADDI R1, 2                      ; Index 3
    ST (R1), R0

    RET

; ==============================================================================
; init_tiles
; Initialize tiles and tilemaps
; ==============================================================================
init_tiles:
    CALL load_logo_tiles

    LD.b R0, (ANIM_LOGO_SLOT)
    CALL copy_logo_tilemap

    ; Configure tilemap modes and bases
    ; BG_MODE: BG0=32x32 (00), BG1=32x64 (10) = 0x08
    LD.b R0, (ANIM_LOGO_SHAPE)
    ST.b (BG_MODE), R0

    ; BG_TMB: BG0=slot 1 (0x01), BG1=slot 2 (0x20) = 0x21
    LDI R0, 0x21
    ST.b (BG_TMB), R0

    RET

; ==============================================================================
; init_entrance_animation
; Set up entrance animation based on entrance ID
; ==============================================================================
init_entrance_animation:
    LD.b R0, (ANIM_ENTRANCE_ID)

    ; Check for random selection (0xFF)
    CMPI R0, RAINBOW_ID
    JRNZ iea_not_random

    ; Get pseudo-random value from DIV register
    LD.b R0, (DIV0)
    ANDI R0, 0x0F                   ; Limit to 0-15 range

    ; Clamp to valid entrance range
iea_clamp_loop:
    CMPI R0, ENTRANCE_COUNT
    JRC iea_not_random              ; If < ENTRANCE_COUNT, we're good
    SUBI R0, ENTRANCE_COUNT         ; Otherwise subtract and try again
    JR iea_clamp_loop

iea_not_random:
    ; Validate ID is in range
    CMPI R0, ENTRANCE_COUNT
    JRC iea_valid_id
    ; Invalid ID - default to none
    LDI R0, 0

iea_valid_id:
    ; Save the validated entrance ID
    ST.b (ANIM_ENTRANCE_ID), R0

    ; Look up function pointer: table_base + (id * 2)
    SHL R0                          ; R0 = R0 * 2 (word offset)
    LDI R1, entrance_table
    ADD R1, R0                      ; R1 = table entry address
    LD R2, (R1)                     ; R2 = function pointer

    ; Call entrance-specific setup
    CALL (R2)

    RET

; ==============================================================================
; animation_tick
; Called once per frame to update animation state
; ==============================================================================
animation_tick:
    ; Increment frame counter
    LD R0, (ANIM_FRAME_L)
    ADDI R0, 1
    ST (ANIM_FRAME_L), R0

    ; Update rainbow colors if enabled
    CALL update_rainbow_colors

    ; Dispatch based on current phase
    LD.b R0, (ANIM_PHASE)

    CMPI R0, PHASE_ENTRY
    JRZ at_phase_entry
    CMPI R0, PHASE_DISPLAY
    JRZ at_phase_display
    CMPI R0, PHASE_EXIT
    JRZ at_phase_exit

    ; Unknown phase - mark complete
    JR at_mark_complete

at_phase_entry:
    CALL animate_logo_entry
    RET

at_phase_display:
    CALL animate_logo_display
    RET

at_phase_exit:
    CALL animate_logo_exit
    RET

at_mark_complete:
    LDI R0, 1
    ST.b (ANIM_COMPLETE), R0
    RET

; ==============================================================================
; animate_logo_entry
; Dispatches to current entrance animation tick function
; ==============================================================================
animate_logo_entry:
    ; Get entrance ID and look up tick function
    LD.b R0, (ANIM_ENTRANCE_ID)
    SHL R0                          ; Word offset
    LDI R1, entrance_tick_table
    ADD R1, R0
    LD R2, (R1)                     ; R2 = tick function pointer

    ; Call the tick function
    CALL (R2)
    RET

; ==============================================================================
; animate_logo_display
; Handles display phase - logo holds with optional effects
; ==============================================================================
animate_logo_display:
    ; Check if display duration has elapsed
    LD R0, (ANIM_FRAME_L)
    LDI R1, DISPLAY_DURATION
    CMP R0, R1
    JRC ald_still_displaying

    ; Duration elapsed - advance to exit phase
    LDI R0, PHASE_EXIT
    ST.b (ANIM_PHASE), R0

    ; Reset frame counter for exit phase
    LDI R0, 0
    ST (ANIM_FRAME_L), R0

ald_still_displaying:
    RET

; ==============================================================================
; animate_logo_exit
; Handles exit phase - fade out
; ==============================================================================
animate_logo_exit:
    ; Simple fade to black over FADE_STEPS frames
    LD.b R0, (ANIM_PALETTE_PHASE)
    CMPI R0, FADE_STEPS
    JRNC ale_exit_complete

    ; Increment palette phase
    INC R0
    ST.b (ANIM_PALETTE_PHASE), R0

    ; Only fade when crossing a threshold (every 4 frames)
    ; Check if (phase & 0x03) == 0
    ANDI R0, 0x03
    JRNZ ale_no_fade

    ; Fade palette toward black (shift once)
    CALL fade_palette_to_black

ale_no_fade:
    RET

ale_exit_complete:
    ; Mark animation as complete
    LDI R0, 1
    ST.b (ANIM_COMPLETE), R0
    RET

; ==============================================================================
; get_bg_color
; Look up background color from ID
; Input: R0 = color ID
; Output: R0 = RGB555 color value
; Clobbers: R1
; ==============================================================================
get_bg_color:
    ; Check for rainbow (0xFF)
    CMPI R0, RAINBOW_ID
    JRNZ gbc_not_rainbow
    CALL apply_rainbow
    RET

gbc_not_rainbow:
    ; Validate ID is in range
    CMPI R0, BG_COLOR_COUNT
    JRC gbc_valid
    LDI R0, 0                       ; Default to black

gbc_valid:
    SHL R0                          ; Word offset
    LDI R1, bg_color_table
    ADD R1, R0
    LD R0, (R1)
    RET

; ==============================================================================
; get_logo_color
; Look up logo color from ID
; Input: R0 = color ID
; Output: R0 = RGB555 color value
; Clobbers: R1
; ==============================================================================
get_logo_color:
    ; Check for rainbow (0xFF)
    CMPI R0, RAINBOW_ID
    JRNZ glc_not_rainbow
    CALL apply_rainbow
    RET

glc_not_rainbow:
    ; Validate ID is in range
    CMPI R0, LOGO_COLOR_COUNT
    JRC glc_valid
    LDI R0, 0                       ; Default to white (index 0)

glc_valid:
    SHL R0                          ; Word offset
    LDI R1, logo_color_table
    ADD R1, R0
    LD R0, (R1)
    RET

; ==============================================================================
; End of anim_engine.asm
; ==============================================================================
