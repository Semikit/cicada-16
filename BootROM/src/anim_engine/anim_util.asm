
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
; Update rainbow colors each frame if enabled
; ==============================================================================
update_rainbow_colors:
    ; Check background rainbow
    LD.b R0, (ANIM_BG_COLOR_ID)
    CMPI R0, RAINBOW_ID
    JRNZ urc_check_logo

    ; Apply rainbow to background
    CALL apply_rainbow
    LDI R1, CRAM_START
    ST (R1), R0

urc_check_logo:
    ; Check logo rainbow
    LD.b R0, (ANIM_LOGO_COLOR_ID)
    CMPI R0, RAINBOW_ID
    JRNZ urc_done

    ; Apply rainbow to logo (offset by 2 indices for visual interest)
    LD R0, (ANIM_FRAME_L)
    ADDI R0, 16                     ; Offset from background rainbow
    SRA R0
    SRA R0
    SRA R0
    ANDI R0, 0x07
    SHL R0
    LDI R1, rainbow_colors
    ADD R1, R0
    LD R0, (R1)

    ; Write to logo color index
    LDI R1, CRAM_START
    ADDI R1, 2
    ST (R1), R0

urc_done:
    RET

; ==============================================================================
; apply_rainbow
; Get current rainbow color based on frame counter
; Output: R0 = RGB555 color value
; Clobbers: R1
; ==============================================================================
apply_rainbow:
    ; Get current frame
    LD R0, (ANIM_FRAME_L)
    ; Divide by 8 to slow animation
    SRA R0
    SRA R0
    SRA R0
    ; Mask to 0-7 range
    ANDI R0, 0x07
    ; Multiply by 2 for word offset
    SHL R0
    ; Add to table base
    LDI R1, rainbow_colors
    ADD R1, R0
    ; Load color
    LD R0, (R1)
    RET

; ==============================================================================
; fade_palette_to_black
; Fade all palette colors toward black by one step
; Called incrementally every 4 frames during exit phase
; ==============================================================================
fade_palette_to_black:
    LDI R3, CRAM_START
    LDI R4, 4                       ; Process 4 colors (bg + 3 logo)

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
; Set first 4 colors of palette to black
; ==============================================================================
set_palette_black:
    LDI R1, CRAM_START
    LDI R2, 4                       ; 4 colors
    LDI R0, 0x0000                  ; Black
spb_loop:
    ST (R1), R0
    ADDI R1, 2
    DEC R2
    JRNZ spb_loop
    RET

; ==============================================================================
; set_palette_white
; Set first 4 colors of palette to white
; ==============================================================================
set_palette_white:
    LDI R1, CRAM_START
    LDI R2, 4                       ; 4 colors
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
