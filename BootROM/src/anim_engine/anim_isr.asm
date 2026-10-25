
; ==============================================================================
; vblank_isr
; V-Blank interrupt service routine
; Minimal ISR - just sets flag for main loop to handle hardware updates
; ==============================================================================
vblank_isr:
    ; Save registers
    PUSH R0

    ; Set V-Blank flag for main loop
    LDI R0, 1
    ST.b (ANIM_VBLANK_FLAG), R0

    ; Clear V-Blank interrupt flag
    SET (IF), 0

    ; Restore registers
    POP R0
    RETI

; ==============================================================================
; lyc_isr
; LYC (scanline) interrupt service routine for wave effects
; Updates BG1 scroll (logo layer) for per-scanline wave distortion
; ==============================================================================
lyc_isr:
    ; Save registers
    PUSH R0
    PUSH R1

    ; Get current scanline index
    LD.b R0, (ANIM_SCANLINE_IDX)

    ; Look up SCY offset from table
    LDI R1, ANIM_SCANLINE_TABLE
    ADD R1, R0
    LD.b R1, (R1)                   ; Get offset value

    ; Apply to base scroll and write to BG1 (logo layer)
    LD R0, (ANIM_SCROLL_Y_L)
    ADD R0, R1
    ST (SCY1_L), R0

    ; Advance to next scanline
    LD.b R0, (ANIM_SCANLINE_IDX)
    INC R0
    ST.b (ANIM_SCANLINE_IDX), R0

    ; Set next LYC (skip some scanlines for performance)
    LD R0, (LY)
    ADDI R0, 3                      ; Process every 4th scanline
    ST.b (LYC), R0

    ; Clear LYC interrupt flag
    LDI R0, INT_LYC
    ST.b (IF), R0

    ; Restore registers
    POP R1
    POP R0
    RETI
