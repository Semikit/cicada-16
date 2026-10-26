
; ==============================================================================
; update_rainbow_colors
; Cycle the foreground color (index 14) through 8 rainbow colors when rainbow
; mode is on. Skipped while a fade entrance is fading in and during the exit
; fade, so the colour does not pop back to full brightness mid-fade.
; ==============================================================================
update_rainbow_colors:
    LD.b R0, (ANIM_RAINBOW_MODE)
    CMPI R0, 0
    JRZ urc_done

    LD.b R0, (ANIM_PHASE)
    CMPI R0, PHASE_EXIT
    JRZ urc_done
    CMPI R0, PHASE_ENTRY
    JRNZ urc_run
    LD.b R0, (ANIM_ENTRANCE_ID)
    CMPI R0, ENTRANCE_FADE_IN_ID
    JRZ urc_done
    CMPI R0, ENTRANCE_FADE_WHITE_ID
    JRZ urc_done

urc_run:
    LD.b R0, (ANIM_RAINBOW_TIMER)
    INC R0
    ST.b (ANIM_RAINBOW_TIMER), R0
    CMPI R0, RAINBOW_CYCLE_RATE
    JRC urc_done

    LDI R0, 0
    ST.b (ANIM_RAINBOW_TIMER), R0

    LD.b R0, (ANIM_RAINBOW_IDX)
    INC R0
    ANDI R0, 0x07
    ST.b (ANIM_RAINBOW_IDX), R0

    SHL R0
    LDI R1, rainbow_colors
    ADD R1, R0
    LD R0, (R1)

    LDI R1, CRAM_START
    ADDI R1, FG_COLOR_OFFSET
    ST (R1), R0

urc_done:
    RET

; ==============================================================================
; fade_palette_to_black
; Halve every colour component of sub-palette 0 (one fade step toward black).
; ==============================================================================
fade_palette_to_black:
    LDI R3, CRAM_START
    LDI R4, 16

fptb_fade_loop:
    LD R0, (R3)
    SHR R0
    ANDI R0, 0x3DEF                 ; drop bits that crossed a component boundary
    ST (R3), R0
    ADDI R3, 2
    DEC R4
    JRNZ fptb_fade_loop

    RET

; ==============================================================================
; set_palette_black / set_palette_white
; Fill all 16 colours of sub-palette 0 with one value.
; ==============================================================================
set_palette_black:
    LDI R0, 0x0000
    JR set_palette_solid

set_palette_white:
    LDI R0, 0x7FFF

set_palette_solid:
    LDI R1, CRAM_START
    LDI R2, 16
sps_loop:
    ST (R1), R0
    ADDI R1, 2
    DEC R2
    JRNZ sps_loop
    RET

; ==============================================================================
; fade_palette_step
; Write sub-palette 0 as the active palette (ANIM_PALETTE_PTR) attenuated by
; shift count n (0 = exact colours, 5 = fully black / white).
;   from black (ANIM_FADE_MODE = 0): c = (t >> n) & mask[n]
;   from white (ANIM_FADE_MODE = 1): c = t + (((0x7FFF - t) >> n) & mask[n])
; mask[n] keeps the low (5 - n) bits of each 5-bit component, so shifting the
; packed RGB555 word does not bleed between components.
;
; Input: R0 = n (0-5)
; Clobbers: R0-R6
; ==============================================================================
fade_palette_step:
    LD R6, R0                       ; R6 = shift count
    SHL R0
    ADDI R0, fade_masks
    LD R5, (R0)                     ; R5 = mask[n]
    LD R3, (ANIM_PALETTE_PTR)       ; R3 = source colour pointer
    LDI R4, CRAM_START              ; R4 = destination
    LDI R2, 16                      ; R2 = colours left

fps_loop:
    LD R0, (R3)                     ; R0 = target colour t
    LD.b R1, (ANIM_FADE_MODE)
    CMPI R1, 0
    JRNZ fps_white

    CALL shift_right_n
    AND R0, R5
    JR fps_store

fps_white:
    LD R1, R0
    LDI R0, 0x7FFF
    SUB R0, R1                      ; R0 = 0x7FFF - t (no borrows between components)
    PUSH R1
    CALL shift_right_n
    AND R0, R5
    POP R1
    ADD R0, R1                      ; t + attenuated remainder

fps_store:
    ST (R4), R0
    ADDI R3, 2
    ADDI R4, 2
    DEC R2
    JRNZ fps_loop
    RET

.align 2
fade_masks:
    .word 0x7FFF, 0x3DEF, 0x1CE7, 0x0C63, 0x0421, 0x0000

; ==============================================================================
; shift_right_n
; Logical shift R0 right by R6 bits. Clobbers R1.
; ==============================================================================
shift_right_n:
    LD R1, R6
srn_loop:
    CMPI R1, 0
    JRZ srn_done
    SHR R0
    DEC R1
    JR srn_loop
srn_done:
    RET

