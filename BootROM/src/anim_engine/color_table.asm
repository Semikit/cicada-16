
; ==============================================================================
; Data Section - Color Lookup Tables
; ==============================================================================
; Each palette is 16 colors (32 bytes):
;   Color 0:     Background color
;   Colors 1-13: Gradient from BG to FG
;   Color 14:    Foreground (logo) color
;   Color 15:    Accent color
; ==============================================================================
.section name="color_data"

; ------------------------------------------------------------------------------
; Boot palette lookup table - 16 palettes, 16 colors each (RGB555 format)
; ------------------------------------------------------------------------------
palette_table:
    .word pal_classic
    .word pal_inverted
    .word pal_night
    .word pal_ocean
    .word pal_forest
    .word pal_sunset
    .word pal_royal
    .word pal_arcade
    .word pal_neon
    .word pal_ice
    .word pal_fire
    .word pal_earth
    .word pal_grape
    .word pal_mint
    .word pal_steel
    .word pal_coral

    ; --------------------------------------------------------------------------
    ; Palette 0x00 - Classic: Black bg -> White fg
    ; --------------------------------------------------------------------------
pal_classic:
    .word 0x0000    ; 0:  BG - Black
    .word 0x0842    ; 1:  Gradient
    .word 0x1084    ; 2:  Gradient
    .word 0x18C6    ; 3:  Gradient
    .word 0x2108    ; 4:  Gradient
    .word 0x294A    ; 5:  Gradient
    .word 0x318C    ; 6:  Gradient
    .word 0x39CE    ; 7:  Gradient
    .word 0x4210    ; 8:  Gradient
    .word 0x4A52    ; 9:  Gradient
    .word 0x5294    ; 10: Gradient
    .word 0x5AD6    ; 11: Gradient
    .word 0x6318    ; 12: Gradient
    .word 0x6B5A    ; 13: Gradient
    .word 0x7FFF    ; 14: FG - White
    .word 0x7C00    ; 15: Accent - Red

    ; --------------------------------------------------------------------------
    ; Palette 0x01 - Inverted: White bg -> Black fg
    ; --------------------------------------------------------------------------
pal_inverted:
    .word 0x7FFF    ; 0:  BG - White
    .word 0x6B5A    ; 1:  Gradient
    .word 0x6318    ; 2:  Gradient
    .word 0x5AD6    ; 3:  Gradient
    .word 0x5294    ; 4:  Gradient
    .word 0x4A52    ; 5:  Gradient
    .word 0x4210    ; 6:  Gradient
    .word 0x39CE    ; 7:  Gradient
    .word 0x318C    ; 8:  Gradient
    .word 0x294A    ; 9:  Gradient
    .word 0x2108    ; 10: Gradient
    .word 0x18C6    ; 11: Gradient
    .word 0x1084    ; 12: Gradient
    .word 0x0842    ; 13: Gradient
    .word 0x0000    ; 14: FG - Black
    .word 0x001F    ; 15: Accent - Blue

    ; --------------------------------------------------------------------------
    ; Palette 0x02 - Night Sky: Navy bg -> White fg
    ; --------------------------------------------------------------------------
pal_night:
    .word 0x0010    ; 0:  BG - Navy (dark blue)
    .word 0x0852    ; 1:  Gradient
    .word 0x1094    ; 2:  Gradient
    .word 0x18D6    ; 3:  Gradient
    .word 0x2118    ; 4:  Gradient
    .word 0x295A    ; 5:  Gradient
    .word 0x319C    ; 6:  Gradient
    .word 0x39DE    ; 7:  Gradient
    .word 0x4220    ; 8:  Gradient
    .word 0x4A62    ; 9:  Gradient
    .word 0x52A4    ; 10: Gradient
    .word 0x5AE6    ; 11: Gradient
    .word 0x6328    ; 12: Gradient
    .word 0x6B6A    ; 13: Gradient
    .word 0x7FFF    ; 14: FG - White
    .word 0x7FE0    ; 15: Accent - Yellow

    ; --------------------------------------------------------------------------
    ; Palette 0x03 - Ocean: Dark Blue bg -> Cyan fg
    ; --------------------------------------------------------------------------
