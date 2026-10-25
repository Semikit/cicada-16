# Boot Animation Engine Design

This document outlines the structure and operation of the lightweight animation engine used for the Cicada-16 boot animation. The engine is designed to be minimal and efficient, operating entirely within the boot ROM's constrained environment.

## Overview

The boot animation displays a logo on the BG0 tilemap layer and animates it using:
- **Scroll animation**: Moving the BG0 layer using SCY0/SCX0 registers
- **Color animation**: Modifying tile palettes in CRAM
- **Scanline effects**: Using LYC interrupts to apply per-scanline SCY modifications

The engine does **not** use sprites, BG1, or the window layer.

## Cartridge Animation ID System

The boot ROM reads a 4-byte **Animation ID** from the cartridge header to customize the boot animation. During boot, cartridge ROM Bank 0 is mapped to `0x4000-0x7FFF`, so these bytes are read from `0x4000-0x4003`.

### Animation ID Format (Cartridge Header 0x0000-0x0003)

| Offset | Name | Description |
|--------|------|-------------|
| 0x0000 | `ANIM_ENTRANCE` | Entrance animation effect ID |
| 0x0001 | `ANIM_BG_COLOR` | Background color ID (0xFF = animated rainbow) |
| 0x0002 | `ANIM_LOGO_COLOR` | Logo/text color ID (0xFF = animated rainbow) |
| 0x0003 | `ANIM_AUDIO` | Boot audio ID (reserved for future use) |

### Entrance Animation Table (Byte 0x0000)

| ID | Name | Description |
|----|------|-------------|
| 0x00 | `ENTRANCE_NONE` | No animation, logo appears instantly centered |
| 0x01 | `ENTRANCE_SLIDE_DOWN` | Logo slides in from top of screen |
| 0x02 | `ENTRANCE_SLIDE_UP` | Logo slides in from bottom of screen |
| 0x03 | `ENTRANCE_SLIDE_LEFT` | Logo slides in from right side |
| 0x04 | `ENTRANCE_SLIDE_RIGHT` | Logo slides in from left side |
| 0x05 | `ENTRANCE_FADE_IN` | Logo fades in from black (palette animation) |
| 0x06 | `ENTRANCE_FADE_WHITE` | Logo fades in from white |
| 0x07 | `ENTRANCE_WAVE_HORZ` | Logo appears with horizontal scanline wave effect |
| 0x08 | `ENTRANCE_WAVE_VERT` | Logo appears with vertical wave distortion |
| 0x09 | `ENTRANCE_ZOOM_IN` | Simulated zoom using palette/tile tricks |
| 0x0A | `ENTRANCE_DROP_BOUNCE` | Logo drops from top and bounces |
| 0x0B | `ENTRANCE_SPIN_IN` | Logo spins in using scroll manipulation |
| 0x0C-0xFE | Reserved | Reserved for future entrance effects |
| 0xFF | `ENTRANCE_RANDOM` | Randomly select an entrance animation |

### Background Color Table (Byte 0x0001)

