; ==============================================================================
; hardware.asm - Cicada-16 Hardware Address Constants
; ==============================================================================
; This file contains all hardware-mapped I/O register addresses for the
; Cicada-16 system, including PPU, APU, DMA, timers, serial, RTC, and more.
; ==============================================================================

; ==============================================================================
; Memory Map Base Addresses
; ==============================================================================
.define ROM_BANK0_START     0x0000      ; ROM Bank 0 (fixed, 16 KiB)
.define ROM_BANKN_START     0x4000      ; ROM Bank N (switchable, 16 KiB)
.define CART_RAM_START      0x8000      ; Cartridge RAM window (banked, 4 KiB)
.define VRAM_START          0x9000      ; VRAM window (banked, 8 KiB)
.define WRAM0_START         0xB000      ; Work RAM Bank 0 (fixed, 8 KiB)
.define WRAM1_START         0xD000      ; Work RAM window (banked, 4 KiB)
.define SYSLIB_START        0xE000      ; System Library RAM (4 KiB)
.define IO_START            0xF000      ; I/O Registers start
.define CRAM_START          0xF200      ; Color RAM / Palette (512 B)
.define OAM_START           0xF400      ; Object Attribute Memory (512 B)
.define DSP_BUFFER_START    0xF600      ; DSP Delay Buffer (1 KiB)
.define WAVE_RAM_START      0xFA00      ; Wave RAM (1 KiB)
.define HRAM_START          0xFE00      ; High-speed RAM (512 B)

; ==============================================================================
; Serial Communication Registers (0xF000 - 0xF001)
; ==============================================================================
.define SB                  0xF000      ; Serial Buffer (R/W)
.define SC                  0xF001      ; Serial Control (R/W)

; ------------------------------------------------------------------------------
; Serial Control (SC) Bit Flags
; ------------------------------------------------------------------------------
.define SC_START            0x80        ; Bit 7: Start transfer (auto-clears)
.define SC_CONNECTED        0x40        ; Bit 6: Connection status (read-only)
.define SC_SPEED_FAST       0x04        ; Bit 2: Fast transfer (256 Kbps)
.define SC_SPEED_NORMAL     0x00        ; Bit 2: Normal transfer (8 Kbps)
.define SC_CLK_MASTER       0x00        ; Bit 1: Master (internal clock)
.define SC_CLK_SLAVE        0x02        ; Bit 1: Slave (external clock)
.define SC_ENABLE           0x01        ; Bit 0: Serial port enable

; ==============================================================================
; Divider Registers (0xF002 - 0xF005)
; ==============================================================================
.define DIV0                0xF002      ; 32-bit divider byte 0 (LSB)
.define DIV1                0xF003      ; 32-bit divider byte 1
.define DIV2                0xF004      ; 32-bit divider byte 2
.define DIV3                0xF005      ; 32-bit divider byte 3 (MSB)

; ==============================================================================
; Joypad Register (0xF006)
; ==============================================================================
.define JOYPAD              0xF006      ; Joypad input register
.define JOYP                0xF006      ; Alias for JOYPAD

; ==============================================================================
; Timer 0 Registers (0xF007 - 0xF009)
; ==============================================================================
.define TIMA0               0xF007      ; Timer 0 counter (increments at TAC0 rate)
.define TMA0                0xF008      ; Timer 0 modulo (reload value)
.define TAC0                0xF009      ; Timer 0 control register

; ==============================================================================
; DMA Controller Registers (0xF00A - 0xF010)
; ==============================================================================
.define DMA_SRC_L           0xF00A      ; DMA source address low byte
.define DMA_SRC_H           0xF00B      ; DMA source address high byte
.define DMA_DST_L           0xF00C      ; DMA destination address low byte
.define DMA_DST_H           0xF00D      ; DMA destination address high byte
.define DMA_LEN_L           0xF00E      ; DMA transfer length low byte
.define DMA_LEN_H           0xF00F      ; DMA transfer length high byte
.define DMA_CTL             0xF010      ; DMA control register

