; ==============================================================================
; entrance_anims.asm - Boot Animation entrance animation tables and functions
; ==============================================================================

.section name="anim_tables"
; ------------------------------------------------------------------------------
; Entrance animation function pointer table
; ------------------------------------------------------------------------------
entrance_table:
    .word entrance_none             ; 0x00 - No animation
    .word entrance_slide_down       ; 0x01 - Slide from top
    .word entrance_slide_up         ; 0x02 - Slide from bottom
    .word entrance_slide_left       ; 0x03 - Slide from right
    .word entrance_slide_right      ; 0x04 - Slide from left
    .word entrance_fade_in          ; 0x05 - Fade from black
    .word entrance_fade_white       ; 0x06 - Fade from white
    .word entrance_wave_horz        ; 0x07 - Horizontal wave
    .word entrance_wave_vert        ; 0x08 - Vertical wave
    .word entrance_none             ; 0x09 - Zoom in (TODO: implement)
    .word entrance_drop_bounce      ; 0x0A - Drop and bounce
    .word entrance_none             ; 0x0B - Spin in (TODO: implement)

; ------------------------------------------------------------------------------
; Entrance animation tick function pointer table
; Vertical slides (up/down) use unified tick - 32x64 tilemap has 512px height
; Horizontal slides (left/right) - X-axis still 256px, slide_right needs wrap
; ------------------------------------------------------------------------------
entrance_tick_table:
    .word entrance_none_tick        ; 0x00
    .word entrance_slide_tick       ; 0x01 - slide_down (Y: 96→176)
    .word entrance_slide_tick       ; 0x02 - slide_up (Y: 256→176)
    .word entrance_slide_tick       ; 0x03 - slide_left (X: 80→0)
    .word entrance_slide_tick       ; 0x04 - slide_right (X: 176→0, wrap)
    .word entrance_fade_tick        ; 0x05
    .word entrance_fade_tick        ; 0x06
    .word entrance_wave_tick        ; 0x07
    .word entrance_wave_tick        ; 0x08
    .word entrance_none_tick        ; 0x09
    .word entrance_bounce_tick      ; 0x0A
    .word entrance_none_tick        ; 0x0B

.section_end

; ==============================================================================
; Entrance Animation: None (Instant)
; ==============================================================================
entrance_none:
    ; Position logo centered immediately
    LDI R0, LOGO_CENTER_X
    ST (ANIM_SCROLL_X_L), R0
    LDI R0, LOGO_CENTER_Y
    ST (ANIM_SCROLL_Y_L), R0

    ; Skip directly to display phase
    LDI R0, PHASE_DISPLAY
    ST.b (ANIM_PHASE), R0

    ; Reset frame counter for display phase
    LDI R0, 0
    ST (ANIM_FRAME_L), R0

    LDI R0, LOGO_SLOT_A
    ST.b (ANIM_LOGO_SLOT), R0

    LDI R0, LOGO_SHAPE_TALL
    ST.b (ANIM_LOGO_SHAPE), R0

    RET

entrance_none_tick:
    ; Nothing to do - should never be called
    RET

; ==============================================================================
; Entrance Animation: Slide Down (from top)
; With 32x64 tilemap, LOGO_CENTER_Y = 176
; Start 80 pixels above center (Y = 96), animate to center (Y = 176)
; ==============================================================================
entrance_slide_down:
    ; Start at Y = 96 (logo 80 pixels above center)
    LDI R0, 392
    ST (ANIM_SCROLL_Y_L), R0
    LDI R0, LOGO_CENTER_X
    ST (ANIM_SCROLL_X_L), R0

    ; Set target Y (centered at 176)
    LDI R0, 259
    ST (ANIM_SCROLL_Y_TGT_L), R0
    LDI R0, LOGO_CENTER_X
    ST (ANIM_SCROLL_X_TGT_L), R0

    LDI R0, LOGO_SLOT_B
    ST.b (ANIM_LOGO_SLOT), R0

    LDI R0, LOGO_SHAPE_TALL
    ST.b (ANIM_LOGO_SHAPE), R0

    RET