pal_ocean:
    .word 0x0008    ; 0:  BG - Dark Blue
    .word 0x0049    ; 1:  Gradient
    .word 0x008A    ; 2:  Gradient
    .word 0x00CB    ; 3:  Gradient
    .word 0x010C    ; 4:  Gradient
    .word 0x014D    ; 5:  Gradient
    .word 0x018E    ; 6:  Gradient
    .word 0x01CF    ; 7:  Gradient
    .word 0x0210    ; 8:  Gradient
    .word 0x0251    ; 9:  Gradient
    .word 0x0292    ; 10: Gradient
    .word 0x02D3    ; 11: Gradient
    .word 0x0314    ; 12: Gradient
    .word 0x0355    ; 13: Gradient
    .word 0x03FF    ; 14: FG - Cyan
    .word 0x7C00    ; 15: Accent - Red

    ; --------------------------------------------------------------------------
    ; Palette 0x04 - Forest: Dark Green bg -> Lime fg
    ; --------------------------------------------------------------------------
pal_forest:
    .word 0x0100    ; 0:  BG - Dark Green
    .word 0x0520    ; 1:  Gradient
    .word 0x0940    ; 2:  Gradient
    .word 0x0D60    ; 3:  Gradient
    .word 0x1180    ; 4:  Gradient
    .word 0x15A0    ; 5:  Gradient
    .word 0x19C0    ; 6:  Gradient
    .word 0x1DE0    ; 7:  Gradient
    .word 0x2600    ; 8:  Gradient
    .word 0x2A20    ; 9:  Gradient
    .word 0x2E40    ; 10: Gradient
    .word 0x3260    ; 11: Gradient
    .word 0x3680    ; 12: Gradient
    .word 0x3AA0    ; 13: Gradient
    .word 0x47E0    ; 14: FG - Lime
    .word 0x7C1F    ; 15: Accent - Magenta

    ; --------------------------------------------------------------------------
    ; Palette 0x05 - Sunset: Dark Red bg -> Orange fg
    ; --------------------------------------------------------------------------
pal_sunset:
    .word 0x4000    ; 0:  BG - Dark Red
    .word 0x4400    ; 1:  Gradient
    .word 0x4800    ; 2:  Gradient
    .word 0x4C00    ; 3:  Gradient
    .word 0x5000    ; 4:  Gradient
    .word 0x5400    ; 5:  Gradient
    .word 0x5800    ; 6:  Gradient
    .word 0x5C00    ; 7:  Gradient
    .word 0x6000    ; 8:  Gradient
    .word 0x6400    ; 9:  Gradient
    .word 0x6800    ; 10: Gradient
    .word 0x6C00    ; 11: Gradient
    .word 0x7000    ; 12: Gradient
    .word 0x7400    ; 13: Gradient
    .word 0x7E00    ; 14: FG - Orange
    .word 0x7FE0    ; 15: Accent - Yellow

    ; --------------------------------------------------------------------------
    ; Palette 0x06 - Royal: Dark Purple bg -> Gold fg
    ; --------------------------------------------------------------------------
pal_royal:
    .word 0x2008    ; 0:  BG - Dark Purple
    .word 0x2808    ; 1:  Gradient
    .word 0x3008    ; 2:  Gradient
    .word 0x3808    ; 3:  Gradient
    .word 0x4008    ; 4:  Gradient
    .word 0x4408    ; 5:  Gradient
    .word 0x4C08    ; 6:  Gradient
    .word 0x5408    ; 7:  Gradient
    .word 0x5808    ; 8:  Gradient
    .word 0x5C20    ; 9:  Gradient
    .word 0x6020    ; 10: Gradient
    .word 0x6440    ; 11: Gradient
    .word 0x6860    ; 12: Gradient
    .word 0x6B40    ; 13: Gradient
    .word 0x6F40    ; 14: FG - Gold
    .word 0x03FF    ; 15: Accent - Cyan

    ; --------------------------------------------------------------------------
    ; Palette 0x07 - Arcade: Black bg -> Green fg (retro terminal)
    ; --------------------------------------------------------------------------