; ------------------------------------------------------------------------------
; DMA Control Register (DMA_CTL) Bit Flags
; ------------------------------------------------------------------------------
.define DMA_MODE_NORMAL     0x00        ; Mode 0: Normal DMA (bits 5-3)
.define DMA_MODE_SYSLIB     0x08        ; Mode 1: System Library / OAM Scanline
.define DMA_MODE_VRAM       0x10        ; Mode 2: VRAM Slot DMA
.define DMA_MODE_CRAM       0x18        ; Mode 3: CRAM (Palette) DMA
.define DMA_MODE_WAVE       0x20        ; Mode 4: Wave RAM DMA
.define DMA_MODE_DSP        0x28        ; Mode 5: DSP Delay Buffer DMA
.define DMA_MODE_FILL       0x30        ; Mode 6: Fill/Pattern Mode
.define DMA_VRAM_SAFE       0x04        ; Bit 2: Wait for H-Blank/V-Blank
.define DMA_ADDR_DECR       0x02        ; Bit 1: Decrement addresses
.define DMA_ADDR_INCR       0x00        ; Bit 1: Increment addresses
.define DMA_START           0x01        ; Bit 0: Start transfer

; ==============================================================================
; Cartridge Mapper Registers (0xF011 - 0xF015)
; ==============================================================================
.define MPR_BANK            0xF011      ; ROM bank select for 4000-7FFF window
.define RAM_BANK            0xF012      ; Cart RAM bank select
.define WE_LATCH            0xF013      ; Write-enable latch for save RAM
.define VRAM_BANK           0xF014      ; VRAM bank select (0-3)
.define WRAM_BANK           0xF015      ; WRAM bank select (0-5)

; ==============================================================================
; Real-Time Clock Registers (0xF018 - 0xF01F)
; ==============================================================================
.define RTC_SEC             0xF018      ; Seconds (0-59)
.define RTC_MIN             0xF019      ; Minutes (0-59)
.define RTC_HOUR            0xF01A      ; Hours (0-23)
.define RTC_DAY             0xF01B      ; Day of month (1-31)
.define RTC_MONTH           0xF01C      ; Month (1-12)
.define RTC_YEAR_L          0xF01D      ; Year low byte
.define RTC_YEAR_H          0xF01E      ; Year high byte
.define RTC_CTL             0xF01F      ; RTC control register

; ------------------------------------------------------------------------------
; RTC Control (RTC_CTL) Bit Flags
; ------------------------------------------------------------------------------
.define RTC_LATCH           0x02        ; Bit 1: Latch RTC snapshot
.define RTC_HALT            0x01        ; Bit 0: Halt clock

; ==============================================================================
; Interrupt Registers (0xF020 - 0xF022)
; ==============================================================================
.define IE                  0xF020      ; Interrupt enable register
.define IF                  0xF021      ; Interrupt flag register
.define BOOT_CTRL           0xF022      ; Boot control (write 1 to exit boot ROM)

; ==============================================================================
; Timer 1 Registers (0xF023 - 0xF025)
; ==============================================================================
.define TIMA1               0xF023      ; Timer 1 counter (increments at TAC1 rate)
.define TMA1                0xF024      ; Timer 1 modulo (reload value)
.define TAC1                0xF025      ; Timer 1 control register

; ==============================================================================
; System Config (0xF026)
; ==============================================================================
.define SYS_CFG             0xF026      ; System Config flags (bit 7 sets standard/enhanced interrupt mode)

; ------------------------------------------------------------------------------
; Timer Control (TAC0/TAC1) Bit Flags
; ------------------------------------------------------------------------------
.define TAC_ENABLE          0x20        ; Bit 5: Timer enable
.define TAC_CLK_MASK        0x1F        ; Bits 4-0: Clock select (0-31)

; ==============================================================================
; PPU Registers (0xF040 - 0xF07F)
; ==============================================================================
.define LCDC                0xF040      ; LCD Control register
.define STAT                0xF041      ; LCD Status register
.define SCY0_L              0xF042      ; Background 0 vertical scroll
.define SCY0_H              0xF043      ; Background 0 vertical scroll
.define SCX0_L              0xF044      ; Background 0 horizontal scroll
.define SCX0_H              0xF045      ; Background 0 horizontal scroll
.define SCY1_L              0xF046      ; Background 1 vertical scroll
.define SCY1_H              0xF047      ; Background 1 vertical scroll
.define SCX1_L              0xF048      ; Background 1 horizontal scroll
.define SCX1_H              0xF049      ; Background 1 horizontal scroll
.define WINY                0xF04A      ; Window Y position
.define WINX                0xF04B      ; Window X position
.define LY                  0xF04C      ; Current scanline (read-only, 0-215)
.define LYC                 0xF04D      ; LY compare value
.define BG_MODE             0xF04E      ; Background tilemap size mode
.define BG_TMB              0xF04F      ; BG0/BG1 tilemap base slots
.define WIN_TMB             0xF050      ; Window tilemap base slot

