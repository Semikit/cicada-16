; ==============================================================================
; mem_layout.asm - Boot Animation memory layout and constants
; ==============================================================================

; ==============================================================================
; HRAM Animation State Variables (0xFE00 - 0xFF6F)
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

.define ANIM_SCROLL_X_L     0xFE0A      ; BG1 scroll X (16-bit)
.define ANIM_SCROLL_X_H     0xFE0B
.define ANIM_SCROLL_Y_L     0xFE0C      ; BG1 scroll Y (16-bit)
.define ANIM_SCROLL_Y_H     0xFE0D
.define ANIM_SCROLL_X_TGT_L 0xFE0E      ; Scroll X target (16-bit)
.define ANIM_SCROLL_X_TGT_H 0xFE0F
.define ANIM_SCROLL_Y_TGT_L 0xFE10      ; Scroll Y target (16-bit)
.define ANIM_SCROLL_Y_TGT_H 0xFE11

.define ANIM_RAINBOW_MODE   0xFE13      ; Rainbow mode flag (0=off, 1=on)
.define ANIM_RAINBOW_IDX    0xFE14      ; Current rainbow color index (0-7)
.define ANIM_RAINBOW_TIMER  0xFE15      ; Rainbow color cycle timer

.define ANIM_PALETTE_PHASE  0xFE16      ; Palette fade phase counter
.define ANIM_FADE_MODE      0xFE17      ; Fade-in source: 0 = from black, 1 = from white

.define ANIM_SCANLINE_EFFECT 0xFE19     ; Active scanline effect (see SCANLINE_* below)
.define ANIM_WAVE_PHASE     0xFE1B      ; Wave animation phase (sine table index)
.define ANIM_EFFECT_PARAM_L 0xFE1C      ; Effect parameter (16-bit): wave = shift count,
.define ANIM_EFFECT_PARAM_H 0xFE1D      ;   scale = K in 8.4 fixed point (see anim_util.asm)
.define ANIM_EFFECT_TIMER   0xFE1E      ; Generic per-effect countdown timer
.define ANIM_BOUNCE_COUNT   0xFE1F      ; Bounce counter for drop_bounce
.define ANIM_BOUNCE_VEL     0xFE20      ; Current bounce velocity (signed byte)
.define ANIM_LOGO_SHAPE     0xFE21      ; BG_MODE value for BG1 (LOGO_SHAPE_TALL/WIDE)

.define ANIM_PALETTE_PTR    0xFE22      ; ROM address of the active 16-color palette (16-bit)
.define ANIM_SCANLINE_REG   0xFE24      ; Scroll register the LYC ISR writes (SCX1_L or SCY1_L)
.define ANIM_SCANLINE_BASE  0xFE26      ; Base scroll value the scanline table is built around
.define ANIM_SPIN_ANGLE     0xFE28      ; Spin angle, 0-255 = one full turn
.define ANIM_SPIN_STEP      0xFE29      ; Spin angle increment per frame
.define ANIM_SPIN_TURNS     0xFE2A      ; Remaining full turns
.define ANIM_AUDIO_STEP     0xFE2B      ; Boot chime sequencer step (0xFF = silent)
.define ANIM_AUDIO_TIMER    0xFE2C      ; Frames until the next chime step

; Per-scanline scroll table: 160 16-bit entries, one per visible line.
; Entry L is the full scroll value written for scanline L by lyc_isr.
.define ANIM_SCANLINE_TABLE 0xFE30      ; 0xFE30-0xFF6F (320 bytes)

; ==============================================================================
; Animation Constants
; ==============================================================================
.define ENTRANCE_COUNT      12          ; Number of defined entrance animations
.define ENTRANCE_RANDOM_ID  0xFF        ; Header value requesting a random entrance animation
.define PALETTE_COUNT       16          ; Number of curated palettes (0x00-0x0F)
.define PALETTE_SIZE        32          ; Size of each palette in bytes (16 colors * 2 bytes)
.define RAINBOW_DARK_ID     0x10        ; Rainbow animation with black background
.define RAINBOW_LIGHT_ID    0x11        ; Rainbow animation with white background
.define FG_COLOR_INDEX      14          ; Foreground color index in palette
.define FG_COLOR_OFFSET     28          ; Byte offset for FG color (14 * 2)
.define RAINBOW_COLOR_COUNT 8           ; Number of colors in rainbow table
.define RAINBOW_CYCLE_RATE  8           ; Frames between rainbow color changes

