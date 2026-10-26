; ==============================================================================
; entrance_anims.asm - Boot Animation entrance animation tables and functions
; ==============================================================================
; Every entrance has an init function (called once from
; init_entrance_animation, before the PPU is enabled) and a tick function
; (called once per frame during PHASE_ENTRY). The init function must set
; ANIM_LOGO_SHAPE and the starting scroll position; the tick function moves
; the animation and switches to PHASE_DISPLAY when done.
; ==============================================================================

.section name="anim_tables"
.align 2
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
    .word entrance_zoom_in          ; 0x09 - Zoom in (vertical scale)
    .word entrance_drop_bounce      ; 0x0A - Drop and bounce
    .word entrance_spin_in          ; 0x0B - Spin in (flip about the X axis)

entrance_tick_table:
    .word entrance_none_tick        ; 0x00
    .word entrance_slide_tick       ; 0x01
    .word entrance_slide_tick       ; 0x02
    .word entrance_slide_tick       ; 0x03
    .word entrance_slide_tick       ; 0x04
    .word entrance_fade_tick        ; 0x05
    .word entrance_fade_tick        ; 0x06
    .word entrance_wave_tick        ; 0x07
    .word entrance_wave_tick        ; 0x08
    .word entrance_zoom_tick        ; 0x09
    .word entrance_bounce_tick      ; 0x0A
    .word entrance_spin_tick        ; 0x0B

; 1/|cos| - 1 in 8.4 fixed point, indexed by |cos| >> 3 (cos from the signed
; 8-bit sine table), capped at ZOOM_K_START. Used by the spin entrance.
spin_k_table:
    .byte 112, 112, 86, 57, 40, 30, 23, 18, 14, 11, 8, 6, 4, 3, 2, 0
.section_end

; ==============================================================================
; Shared helpers
; ==============================================================================

; Put the logo at its centred position (current and target) using the tall map.
logo_center_tall:
    LDI R0, LOGO_SHAPE_TALL
    ST.b (ANIM_LOGO_SHAPE), R0
    LDI R0, LOGO_CENTER_X
    ST (ANIM_SCROLL_X_L), R0
    ST (ANIM_SCROLL_X_TGT_L), R0
    LDI R0, LOGO_CENTER_Y
    ST (ANIM_SCROLL_Y_L), R0
    ST (ANIM_SCROLL_Y_TGT_L), R0
    RET

; Finish the entry phase: switch to PHASE_DISPLAY and restart the frame counter.
enter_display_phase:
    LDI R0, PHASE_DISPLAY
    ST.b (ANIM_PHASE), R0
    LDI R0, 0
    ST (ANIM_FRAME_L), R0
    RET

; Stop any scanline effect and restore the base scroll.
end_scanline_effect:
    LDI R0, SCANLINE_NONE
    ST.b (ANIM_SCANLINE_EFFECT), R0
    CALL apply_scroll
    RET

; ==============================================================================
; 0x00 None (instant)
; ==============================================================================
entrance_none:
    CALL logo_center_tall
    CALL enter_display_phase
    RET

entrance_none_tick:
    RET

; ==============================================================================
; 0x01-0x04 Slides
; Vertical slides use the tall map (room above and below), horizontal slides
; the wide map (room left and right). The logo starts fully off-screen and
; eases toward the centre.
; ==============================================================================
entrance_slide_down:
    CALL logo_center_tall
    LDI R0, LOGO_CENTER_Y
    ADDI R0, SLIDE_DIST_Y           ; larger scroll = logo higher on screen
    ST (ANIM_SCROLL_Y_L), R0
    RET

entrance_slide_up:
    CALL logo_center_tall
    LDI R0, LOGO_CENTER_Y
    SUBI R0, SLIDE_DIST_Y
    ST (ANIM_SCROLL_Y_L), R0
    RET