; ------------------------------------------------------------------------------
; LCD Control (LCDC) Bit Flags
; ------------------------------------------------------------------------------
.define LCDC_PPU_ENABLE     0x80        ; Bit 7: PPU master enable
.define LCDC_SPR_ENABLE     0x40        ; Bit 6: Sprite enable
.define LCDC_BG1_ENABLE     0x20        ; Bit 5: Background 1 enable
.define LCDC_BG0_ENABLE     0x10        ; Bit 4: Background 0 enable
.define LCDC_WIN_ENABLE     0x01        ; Bit 0: Window layer enable

; ------------------------------------------------------------------------------
; LCD Status (STAT) Bit Flags
; ------------------------------------------------------------------------------
.define STAT_LYC_INT_EN     0x40        ; Bit 6: LY==LYC interrupt enable
.define STAT_VBLK_INT_EN    0x10        ; Bit 4: V-Blank interrupt enable
.define STAT_HBLK_INT_EN    0x08        ; Bit 3: H-Blank interrupt enable
.define STAT_LYC_FLAG       0x04        ; Bit 2: LY==LYC flag (read-only)
.define STAT_MODE_MASK      0x03        ; Bits 1-0: PPU mode (read-only)

; ------------------------------------------------------------------------------
; PPU Mode Values (from STAT register bits 1-0)
; ------------------------------------------------------------------------------
.define PPU_MODE_HBLANK     0x00        ; Mode 0: H-Blank
.define PPU_MODE_VBLANK     0x01        ; Mode 1: V-Blank
.define PPU_MODE_OAM_SCAN   0x02        ; Mode 2: OAM Scan
.define PPU_MODE_DRAWING    0x03        ; Mode 3: Drawing Pixels

; ------------------------------------------------------------------------------
; Background Mode (BG_MODE) Size Values
; ------------------------------------------------------------------------------
; BG0 size (bits 1-0), BG1 size (bits 3-2)
.define BG_SIZE_32x32       0x00        ; 32x32 tiles (256x256 px, 2 KiB)
.define BG_SIZE_64x32       0x01        ; 64x32 tiles (512x256 px, 4 KiB)
.define BG_SIZE_32x64       0x02        ; 32x64 tiles (256x512 px, 4 KiB)
.define BG_SIZE_64x64       0x03        ; 64x64 tiles (512x512 px, 8 KiB)

; ==============================================================================
; APU (Audio Processing Unit) Registers (0xF080 - 0xF0BF)
; ==============================================================================

; ------------------------------------------------------------------------------
; Channel 0 - Pulse Wave A (with sweep capability)
; ------------------------------------------------------------------------------
.define APU_CH0_CTRL        0xF081      ; Channel 0 control register
.define APU_CH0_ADSR_L      0xF082      ; Channel 0 ADSR envelope low byte
.define APU_CH0_ADSR_H      0xF083      ; Channel 0 ADSR envelope high byte
.define APU_CH0_FREQ_L      0xF084      ; Channel 0 frequency low byte
.define APU_CH0_FREQ_H      0xF085      ; Channel 0 frequency high byte
.define APU_CH0_SWEEP       0xF086      ; Channel 0 sweep control

; ------------------------------------------------------------------------------
; Channel 1 - Pulse Wave B
; ------------------------------------------------------------------------------
.define APU_CH1_CTRL        0xF087      ; Channel 1 control register
.define APU_CH1_ADSR_L      0xF088      ; Channel 1 ADSR envelope low byte
.define APU_CH1_ADSR_H      0xF089      ; Channel 1 ADSR envelope high byte
.define APU_CH1_FREQ_L      0xF08A      ; Channel 1 frequency low byte
.define APU_CH1_FREQ_H      0xF08B      ; Channel 1 frequency high byte

; ------------------------------------------------------------------------------
; Channel 2 - Wave Channel (custom waveform)
; ------------------------------------------------------------------------------
.define APU_CH2_CTRL        0xF08D      ; Channel 2 control (bits 5-0 = wave index)
.define APU_CH2_ADSR_L      0xF08E      ; Channel 2 ADSR envelope low byte
.define APU_CH2_ADSR_H      0xF08F      ; Channel 2 ADSR envelope high byte
.define APU_CH2_FREQ_L      0xF090      ; Channel 2 frequency low byte
.define APU_CH2_FREQ_H      0xF091      ; Channel 2 frequency high byte

