
; ==============================================================================
; Data Section - Color Lookup Tables
; ==============================================================================
.section name="color_data"

; ------------------------------------------------------------------------------
; Background color lookup table (RGB555 values)
; ID 0xFF is handled separately as animated rainbow
; ------------------------------------------------------------------------------
bg_color_table:
    .word 0x0000            ; 0x00 - BG_BLACK
    .word 0x7FFF            ; 0x01 - BG_WHITE
    .word 0x294A            ; 0x02 - BG_DARK_GRAY
    .word 0x56B5            ; 0x03 - BG_LIGHT_GRAY
    .word 0x0008            ; 0x04 - BG_DARK_BLUE
    .word 0x0010            ; 0x05 - BG_NAVY
    .word 0x2D7F            ; 0x06 - BG_ROYAL_BLUE
    .word 0x5EDF            ; 0x07 - BG_SKY_BLUE
    .word 0x0100            ; 0x08 - BG_DARK_GREEN
    .word 0x0280            ; 0x09 - BG_FOREST
    .word 0x4000            ; 0x0A - BG_DARK_RED
    .word 0x4800            ; 0x0B - BG_MAROON
    .word 0x4010            ; 0x0C - BG_PURPLE
    .word 0x2008            ; 0x0D - BG_DARK_PURPLE
    .word 0x5E00            ; 0x0E - BG_ORANGE
    .word 0x2940            ; 0x0F - BG_BROWN

; ------------------------------------------------------------------------------
; Logo color lookup table (RGB555 values)
; ID 0xFF is handled separately as animated rainbow
; ------------------------------------------------------------------------------
logo_color_table:
    .word 0x7FFF            ; 0x00 - LOGO_WHITE
    .word 0x0000            ; 0x01 - LOGO_BLACK
    .word 0x4210            ; 0x02 - LOGO_GRAY
    .word 0x7C00            ; 0x03 - LOGO_RED
    .word 0x03E0            ; 0x04 - LOGO_GREEN
    .word 0x001F            ; 0x05 - LOGO_BLUE
    .word 0x7FE0            ; 0x06 - LOGO_YELLOW
    .word 0x03FF            ; 0x07 - LOGO_CYAN
    .word 0x7C1F            ; 0x08 - LOGO_MAGENTA
    .word 0x7E00            ; 0x09 - LOGO_ORANGE
    .word 0x7E1F            ; 0x0A - LOGO_PINK
    .word 0x47E0            ; 0x0B - LOGO_LIME
    .word 0x6F40            ; 0x0C - LOGO_GOLD
    .word 0x5294            ; 0x0D - LOGO_SILVER
    .word 0x0210            ; 0x0E - LOGO_TEAL
    .word 0x7D0A            ; 0x0F - LOGO_CORAL

; ------------------------------------------------------------------------------
; Rainbow color table (8 colors, cycled every 8 frames)
; ------------------------------------------------------------------------------
rainbow_colors:
    .word 0x7C00            ; Red
    .word 0x7E00            ; Orange
    .word 0x7FE0            ; Yellow
    .word 0x03E0            ; Green
    .word 0x03FF            ; Cyan
    .word 0x001F            ; Blue
    .word 0x4010            ; Indigo
    .word 0x7C1F            ; Violet

.section_end