; ==============================================================================
; Entrance Animation: Slide Up (from bottom)
; With 32x64 tilemap, LOGO_CENTER_Y = 176
; Start 80 pixels below center (Y = 256), animate to center (Y = 176)
; ==============================================================================
entrance_slide_up:
    ; Start at Y = 256 (logo 80 pixels below center)
    LDI R0, 120
    ST (ANIM_SCROLL_Y_L), R0
    LDI R0, LOGO_CENTER_X
    ST (ANIM_SCROLL_X_L), R0

    ; Set target Y (centered at 176)
    LDI R0, 253
    ST (ANIM_SCROLL_Y_TGT_L), R0
    LDI R0, LOGO_CENTER_X
    ST (ANIM_SCROLL_X_TGT_L), R0

    LDI R0, LOGO_SLOT_B
    ST.b (ANIM_LOGO_SLOT), R0

    LDI R0, LOGO_SHAPE_TALL
    ST.b (ANIM_LOGO_SHAPE), R0

    RET

; ==============================================================================
; Entrance Animation: Slide Left (from right)
; X tilemap is still 256 pixels, so we use positive offset
; Start 80 pixels right of center (X = 80), animate to center (X = 0)
; ==============================================================================
entrance_slide_left:
    LDI R0, LOGO_CENTER_Y
    ST (ANIM_SCROLL_Y_L), R0
    LDI R0, 80                      ; 80 pixels right of center
    ST (ANIM_SCROLL_X_L), R0

    ; Set targets
    LDI R0, LOGO_CENTER_X
    ST (ANIM_SCROLL_X_TGT_L), R0
    LDI R0, LOGO_CENTER_Y
    ST (ANIM_SCROLL_Y_TGT_L), R0

    LDI R0, LOGO_SLOT_A
    ST.b (ANIM_LOGO_SLOT), R0

    LDI R0, LOGO_SHAPE_WIDE
    ST.b (ANIM_LOGO_SHAPE), R0

    RET

; ==============================================================================
; Entrance Animation: Slide Right (from left)
; X tilemap is 256 pixels, use wrapped negative value
; Start at X = 176 (equivalent to -80), animate to center (X = 0)
; ==============================================================================
entrance_slide_right:
    LDI R0, LOGO_CENTER_Y
    ST (ANIM_SCROLL_Y_L), R0
    LDI R0, 176                     ; -80 wrapped in 256-pixel space
    ST (ANIM_SCROLL_X_L), R0

    ; Set targets
    LDI R0, LOGO_CENTER_X
    ST (ANIM_SCROLL_X_TGT_L), R0
    LDI R0, LOGO_CENTER_Y
    ST (ANIM_SCROLL_Y_TGT_L), R0

    LDI R0, LOGO_SLOT_B
    ST.b (ANIM_LOGO_SLOT), R0

    LDI R0, LOGO_SHAPE_WIDE
    ST.b (ANIM_LOGO_SHAPE), R0

    RET

; ==============================================================================
; Entrance Animation: Slide Tick (shared for all slide directions)
; Uses constant speed of 1 pixel per frame with signed comparison
; ==============================================================================
entrance_slide_tick:
    ; Move X position toward target by constant speed (signed)
    LD R0, (ANIM_SCROLL_X_L)
    LD R1, (ANIM_SCROLL_X_TGT_L)
    LD R2, R1                       ; Save target
    SUB R1, R0                      ; R1 = target - current (signed diff)
    JRZ est_x_done                  ; X already at target
    JRN est_x_decrease              ; target < current (signed), decrease
    ; target > current (signed), increase
    INC R0
    JR est_x_store
est_x_decrease:
    DEC R0
est_x_store:
    ST (ANIM_SCROLL_X_L), R0