pal_arcade:
    .word 0x0000    ; 0:  BG - Black
    .word 0x0040    ; 1:  Gradient
    .word 0x0060    ; 2:  Gradient
    .word 0x0080    ; 3:  Gradient
    .word 0x00A0    ; 4:  Gradient
    .word 0x00C0    ; 5:  Gradient
    .word 0x00E0    ; 6:  Gradient
    .word 0x0120    ; 7:  Gradient
    .word 0x0160    ; 8:  Gradient
    .word 0x01A0    ; 9:  Gradient
    .word 0x01E0    ; 10: Gradient
    .word 0x0260    ; 11: Gradient
    .word 0x02E0    ; 12: Gradient
    .word 0x0360    ; 13: Gradient
    .word 0x03E0    ; 14: FG - Green
    .word 0x7FE0    ; 15: Accent - Yellow

    ; --------------------------------------------------------------------------
    ; Palette 0x08 - Neon: Black bg -> Magenta fg
    ; --------------------------------------------------------------------------
pal_neon:
    .word 0x0000    ; 0:  BG - Black
    .word 0x0801    ; 1:  Gradient
    .word 0x1002    ; 2:  Gradient
    .word 0x1803    ; 3:  Gradient
    .word 0x2004    ; 4:  Gradient
    .word 0x2805    ; 5:  Gradient
    .word 0x3006    ; 6:  Gradient
    .word 0x3807    ; 7:  Gradient
    .word 0x4008    ; 8:  Gradient
    .word 0x480A    ; 9:  Gradient
    .word 0x500C    ; 10: Gradient
    .word 0x580E    ; 11: Gradient
    .word 0x6010    ; 12: Gradient
    .word 0x6814    ; 13: Gradient
    .word 0x7C1F    ; 14: FG - Magenta
    .word 0x03FF    ; 15: Accent - Cyan

    ; --------------------------------------------------------------------------
    ; Palette 0x09 - Ice: Sky Blue bg -> White fg
    ; --------------------------------------------------------------------------
pal_ice:
    .word 0x5EDF    ; 0:  BG - Sky Blue
    .word 0x5EFF    ; 1:  Gradient
    .word 0x631F    ; 2:  Gradient
    .word 0x633F    ; 3:  Gradient
    .word 0x675F    ; 4:  Gradient
    .word 0x677F    ; 5:  Gradient
    .word 0x6B9F    ; 6:  Gradient
    .word 0x6BBF    ; 7:  Gradient
    .word 0x6FDF    ; 8:  Gradient
    .word 0x6FFF    ; 9:  Gradient
    .word 0x741F    ; 10: Gradient
    .word 0x743F    ; 11: Gradient
    .word 0x785F    ; 12: Gradient
    .word 0x7C9F    ; 13: Gradient
    .word 0x7FFF    ; 14: FG - White
    .word 0x001F    ; 15: Accent - Blue

    ; --------------------------------------------------------------------------
    ; Palette 0x0A - Fire: Maroon bg -> Yellow fg
    ; --------------------------------------------------------------------------
pal_fire:
    .word 0x4800    ; 0:  BG - Maroon
    .word 0x4C20    ; 1:  Gradient
    .word 0x5040    ; 2:  Gradient
    .word 0x5460    ; 3:  Gradient
    .word 0x5880    ; 4:  Gradient
    .word 0x5CA0    ; 5:  Gradient
    .word 0x60C0    ; 6:  Gradient
    .word 0x64E0    ; 7:  Gradient
    .word 0x6900    ; 8:  Gradient
    .word 0x6D20    ; 9:  Gradient
    .word 0x7140    ; 10: Gradient
    .word 0x7560    ; 11: Gradient
    .word 0x7980    ; 12: Gradient
    .word 0x7DA0    ; 13: Gradient
    .word 0x7FE0    ; 14: FG - Yellow
    .word 0x001F    ; 15: Accent - Blue

    ; --------------------------------------------------------------------------
    ; Palette 0x0B - Earth: Brown bg -> Gold fg
    ; --------------------------------------------------------------------------
pal_earth:
    .word 0x2940    ; 0:  BG - Brown
    .word 0x2D40    ; 1:  Gradient
    .word 0x3140    ; 2:  Gradient
    .word 0x3540    ; 3:  Gradient
    .word 0x3940    ; 4:  Gradient
    .word 0x3D40    ; 5:  Gradient
    .word 0x4540    ; 6:  Gradient
    .word 0x4940    ; 7:  Gradient
    .word 0x4D40    ; 8:  Gradient
    .word 0x5540    ; 9:  Gradient
    .word 0x5940    ; 10: Gradient
    .word 0x5D40    ; 11: Gradient
    .word 0x6540    ; 12: Gradient
    .word 0x6940    ; 13: Gradient
    .word 0x6F40    ; 14: FG - Gold
    .word 0x03E0    ; 15: Accent - Green

    ; --------------------------------------------------------------------------
    ; Palette 0x0C - Grape: Purple bg -> Pink fg
    ; --------------------------------------------------------------------------