entrance_slide_left:                ; from the right edge
    CALL logo_center_tall
    LDI R0, LOGO_SHAPE_WIDE
    ST.b (ANIM_LOGO_SHAPE), R0
    LDI R0, LOGO_CENTER_X
    SUBI R0, SLIDE_DIST_X           ; smaller scroll = logo further right
    ST (ANIM_SCROLL_X_L), R0
    RET

entrance_slide_right:               ; from the left edge
    CALL logo_center_tall
    LDI R0, LOGO_SHAPE_WIDE
    ST.b (ANIM_LOGO_SHAPE), R0
    LDI R0, LOGO_CENTER_X
    ADDI R0, SLIDE_DIST_X
    ST (ANIM_SCROLL_X_L), R0
    RET

entrance_slide_tick:
    LD R0, (ANIM_SCROLL_X_L)
    LD R1, (ANIM_SCROLL_X_TGT_L)
    CALL slide_axis
    ST (ANIM_SCROLL_X_L), R0

    LD R0, (ANIM_SCROLL_Y_L)
    LD R1, (ANIM_SCROLL_Y_TGT_L)
    CALL slide_axis
    ST (ANIM_SCROLL_Y_L), R0

    LD R0, (ANIM_SCROLL_X_L)
    LD R1, (ANIM_SCROLL_X_TGT_L)
    CMP R0, R1
    JRNZ est_not_done
    LD R0, (ANIM_SCROLL_Y_L)
    LD R1, (ANIM_SCROLL_Y_TGT_L)
    CMP R0, R1
    JRNZ est_not_done

    CALL enter_display_phase
est_not_done:
    RET

; ==============================================================================
; 0x05 Fade in (from black), 0x06 Fade white (from white)
; Sub-palette 0 starts solid and is rewritten every 4 frames with the target
; palette attenuated by a decreasing shift (5, 4, 3, 2, 1, 0).
; ==============================================================================
entrance_fade_in:
    CALL logo_center_tall
    LDI R0, 0
    ST.b (ANIM_FADE_MODE), R0
    ST.b (ANIM_PALETTE_PHASE), R0
    CALL set_palette_black
    RET

entrance_fade_white:
    CALL logo_center_tall
    LDI R0, 1
    ST.b (ANIM_FADE_MODE), R0
    LDI R0, 0
    ST.b (ANIM_PALETTE_PHASE), R0
    CALL set_palette_white
    RET

entrance_fade_tick:
    LD.b R0, (ANIM_PALETTE_PHASE)
    INC R0
    ST.b (ANIM_PALETTE_PHASE), R0

    ANDI R0, 0x03                   ; one step every 4 frames
    JRNZ eft_done

    LD.b R0, (ANIM_PALETTE_PHASE)
    SHR R0
    SHR R0                          ; R0 = step k (1..6)
    CMPI R0, 6
    JRNC eft_complete

    ; from black the attenuation shift falls (5-k: 4,3,2,1,0), from white the
    ; remainder shift rises (k: 1,2,3,4,5); both end on the target palette
    LD.b R1, (ANIM_FADE_MODE)
    CMPI R1, 0
    JRNZ eft_step
    LDI R1, 5
    SUB R1, R0
    LD R0, R1
eft_step:
    CALL fade_palette_step
    RET

eft_complete:
    CALL init_colors                ; exact target colours
    CALL enter_display_phase
eft_done:
    RET

; ==============================================================================
; 0x07 Wave horizontal (per-line SCX1), 0x08 Wave vertical (per-line SCY1)
; A sine wave scrolls down the logo while its amplitude halves every
; WAVE_STEP_FRAMES frames from +/-16 px to +/-1 px.
; ==============================================================================
entrance_wave_horz:
    CALL logo_center_tall
    LDI R0, SCANLINE_WAVE_HORZ
    ST.b (ANIM_SCANLINE_EFFECT), R0
    LDI R0, SCX1_L
    ST (ANIM_SCANLINE_REG), R0
    LDI R0, LOGO_CENTER_X
    ST (ANIM_SCANLINE_BASE), R0
    JR wave_common_init