est_x_done:

    ; Move Y position toward target by constant speed (signed)
    LD R0, (ANIM_SCROLL_Y_L)
    LD R1, (ANIM_SCROLL_Y_TGT_L)
    LD R2, R1                       ; Save target
    SUB R1, R0                      ; R1 = target - current (signed diff)
    JRZ est_y_done                  ; Y already at target
    JRN est_y_decrease              ; target < current (signed), decrease
    ; target > current (signed), increase
    INC R0
    JR est_y_store
est_y_decrease:
    DEC R0
est_y_store:
    ST (ANIM_SCROLL_Y_L), R0
est_y_done:

    ; Check if both X and Y have reached target
    LD R0, (ANIM_SCROLL_X_L)
    LD R1, (ANIM_SCROLL_X_TGT_L)
    CMP R0, R1
    JRNZ est_not_done               ; X not at target yet

    LD R0, (ANIM_SCROLL_Y_L)
    LD R1, (ANIM_SCROLL_Y_TGT_L)
    CMP R0, R1
    JRNZ est_not_done               ; Y not at target yet

    ; Both at target - advance to display phase
    LDI R0, PHASE_DISPLAY
    ST.b (ANIM_PHASE), R0

    ; Reset frame counter
    LDI R0, 0
    ST (ANIM_FRAME_L), R0

est_not_done:
    RET

; ==============================================================================
; Entrance Animation: Slide Right Tick (increment X with 8-bit wrap)
; X-axis is still 256 pixels, so we need to wrap from 255 to 0
; ==============================================================================
entrance_slide_right_tick:
    ; Keep Y at target (LOGO_CENTER_Y = 176)
    LD R0, (ANIM_SCROLL_Y_TGT_L)
    ST (ANIM_SCROLL_Y_L), R0

    ; Increment X position (will wrap 255 -> 0)
    LD R0, (ANIM_SCROLL_X_L)
    LD R1, (ANIM_SCROLL_X_TGT_L)
    CMP R0, R1
    JRZ esrt_at_target              ; Already at target

    ; Increment and mask to 8 bits (wrap at 256)
    INC R0
    ANDI R0, 0xFF
    ST (ANIM_SCROLL_X_L), R0

    ; Check if we've reached target after increment
    CMP R0, R1
    JRNZ esrt_not_done

esrt_at_target:
    ; Snap to exact target
    LD R0, (ANIM_SCROLL_X_TGT_L)
    ST (ANIM_SCROLL_X_L), R0

    ; Advance to display phase
    LDI R0, PHASE_DISPLAY
    ST.b (ANIM_PHASE), R0

    ; Reset frame counter
    LDI R0, 0
    ST (ANIM_FRAME_L), R0

esrt_not_done:
    RET

; ==============================================================================
; Entrance Animation: Fade In (from black)
; ==============================================================================
entrance_fade_in:
    ; Position logo centered immediately
    LDI R0, LOGO_CENTER_X
    ST (ANIM_SCROLL_X_L), R0
    LDI R0, LOGO_CENTER_Y
    ST (ANIM_SCROLL_Y_L), R0

    ; Set palette phase to 0 (start of fade)
    LDI R0, 0
    ST.b (ANIM_PALETTE_PHASE), R0

    LDI R0, LOGO_SLOT_A
    ST.b (ANIM_LOGO_SLOT), R0

    LDI R0, LOGO_SHAPE_TALL
    ST.b (ANIM_LOGO_SHAPE), R0

    ; Set all palette entries to black
    CALL set_palette_black
    RET

; ==============================================================================
; Entrance Animation: Fade White (from white)
; ==============================================================================
entrance_fade_white:
    ; Position logo centered immediately
    LDI R0, LOGO_CENTER_X
    ST (ANIM_SCROLL_X_L), R0
    LDI R0, LOGO_CENTER_Y
    ST (ANIM_SCROLL_Y_L), R0

    ; Set palette phase to 0 (start of fade)
    LDI R0, 0
    ST.b (ANIM_PALETTE_PHASE), R0

    LDI R0, LOGO_SLOT_A
    ST.b (ANIM_LOGO_SLOT), R0

    LDI R0, LOGO_SHAPE_TALL
    ST.b (ANIM_LOGO_SHAPE), R0

    ; Set all palette entries to white
    CALL set_palette_white
    RET