pal_grape:
    .word 0x4010    ; 0:  BG - Purple
    .word 0x4411    ; 1:  Gradient
    .word 0x4812    ; 2:  Gradient
    .word 0x4C13    ; 3:  Gradient
    .word 0x5014    ; 4:  Gradient
    .word 0x5415    ; 5:  Gradient
    .word 0x5816    ; 6:  Gradient
    .word 0x5C17    ; 7:  Gradient
    .word 0x6018    ; 8:  Gradient
    .word 0x6419    ; 9:  Gradient
    .word 0x681A    ; 10: Gradient
    .word 0x6C1B    ; 11: Gradient
    .word 0x701C    ; 12: Gradient
    .word 0x741D    ; 13: Gradient
    .word 0x7E1F    ; 14: FG - Pink
    .word 0x7FE0    ; 15: Accent - Yellow

    ; --------------------------------------------------------------------------
    ; Palette 0x0D - Mint: Dark Green bg -> Cyan fg
    ; --------------------------------------------------------------------------
pal_mint:
    .word 0x0100    ; 0:  BG - Dark Green
    .word 0x0121    ; 1:  Gradient
    .word 0x0142    ; 2:  Gradient
    .word 0x0163    ; 3:  Gradient
    .word 0x0184    ; 4:  Gradient
    .word 0x01A5    ; 5:  Gradient
    .word 0x01C6    ; 6:  Gradient
    .word 0x01E7    ; 7:  Gradient
    .word 0x0228    ; 8:  Gradient
    .word 0x0269    ; 9:  Gradient
    .word 0x02AA    ; 10: Gradient
    .word 0x02EB    ; 11: Gradient
    .word 0x032C    ; 12: Gradient
    .word 0x036D    ; 13: Gradient
    .word 0x03FF    ; 14: FG - Cyan
    .word 0x7C00    ; 15: Accent - Red

    ; --------------------------------------------------------------------------
    ; Palette 0x0E - Steel: Dark Gray bg -> Silver fg
    ; --------------------------------------------------------------------------
pal_steel:
    .word 0x294A    ; 0:  BG - Dark Gray
    .word 0x2D4A    ; 1:  Gradient
    .word 0x314C    ; 2:  Gradient
    .word 0x354E    ; 3:  Gradient
    .word 0x3950    ; 4:  Gradient
    .word 0x3D52    ; 5:  Gradient
    .word 0x4154    ; 6:  Gradient
    .word 0x4556    ; 7:  Gradient
    .word 0x4958    ; 8:  Gradient
    .word 0x4D5A    ; 9:  Gradient
    .word 0x4D6C    ; 10: Gradient
    .word 0x4D7E    ; 11: Gradient
    .word 0x4D90    ; 12: Gradient
    .word 0x5292    ; 13: Gradient
    .word 0x5294    ; 14: FG - Silver
    .word 0x03FF    ; 15: Accent - Cyan

    ; --------------------------------------------------------------------------
    ; Palette 0x0F - Coral Reef: Dark Blue bg -> Coral fg
    ; --------------------------------------------------------------------------
pal_coral:
    .word 0x0008    ; 0:  BG - Dark Blue
    .word 0x0C08    ; 1:  Gradient
    .word 0x1808    ; 2:  Gradient
    .word 0x2408    ; 3:  Gradient
    .word 0x3008    ; 4:  Gradient
    .word 0x3C08    ; 5:  Gradient
    .word 0x4808    ; 6:  Gradient
    .word 0x5408    ; 7:  Gradient
    .word 0x6008    ; 8:  Gradient
    .word 0x6408    ; 9:  Gradient
    .word 0x6808    ; 10: Gradient
    .word 0x6C09    ; 11: Gradient
    .word 0x7009    ; 12: Gradient
    .word 0x7809    ; 13: Gradient
    .word 0x7D0A    ; 14: FG - Coral
    .word 0x03FF    ; 15: Accent - Cyan

; ------------------------------------------------------------------------------
; Rainbow color table (8 colors, cycled for animated rainbow effect)
; Used to replace color 14 (FG) when rainbow mode is selected
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