entrance_wave_vert:
    CALL logo_center_tall
    LDI R0, SCANLINE_WAVE_VERT
    ST.b (ANIM_SCANLINE_EFFECT), R0
    LDI R0, SCY1_L
    ST (ANIM_SCANLINE_REG), R0
    LDI R0, LOGO_CENTER_Y
    ST (ANIM_SCANLINE_BASE), R0

wave_common_init:
    LDI R0, 0
    ST.b (ANIM_WAVE_PHASE), R0
    LDI R0, WAVE_SHIFT_START
    ST (ANIM_EFFECT_PARAM_L), R0
    LDI R0, WAVE_STEP_FRAMES
    ST.b (ANIM_EFFECT_TIMER), R0
    CALL build_wave_table
    RET

entrance_wave_tick:
    LD.b R0, (ANIM_WAVE_PHASE)
    ADDI R0, 4                      ; wave speed
    ST.b (ANIM_WAVE_PHASE), R0

    LD.b R0, (ANIM_EFFECT_TIMER)
    DEC R0
    ST.b (ANIM_EFFECT_TIMER), R0
    JRNZ ewt_build

    LDI R0, WAVE_STEP_FRAMES
    ST.b (ANIM_EFFECT_TIMER), R0
    LD R0, (ANIM_EFFECT_PARAM_L)
    INC R0
    ST (ANIM_EFFECT_PARAM_L), R0
    CMPI R0, WAVE_SHIFT_END
    JRNC ewt_finished

ewt_build:
    CALL build_wave_table
    RET

ewt_finished:
    CALL end_scanline_effect
    CALL enter_display_phase
    RET

; ==============================================================================
; 0x09 Zoom in
; Vertical scale from 1/8 height to full height about the screen centre,
; easing out. (The PPU has no horizontal scaling; the width is constant.)
; ==============================================================================
entrance_zoom_in:
    CALL logo_center_tall
    LDI R0, SCANLINE_SCALE
    ST.b (ANIM_SCANLINE_EFFECT), R0
    LDI R0, SCY1_L
    ST (ANIM_SCANLINE_REG), R0
    LDI R0, LOGO_CENTER_Y
    ST (ANIM_SCANLINE_BASE), R0
    LDI R0, ZOOM_K_START
    ST (ANIM_EFFECT_PARAM_L), R0
    CALL build_scale_table
    RET

entrance_zoom_tick:
    LD R0, (ANIM_EFFECT_PARAM_L)
    CMPI R0, 0
    JRZ ezt_finished

    ; K -= K/16 + 1 (ease out)
    LD R1, R0
    SHR R1
    SHR R1
    SHR R1
    SHR R1
    INC R1
    SUB R0, R1
    JRNN ezt_store
    LDI R0, 0                       ; clamp at 0
ezt_store:
    ST (ANIM_EFFECT_PARAM_L), R0
    CALL build_scale_table
    RET

ezt_finished:
    CALL end_scanline_effect
    CALL enter_display_phase
    RET

; ==============================================================================
; 0x0A Drop and bounce
; The logo falls from above the screen under gravity and bounces three times.
; Scroll decreases as the logo falls (larger scroll = logo higher).
; ==============================================================================
entrance_drop_bounce:
    CALL logo_center_tall
    LDI R0, LOGO_CENTER_Y
    ADDI R0, SLIDE_DIST_Y
    ST (ANIM_SCROLL_Y_L), R0

    LDI R0, 3
    ST.b (ANIM_BOUNCE_COUNT), R0
    LDI R0, 0
    ST.b (ANIM_BOUNCE_VEL), R0
    RET

entrance_bounce_tick:
    ; velocity (signed byte) with sign extension
    LD.b R0, (ANIM_BOUNCE_VEL)
    BIT R0, 7
    JRZ ebt_positive_vel
    ORI R0, 0xFF00