; ------------------------------------------------------------------------------
; Channel 3 - Noise Channel
; ------------------------------------------------------------------------------
.define APU_CH3_CTRL        0xF093      ; Channel 3 control register
.define APU_CH3_ADSR_L      0xF094      ; Channel 3 ADSR envelope low byte
.define APU_CH3_ADSR_H      0xF095      ; Channel 3 ADSR envelope high byte

; ------------------------------------------------------------------------------
; Mixer Controls
; ------------------------------------------------------------------------------
.define APU_MIX_CTRL        0xF096      ; Mixer control (APU enable, channel enables)
.define APU_MIX_VOL         0xF097      ; Master volume (L: bits 7-4, R: bits 3-0)

; ------------------------------------------------------------------------------
; Channel Output/Panning Controls
; ------------------------------------------------------------------------------
.define APU_CH0_OUT         0xF099      ; Channel 0 stereo volume (L: 7-4, R: 3-0)
.define APU_CH1_OUT         0xF09A      ; Channel 1 stereo volume (L: 7-4, R: 3-0)
.define APU_CH2_OUT         0xF09B      ; Channel 2 stereo volume (L: 7-4, R: 3-0)
.define APU_CH3_OUT         0xF09C      ; Channel 3 stereo volume (L: 7-4, R: 3-0)

; ------------------------------------------------------------------------------
; DSP Effects
; ------------------------------------------------------------------------------
.define APU_DSP_CTRL        0xF09D      ; DSP control register
.define APU_DSP_DELAY       0xF09E      ; DSP delay time
.define APU_DSP_FBACK       0xF09F      ; DSP feedback level (0-15)
.define APU_DSP_WET         0xF0A0      ; DSP wet signal mix level (0-15)

; ------------------------------------------------------------------------------
; Wave RAM
; ------------------------------------------------------------------------------
.define APU_WAVE_RAM        0xFA00      ; Wave RAM base address (1KB total)
                                        ; 32 waveforms × 32 bytes each
                                        ; Each waveform = 64 samples (4-bit nibbles)

; ------------------------------------------------------------------------------
; APU Pulse Channel Control Bit Flags (CH0_CTRL, CH1_CTRL)
; ------------------------------------------------------------------------------
.define APU_CTRL_KEY_ON     0x80        ; Bit 7: Key on (1=attack, 0=release)
.define APU_CTRL_RETRIGGER  0x10        ; Bit 4: Retrigger ADSR (auto-clears)
.define APU_CTRL_DUTY_12_5  0x00        ; Bits 6-5: 12.5% duty cycle
.define APU_CTRL_DUTY_25    0x20        ; Bits 6-5: 25% duty cycle
.define APU_CTRL_DUTY_50    0x40        ; Bits 6-5: 50% duty cycle
.define APU_CTRL_DUTY_75    0x60        ; Bits 6-5: 75% duty cycle

; ------------------------------------------------------------------------------
; APU Wave Channel Control Bit Flags (CH2_CTRL)
; ------------------------------------------------------------------------------
.define APU_WAVE_KEY_ON     0x80        ; Bit 7: Key on
.define APU_WAVE_RETRIGGER  0x40        ; Bit 6: Retrigger ADSR
.define APU_WAVE_IDX_MASK   0x3F        ; Bits 5-0: Wave index (0-31)

; ------------------------------------------------------------------------------
; APU Noise Channel Control Bit Flags (CH3_CTRL)
; ------------------------------------------------------------------------------
.define APU_NOISE_KEY_ON    0x80        ; Bit 7: Key on
.define APU_NOISE_MODE_7BIT 0x40        ; Bit 6: 7-bit LFSR (metallic noise)
.define APU_NOISE_MODE_15BIT 0x00       ; Bit 6: 15-bit LFSR (white noise)
.define APU_NOISE_RETRIGGER 0x20        ; Bit 5: Retrigger ADSR
.define APU_NOISE_CLK_MASK  0x1F        ; Bits 4-0: Clock divider (0-31)

; ------------------------------------------------------------------------------
; APU Sweep Control Bit Flags (CH0_SWEEP)
; ------------------------------------------------------------------------------
.define APU_SWP_ENABLE      0x80        ; Bit 7: Sweep enable
.define APU_SWP_TIME_MASK   0x70        ; Bits 6-4: Sweep time (0-7)
.define APU_SWP_DIR_DOWN    0x08        ; Bit 3: Sweep direction down (subtract)
.define APU_SWP_DIR_UP      0x00        ; Bit 3: Sweep direction up (add)
.define APU_SWP_SHIFT_MASK  0x07        ; Bits 2-0: Sweep shift amount