; ==============================================================================
; Entrance Animation: Fade Tick (shared for fade in/white)
; ==============================================================================
entrance_fade_tick:
    ; Increment palette phase
    LD.b R0, (ANIM_PALETTE_PHASE)
    INC R0
    ST.b (ANIM_PALETTE_PHASE), R0

    ; Check if fade complete
    CMPI R0, FADE_STEPS
    JRC eft_continue_fade

    ; Fade complete - advance to display phase
    LDI R0, PHASE_DISPLAY
    ST.b (ANIM_PHASE), R0

    ; Reset frame counter
    LDI R0, 0
    ST (ANIM_FRAME_L), R0

    ; Restore target colors
    CALL init_colors
    RET

eft_continue_fade:
    ; Interpolate palette toward target
    CALL fade_palette_step
    RET

; ==============================================================================
; Entrance Animation: Wave Horizontal
; ==============================================================================
entrance_wave_horz:
    ; Position logo centered
    LDI R0, 0
    ST (ANIM_SCROLL_X_L), R0
    LDI R0, 0
    ST (ANIM_SCROLL_Y_L), R0

    ; Enable scanline effect
    LDI R0, 1                       ; Effect type: horizontal wave
    ST.b (ANIM_SCANLINE_EFFECT), R0

    ; Initialize wave phase
    LDI R0, 0
    ST.b (ANIM_WAVE_PHASE), R0

    ; Start with high amplitude (16)
    LDI R0, 16
    ST.b (ANIM_EFFECT_PARAM_L), R0

    LDI R0, LOGO_SLOT_A
    ST.b (ANIM_LOGO_SLOT), R0

    LDI R0, LOGO_SHAPE_TALL
    ST.b (ANIM_LOGO_SHAPE), R0

    RET

; ==============================================================================
; Entrance Animation: Wave Vertical
; ==============================================================================
entrance_wave_vert:
    ; Position logo centered
    LDI R0, LOGO_CENTER_X
    ST (ANIM_SCROLL_X_L), R0
    LDI R0, LOGO_CENTER_Y
    ST (ANIM_SCROLL_Y_L), R0

    ; Enable scanline effect
    LDI R0, 2                       ; Effect type: vertical wave
    ST.b (ANIM_SCANLINE_EFFECT), R0

    ; Initialize wave phase
    LDI R0, 0
    ST.b (ANIM_WAVE_PHASE), R0

    ; Start with high amplitude (16)
    LDI R0, 16
    ST.b (ANIM_EFFECT_PARAM_L), R0

    LDI R0, LOGO_SLOT_A
    ST.b (ANIM_LOGO_SLOT), R0

    LDI R0, LOGO_SHAPE_TALL
    ST.b (ANIM_LOGO_SHAPE), R0

    RET

; ==============================================================================
; Entrance Animation: Wave Tick
; ==============================================================================
entrance_wave_tick:
    ; Advance wave phase
    LD.b R0, (ANIM_WAVE_PHASE)
    ADDI R0, 4                      ; Speed of wave animation
    ST.b (ANIM_WAVE_PHASE), R0

    ; Reduce amplitude over time
    LD.b R1, (ANIM_EFFECT_PARAM_L)
    CMPI R1, 0
    JRZ ewt_wave_done

    ; Decrement amplitude every 8 frames
    LD R0, (ANIM_FRAME_L)
    ANDI R0, 0x07
    JRNZ ewt_update_table
    DEC R1
    ST.b (ANIM_EFFECT_PARAM_L), R1

ewt_update_table:
    ; Build scanline offset table
    CALL build_wave_table
    RET

