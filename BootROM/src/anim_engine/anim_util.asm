
; ==============================================================================
; lerp_toward
; Move R0 1/64 of the way toward R1 (using signed arithmetic)
; Input: R0 = current value, R1 = target value
; Output: R0 = new value
; Clobbers: R1, R2
; ==============================================================================
lerp_toward:
    ; Save target for later comparison
    LD R2, R1

    ; Calculate distance (signed): R1 = target - current
    SUB R1, R0                      ; R1 = distance (can be negative)

    ; Check if already at target
    CMPI R1, 0
    JRZ lt_done

    ; Move 1/64 of distance using arithmetic shift (preserves sign)
    ; 6 shifts = divide by 64
    SRA R1
    SRA R1
    SRA R1
    SRA R1
    SRA R1
    SRA R1

    ; Ensure minimum movement of +/-1 when distance is small
    CMPI R1, 0
    JRNZ lt_apply

    ; Distance/64 rounded to 0, use +1 or -1 based on direction
    ; Check if target > current (need positive step) or target < current (need negative step)
    CMP R2, R0
    JRC lt_neg_step                 ; target < current, use -1
    LDI R1, 1                       ; target > current, use +1
    JR lt_apply
lt_neg_step:
    LDI R1, 0xFFFF                  ; -1 in two's complement

lt_apply:
    ADD R0, R1                      ; new = current + step
lt_done:
    RET

; ==============================================================================
; update_rainbow_colors
; Update rainbow foreground color (index 14) each frame if rainbow mode enabled
; Cycles through 8 rainbow colors, updating CRAM slot 0 color 14
; ==============================================================================
update_rainbow_colors:
    ; Check if rainbow mode is enabled
    LD.b R0, (ANIM_RAINBOW_MODE)
    CMPI R0, 0
    JRZ urc_done

    ; Increment rainbow timer
    LD.b R0, (ANIM_RAINBOW_TIMER)
    INC R0
    ST.b (ANIM_RAINBOW_TIMER), R0

    ; Check if time to change color (every RAINBOW_CYCLE_RATE frames)
    CMPI R0, RAINBOW_CYCLE_RATE
    JRC urc_done

    ; Reset timer
    LDI R0, 0
    ST.b (ANIM_RAINBOW_TIMER), R0

    ; Advance rainbow color index
    LD.b R0, (ANIM_RAINBOW_IDX)
    INC R0
    ANDI R0, 0x07                   ; Wrap to 0-7 range (8 colors)
    ST.b (ANIM_RAINBOW_IDX), R0

    ; Look up rainbow color: rainbow_colors + (index * 2)
    SHL R0                          ; R0 = index * 2 (word offset)
    LDI R1, rainbow_colors
    ADD R1, R0                      ; R1 = color address
    LD R0, (R1)                     ; R0 = RGB555 color value

    ; Write to CRAM sub-palette 0, color index 14
    ; CRAM address = CRAM_START + (FG_COLOR_INDEX * 2) = CRAM_START + 28
    LDI R1, CRAM_START
    ADDI R1, FG_COLOR_OFFSET        ; Point to color 14
    ST (R1), R0                     ; Update FG color

urc_done:
    RET

; ==============================================================================
; fade_palette_to_black
; Fade all 16 palette colors toward black by one step
; Called incrementally every 4 frames during exit phase
; ==============================================================================
fade_palette_to_black:
    LDI R3, CRAM_START
    LDI R4, 16                      ; Process all 16 colors in sub-palette 0

fptb_fade_loop:
    LD R0, (R3)                     ; Load current color

    ; Shift color right by 1 to fade toward black
    SRA R0
    ANDI R0, 0x3DEF                 ; Mask to prevent component bleed

    ST (R3), R0                     ; Store faded color
    ADDI R3, 2                      ; Next color
    DEC R4
    JRNZ fptb_fade_loop

    RET

; ==============================================================================
; set_palette_black
; Set all 16 colors of sub-palette 0 to black
; ==============================================================================
set_palette_black:
    LDI R1, CRAM_START
    LDI R2, 16                      ; 16 colors
    LDI R0, 0x0000                  ; Black
spb_loop:
    ST (R1), R0
    ADDI R1, 2
    DEC R2
    JRNZ spb_loop
    RET

; ==============================================================================
; set_palette_white
; Set all 16 colors of sub-palette 0 to white
; ==============================================================================
set_palette_white:
    LDI R1, CRAM_START
    LDI R2, 16                      ; 16 colors
    LDI R0, 0x7FFF                  ; White
spw_loop:
    ST (R1), R0
    ADDI R1, 2
    DEC R2
    JRNZ spw_loop
    RET

; ==============================================================================
; fade_palette_step
; Interpolate palette one step toward target colors
; ==============================================================================
fade_palette_step:
    ; For simplicity, just call init_colors when phase reaches threshold
    ; A full implementation would interpolate each color component
    LD.b R0, (ANIM_PALETTE_PHASE)
    CMPI R0, FADE_STEPS
    JRC fps_not_done
    CALL init_colors
fps_not_done:
    RET

; ==============================================================================
; build_wave_table
; Build wave offset table for LYC ISR using syslib sine table
; ==============================================================================
build_wave_table:
    ; Get sine table pointer from syslib
    LD R6, (SYSLIB_SINE_PTR)

    LDI R3, ANIM_SCANLINE_TABLE     ; Destination
    LDI R4, 0                       ; Scanline counter
    LD.b R5, (ANIM_WAVE_PHASE)      ; Current phase

bwt_loop:
    ; Calculate sine index: (phase + scanline * 2) & 0xFF
    LD R0, R4
    SHL R0                          ; Multiply scanline by 2 for wave frequency
    ADD R0, R5                      ; Add current phase
    ANDI R0, 0xFF                   ; Wrap to table size

    ; Look up sine value from syslib table
    LD R1, R6
    ADD R1, R0
    LD.b R0, (R1)                   ; Get sine value (signed)

    ; Scale by amplitude
    LD.b R2, (ANIM_EFFECT_PARAM_L)
    SRA R0                          ; Reduce range
    AND R0, R2                      ; Apply amplitude mask

    ; Store offset
    ST.b (R3), R0
    INC R3
    INC R4
    CMPI R4, 48                     ; 48 scanlines of table
    JRC bwt_loop
    RET