; ------------------------------------------------------------------------------
; APU Mixer Control Bit Flags (MIX_CTRL)
; ------------------------------------------------------------------------------
.define APU_ENABLE          0x80        ; Bit 7: Master APU enable
.define APU_CH3_ENABLE      0x08        ; Bit 3: Noise channel enable
.define APU_CH2_ENABLE      0x04        ; Bit 2: Wave channel enable
.define APU_CH1_ENABLE      0x02        ; Bit 1: Pulse B enable
.define APU_CH0_ENABLE      0x01        ; Bit 0: Pulse A enable

; ------------------------------------------------------------------------------
; APU DSP Control Bit Flags (DSP_CTRL)
; ------------------------------------------------------------------------------
.define APU_DSP_ENABLE      0x80        ; Bit 7: DSP master enable
.define APU_DSP_CH3_IN      0x08        ; Bit 3: Send CH3 to DSP
.define APU_DSP_CH2_IN      0x04        ; Bit 2: Send CH2 to DSP
.define APU_DSP_CH1_IN      0x02        ; Bit 1: Send CH1 to DSP
.define APU_DSP_CH0_IN      0x01        ; Bit 0: Send CH0 to DSP

; ==============================================================================
; Interrupt Flag Bits (IE/IF register bits)
; ==============================================================================
.define INT_VBLANK          0x01        ; Bit 0: V-Blank interrupt
.define INT_HBLANK          0x02        ; Bit 1: H-Blank interrupt
.define INT_LYC             0x04        ; Bit 2: LY == LYC interrupt
.define INT_TIMER0          0x08        ; Bit 3: Timer 0 overflow interrupt
.define INT_TIMER1          0x10        ; Bit 4: Timer 1 overflow interrupt
.define INT_SERIAL          0x20        ; Bit 5: Serial transfer complete interrupt
.define INT_LINK            0x40        ; Bit 6: Link status change interrupt
.define INT_JOYPAD          0x80        ; Bit 7: Joypad button press interrupt

; ==============================================================================
; Joypad Group Select Values (write to JOYP bits 5-4)
; ==============================================================================
.define JOYP_SEL_DPAD       0x10        ; Select D-Pad group
.define JOYP_SEL_ACTION     0x20        ; Select Action group (A, B, X, Y)
.define JOYP_SEL_UTILITY    0x30        ; Select Utility group (Start, Select, L, R)

; ==============================================================================
; Joypad Button Masks (read from JOYP bits 3-0, active low)
; ==============================================================================
; D-Pad group (JOYP_SEL_DPAD):
.define BTN_RIGHT           0x01        ; Bit 0: D-pad right
.define BTN_LEFT            0x02        ; Bit 1: D-pad left
.define BTN_UP              0x04        ; Bit 2: D-pad up
.define BTN_DOWN            0x08        ; Bit 3: D-pad down

; Action group (JOYP_SEL_ACTION):
.define BTN_A               0x01        ; Bit 0: A button
.define BTN_B               0x02        ; Bit 1: B button
.define BTN_X               0x04        ; Bit 2: X button
.define BTN_Y               0x08        ; Bit 3: Y button

; Utility group (JOYP_SEL_UTILITY):
.define BTN_START           0x01        ; Bit 0: Start button
.define BTN_SELECT          0x02        ; Bit 1: Select button
.define BTN_R               0x04        ; Bit 2: R shoulder button
.define BTN_L               0x08        ; Bit 3: L shoulder button

; ==============================================================================
; Tilemap Entry Bit Flags
; ==============================================================================
.define TILE_PRIORITY       0x8000      ; Bit 15: Tile priority over sprites
.define TILE_VFLIP          0x4000      ; Bit 14: Vertical flip
.define TILE_HFLIP          0x2000      ; Bit 13: Horizontal flip
.define TILE_PAL_MASK       0x1C00      ; Bits 12-10: Palette select (0-7)
.define TILE_INDEX_MASK     0x03FF      ; Bits 9-0: Tile index (0-1023)

; ==============================================================================
; OAM Sprite Entry Bit Flags (Byte 4 - Attribute Flags)
; ==============================================================================
.define SPR_PRIORITY        0x80        ; Bit 7: Priority (1=in front of BG tiles)
.define SPR_VFLIP           0x40        ; Bit 6: Vertical flip
.define SPR_HFLIP           0x20        ; Bit 5: Horizontal flip
.define SPR_PAL_MASK        0x0F        ; Bits 3-0: Palette select (0-15)