ewt_wave_done:
    ; Wave finished - disable scanline effect and advance phase
    LDI R0, 0
    ST.b (ANIM_SCANLINE_EFFECT), R0

    LDI R0, PHASE_DISPLAY
    ST.b (ANIM_PHASE), R0

    ; Reset frame counter
    LDI R0, 0
    ST (ANIM_FRAME_L), R0
    RET

; ==============================================================================
; Entrance Animation: Drop and Bounce
; ==============================================================================
entrance_drop_bounce:
    ; Start above screen (positive scroll moves logo up)
    LDI R0, 80                      ; 80 pixels above center
    ST (ANIM_SCROLL_Y_L), R0
    LDI R0, LOGO_CENTER_X
    ST (ANIM_SCROLL_X_L), R0

    ; Set target (ground level = centered)
    LDI R0, LOGO_CENTER_Y
    ST (ANIM_SCROLL_Y_TGT_L), R0

    ; Initialize bounce state
    LDI R0, 3                       ; Number of bounces
    ST.b (ANIM_BOUNCE_COUNT), R0
    LDI R0, 0                       ; Initial velocity
    ST.b (ANIM_BOUNCE_VEL), R0

    LDI R0, LOGO_SLOT_A
    ST.b (ANIM_LOGO_SLOT), R0

    LDI R0, LOGO_SHAPE_TALL
    ST.b (ANIM_LOGO_SHAPE), R0

    RET

; ==============================================================================
; Entrance Animation: Bounce Tick
; Uses 16-bit signed velocity for proper bounce physics
; ==============================================================================
entrance_bounce_tick:
    ; Load velocity with sign extension (velocity stored as signed byte)
    LD.b R0, (ANIM_BOUNCE_VEL)
    ; Sign extend: if bit 7 is set, OR with 0xFF00
    ANDI R0, 0x00FF                 ; Ensure only low byte
    BIT R0, 7                       ; Test sign bit
    JRZ ebt_positive_vel
    ORI R0, 0xFF00                  ; Sign extend negative value
ebt_positive_vel:

    ; Apply gravity (velocity becomes more positive = falling faster)
    ADDI R0, 2                      ; Gravity acceleration
    ST.b (ANIM_BOUNCE_VEL), R0      ; Store low byte

    ; Update position: scroll decreases as logo falls toward center (0)
    LD R1, (ANIM_SCROLL_Y_L)
    SUB R1, R0                      ; position -= velocity (scroll decreases as we fall)

    ; Check for "ground" (target position, typically 0)
    LD R2, (ANIM_SCROLL_Y_TGT_L)

    ; If position <= target, we've hit or passed ground
    CMP R1, R2
    JRNC ebt_no_bounce              ; position > target, still falling

    ; Hit ground - check if bounces remaining
    LD.b R0, (ANIM_BOUNCE_COUNT)
    CMPI R0, 0
    JRZ ebt_done                    ; No more bounces

    DEC R0
    ST.b (ANIM_BOUNCE_COUNT), R0

    ; Reverse and dampen velocity (negate and halve)
    LD.b R0, (ANIM_BOUNCE_VEL)
    ; Sign extend for proper negation
    ANDI R0, 0x00FF
    BIT R0, 7
    JRZ ebt_bounce_negate
    ORI R0, 0xFF00
ebt_bounce_negate:
    NEG                             ; Reverse direction
    SRA R0                          ; Reduce magnitude by half
    ST.b (ANIM_BOUNCE_VEL), R0

    ; Snap to ground level
    LD R1, (ANIM_SCROLL_Y_TGT_L)

ebt_no_bounce:
    ST (ANIM_SCROLL_Y_L), R1
    RET

ebt_done:
    ; Snap to final position
    LD R0, (ANIM_SCROLL_Y_TGT_L)
    ST (ANIM_SCROLL_Y_L), R0

    LDI R0, PHASE_DISPLAY
    ST.b (ANIM_PHASE), R0

    ; Reset frame counter
    LDI R0, 0
    ST (ANIM_FRAME_L), R0
    RET
