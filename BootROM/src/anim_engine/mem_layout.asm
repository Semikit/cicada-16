; ==============================================================================
; mem_layout.asm - Boot Animation memory layout and constants
; ==============================================================================

; ==============================================================================
; HRAM Animation State Variables (0xFE00 - 0xFE4F)
; ==============================================================================
.define ANIM_ENTRANCE_ID    0xFE00      ; Entrance animation ID (from cart)
.define ANIM_PALETTE_ID     0xFE01      ; Palette ID (combined bg/logo, from cart)
.define ANIM_RESERVED       0xFE02      ; Reserved (unused)
.define ANIM_AUDIO_ID       0xFE03      ; Audio ID (from cart)

.define ANIM_FRAME_L        0xFE04      ; Frame counter low byte
.define ANIM_FRAME_H        0xFE05      ; Frame counter high byte
.define ANIM_PHASE          0xFE06      ; Current phase (0=entry, 1=display, 2=exit)
.define ANIM_COMPLETE       0xFE07      ; Animation complete flag
.define ANIM_VBLANK_FLAG    0xFE08      ; V-Blank occurred flag

.define ANIM_SCROLL_X_L     0xFE0A      ; Scroll X position low byte
.define ANIM_SCROLL_X_H     0xFE0B      ; Scroll X position high byte
.define ANIM_SCROLL_Y_L     0xFE0C      ; Scroll Y position low byte
.define ANIM_SCROLL_Y_H     0xFE0D      ; Scroll Y position high byte
.define ANIM_SCROLL_X_TGT_L 0xFE0E      ; Scroll X target low byte
.define ANIM_SCROLL_X_TGT_H 0xFE0F      ; Scroll X target high byte
.define ANIM_SCROLL_Y_TGT_L 0xFE10      ; Scroll Y target low byte
.define ANIM_SCROLL_Y_TGT_H 0xFE11      ; Scroll Y target high byte

.define ANIM_PALETTE_IDX    0xFE12      ; Active sub-palette index (0-15)
.define ANIM_RAINBOW_MODE   0xFE13      ; Rainbow mode flag (0=off, 1=on)
.define ANIM_RAINBOW_IDX    0xFE14      ; Current rainbow color index (0-7)
.define ANIM_RAINBOW_TIMER  0xFE15      ; Rainbow color cycle timer

.define ANIM_PALETTE_PHASE  0xFE16      ; Palette fade/cycle phase (0-255)

.define ANIM_SCANLINE_EFFECT 0xFE19     ; Active scanline effect type
.define ANIM_SCANLINE_IDX   0xFE1A      ; Current scanline in effect table
.define ANIM_WAVE_PHASE     0xFE1B      ; Wave animation phase
.define ANIM_EFFECT_PARAM_L 0xFE1C      ; Effect parameter low byte
.define ANIM_EFFECT_PARAM_H 0xFE1D      ; Effect parameter high byte

.define ANIM_BOUNCE_COUNT   0xFE1E      ; Bounce counter for drop_bounce
.define ANIM_BOUNCE_VEL     0xFE1F      ; Current bounce velocity

.define ANIM_LOGO_SLOT      0xFE20      ; VRAM slot to put logo tilemap into
.define ANIM_LOGO_SHAPE     0xFE21      ; shape to set BG1 to (vertical or horizontal)

.define ANIM_SCANLINE_TABLE 0xFE22      ; Scanline offset table (48 bytes)

; ==============================================================================
; Animation Constants
; ==============================================================================
.define ENTRANCE_COUNT      12          ; Number of defined entrance animations
.define PALETTE_COUNT       16          ; Number of curated palettes (0x00-0x0F)
.define PALETTE_SIZE        32          ; Size of each palette in bytes (16 colors * 2 bytes)
.define RAINBOW_DARK_ID     0x10        ; Rainbow animation with black background
.define RAINBOW_LIGHT_ID    0x11        ; Rainbow animation with white background
.define FG_COLOR_INDEX      14          ; Foreground color index in palette
.define FG_COLOR_OFFSET     28          ; Byte offset for FG color (14 * 2)
.define RAINBOW_COLOR_COUNT 8           ; Number of colors in rainbow table
.define RAINBOW_CYCLE_RATE  8           ; Frames between rainbow color changes

; BG1 scroll values to center logo on screen
; Logo is in rows 16-47 of the 32x64 tilemap (pixels 128-383)
; Screen is 240x160, so center is at (120, 80)
; Tilemap pixel 256 is logo center, so scroll Y = 256 - 80 = 176
.define LOGO_CENTER_X       0           ; X scroll for centered logo (unchanged)
.define LOGO_CENTER_Y       176         ; Y scroll for centered logo in 32x64 tilemap

.define PHASE_ENTRY         0           ; Logo entry phase
.define PHASE_DISPLAY       1           ; Logo display phase
.define PHASE_EXIT          2           ; Logo exit phase

.define DISPLAY_DURATION    60          ; Frames to hold logo (1 second at 60fps)
.define FADE_STEPS          24          ; Number of steps for fade effects

; System Library sine table pointer
.define SYSLIB_SINE_PTR     0xE002      ; Pointer to sine table in syslib

.define LOGO_SLOT_A         2
.define LOGO_SLOT_B         3

.define LOGO_SHAPE_WIDE     0x4         ; set BG1 to horizontal (BG_MODE: 0b01)
.define LOGO_SHAPE_TALL     0x8         ; set BG1 to vertical (BG_MODE: 0b10)