; Entrance IDs the engine needs to recognise by value
.define ENTRANCE_FADE_IN_ID    0x05
.define ENTRANCE_FADE_WHITE_ID 0x06

; Audio IDs (cartridge header byte 3)
.define AUDIO_DEFAULT_ID    0x00        ; default boot chime
.define AUDIO_SILENT_ID     0x01        ; no audio
.define AUDIO_RANDOM_ID     0xFF        ; pick one (currently: default chime)

; Scanline effect types (ANIM_SCANLINE_EFFECT)
.define SCANLINE_NONE       0
.define SCANLINE_WAVE_HORZ  1           ; per-line SCX1 offset from sine table
.define SCANLINE_WAVE_VERT  2           ; per-line SCY1 offset from sine table
.define SCANLINE_SCALE      3           ; per-line SCY1 for vertical scaling (zoom / spin)

; ------------------------------------------------------------------------------
; Logo placement
;
; The logo source tilemap (c-16_logo/tilemap_0.bin) is a 32x32 map with the
; "C-16" logo in tile rows 5-13, columns 5-24 (pixels x 40-199, y 40-111,
; centre (120, 76)). It is always DMAed into VRAM slot 3. BG1 uses slots 2-3:
;
;   TALL (32x64, 256x512 px): slot 3 is rows 32-63, logo centre = (120, 332)
;   WIDE (64x32, 512x256 px): slot 3 is cols 32-63, logo centre = (376, 76)
;
; Scroll values wrap to the map size, so a single pair of constants centres
; the logo on the 240x160 screen (screen centre (120, 80)) in both shapes:
;   X = 256: tall 256 mod 256 = 0 = 120-120;  wide 256 = 376-120
;   Y = 252: tall 252 = 332-80;              wide 252 mod 256 = -4 = 76-80
; ------------------------------------------------------------------------------
.define LOGO_SLOT           3           ; VRAM slot holding the logo tilemap
.define LOGO_MIRROR_SLOT    2           ; VRAM slot for the vertically mirrored copy (spin)
.define LOGO_MIRROR_SLOT_ADDR 0xA000    ; CPU address of slot 2 (VRAM window + 2 * 2 KiB)
.define LOGO_CENTER_X       256         ; X scroll for centered logo (both shapes)
.define LOGO_CENTER_Y       252         ; Y scroll for centered logo (both shapes)
.define LOGO_MIRROR_Y       100         ; Y scroll centering the mirrored logo (tall shape)
.define SLIDE_DIST_Y        116         ; vertical offset that puts the logo fully off-screen
.define SLIDE_DIST_X        200         ; horizontal offset that puts the logo fully off-screen

.define LOGO_SHAPE_WIDE     0x4         ; BG_MODE: BG1 = 64x32 (bits 3-2 = 01)
.define LOGO_SHAPE_TALL     0x8         ; BG_MODE: BG1 = 32x64 (bits 3-2 = 10)

.define PHASE_ENTRY         0           ; Logo entry phase
.define PHASE_DISPLAY       1           ; Logo display phase
.define PHASE_EXIT          2           ; Logo exit phase

.define DISPLAY_DURATION    60          ; Frames to hold logo (1 second at 60fps)
.define FADE_STEPS          24          ; Frames for fade effects (one step every 4 frames)

.define WAVE_SHIFT_START    3           ; sine >> 3 = +/-16 px
.define WAVE_SHIFT_END      7           ; sine >> 7 = +/-1 px, then stop
.define WAVE_STEP_FRAMES    12          ; frames per amplitude step

.define ZOOM_K_START        112         ; 8.4 fixed: 1/scale - 1 = 7.0 (logo 1/8 height)
.define SCALE_CLAMP         40          ; |offset| beyond this (logo half height + 4) shows a blank row
.define SCALE_CLAMP_RANGE   81          ; 2 * SCALE_CLAMP + 1
.define SCALE_BLANK_ROW     8           ; map row that is blank in every layout (SCALE_BLANK_ROW - 160 = -152)
.define SPIN_STEP_START     8           ; angle units per frame on the first turn
.define SPIN_TURNS          2           ; full turns before settling

; System Library sine table pointer (vector 0x01)
.define SYSLIB_SINE_PTR     0xE002