ebt_positive_vel:

    ADDI R0, 2                      ; gravity
    ST.b (ANIM_BOUNCE_VEL), R0

    LD R1, (ANIM_SCROLL_Y_L)
    SUB R1, R0                      ; position -= velocity
    LD R2, (ANIM_SCROLL_Y_TGT_L)
    CMP R1, R2
    JRNC ebt_no_bounce              ; still above the ground

    LD.b R0, (ANIM_BOUNCE_COUNT)
    CMPI R0, 0
    JRZ ebt_done
    DEC R0
    ST.b (ANIM_BOUNCE_COUNT), R0

    ; reverse and halve the velocity
    LD.b R0, (ANIM_BOUNCE_VEL)
    BIT R0, 7
    JRZ ebt_bounce_negate
    ORI R0, 0xFF00
ebt_bounce_negate:
    NEG
    SRA R0
    ST.b (ANIM_BOUNCE_VEL), R0

    LD R1, (ANIM_SCROLL_Y_TGT_L)    ; snap to the ground

ebt_no_bounce:
    ST (ANIM_SCROLL_Y_L), R1
    RET

ebt_done:
    LD R0, (ANIM_SCROLL_Y_TGT_L)
    ST (ANIM_SCROLL_Y_L), R0
    CALL enter_display_phase
    RET

; ==============================================================================
; 0x0B Spin in
; The logo flips about its horizontal axis: its height follows |cos(angle)|
; via the scale table, and while cos is negative the vertically mirrored copy
; in slot 2 is shown instead. Two full turns, the second at half speed.
; ==============================================================================
entrance_spin_in:
    CALL logo_center_tall
    CALL build_mirror_tilemap
    LDI R0, SCANLINE_SCALE
    ST.b (ANIM_SCANLINE_EFFECT), R0
    LDI R0, SCY1_L
    ST (ANIM_SCANLINE_REG), R0
    LDI R0, 0
    ST.b (ANIM_SPIN_ANGLE), R0
    LDI R0, SPIN_STEP_START
    ST.b (ANIM_SPIN_STEP), R0
    LDI R0, SPIN_TURNS
    ST.b (ANIM_SPIN_TURNS), R0
    CALL spin_build
    RET

entrance_spin_tick:
    LD.b R0, (ANIM_SPIN_ANGLE)
    LD.b R1, (ANIM_SPIN_STEP)
    ADD R0, R1
    ANDI R0, 0xFF
    ST.b (ANIM_SPIN_ANGLE), R0
    CMPI R0, 0
    JRNZ est_build                  ; mid-turn

    ; completed a full turn
    LD.b R0, (ANIM_SPIN_TURNS)
    DEC R0
    ST.b (ANIM_SPIN_TURNS), R0
    JRZ est_finished
    LD.b R0, (ANIM_SPIN_STEP)       ; slow down for the next turn
    SHR R0
    ST.b (ANIM_SPIN_STEP), R0

est_build:
    CALL spin_build
    RET

est_finished:
    CALL end_scanline_effect
    CALL enter_display_phase
    RET

; Compute base scroll and K for the current angle, then build the table.
spin_build:
    LD.b R0, (ANIM_SPIN_ANGLE)
    ADDI R0, 64                     ; cos(a) = sin(a + 90 degrees)
    ANDI R0, 0xFF
    LD R1, (SYSLIB_SINE_PTR)
    ADD R0, R1
    LD.b R0, (R0)

    BIT R0, 7
    JRZ sb_front
    ; back side: mirrored logo, |cos| = -cos
    ORI R0, 0xFF00
    NEG
    LDI R1, LOGO_MIRROR_Y
    JR sb_lookup
sb_front:
    LDI R1, LOGO_CENTER_Y
sb_lookup:
    ST (ANIM_SCANLINE_BASE), R1

    SHR R0
    SHR R0
    SHR R0                          ; |cos| >> 3 (0-15)
    ADDI R0, spin_k_table
    LD.b R0, (R0)
    ST (ANIM_EFFECT_PARAM_L), R0
    CALL build_scale_table
    RET
