
; ==============================================================================
; vblank_isr
; V-Blank interrupt service routine
; Minimal ISR - just sets flag for main loop to handle hardware updates
; ==============================================================================
vblank_isr:
    PUSH R0

    LDI R0, 1
    ST.b (ANIM_VBLANK_FLAG), R0

    ; Clear V-Blank interrupt flag (write 1 to clear)
    LDI R0, INT_VBLANK
    ST.b (IF), R0

    POP R0
    RETI

; ==============================================================================
; lyc_isr
; LYC (scanline) interrupt service routine for per-scanline scroll effects.
; Fires on every visible scanline while a scanline effect is active (STAT
; LYC_INT_EN is set by update_lyc_enable). Writes entry LY of
; ANIM_SCANLINE_TABLE to the scroll register in ANIM_SCANLINE_REG, then arms
; LYC for the next line. On entering V-Blank it re-arms LYC for line 0.
; The scroll write is done as early as possible so it lands before the PPU
; starts drawing the line.
; ==============================================================================
lyc_isr:
    PUSH R0
    PUSH R1

    LD.b R0, (LY)
    CMPI R0, 160
    JRNC li_vblank                  ; LY >= 160: no table entry, re-arm for line 0

    ; R1 = table[LY]
    LD R1, R0
    SHL R1
    ADDI R1, ANIM_SCANLINE_TABLE
    LD R1, (R1)

    ; write it to the selected BG1 scroll register
    LD R0, (ANIM_SCANLINE_REG)
    ST (R0), R1

    ; next line
    LD.b R0, (LY)
    INC R0
    ST.b (LYC), R0
    JR li_done

li_vblank:
    LDI R0, 0
    ST.b (LYC), R0

li_done:
    ; Clear LYC interrupt flag (write 1 to clear)
    LDI R0, INT_LYC
    ST.b (IF), R0

    POP R1
    POP R0
    RETI