The background color is applied to palette index 0 of sub-palette 0 (BG0's backdrop color).

- **IDs 0x00-0x0F**: 16 predefined colors (see `bg_color_table` in Color Lookup Tables section)
- **IDs 0x10-0xFE**: Reserved for additional colors
- **ID 0xFF**: `BG_RAINBOW` - Cycles through rainbow colors

### Logo/Text Color Table (Byte 0x0002)

The logo color is applied to the primary text color indices in sub-palette 0 (typically indices 1-3).

- **IDs 0x00-0x0F**: 16 predefined colors (see `logo_color_table` in Color Lookup Tables section)
- **IDs 0x10-0xFE**: Reserved for additional colors
- **ID 0xFF**: `LOGO_RAINBOW` - Cycles through rainbow colors

### Audio ID (Byte 0x0003) - Reserved

| ID | Name | Description |
|----|------|-------------|
| 0x00 | `AUDIO_DEFAULT` | Default boot chime |
| 0x01 | `AUDIO_SILENT` | No audio |
| 0x02-0xFE | Reserved | Reserved for future audio effects |
| 0xFF | `AUDIO_RANDOM` | Randomly select boot audio |

### Rainbow Animation

When `BG_RAINBOW` (0xFF) or `LOGO_RAINBOW` (0xFF) is selected, the engine applies a cycling color effect:

```asm
; Rainbow color table (8 colors, cycled every 8 frames)
rainbow_colors:
    .word 0x7C00  ; Red
    .word 0x7E00  ; Orange
    .word 0x7FE0  ; Yellow
    .word 0x03E0  ; Green
    .word 0x03FF  ; Cyan
    .word 0x001F  ; Blue
    .word 0x4010  ; Indigo
    .word 0x7C1F  ; Violet

; Apply rainbow effect
apply_rainbow:
    ; Get current frame
    LD R0, (anim_frame)
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
```

## Hardware Registers Used

### PPU Control Registers

| Address | Register | Purpose |
|---------|----------|---------|
| F040 | LCDC | Enable PPU (bit 7), BG0 (bit 4) |
| F041 | STAT | LYC interrupt enable (bit 6), H-Blank interrupt enable (bit 3) |
| F042 | SCY0 | BG0 vertical scroll position |
| F043 | SCX0 | BG0 horizontal scroll position |
| F048 | LY | Current scanline (read-only, 0-215) |
| F049 | LYC | LY compare value for interrupt triggering |
| F04A | BG_MODE | BG0 tilemap size (bits 1-0) |
| F04B | BG_TMB | BG0 tilemap base slot in VRAM (bits 3-0) |

### Interrupt Registers

| Address | Register | Purpose |
|---------|----------|---------|
| F020 | IE | Interrupt enable (V-Blank=bit 0, H-Blank=bit 1, LYC=bit 2) |
| F021 | IF | Interrupt flags (must be cleared in ISR) |

### Memory Regions

| Address Range | Region | Purpose |
|---------------|--------|---------|
| 9000-AFFF | VRAM | Tile graphics and tilemap data |
| F200-F3FF | CRAM | 256 color palette entries (16 sub-palettes x 16 colors) |
| FE00-FFFF | HRAM | Animation state variables and scratch space |

## Memory Layout

### HRAM Animation State (FE00-FE4F)

The animation engine maintains its state in HRAM for fast access:

```
; Animation ID values (read from cartridge header)
FE00:      entrance_id     - Entrance animation ID (from cart 0x0000)
FE01:      bg_color_id     - Background color ID (from cart 0x0001)
FE02:      logo_color_id   - Logo color ID (from cart 0x0002)
FE03:      audio_id        - Audio ID (from cart 0x0003)

; Animation state
FE04-FE05: anim_frame      - Current animation frame counter (16-bit)
FE06:      anim_phase      - Current animation phase (0=entry, 1=display, 2=exit)
FE07:      anim_complete   - Animation complete flag
FE08:      vblank_flag     - V-Blank occurred flag

; Scroll state
FE0A-FE0B: scroll_x        - Current X scroll position (16-bit for sub-pixel)
FE0C-FE0D: scroll_y        - Current Y scroll position (16-bit for sub-pixel)
FE0E-FE0F: scroll_x_target - X scroll target position
FE10-FE11: scroll_y_target - Y scroll target position
FE12-FE13: scroll_x_vel    - X scroll velocity (signed 16-bit)
FE14-FE15: scroll_y_vel    - Y scroll velocity (signed 16-bit)

; Palette animation state
FE16:      palette_phase   - Current palette fade/cycle phase (0-255)
FE17:      bg_rainbow_idx  - Background rainbow color index
FE18:      logo_rainbow_idx - Logo rainbow color index

; Scanline effect state
FE19:      scanline_effect - Active scanline effect type
FE1A:      scanline_index  - Current scanline in effect table
FE1B:      wave_phase      - Wave animation phase (for wave effects)
FE1C-FE1D: effect_param    - Effect-specific parameter

; Entrance-specific state
FE1E:      bounce_count    - Bounce counter for drop_bounce effect
FE1F:      bounce_vel      - Current bounce velocity

; Scanline offset table (for wave/distortion effects)
FE20-FE4F: scanline_table  - Per-scanline SCY offset table (48 bytes)
```

### VRAM Layout

```
Slot 0-3 (0x0000-0x1FFF): Tile graphics (boot logo tiles)
Slot 4   (0x2000-0x27FF): BG0 tilemap (32x32 tiles = 2 KiB)
```

## Animation Engine Architecture

### Core Components

```
+------------------+
|   Main Loop      |  Runs during boot, calls animation_tick() each V-Blank
+--------+---------+
         |
         v
+------------------+
| animation_tick() |  Called once per frame (~60 Hz)
+--------+---------+
         |
    +----+----+
    |         |
    v         v
+-------+  +--------+
| State |  | Effect |
| Update|  | Apply  |
+-------+  +--------+
    |         |
    +----+----+
         |
         v
+------------------+
|   Render Phase   |  Updates PPU registers during safe periods
+------------------+
```

### Interrupt Service Routines

The boot ROM's internal vector table (at 0x3FE0) points to ISRs within the boot ROM:

1. **V-Blank ISR**: Signals frame completion, updates scroll registers
2. **H-Blank ISR**: (Optional) Updates per-scanline effects
3. **LYC ISR**: Triggers at specific scanlines for raster effects

## Animation Phases

The boot animation progresses through distinct phases. Note that initialization (loading tiles, tilemap, palette) happens *before* the phase loop begins in `run_boot_animation`.

### Phase 0: Logo Entry
- Animate logo sliding/floating into view
- Apply easing function to scroll values
- Optional: Wave/wobble effect using scanline interrupts
- Transitions to Phase 1 when entrance animation completes

### Phase 1: Logo Display
- Logo holds in center position
- Color cycling or shimmer effect on palette
- Optional: Subtle idle animation
- Transitions to Phase 2 after display duration

### Phase 2: Logo Exit
- Fade to white or black via palette animation
- Prepare for cartridge handoff
- Sets `anim_complete` flag when finished

## Scroll Animation System

### Basic Scroll Update

Each frame, the scroll position is updated based on velocity:

```asm
; Update scroll position
LD R0, (scroll_x)        ; Load current X position
LD R1, (scroll_x_vel)    ; Load X velocity
ADD R0, R1               ; Add velocity
ST (scroll_x), R0        ; Store new position
ST.b (SCX0), R0          ; Apply to hardware register

LD R0, (scroll_y)        ; Same for Y
LD R1, (scroll_y_vel)
ADD R0, R1
ST (scroll_y), R0
ST.b (SCY0), R0
```

### Easing Functions

For smooth animation, apply easing to velocity/position changes:

**Linear interpolation (LERP):**
```
new_pos = current_pos + (target_pos - current_pos) / factor
```

**Implementation approach:**
```asm
; Simple LERP: move 1/8 of distance each frame
LD R0, (scroll_y)        ; Current position
LD R1, (scroll_y_target) ; Target position
SUB R1, R0               ; R1 = distance remaining
SRA R1                   ; R1 = distance / 2
SRA R1                   ; R1 = distance / 4
SRA R1                   ; R1 = distance / 8
ADD R0, R1               ; Apply fraction of distance
ST (scroll_y), R0
```

## Scanline Effect System

The LYC interrupt allows modifying SCY0 at specific scanlines, creating visual effects like:

- **Wave distortion**: Apply sine-wave offset to each scanline
- **Split-screen**: Different scroll positions for top/bottom
- **Parallax bands**: Multiple scroll rates within the frame

### LYC Interrupt Flow

```
1. Set LYC to target scanline
2. Enable LYC interrupt in IE
3. When LY == LYC, ISR fires
4. ISR modifies SCY0 for current scanline
5. ISR sets LYC to next target scanline
6. ISR clears IF bit 2
7. Return from interrupt
```

### Scanline Table Approach

For complex effects, pre-compute a table of SCY offsets:

```asm
; In V-Blank: reset scanline pointer
LDI R0, 0
ST.b (scanline_index), R0
LDI R0, 0                ; First LYC target
ST.b (LYC), R0

; In LYC ISR:
lyc_isr:
    ; Get current scanline index
    LD.b R0, (scanline_index)

    ; Look up SCY offset from table
    LDI R1, scanline_table
    ADD R1, R0
    LD.b R2, (R1)

    ; Apply to base scroll
    LD.b R3, (scroll_y_base)
    ADD R3, R2
    ST.b (SCY0), R3

    ; Advance to next scanline
    INC R0
    ST.b (scanline_index), R0

    ; Set next LYC
    ST.b (LYC), R0

    ; Clear interrupt flag
    LDI R0, 0x04
    ST.b (IF), R0

    RETI
```

## Palette Animation System

### Color Format

CRAM stores colors in RGB555 format (16-bit):
```
Bit 15:    Unused
Bits 14-10: Red   (0-31)
Bits 9-5:   Green (0-31)
Bits 4-0:   Blue  (0-31)
```

### Fade Effect

Fade from black by incrementing RGB components each frame:

```asm
; Increment all palette entries toward target
fade_palette:
    LDI R3, CRAM_START       ; R3 = current CRAM address
    LDI R4, target_palette   ; R4 = target color address
    LDI R5, 16               ; R5 = number of colors to process

.loop:
    LD R0, (R3)              ; Current color
    LD R1, (R4)              ; Target color

    ; Compare and increment each component
    CALL increment_color     ; R0 = adjusted color

    ST (R3), R0              ; Write back

    ADDI R3, 2               ; Next CRAM entry
    ADDI R4, 2               ; Next target entry
    DEC R5
    JRNZ .loop

    RET
```

### Color Cycling

Rotate palette entries for shimmer/glow effects:

```asm
; Rotate colors in palette range [start, end)
cycle_palette:
    ; Save first color
    LD R0, (palette_start)
    PUSH R0

    ; Shift all colors down
    LDI R1, palette_start
    LDI R2, palette_start
    ADDI R2, 2               ; R2 = source (start + 1)
    LDI R3, cycle_count

.shift_loop:
    LD R0, (R2)
    ST (R1), R0
    ADDI R1, 2
    ADDI R2, 2
    DEC R3
    JRNZ .shift_loop

    ; Put saved color at end
    POP R0
    ST (R1), R0

    RET
```

### DMA-Based Palette Update

For bulk palette changes, use DMA Mode 3:

```asm
; Copy new palette via DMA
; R0 = source address
; R1 = starting palette index
; R2 = number of entries
dma_palette:
    ST (DMA_SRC_L), R0       ; Set source
    ST.b (DMA_DST_L), R1     ; Set palette index
    ST (DMA_LEN_L), R2       ; Set entry count

    ; Mode 3 + VRAM_SAFE + START
    LDI R0, 0x1D             ; 0b00011101
    ST.b (DMA_CTL), R0

    RET
```

## Main Animation Loop

### Reading Animation IDs from Cartridge

```asm
; Cartridge header addresses (mapped during boot)
.define CART_ANIM_ENTRANCE  0x4000  ; Entrance animation ID
.define CART_ANIM_BG_COLOR  0x4001  ; Background color ID
.define CART_ANIM_LOGO_CLR  0x4002  ; Logo color ID
.define CART_ANIM_AUDIO     0x4003  ; Audio ID

; HRAM state addresses
.define entrance_id         0xFE00
.define bg_color_id         0xFE01
.define logo_color_id       0xFE02
.define audio_id            0xFE03

; Read animation IDs from cartridge header
read_animation_ids:
    ; Read entrance animation ID
    LD.b R0, (CART_ANIM_ENTRANCE)
    ST.b (entrance_id), R0

    ; Read background color ID
    LD.b R0, (CART_ANIM_BG_COLOR)
    ST.b (bg_color_id), R0

    ; Read logo color ID
    LD.b R0, (CART_ANIM_LOGO_CLR)
    ST.b (logo_color_id), R0

    ; Read audio ID
    LD.b R0, (CART_ANIM_AUDIO)
    ST.b (audio_id), R0

    RET
```

### Entrance Animation Dispatch

```asm
; Entrance animation function pointer table
entrance_table:
    .word entrance_none         ; 0x00 - No animation
    .word entrance_slide_down   ; 0x01 - Slide from top
    .word entrance_slide_up     ; 0x02 - Slide from bottom
    .word entrance_slide_left   ; 0x03 - Slide from right
    .word entrance_slide_right  ; 0x04 - Slide from left
    .word entrance_fade_in      ; 0x05 - Fade from black
    .word entrance_fade_white   ; 0x06 - Fade from white
    .word entrance_wave_horz    ; 0x07 - Horizontal wave
    .word entrance_wave_vert    ; 0x08 - Vertical wave
    .word entrance_zoom_in      ; 0x09 - Zoom in effect
    .word entrance_drop_bounce  ; 0x0A - Drop and bounce
    .word entrance_spin_in      ; 0x0B - Spin in
entrance_table_end:

.define ENTRANCE_COUNT 12       ; Number of defined entrance animations

; Initialize entrance animation based on ID
init_entrance_animation:
    LD.b R0, (entrance_id)

    ; Check for random selection (0xFF)
    CMPI R0, 0xFF
    JRNZ .not_random
    ; Get pseudo-random value from DIV register
    LD.b R0, (DIV0)
    ANDI R0, 0x0F              ; Limit to 0-15 range
    ; Clamp to valid entrance range
.clamp_loop:
    CMPI R0, ENTRANCE_COUNT
    JRC .not_random            ; If < ENTRANCE_COUNT, we're good
    SUBI R0, ENTRANCE_COUNT    ; Otherwise subtract and try again
    JMP .clamp_loop

.not_random:
    ; Validate ID is in range
    CMPI R0, ENTRANCE_COUNT
    JRC .valid_id
    ; Invalid ID - default to none
    LDI R0, 0

.valid_id:
    ; Look up function pointer: table_base + (id * 2)
    SHL R0                     ; R0 = R0 * 2 (word offset)
    LDI R1, entrance_table
    ADD R1, R0                 ; R1 = table entry address
    LD R2, (R1)                ; R2 = function pointer

    ; Store for later dispatch
    ST (entrance_func_ptr), R2

    ; Call entrance-specific setup
    CALL (R2)                  ; Initial setup call

    RET
```

### Color Lookup Tables

```asm
; Background color lookup table (RGB555 values)
; ID 0xFF is handled separately as animated rainbow
bg_color_table:
    .word 0x0000  ; 0x00 - BG_BLACK
    .word 0x7FFF  ; 0x01 - BG_WHITE
    .word 0x294A  ; 0x02 - BG_DARK_GRAY
    .word 0x56B5  ; 0x03 - BG_LIGHT_GRAY
    .word 0x0008  ; 0x04 - BG_DARK_BLUE
    .word 0x0010  ; 0x05 - BG_NAVY
    .word 0x2D7F  ; 0x06 - BG_ROYAL_BLUE
    .word 0x5EDF  ; 0x07 - BG_SKY_BLUE
    .word 0x0100  ; 0x08 - BG_DARK_GREEN
    .word 0x0280  ; 0x09 - BG_FOREST
    .word 0x4000  ; 0x0A - BG_DARK_RED
    .word 0x4800  ; 0x0B - BG_MAROON
    .word 0x4010  ; 0x0C - BG_PURPLE
    .word 0x2008  ; 0x0D - BG_DARK_PURPLE
    .word 0x5E00  ; 0x0E - BG_ORANGE
    .word 0x2940  ; 0x0F - BG_BROWN
bg_color_table_end:

.define BG_COLOR_COUNT 16

; Logo color lookup table (RGB555 values)
; ID 0xFF is handled separately as animated rainbow
logo_color_table:
    .word 0x7FFF  ; 0x00 - LOGO_WHITE
    .word 0x0000  ; 0x01 - LOGO_BLACK
    .word 0x4210  ; 0x02 - LOGO_GRAY
    .word 0x7C00  ; 0x03 - LOGO_RED
    .word 0x03E0  ; 0x04 - LOGO_GREEN
    .word 0x001F  ; 0x05 - LOGO_BLUE
    .word 0x7FE0  ; 0x06 - LOGO_YELLOW
    .word 0x03FF  ; 0x07 - LOGO_CYAN
    .word 0x7C1F  ; 0x08 - LOGO_MAGENTA
    .word 0x7E00  ; 0x09 - LOGO_ORANGE
    .word 0x7E1F  ; 0x0A - LOGO_PINK
    .word 0x47E0  ; 0x0B - LOGO_LIME
    .word 0x6F40  ; 0x0C - LOGO_GOLD
    .word 0x5294  ; 0x0D - LOGO_SILVER
    .word 0x0210  ; 0x0E - LOGO_TEAL
    .word 0x7D0A  ; 0x0F - LOGO_CORAL
logo_color_table_end:

.define LOGO_COLOR_COUNT 16

; Look up background color from ID
; Input: R0 = color ID
; Output: R0 = RGB555 color value
; Clobbers: R1
get_bg_color:
    ; Check for rainbow (0xFF)
    CMPI R0, 0xFF
    JRNZ .not_rainbow
    CALL apply_rainbow
    RET

.not_rainbow:
    ; Validate ID is in range
    CMPI R0, BG_COLOR_COUNT
    JRC .valid
    LDI R0, 0                  ; Default to black

.valid:
    SHL R0                     ; Word offset
    LDI R1, bg_color_table
    ADD R1, R0
    LD R0, (R1)
    RET

; Look up logo color from ID (same pattern as bg color)
; Input: R0 = color ID
; Output: R0 = RGB555 color value
get_logo_color:
    CMPI R0, 0xFF
    JRNZ .not_rainbow
    CALL apply_rainbow
    RET

.not_rainbow:
    CMPI R0, LOGO_COLOR_COUNT
    JRC .valid
    LDI R0, 0                  ; Default to white (index 0)

.valid:
    SHL R0
    LDI R1, logo_color_table
    ADD R1, R0
    LD R0, (R1)
    RET
```

### Main Animation Entry Point

```asm
; Animation entry point (called from boot main)
run_boot_animation:
    ; Read animation configuration from cartridge header
    CALL read_animation_ids

    ; Initialize animation state
    CALL init_animation

    ; Set up colors based on IDs
    CALL init_colors

    ; Initialize entrance animation based on ID
    CALL init_entrance_animation

    ; Load graphics data
    CALL load_logo_tiles
    CALL load_logo_tilemap

    ; Enable PPU with BG0 only
    LDI R0, 0x90             ; PPU enable + BG0 enable
    ST.b (LCDC), R0

    ; Enable V-Blank interrupt (and LYC if using scanline effects)
    LD.b R0, (scanline_effect)
    CMPI R0, 0
    JRZ .no_lyc
    LDI R0, 0x05             ; V-Blank + LYC
    JMP .set_ie
.no_lyc:
    LDI R0, 0x01             ; V-Blank only
.set_ie:
    ST.b (IE), R0
    EI

    ; Animation loop
.anim_loop:
    HALT                     ; Wait for V-Blank interrupt

    ; V-Blank ISR sets vblank_flag
    LD.b R0, (vblank_flag)
    CMPI R0, 0
    JRZ .anim_loop           ; No V-Blank yet, keep waiting

    ; Clear flag
    LDI R0, 0
    ST.b (vblank_flag), R0

    ; Run animation tick
    CALL animation_tick

    ; Check if animation complete
    LD.b R0, (anim_complete)
    CMPI R0, 0
    JRZ .anim_loop

    ; Cleanup
    DI
    RET

; Initialize palette colors based on animation IDs
init_colors:
    ; Set background color (CRAM index 0)
    LD.b R0, (bg_color_id)
    CALL get_bg_color
    LDI R1, CRAM_START
    ST (R1), R0

    ; Set logo colors (CRAM indices 1-3)
    LD.b R0, (logo_color_id)
    CALL get_logo_color
    LDI R1, CRAM_START
    ADDI R1, 2               ; Index 1
    ST (R1), R0
    ; Can set additional shades for indices 2, 3 based on logo color

    RET

; Called once per frame
animation_tick:
    ; Increment frame counter
    LD R0, (anim_frame)
    INC R0
    ST (anim_frame), R0

    ; Update rainbow colors if enabled
    CALL update_rainbow_colors

    ; Dispatch based on current phase
    LD.b R0, (anim_phase)

    CMPI R0, 0
    JRZ .phase_entry
    CMPI R0, 1
    JRZ .phase_display
    CMPI R0, 2
    JRZ .phase_exit

    ; Unknown phase - mark complete
    JMP .mark_complete

.phase_entry:
    CALL animate_logo_entry
    RET

.phase_display:
    CALL animate_logo_display
    RET

.phase_exit:
    CALL animate_logo_exit
    RET

.mark_complete:
    LDI R0, 1
    ST.b (anim_complete), R0
    RET

; Update rainbow colors each frame if enabled
update_rainbow_colors:
    ; Check background rainbow
    LD.b R0, (bg_color_id)
    CMPI R0, 0xFF
    JRNZ .check_logo

    ; Apply rainbow to background
    CALL apply_rainbow
    LDI R1, CRAM_START
    ST (R1), R0

.check_logo:
    ; Check logo rainbow
    LD.b R0, (logo_color_id)
    CMPI R0, 0xFF
    JRNZ .done

    ; Apply rainbow to logo (offset by a few indices for effect)
    LD R0, (anim_frame)
    ADDI R0, 16              ; Offset from background rainbow
    SRA R0
    SRA R0
    SRA R0
    ANDI R0, 0x07
    SHL R0
    LDI R1, rainbow_colors
    ADD R1, R0
    LD R0, (R1)

    ; Write to logo color indices
    LDI R1, CRAM_START
    ADDI R1, 2
    ST (R1), R0

.done:
    RET
```

## V-Blank ISR Implementation

```asm
; V-Blank interrupt service routine
vblank_isr:
    ; Save registers
    PUSH R0

    ; Set V-Blank flag for main loop
    LDI R0, 1
    ST.b (vblank_flag), R0

    ; Apply scroll values to hardware
    LD.b R0, (scroll_x)
    ST.b (SCX0), R0
    LD.b R0, (scroll_y)
    ST.b (SCY0), R0

    ; Reset scanline effect state for new frame
    LDI R0, 0
    ST.b (scanline_index), R0
    ST.b (LYC), R0           ; First LYC at scanline 0

    ; Clear V-Blank interrupt flag
    LDI R0, 0x01
    ST.b (IF), R0

    ; Restore registers
    POP R0
    RETI
```

## Timing Constraints

### V-Blank Window
- Duration: 56 scanlines x 1300 cycles = 72,800 cycles
- Safe for: Bulk VRAM/CRAM/OAM updates, scroll register changes

### H-Blank Window
- Duration: 180 cycles per scanline
- Safe for: Single register writes, quick palette changes

### Cycle Budget per Frame
- Total: 280,800 cycles per frame
- Animation logic: Should complete well within V-Blank
- Target: < 30,000 cycles for animation_tick()

## Integration with Boot Sequence

The animation engine integrates into the boot sequence at step 3 (Display Boot Animation):

```asm
; In main.asm, after hardware init and syslib DMA:

    ; TODO: run boot animation and sound
    CALL run_boot_animation

    ; Continue with cartridge verification and handoff...
```

## Entrance Animation Implementations

Each entrance animation function is called during setup to configure initial state, and then called each frame during the entry phase to update the animation.

### Slide Animations

```asm
; Screen dimensions for positioning
.define SCREEN_W 240
.define SCREEN_H 160
.define LOGO_CENTER_X 0     ; X scroll for centered logo
.define LOGO_CENTER_Y 0     ; Y scroll for centered logo

; Slide from top (logo starts above screen, slides down)
entrance_slide_down:
    ; Initial setup - position logo off-screen above
    LDI R0, 0xFF00           ; Large negative Y (wraps to below visible)
    ST (scroll_y), R0
    LDI R0, LOGO_CENTER_X
    ST (scroll_x), R0
    ; Set target
    LDI R0, LOGO_CENTER_Y
    ST (scroll_y_target), R0
    ; Set velocity (positive = moving down in scroll space)
    LDI R0, 0x0300           ; Speed factor
    ST (scroll_y_vel), R0
    RET

entrance_slide_down_tick:
    ; LERP toward target
    LD R0, (scroll_y)
    LD R1, (scroll_y_target)
    SUB R1, R0               ; Distance remaining
    ; Check if close enough to snap
    CMPI R1, 2
    JRC .done
    CMPI R1, 0xFFFE          ; Check negative side too
    JRNC .done
    ; Move 1/8 of remaining distance
    SRA R1
    SRA R1
    SRA R1
    ; Ensure minimum movement of 1
    CMPI R1, 0
    JRNZ .apply
    LDI R1, 1
.apply:
    ADD R0, R1
    ST (scroll_y), R0
    RET
.done:
    ; Snap to target and advance phase
    LD R0, (scroll_y_target)
    ST (scroll_y), R0
    LDI R0, 1                ; Phase 1: display
    ST.b (anim_phase), R0
    RET

; Slide from bottom (logo starts below screen, slides up)
entrance_slide_up:
    LDI R0, 0x00A0           ; Start below visible area
    ST (scroll_y), R0
    LDI R0, LOGO_CENTER_X
    ST (scroll_x), R0
    LDI R0, LOGO_CENTER_Y
    ST (scroll_y_target), R0
    RET

; Slide from right (logo starts off-screen right, slides left)
entrance_slide_left:
    LDI R0, LOGO_CENTER_Y
    ST (scroll_y), R0
    LDI R0, 0x00F0           ; Start off-screen right
    ST (scroll_x), R0
    LDI R0, LOGO_CENTER_X
    ST (scroll_x_target), R0
    RET

; Slide from left (logo starts off-screen left, slides right)
entrance_slide_right:
    LDI R0, LOGO_CENTER_Y
    ST (scroll_y), R0
    LDI R0, 0xFF10           ; Start off-screen left (negative)
    ST (scroll_x), R0
    LDI R0, LOGO_CENTER_X
    ST (scroll_x_target), R0
    RET
```

### Fade Animations

```asm
; Fade in from black
entrance_fade_in:
    ; Position logo centered immediately
    LDI R0, LOGO_CENTER_X
    ST (scroll_x), R0
    LDI R0, LOGO_CENTER_Y
    ST (scroll_y), R0
    ; Set all palette entries to black
    LDI R0, 0
    ST.b (palette_phase), R0
    ; Initialize palette to all black
    CALL set_palette_black
    RET

entrance_fade_in_tick:
    ; Increment palette phase
    LD.b R0, (palette_phase)
    INC R0
    ST.b (palette_phase), R0
    ; Check if fade complete (phase >= 32 for full fade)
    CMPI R0, 32
    JRC .continue
    ; Fade complete - advance to display phase
    LDI R0, 1
    ST.b (anim_phase), R0
    RET
.continue:
    ; Interpolate palette toward target
    CALL fade_palette_step
    RET

; Set all 16 colors in sub-palette 0 to black
set_palette_black:
    LDI R1, CRAM_START
    LDI R2, 16               ; 16 colors
    LDI R0, 0x0000           ; Black
.loop:
    ST (R1), R0
    ADDI R1, 2
    DEC R2
    JRNZ .loop
    RET

; Fade in from white
entrance_fade_white:
    LDI R0, LOGO_CENTER_X
    ST (scroll_x), R0
    LDI R0, LOGO_CENTER_Y
    ST (scroll_y), R0
    LDI R0, 0
    ST.b (palette_phase), R0
    ; Initialize palette to all white
    LDI R1, CRAM_START
    LDI R2, 16
    LDI R0, 0x7FFF           ; White
.loop:
    ST (R1), R0
    ADDI R1, 2
    DEC R2
    JRNZ .loop
    RET
```

### Wave Effects

```asm
; Horizontal scanline wave effect
entrance_wave_horz:
    ; Position logo centered
    LDI R0, LOGO_CENTER_X
    ST (scroll_x), R0
    LDI R0, LOGO_CENTER_Y
    ST (scroll_y), R0
    ; Enable scanline effect
    LDI R0, 1                ; Effect type: horizontal wave
    ST.b (scanline_effect), R0
    ; Initialize wave phase
    LDI R0, 0
    ST.b (wave_phase), R0
    ; Start with high amplitude
    LDI R0, 16
    ST.b (effect_param), R0
    RET

entrance_wave_horz_tick:
    ; Advance wave phase
    LD.b R0, (wave_phase)
    ADDI R0, 4               ; Speed of wave animation
    ST.b (wave_phase), R0
    ; Reduce amplitude over time
    LD.b R1, (effect_param)
    CMPI R1, 0
    JRZ .wave_done
    ; Decrement amplitude every 8 frames
    LD R0, (anim_frame)
    ANDI R0, 0x07
    JRNZ .update_table
    DEC R1
    ST.b (effect_param), R1
.update_table:
    ; Build scanline offset table based on sine wave
    CALL build_wave_table
    RET
.wave_done:
    ; Wave finished - disable scanline effect and advance phase
    LDI R0, 0
    ST.b (scanline_effect), R0
    LDI R0, 1
    ST.b (anim_phase), R0
    RET

; Build wave offset table for LYC ISR
; See build_wave_table implementation in "System Library Resources" section
CALL build_wave_table
```

### Drop and Bounce

```asm
; Drop from top and bounce
entrance_drop_bounce:
    ; Start above screen
    LDI R0, 0xFF00
    ST (scroll_y), R0
    LDI R0, LOGO_CENTER_X
    ST (scroll_x), R0
    ; Initialize bounce state
    LDI R0, 3                ; Number of bounces
    ST.b (bounce_count), R0
    LDI R0, 0                ; Initial velocity (will accelerate)
    ST.b (bounce_vel), R0
    RET

entrance_drop_bounce_tick:
    ; Apply gravity (increase velocity)
    LD.b R0, (bounce_vel)
    ADDI R0, 2               ; Gravity acceleration
    ST.b (bounce_vel), R0
    ; Update position
    LD R1, (scroll_y)
    ADD R1, R0
    ; Check for "ground" (center position)
    LD R2, (scroll_y_target)
    CMP R1, R2
    JRC .no_bounce           ; Haven't hit ground yet
    JRNZ .no_bounce
    ; Hit ground - bounce!
    LD.b R0, (bounce_count)
    CMPI R0, 0
    JRZ .done                ; No more bounces
    DEC R0
    ST.b (bounce_count), R0
    ; Reverse and dampen velocity
    LD.b R0, (bounce_vel)
    NEG
    SRA R0                   ; Reduce by half each bounce
    ST.b (bounce_vel), R0
    ; Snap to ground
    LD R1, (scroll_y_target)
.no_bounce:
    ST (scroll_y), R1
    RET
.done:
    ; Snap to final position
    LD R0, (scroll_y_target)
    ST (scroll_y), R0
    LDI R0, 1
    ST.b (anim_phase), R0
    RET
```

### No Animation (Instant)

```asm
; No animation - logo appears instantly
entrance_none:
    ; Position logo centered immediately
    LDI R0, LOGO_CENTER_X
    ST (scroll_x), R0
    LDI R0, LOGO_CENTER_Y
    ST (scroll_y), R0
    ; Skip directly to display phase
    LDI R0, 1
    ST.b (anim_phase), R0
    RET
```

## Summary of Required Functions

### Core Functions

| Function | Purpose |
|----------|---------|
| `run_boot_animation` | Main animation entry point and loop |
| `read_animation_ids` | Read animation config from cartridge header |
| `init_animation` | Initialize HRAM state variables |
| `init_colors` | Set up palette based on color IDs |
| `init_entrance_animation` | Set up entrance based on entrance ID |
| `animation_tick` | Per-frame animation update dispatcher |
| `update_rainbow_colors` | Update rainbow effect each frame if enabled |

### Graphics Loading

| Function | Purpose |
|----------|---------|
| `load_logo_tiles` | Copy tile graphics to VRAM via DMA |
| `load_logo_tilemap` | Copy tilemap to VRAM via DMA |

### Color Functions

| Function | Purpose |
|----------|---------|
| `get_bg_color` | Look up background color from ID |
| `get_logo_color` | Look up logo color from ID |
| `apply_rainbow` | Get current rainbow color for frame |
| `fade_palette` | Incrementally fade palette toward target |
| `fade_palette_step` | Single step of palette fade |
| `set_palette_black` | Set all palette entries to black |
| `cycle_palette` | Rotate palette entries for shimmer |
| `dma_palette` | Bulk palette update via DMA Mode 3 |

### Entrance Animations

| Function | Purpose |
|----------|---------|
| `entrance_none` | Instant appearance, no animation |
| `entrance_slide_down` | Logo slides in from top |
| `entrance_slide_up` | Logo slides in from bottom |
| `entrance_slide_left` | Logo slides in from right |
| `entrance_slide_right` | Logo slides in from left |
| `entrance_fade_in` | Logo fades in from black |
| `entrance_fade_white` | Logo fades in from white |
| `entrance_wave_horz` | Horizontal scanline wave effect |
| `entrance_wave_vert` | Vertical wave distortion |
| `entrance_zoom_in` | Simulated zoom effect |
| `entrance_drop_bounce` | Drop and bounce animation |
| `entrance_spin_in` | Spinning entrance effect |

### Animation Phase Handlers

| Function | Purpose |
|----------|---------|
| `animate_logo_entry` | Dispatches to current entrance animation tick |
| `animate_logo_display` | Handles display phase (idle effects) |
| `animate_logo_exit` | Handles exit phase (fade out) |

### Interrupt Service Routines

| Function | Purpose |
|----------|---------|
| `vblank_isr` | V-Blank interrupt handler |
| `lyc_isr` | LYC interrupt handler for scanline effects |

### Utility Functions

| Function | Purpose |
|----------|---------|
| `build_wave_table` | Generate scanline offset table for wave effects (uses syslib sine) |
| `get_sine` | Look up sine value from syslib table |
| `get_cosine` | Look up cosine value (sine + 64) |

## Data Requirements

### Logo Assets (to be stored in boot ROM)

1. **Tile graphics**: 4bpp planar format, 32 bytes per tile
2. **Tilemap data**: 16-bit entries, 32x32 or smaller
3. **Target palette**: 16-32 colors (1-2 sub-palettes)

### System Library Resources

The animation engine uses the **sine table from the System Library** rather than including its own copy. Since the boot ROM copies the system library to 0xE000-0xEFFF via DMA Mode 1 *before* the animation engine runs, the sine table is already available in RAM.

#### System Library Pointer Table (0xE000)

| Offset | Content |
|--------|---------|
| +0x00 | Pointer to default font data |
| +0x02 | **Pointer to sine wave table** |
| +0x04 | Pointer to note frequency table |
| +0x06 | Pointer to default APU waves |
| +0x08 | Pointer to APU percussion presets |
| +0x0A | Pointer to initDefaultFont function |

#### Accessing the Sine Table

```asm
.define SYSLIB_BASE       0xE000
.define SYSLIB_SINE_PTR   0xE002  ; Pointer to sine table

; Get sine value for angle
; Input: R0 = angle (0-255, where 256 = full circle)
; Output: R0 = sine value (signed 8-bit or 16-bit depending on table format)
get_sine:
    ; Load pointer to sine table from syslib
    LD R1, (SYSLIB_SINE_PTR)
    ; Add angle offset
    ADD R1, R0
    ; Load sine value
    LD.b R0, (R1)
    RET

; Example: Get cosine (sine + 90 degrees = sine + 64 in 256-degree system)
get_cosine:
    ADDI R0, 64              ; Add 90 degrees (64/256 of circle)
    ANDI R0, 0xFF            ; Wrap to 0-255
    JMP get_sine
```

#### Using Sine Table for Wave Effects

```asm
; Build wave offset table for LYC ISR using syslib sine table
; Generates per-scanline SCY offsets for wave distortion effects
build_wave_table:
    ; Get sine table pointer from syslib
    LD R6, (SYSLIB_SINE_PTR)

    LDI R3, scanline_table   ; Destination
    LDI R4, 0                ; Scanline counter
    LD.b R5, (wave_phase)    ; Current phase

.loop:
    ; Calculate sine index: (phase + scanline * 2) & 0xFF
    LD R0, R4
    SHL R0                   ; Multiply scanline by 2 for wave frequency
    ADD R0, R5               ; Add current phase
    ANDI R0, 0xFF            ; Wrap to table size

    ; Look up sine value
    LD R1, R6
    ADD R1, R0
    LD.b R0, (R1)            ; Get sine value (signed)

    ; Scale by amplitude
    LD.b R2, (effect_param)
    SRA R0                   ; Reduce range
    AND R0, R2               ; Apply amplitude mask

    ; Store offset
    ST.b (R3), R0
    INC R3
    INC R4
    CMPI R4, 48              ; 48 scanlines of table
    JRC .loop
    RET
```

### Estimated Size

- Tile graphics: ~1-2 KiB (32-64 tiles)
- Tilemap: ~256 bytes (16x8 logo area)
- Palette: ~32 bytes (16 colors)
- Animation code: ~512-1024 bytes
- **Total**: ~2-3 KiB (no sine table needed - uses syslib)

This fits comfortably within the boot ROM's available space.