; ==============================================================================
; slide_axis
; Move one scroll axis toward its target with an ease-out curve:
; step = max(1, |target - current| / 8).
;
; Input:  R0 = current, R1 = target
; Output: R0 = new value
; Clobbers: R1, R2
; ==============================================================================
slide_axis:
    LD R2, R0                       ; R2 = current
    LD R0, R1
    SUB R0, R2                      ; R0 = target - current (signed)
    JRZ sa_same
    JRN sa_neg

    SHR R0
    SHR R0
    SHR R0
    CMPI R0, 0
    JRNZ sa_add
    LDI R0, 1
sa_add:
    ADD R0, R2
    RET

sa_neg:
    NEG                             ; R0 = |diff|
    SHR R0
    SHR R0
    SHR R0
    CMPI R0, 0
    JRNZ sa_sub
    LDI R0, 1
sa_sub:
    LD R1, R2
    SUB R1, R0
    LD R0, R1
    RET

sa_same:
    LD R0, R2
    RET

; ==============================================================================
; build_wave_table
; Fill ANIM_SCANLINE_TABLE with base + (sine[(phase + 2 * line) & 0xFF] >> shift)
; for each of the 160 visible lines. The sine table is the System Library's
; 256-entry signed 8-bit table (vector 0x01). shift = ANIM_EFFECT_PARAM_L.
;
; Clobbers: R0-R6
; ==============================================================================
build_wave_table:
    LD R6, (SYSLIB_SINE_PTR)
    LDI R3, ANIM_SCANLINE_TABLE
    LDI R4, 0                       ; line
    LD.b R5, (ANIM_WAVE_PHASE)

bwt_loop:
    LD R0, R4
    SHL R0                          ; line * 2 (wave period = 128 lines)
    ADD R0, R5
    ANDI R0, 0xFF
    ADD R0, R6
    LD.b R0, (R0)                   ; sample, zero-extended

    BIT R0, 7                       ; sign-extend
    JRZ bwt_positive
    ORI R0, 0xFF00
bwt_positive:

    LD.b R1, (ANIM_EFFECT_PARAM_L)  ; arithmetic shift by amplitude
bwt_shift:
    CMPI R1, 0
    JRZ bwt_shifted
    SRA R0
    DEC R1
    JR bwt_shift
bwt_shifted:

    LD R1, (ANIM_SCANLINE_BASE)
    ADD R0, R1
    ST (R3), R0
    ADDI R3, 2
    INC R4
    CMPI R4, 160
    JRC bwt_loop
    RET

; ==============================================================================
; build_scale_table
; Fill ANIM_SCANLINE_TABLE so BG1 appears vertically scaled about the screen
; centre (line 80):  SCY(L) = base + ((L - 80) * K) >> 4
; where K = 1/scale - 1 in 8.4 fixed point (ANIM_EFFECT_PARAM, 0 = unscaled,
; 112 = 1/8 height). Computed incrementally: acc starts at -80 * K and gains K
; per line.
;
; Clobbers: R0-R6
; ==============================================================================
build_scale_table:
    LD R5, (ANIM_EFFECT_PARAM_L)    ; R5 = K
    LD R0, R5
    SHL R0
    SHL R0
    SHL R0
    SHL R0                          ; 16K
    LD R1, R0
    SHL R1
    SHL R1                          ; 64K
    ADD R0, R1                      ; 80K
    NEG
    LD R6, R0                       ; acc = -80K

    LD R2, (ANIM_SCANLINE_BASE)
    LDI R3, ANIM_SCANLINE_TABLE
    LDI R4, 160

bst_loop:
    LD R0, R6
    SRA R0
    SRA R0
    SRA R0
    SRA R0                          ; R0 = offset = acc >> 4 (signed)

    ; Lines whose offset reaches past the logo would wrap round the map and
    ; show the other copy (or the mirror in slot 2); point them at a blank
    ; map row instead: entry = SCALE_BLANK_ROW - line, line = 160 - R4
    LD R1, R0
    ADDI R1, SCALE_CLAMP
    CMPI R1, SCALE_CLAMP_RANGE
    JRNC bst_blank                  ; (offset + CLAMP) >= RANGE unsigned
    ADD R0, R2
    JR bst_store
bst_blank:
    LD R0, R4
    SUBI R0, 152                    ; (SCALE_BLANK_ROW - 160) + R4
bst_store:
    ST (R3), R0
    ADDI R3, 2
    ADD R6, R5
    DEC R4
    JRNZ bst_loop
    RET

; ==============================================================================
; update_lyc_enable
; Enable the LYC interrupt in STAT while a scanline effect is active and arm
; LYC for line 0; otherwise leave only the V-Blank interrupt enabled.
; ==============================================================================
update_lyc_enable:
    LD.b R0, (ANIM_SCANLINE_EFFECT)
    CMPI R0, SCANLINE_NONE
    JRZ ule_off

    LDI R0, 0x50                    ; STAT_LYC_INT_EN | STAT_VBLK_INT_EN
    ST.b (STAT), R0
    LDI R0, 0
    ST.b (LYC), R0
    RET

ule_off:
    LDI R0, STAT_VBLK_INT_EN
    ST.b (STAT), R0
    RET