; ------------------------------------------------------------------------------
; OAM Sprite Shape/Size (Byte 2)
; ------------------------------------------------------------------------------
; SHAPE (bits 3-2): 00=Square, 01=H-Rect, 10=V-Rect
; SIZE (bits 1-0): Selects dimension from shape-dependent table
.define SPR_SHAPE_SQUARE    0x00        ; Square sprite
.define SPR_SHAPE_HRECT     0x04        ; Horizontal rectangle
.define SPR_SHAPE_VRECT     0x08        ; Vertical rectangle

.define SPR_SIZE_0          0x00        ; Size variant 0
.define SPR_SIZE_1          0x01        ; Size variant 1
.define SPR_SIZE_2          0x02        ; Size variant 2
.define SPR_SIZE_3          0x03        ; Size variant 3

; Common sprite size combinations:
.define SPR_8x8             0x00        ; Square, Size 0: 8x8
.define SPR_16x16           0x01        ; Square, Size 1: 16x16
.define SPR_32x32           0x02        ; Square, Size 2: 32x32
.define SPR_64x64           0x03        ; Square, Size 3: 64x64
.define SPR_16x8            0x04        ; H-Rect, Size 0: 16x8
.define SPR_32x8            0x05        ; H-Rect, Size 1: 32x8
.define SPR_32x16           0x06        ; H-Rect, Size 2: 32x16
.define SPR_64x32           0x07        ; H-Rect, Size 3: 64x32
.define SPR_8x16            0x08        ; V-Rect, Size 0: 8x16
.define SPR_8x32            0x09        ; V-Rect, Size 1: 8x32
.define SPR_16x32           0x0A        ; V-Rect, Size 2: 16x32
.define SPR_32x64           0x0B        ; V-Rect, Size 3: 32x64

; ==============================================================================
; Interrupt Vector Table Offsets (from base address)
; ==============================================================================
.define VEC_RESET           0x00        ; Reset vector
.define VEC_BUS_ERROR       0x02        ; Bus error fault
.define VEC_ILLEGAL_INST    0x04        ; Illegal instruction fault
.define VEC_PROT_MEM        0x06        ; Protected memory fault
.define VEC_STACK_OVERFLOW  0x08        ; Stack overflow fault
.define VEC_VBLANK          0x0A        ; V-Blank interrupt
.define VEC_HBLANK          0x0C        ; H-Blank interrupt
.define VEC_LYC             0x0E        ; LY==LYC interrupt
.define VEC_TIMER0          0x10        ; Timer 0 interrupt
.define VEC_TIMER1          0x12        ; Timer 1 interrupt
.define VEC_SERIAL          0x14        ; Serial transfer complete
.define VEC_LINK            0x16        ; Link status change
.define VEC_JOYPAD          0x18        ; Joypad button press

; Vector table locations:
.define VEC_TABLE_ROM       0x0060      ; ROM-based vector table (standard mode)
.define VEC_TABLE_RAM       0xBFE0      ; RAM-based vector table (enhanced mode)

; ==============================================================================
; System Constants
; ==============================================================================
.define SCREEN_WIDTH        240         ; Screen width in pixels
.define SCREEN_HEIGHT       160         ; Screen height in pixels
.define TOTAL_SCANLINES     216         ; Total scanlines per frame (160 visible + 56 V-Blank)
.define CYCLES_PER_LINE     1300        ; Master clock cycles per scanline
.define CYCLES_PER_FRAME    280800      ; Total cycles per frame (216 × 1300)

.define TILE_SIZE_BYTES     32          ; Bytes per 8x8 tile (4bpp planar)
.define TILEMAP_ENTRY_SIZE  2           ; Bytes per tilemap entry
.define OAM_ENTRY_SIZE      8           ; Bytes per OAM sprite entry
.define PALETTE_ENTRY_SIZE  2           ; Bytes per color (RGB555)
.define WAVEFORM_SIZE       32          ; Bytes per APU waveform

.define MAX_SPRITES         64          ; Maximum hardware sprites
.define SPRITES_PER_LINE    16          ; Maximum sprites per scanline
.define NUM_SUBPALETTES     16          ; Number of 16-color sub-palettes
.define COLORS_PER_PALETTE  16          ; Colors per sub-palette
.define NUM_WAVEFORMS       32          ; Number of waveform slots in Wave RAM

; ==============================================================================
; End of hardware.asm
; ==============================================================================
