# **Cicada-16 System Library Reference**

This document provides detailed documentation for all System Library functions and data blocks. For information about the System Library architecture, memory layout, and calling conventions, see [HardwareSpec/System_Library.md](../HardwareSpec/System_Library.md).

## **Quick Reference: Vector Table Index Map**

| Index     | Type       | Name                     |
| :-------- | :--------- | :----------------------- |
| 0x00      | Data Block | `Default Font Data`      |
| 0x01      | Data Block | `Sine Wave Table`        |
| 0x02      | Data Block | `Note Frequency Table`   |
| 0x03      | Data Block | `Default APU Waves`      |
| 0x04      | Data Block | `APU Percussion Presets` |
| 0x05      | Function   | `initDefaultFont`        |
| 0x06      | Function   | `serialExchangeByte`     |
| 0x07      | Function   | `serialByteWrite`        |
| 0x08      | Function   | `serialByteRecv`         |
| 0x09      | Function   | `fastMultiply16`         |
| 0x0A      | Function   | `fastDivide32`           |
| 0x0B      | Function   | `fastMultiply8`          |
| 0x0C      | Function   | `fastDivide16`           |
| 0x0D      | Function   | `decompressRLE`          |
| 0x0E      | Function   | `clearTilemap`           |
| 0x0F      | Function   | `waitForVBlank`          |
| 0x10      | Function   | `drawChar`               |
| 0x11      | Function   | `drawString`             |
| 0x12      | Function   | `setPalette`             |
| 0x13      | Function   | `memcpy`                 |
| 0x14      | Function   | `memset`                 |
| 0x15      | Function   | `setBankROM`             |
| 0x16      | Function   | `setBankWRAM`            |
| 0x17      | Function   | `setBankVRAM`            |
| 0x18      | Function   | `playSoundEffect`        |
| 0x19      | ---        | *Reserved*               |
| 0x1A      | ---        | *Reserved*               |
| 0x1B      | Function   | `readJoypad`             |
| 0x1C      | Function   | `readJoypadTrigger`      |
| 0x1D      | Function   | `rand`                   |
| 0x1E      | Function   | `setInterruptHandler`    |
| 0x1F      | Function   | `dmaCopy`                |
| 0x20      | Function   | `dmaCopyVBlank`          |
| 0x21      | Function   | `callFar`                |
| 0x22      | Function   | `jmpFar`                 |
| 0x23      | Function   | `dmaOAM`                 |
| 0x24      | Function   | `dmaVRAMSlot`            |
| 0x25      | Function   | `dmaPalette`             |
| 0x26      | Function   | `dmaWaveforms`           |
| 0x27      | Function   | `dmaFill`                |
| 0x28      | Function   | `poolInit`               |
| 0x29      | Function   | `poolAlloc`              |
| 0x2A      | Function   | `poolFree`               |
| 0x2B      | Function   | `stackInit`              |
| 0x2C      | Function   | `stackAlloc`             |
| 0x2D      | Function   | `stackFree`              |
| 0x2E      | Function   | `ringInit`               |
| 0x2F      | Function   | `ringPush`               |
| 0x30      | Function   | `ringPop`                |
| 0x31      | Function   | `ringPeek`               |
| 0x32      | Function   | `ringCount`              |
| 0x33-0x7F | ---        | **Unused**               |

---

## **Data Blocks**

### **Default Font Data** : Index 0x00

#### **Font Storage Format (1bpp vs 4bpp)**

To save a significant amount of space in the System Library, the default font is stored in a compact, 1-bit-per-pixel (1bpp) monochrome format.

- **Hardware Format (4bpp):** The PPU requires every 8x8 tile in VRAM to be in its native 4bpp planar format, which takes 32 bytes. Storing the 96-character font this way would consume `96 * 32 = 3072` bytes, which is too large.
- **Storage Format (1bpp):** In the 1bpp library format, each 8x8 character only requires 8 bytes (1 bit per pixel). The total storage size is therefore `96 * 8 = 768` bytes.

The `initDefaultFont` function handles the conversion, reading the compact 8-byte characters and expanding them into the 32-byte, 4bpp format that the PPU requires before writing them to VRAM.

### **Sine Wave Table** : Index 0x01

A 256-byte table containing a single cycle of a sine wave. This can be used by the APU's wave channel to produce a pure tone, or as a building block for more complex sounds.

### **Note Frequency Table** : Index 0x02

To simplify music creation, the System Library provides a pre-calculated lookup table containing the 16-bit `FREQ_REG` values for a range of standard musical notes. This allows developers to play specific pitches without needing to perform the frequency calculation manually.

- **Location:** The table resides at a fixed address within the System Library space.
- **Range:** The table covers 5 octaves, from C2 to B6.
- **Format:** The table is a simple array of 16-bit unsigned integers. Each entry corresponds to a note in the chromatic scale.

**Note:** The exact addresses and constant names will be finalized in the official toolchain documentation.

### **Default APU Waves** : Index 0x03

This is a 128-byte block containing four simple, ready-to-use 32-byte waveforms for the APU's wave channel. These include a sawtooth wave, a triangle wave, and others, providing a quick way to get varied sounds without having to define custom waveforms.

### **APU Percussion Presets** : Index 0x04

A small 24-byte data block containing a set of pre-configured ADSR and timing parameters for creating common percussion sounds (like a kick drum or hi-hat) using the APU's noise channel.

---

## **Graphics & Display Functions**

### `initDefaultFont` : Index 0x05

This function initializes the default system font by copying it from the System Library's compact storage format into VRAM in the PPU-ready 4bpp format.

- **Inputs:**
  - `R0`: The starting address in VRAM where the expanded font data should be written.
- **Action:**
  1.  Reads the 1bpp font data from its internal location within the System Library.
  2.  Iterates through each of the 96 characters.
  3.  For each character, it expands the 8 bytes of 1bpp data into the 32 bytes required for the 4bpp planar format.
  4.  Writes the resulting 32-byte tile to the destination address in VRAM specified by `R0`.
  5.  `R0` is incremented by 32 after each tile is written.
- **Output:** None.
- **Clobbered Registers:** `R1`, `R2`, `R3`.

### `clearTilemap` : Index 0x0E

Fills a rectangular area of a background tilemap in VRAM with a specific tile entry.

- **Inputs:**
  - R0: VRAM address of the tilemap
  - R1: Tile entry value to write (16-bit)
  - R2.b: Width of area in tiles
  - R3.b: Height of area in tiles
- **Action:**
  - Fills the specified rectangular area of the tilemap with the given tile entry.
- **Output:** None.
- **Clobbered Registers:** R0, R1, R2, R3.

### `waitForVBlank` : Index 0x0F

Puts the CPU into a low-power HALT state until the V-Blank interrupt occurs. This synchronizes the game loop to the screen's refresh rate, preventing tearing and freeing the memory bus while idle.

- **Inputs:** None.
- **Action:**
  - Halts the CPU until a V-Blank interrupt occurs.
- **Output:** None.
- **Clobbered Registers:** None.

### `drawChar` : Index 0x10

Writes a single character's tile index to a specified tilemap location. Assumes the font tiles have been loaded to VRAM using `initDefaultFont`.

- **Inputs:**
  - R0: Character to draw (ASCII)
  - R1: Pointer to destination in VRAM tilemap
- **Action:**
  - Writes the tile index for the given character to the specified tilemap location.
- **Output:** None.
- **Clobbered Registers:** R2, R3.

### `drawString` : Index 0x11

Draws a null-terminated string to the tilemap, advancing the cursor position after each character and handling line wrapping.

- **Inputs:**
  - R0: Pointer to null-terminated string
  - R1: Pointer to destination in VRAM tilemap
  - R2.b: Tilemap width (for line wrapping)
- **Action:**
  - Iterates over the string and draws each character to the tilemap, handling line wrapping.
- **Output:**
  - R0 and R1 are updated to point past the end of the source/destination.
- **Clobbered Registers:** R2, R3.

### `setPalette` : Index 0x12

Copies a block of color data into the PPU's CRAM. Should only be called during V-Blank to avoid visual artifacts.

- **Inputs:**
  - R0: Source address of palette data
  - R1: Destination CRAM index (0-255)
  - R2.b: Number of colors to copy
- **Action:**
  - Copies a block of color data to CRAM.
- **Output:** None.
- **Clobbered Registers:** R0, R1, R2, R3.

---

## **Serial Communication Functions**

### `serialExchangeByte` : Index 0x06

This function, intended to be called by the **Master** console, simultaneously sends one byte and receives one byte.

- **Inputs:**
  - `R0.b`: A byte to send.
- **Action:**
  1.  Waits until the serial port is not busy (i.e., the `START` bit in the `SC` register is 0).
  2.  Writes the input byte to the **`SB`** (Serial Buffer) register at `F002`.
  3.  Sets the `START` bit in the **`SC`** (Serial Control) register at `F003` to begin the transfer.
  4.  Waits for the transfer to complete (i.e., for the `START` bit to be cleared by hardware).
- **Output:**
  - `R0.b`: The byte received from the other console.

**Note:** This is a blocking function. It will halt CPU execution until the transfer is complete. It should only be called by the Master console (`CLK_SRC = 0`). The Slave console must have its outgoing byte pre-loaded into its `SB` register before this function is called by the Master.

### `serialByteWrite` : Index 0x07

This non-blocking function simply writes a byte to the serial buffer. It is intended to be used by the **Slave** console to prepare the next byte for transmission before the Master initiates an exchange.

- **Inputs:**
  - `R0.b`: A byte to write.
- **Action:**
  1.  Writes the input byte to the **`SB`** (Serial Buffer) register at `F002`.
- **Output:** None.

### `serialByteRecv` : Index 0x08

This function reads a single byte from the serial buffer. It is designed to be lightweight and is typically called from within the Serial Transfer Complete interrupt service routine, primarily on the **Slave** console.

- **Inputs:** None.
- **Action:**
  1.  Reads the byte from the **`SB`** (Serial Buffer) register at `F002`.
- **Output:**
  - `R0.b`: The received byte.

**Example ISR Usage on Slave Console (Conceptual):**

```assembly
; Serial Transfer Complete ISR (on Slave)
Serial_ISR:
    ; The master has just finished a transfer.
    ; Our outgoing byte was sent, and we have received a byte from the master.

    ; Call the library function to get the byte from the buffer.
    CALL serialByteRecv

    ; R0 now holds the received byte.
    ; Process the byte (e.g., store it in a RAM buffer).
    ...

    ; Pre-load the SB register for the *next* transfer using the new function.
    LD.b R1, (next_byte_to_send) ; Load the next byte into a register
    CALL serialByteWrite        ; Call the library function to write it to SB

    RETI ; Return from interrupt
```

---

## **Math Functions**

### `fastMultiply16` : Index 0x09

Multiplies two 16-bit unsigned integers and returns a 32-bit result.

- **Inputs:**
  - `R0`: Multiplicand (16-bit)
  - `R1`: Multiplier (16-bit)
- **Output:**
  - `R0`: High word of the 32-bit result.
  - `R1`: Low word of the 32-bit result.
- **Clobbered Registers:** `R2`, `R3` (These registers are used internally by the function and their previous values will be lost).

### `fastDivide32` : Index 0x0A

Divides a 32-bit unsigned integer by a 16-bit unsigned integer.

- **Inputs:**
  - `R0`: High word of the 32-bit dividend.
  - `R1`: Low word of the 32-bit dividend.
  - `R2`: 16-bit divisor.
- **Output:**
  - `R0`: 16-bit quotient.
  - `R1`: 16-bit remainder.
- **Error Handling:** If the divisor in `R2` is zero, the function will immediately return, setting the **Carry Flag (F.C)** to 1. The contents of `R0` and `R1` will be undefined in this case.
- **Clobbered Registers:** `R3`.

### `fastMultiply8` : Index 0x0B

Multiplies two 8-bit unsigned integers and returns a 16-bit result. This is the fastest multiplication routine.

- **Inputs:**
  - `R0.b`: Multiplicand (low byte of R0).
  - `R1.b`: Multiplier (low byte of R1).
- **Output:**
  - `R0`: 16-bit result.
- **Clobbered Registers:** `R1`.

### `fastDivide16` : Index 0x0C

Divides a 16-bit unsigned integer by an 8-bit unsigned integer.

- **Inputs:**
  - `R0`: 16-bit dividend.
  - `R1.b`: 8-bit divisor (low byte of R1).
- **Output:**
  - `R0.h`: 8-bit remainder (high byte of R0).
  - `R0.l`: 8-bit quotient (low byte of R0).
- **Error Handling:** If the divisor in `R1.b` is zero, the function will immediately return, setting the **Carry Flag (F.C)** to 1. The contents of `R0` will be undefined in this case.
- **Clobbered Registers:** `R1`, `R2`.

### `rand` : Index 0x1D

Returns a 16-bit pseudo-random number. Uses an internal PRNG state that is seeded from the DIV register on first call.

- **Inputs:** None.
- **Action:**
  - Generates a pseudo-random number.
- **Output:**
  - R0: A 16-bit pseudo-random number.
- **Clobbered Registers:** R1.

---

## **Memory Functions**

### `memcpy` : Index 0x13

Copies a block of memory from a source address to a destination address.

- **Inputs:**
  - R0: Source
  - R1: Destination
  - R2: Length in bytes
- **Action:**
  - Copies a block of memory.
- **Output:** None.
- **Clobbered Registers:** R0, R1, R2, R3.

### `memset` : Index 0x14

Fills a block of memory with a specific byte value.

- **Inputs:**
  - R0: Destination
  - R1.b: Value to write
  - R2: Length in bytes
- **Action:**
  - Fills a block of memory with a specific byte value.
- **Output:** None.
- **Clobbered Registers:** R0, R1, R2, R3.

### `decompressRLE` : Index 0x0D

Decompresses data that was compressed using a Run-Length Encoding (RLE) scheme. The function processes control bytes to expand runs of repeated data and copy raw data blocks.

- **Inputs:**
  - `R0`: Source address (pointer to the compressed RLE data).
  - `R1`: Destination address (pointer to the RAM where data will be decompressed).
- **Action:**
  - Decompresses RLE data from source to destination.
- **Output:**
  - `R0`: Address of the byte following the end-of-stream marker.
  - `R1`: Address of the byte following the last written destination byte.
- **Clobbered Registers:** `R2`, `R3`.
- **Important Note:** The developer is responsible for ensuring the destination buffer in RAM is large enough to hold the fully decompressed data. This function does not perform any bounds checking.

---

## **Bank Switching Functions**

### `setBankROM` : Index 0x15

Switches the active ROM bank by writing to the MPR_BANK register.

- **Inputs:**
  - R0.b: Bank number
- **Action:**
  - Writes the given bank number to the MPR_BANK register.
- **Output:** None.
- **Clobbered Registers:** None.

### `setBankWRAM` : Index 0x16

Switches the active WRAM bank by writing to the WRAM_BANK register.

- **Inputs:**
  - R0.b: Bank number
- **Action:**
  - Writes the given bank number to the WRAM_BANK register.
- **Output:** None.
- **Clobbered Registers:** None.

### `setBankVRAM` : Index 0x17

Switches the active VRAM bank by writing to the VRAM_BANK register.

- **Inputs:**
  - R0.b: Bank number
- **Action:**
  - Writes the given bank number to the VRAM_BANK register.
- **Output:** None.
- **Clobbered Registers:** None.

### `callFar` : Index 0x21

This function provides a "trampoline" to call a function located in a different ROM bank and have it return seamlessly. It handles switching to the target bank, calling the function, and switching back to the original bank automatically. This is the standard mechanism for cross-bank function calls.

This function is designed to be as transparent as possible, allowing registers `R0-R3` to be used for passing arguments to the far function.

- **Inputs:**
  - `R4.b`: The number of the ROM bank to switch to.
  - `R5`: The 16-bit address of the function to call within the target bank.
- **Action:**
  1.  Reads and saves the current ROM bank number.
  2.  Switches to the target ROM bank specified in `R4`.
  3.  Calls the function at the address specified in `R5`.
  4.  Waits for the called function to return.
  5.  Switches back to the original ROM bank.
  6.  Returns to the caller.
- **Register Usage:**
  - **Argument Passing:** Use registers `R0`, `R1`, `R2`, and `R3` to pass arguments to the target (far) function.
  - **Return Values:** Return values from the far function in `R0-R3` are preserved and passed back to the original caller.
  - **Clobbered Registers:** `R4` and `R5` are used as inputs by this function and their contents may be clobbered. All other registers (`R0-R3`, `R6`) are preserved.

### `jmpFar` : Index 0x22

This function provides a "trampoline" to jump to a label located in a different ROM bank. It handles switching to the target bank and then jumping, effectively transferring execution control without returning. This is the standard mechanism for cross-bank jumps.

- **Inputs:**
  - `R4.b`: The number of the ROM bank to switch to.
  - `R5`: The 16-bit address of the label to jump to within the target bank.
- **Action:**
  1.  Switches to the target ROM bank specified in `R4`.
  2.  Jumps to the address specified in `R5`. Execution does not return to the caller.
- **Register Usage:**
  - The state of all registers is preserved during the bank switch and jump. They are not used or modified by the `jmpFar` function itself.

---

## **Input Functions**

### `readJoypad` : Index 0x1B

This function performs the necessary sequence of writes and reads to the JOYP register to poll all three button groups (D-Pad, Action, Utility). It then combines the results into a single, clean 16-bit bitmask. This is much more convenient than doing it manually.

- **Inputs:** None.
- **Action:**
  - Polls the joypad and returns the current state of all buttons.
- **Output:**
  - R0: A 16-bit bitmask where each bit represents a button (e.g., bit 0 = Right, bit 1 = Left, bit 8 = A, etc.).
- **Clobbered Registers:** R1.

### `readJoypadTrigger` : Index 0x1C

Polls the joypad and returns a bitmask of buttons that transitioned from released to pressed since the last call (edge detection). The function stores the previous frame's state internally.

- **Inputs:** None.
- **Action:**
  - Polls the joypad and returns a bitmask of newly pressed buttons.
- **Output:**
  - R0: A 16-bit bitmask of newly pressed buttons.
- **Clobbered Registers:** R1.

---

## **Audio Functions**

### `playSoundEffect` : Index 0x18

Configures an APU channel to play a sound effect defined by a data structure. The structure specifies frequency, ADSR settings, noise parameters, and other channel configuration.

- **Inputs:**
  - R0: Pointer to sound effect data structure
  - R1.b: Channel to play on (0-3)
- **Action:**
  - Configures and plays a sound effect on the specified APU channel.
- **Output:** None.
- **Clobbered Registers:** R2.

---

## **Interrupt Functions**

### `setInterruptHandler` : Index 0x1E

Sets an interrupt handler by writing the ISR address to the WRAM vector table at `0xBFE0`. Only valid in Enhanced Mode (RAM-based vectors).

- **Inputs:**
  - R0.b: Interrupt vector number
  - R1: Address of the new ISR
- **Action:**
  - Sets the interrupt handler for the given vector to the given address.
- **Output:** None.
- **Clobbered Registers:** None.

---

## **DMA Functions**

### `dmaCopy` : Index 0x1F

Configures and starts a DMA transfer (Mode 0) from source to destination.

- **Inputs:**
  - R0: Source address
  - R1: Destination address
  - R2: Length in bytes (1-65535, or 0 for 65536 bytes)
- **Action:**
  - Starts a normal DMA transfer (Mode 0) at standard speed (4 cycles/byte).
- **Output:** None.
- **Clobbered Registers:** None (The CPU is halted during the transfer).

### `dmaCopyVBlank` : Index 0x20

Configures and starts a DMA transfer (Mode 0) with the VRAM_SAFE bit set, ensuring the transfer only occurs during H-Blank or V-Blank.

- **Inputs:**
  - R0: Source address
  - R1: Destination address
  - R2: Length in bytes (1-65535, or 0 for 65536 bytes)
- **Action:**
  - Starts a VRAM-safe normal DMA transfer (Mode 0 with VRAM_SAFE bit set).
- **Output:** None.
- **Clobbered Registers:** None.

### `dmaOAM` : Index 0x23

Convenient wrapper for OAM Scanline DMA (Mode 1). Allows updating a specific range of sprite entries without manually configuring DMA registers or calculating byte offsets.

- **Inputs:**
  - `R0`: Source address containing sprite data in RAM/ROM
  - `R1.b`: Starting sprite index (0-63)
  - `R2.b`: Number of sprites to copy (1-64)
- **Action:**
  1.  Configures DMA Mode 1 (OAM Scanline DMA) and initiates high-speed transfer (2 cycles/byte).
  2.  Transfers `num_sprites × 8` bytes to OAM starting at the specified sprite index.
- **Output:** None.
- **Clobbered Registers:** R3 (used for internal calculations).
- **Use case:** Update only active sprites, animate specific sprite groups. To update all 64 sprites, call with `R1 = 0, R2 = 64`.

**Example:**

```assembly
; Update sprites 10-14 (5 sprites) with data from sprite_buffer
LDI R0, sprite_buffer
LDI R1, 10          ; Starting at sprite index 10
LDI R2, 5           ; Copy 5 sprites
SYSCALL 0x23        ; dmaOAM
```

### `dmaVRAMSlot` : Index 0x24

Simplified wrapper for VRAM Slot DMA (Mode 2). Transfers data directly to a specific 2 KiB VRAM slot without manual bank switching.

- **Inputs:**
  - `R0`: Source address in ROM/RAM
  - `R1`: Destination VRAM slot (0-15)
  - `R2`: Number of VRAM slots to transfer
- **Action:**
  1.  Configures DMA Mode 2 (VRAM Slot DMA) and initiates high-speed transfer (2 cycles/byte).
  2.  Automatically encodes slot number into DMA_LEN register.
  3.  Sets VRAM_SAFE bit to ensure transfer occurs during H-Blank/V-Blank.
- **Output:** None.
- **Clobbered Registers:** R3 (used for mode configuration).
- **Use case:** Load tilemap data or tile graphics to a specific VRAM location. Ideal for level loading, dynamic tile updates.

**Example:**

```assembly
; Copy 4096 bytes (2 slots) of tile data to VRAM slot 5
LDI R0, tile_data
LDI R1, 5
LDI R2, 2
SYSCALL 0x24        ; dmaVRAMSlot
```

### `dmaPalette` : Index 0x25

Fast palette update wrapper for CRAM DMA (Mode 3). Simplifies loading color palettes.

- **Inputs:**
  - `R0`: Source address containing palette data (RGB555 format, 2 bytes per color)
  - `R1.b`: Starting palette index (0-255)
  - `R2.b`: Number of colors to copy (1-256)
- **Action:**
  1.  Configures DMA Mode 3 (CRAM/Palette DMA) and initiates high-speed transfer (2 cycles/byte).
  2.  Transfers `num_colors × 2` bytes to CRAM starting at the specified palette index.
  3.  Automatically sets VRAM_SAFE bit for safe palette updates during rendering.
- **Output:** None.
- **Clobbered Registers:** R3 (used for internal calculations).
- **Use case:** Palette swaps, fade effects, day/night cycles, cutscene color changes.

**Example:**

```assembly
; Load a 16-color sub-palette (palette 0) from ROM
LDI R0, palette_data
LDI R1, 0           ; Starting at palette index 0
LDI R2, 16          ; Load 16 colors
SYSCALL 0x25        ; dmaPalette

; Update only 4 colors in the middle of a sub-palette
LDI R0, color_buffer
LDI R1, 36          ; Palette index 36 (sub-palette 2, color 4)
LDI R2, 4
SYSCALL 0x25        ; dmaPalette
```

### `dmaWaveforms` : Index 0x26

Convenient wrapper for Wave RAM DMA (Mode 4). Loads custom waveforms for the APU's wave channel.

- **Inputs:**
  - `R0`: Source address containing waveform data (32 bytes per waveform)
  - `R1.b`: Starting waveform slot (0-31)
  - `R2.b`: Number of waveforms to copy (1-32)
- **Action:**
  1.  Configures DMA Mode 4 (Wave RAM DMA) and initiates high-speed transfer (2 cycles/byte).
  2.  Transfers `num_waveforms × 32` bytes to Wave RAM starting at the specified slot.
- **Output:** None.
- **Clobbered Registers:** R3 (used for mode configuration).
- **Use case:** Load custom instrument waveforms, switch sound effect samples, implement dynamic audio synthesis.

**Example:**

```assembly
; Load a single custom waveform to slot 10
LDI R0, sawtooth_wave
LDI R1, 10          ; Waveform slot 10
LDI R2, 1           ; Load 1 waveform
SYSCALL 0x26        ; dmaWaveforms

; Load 4 consecutive instrument waveforms starting at slot 0
LDI R0, instrument_bank
LDI R1, 0
LDI R2, 4
SYSCALL 0x26        ; dmaWaveforms
```

### `dmaFill` : Index 0x27

Hardware-accelerated memory fill using DMA Mode 6 (Fill/Pattern Mode). Much faster than CPU loops for large fills.

- **Inputs:**
  - `R0`: 16-bit pattern value to repeat
  - `R1`: Destination address in memory
  - `R2`: Number of 16-bit words to write
- **Action:**
  1.  Stores the pattern value to a temporary location in HRAM.
  2.  Configures DMA Mode 6 (Fill/Pattern Mode) and initiates high-speed transfer (2 cycles/byte).
  3.  Repeatedly writes the pattern value to consecutive 16-bit locations.
- **Output:** None.
- **Clobbered Registers:** R3 (used for internal operations).
- **Use case:** Clear tilemaps with a specific tile, initialize background layers, fill VRAM regions with solid patterns, bulk initialization of data structures.

**Example:**

```assembly
; Clear a 32×32 tilemap with tile index 0x0000
LDI R0, 0x0000      ; Fill pattern (empty tile)
LDI R1, tilemap_addr
LDI R2, 1024        ; 32×32 = 1024 words
SYSCALL 0x27        ; dmaFill

; Initialize a tilemap region with tile 0x0042
LDI R0, 0x0042
LDI R1, tilemap_addr
LDI R2, 256         ; Fill 256 words
SYSCALL 0x27        ; dmaFill
```

---

## **Memory Management Functions**

The System Library provides lightweight memory management systems for different allocation patterns. All systems operate on developer-provided memory regions and use small header structures to track allocator state.

### `poolInit` : Index 0x28

Initializes a memory pool allocator for fixed-size block allocation. The pool uses a linked-list strategy where each free block stores the address of the next free block, enabling O(1) allocation and deallocation.

- **Inputs:**
  - `R0`: Base address of the memory region to use for the pool
  - `R1`: Size of each block in bytes (minimum 2 bytes)
  - `R2`: Number of blocks to create
- **Action:**
  1.  Writes the pool header at the base address:
      - Bytes 0-1: Address of the first free block (head of free list)
      - Bytes 2-3: Block size
      - Bytes 4-5: Total block count
  2.  Initializes the free list by writing the address of the next free block into each block, with the last block containing `0x0000` (null) to indicate end of list.
  3.  The usable pool memory begins immediately after the 6-byte header.
- **Output:**
  - `R0`: Address of the pool header (same as input, for convenience)
- **Clobbered Registers:** `R1`, `R2`, `R3`.
- **Memory Layout:**

```
Pool Header (6 bytes):
  +0: Free list head pointer (2 bytes)
  +2: Block size (2 bytes)
  +4: Block count (2 bytes)

Pool Blocks (immediately following header):
  Block 0: [Next free ptr | ... unused space ...]
  Block 1: [Next free ptr | ... unused space ...]
  ...
  Block N: [0x0000 (null) | ... unused space ...]
```

**Example:**

```assembly
; Create a pool of 32 blocks, each 16 bytes, at address 0x8000
LDI R0, 0x8000
LDI R1, 16          ; Block size
LDI R2, 32          ; Number of blocks
SYSCALL 0x28        ; poolInit
; R0 now contains 0x8000 (pool header address)
; Total memory used: 6 + (32 × 16) = 518 bytes
```

### `poolAlloc` : Index 0x29

Allocates a single block from a memory pool. Returns the address of the allocated block in O(1) time by removing it from the head of the free list.

- **Inputs:**
  - `R0`: Address of the pool header
- **Action:**
  1.  Reads the free list head pointer from the pool header.
  2.  If the head pointer is null (0x0000), the pool is exhausted; sets the Carry Flag and returns.
  3.  Reads the next free block pointer from the allocated block.
  4.  Updates the pool header's free list head to point to the next free block.
  5.  Returns the address of the allocated block.
- **Output:**
  - `R0`: Address of the allocated block, or `0x0000` if pool is exhausted.
  - **Carry Flag (F.C):** Set to 1 if allocation failed (pool exhausted), cleared otherwise.
- **Clobbered Registers:** `R1`.

**Example:**

```assembly
; Allocate a block from the pool
LDI R0, pool_header
SYSCALL 0x29        ; poolAlloc
JC .alloc_failed    ; Jump if Carry is set (pool exhausted)
; R0 now contains the address of the allocated block
ST.w (my_block_ptr), R0
```

### `poolFree` : Index 0x2A

Returns a previously allocated block to the memory pool. The block is added to the head of the free list in O(1) time.

- **Inputs:**
  - `R0`: Address of the pool header
  - `R1`: Address of the block to free
- **Action:**
  1.  Reads the current free list head pointer from the pool header.
  2.  Writes the current head pointer into the block being freed (making it point to the old head).
  3.  Updates the pool header's free list head to point to the newly freed block.
- **Output:** None.
- **Clobbered Registers:** `R2`.
- **Important Note:** The developer is responsible for ensuring the block address is valid and was previously allocated from this pool. Freeing an invalid address will corrupt the pool's free list.

**Example:**

```assembly
; Free a block back to the pool
LDI R0, pool_header
LD.w R1, (my_block_ptr)
SYSCALL 0x2A        ; poolFree
```

---

### `stackInit` : Index 0x2B

Initializes a stack allocator for variable-size block allocation in FILO (First-In, Last-Out) order. The stack grows upward from a base address toward a maximum boundary.

- **Inputs:**
  - `R0`: Base address of the memory region to use for the stack
  - `R1`: Total size of the stack region in bytes
- **Action:**
  1.  Writes the stack header at the base address:
      - Bytes 0-1: Current stack top pointer (initially points to first usable byte after header)
      - Bytes 2-3: Stack base address (first usable byte after header)
      - Bytes 4-5: Stack ceiling address (base + size, the first invalid address)
  2.  The usable stack memory begins immediately after the 6-byte header.
- **Output:**
  - `R0`: Address of the stack header (same as input, for convenience)
- **Clobbered Registers:** `R1`, `R2`.
- **Memory Layout:**

```
Stack Header (6 bytes):
  +0: Stack top pointer (2 bytes) - points to next free byte
  +2: Stack base address (2 bytes)
  +4: Stack ceiling address (2 bytes)

Stack Memory (grows upward):
  [Base] -> [Allocation 1][Size1] -> [Allocation 2][Size2] -> ... -> [Top]
                          ^-- 2-byte size stored after each allocation
```

**Example:**

```assembly
; Create a stack allocator with 1024 bytes at address 0x9000
LDI R0, 0x9000
LDI R1, 1024
SYSCALL 0x2B        ; stackInit
; Usable stack space: 1024 - 6 = 1018 bytes
```

### `stackAlloc` : Index 0x2C

Allocates a block of the specified size from the stack. The allocation is pushed onto the top of the stack, and a 2-byte size field is stored after the allocation data to enable proper deallocation.

- **Inputs:**
  - `R0`: Address of the stack header
  - `R1`: Size of the block to allocate in bytes
- **Action:**
  1.  Reads the current stack top pointer and ceiling address from the header.
  2.  Calculates the new top position: `current_top + size + 2` (2 bytes for size field).
  3.  If the new top would exceed the ceiling, allocation fails; sets the Carry Flag and returns.
  4.  Stores the allocation size (2 bytes) at `current_top + size`.
  5.  Updates the stack header's top pointer to the new position.
  6.  Returns the address of the allocated block (the old top pointer).
- **Output:**
  - `R0`: Address of the allocated block, or `0x0000` if stack overflow.
  - **Carry Flag (F.C):** Set to 1 if allocation failed (stack overflow), cleared otherwise.
- **Clobbered Registers:** `R1`, `R2`, `R3`.

**Example:**

```assembly
; Allocate 64 bytes from the stack
LDI R0, stack_header
LDI R1, 64
SYSCALL 0x2C        ; stackAlloc
JC .stack_overflow  ; Jump if allocation failed
; R0 now contains the address of the 64-byte block
ST.w (temp_buffer), R0
```

### `stackFree` : Index 0x2D

Deallocates the most recently allocated block from the stack (FILO order). Reads the size field stored after the top allocation to determine how much to pop.

- **Inputs:**
  - `R0`: Address of the stack header
- **Action:**
  1.  Reads the current stack top pointer and base address from the header.
  2.  If the top pointer equals the base address, the stack is empty; sets the Carry Flag and returns.
  3.  Reads the 2-byte size field located at `top - 2`.
  4.  Calculates the new top position: `top - size - 2`.
  5.  Updates the stack header's top pointer to the new position.
- **Output:**
  - `R0`: Address of the freed block (the block that was just deallocated), or `0x0000` if stack was empty.
  - `R1`: Size of the freed block in bytes.
  - **Carry Flag (F.C):** Set to 1 if deallocation failed (stack empty), cleared otherwise.
- **Clobbered Registers:** `R2`.
- **Important Note:** Stack allocations must be freed in reverse order (FILO). Attempting to free allocations out of order will corrupt the stack.

**Example:**

```assembly
; Free the most recent allocation
LDI R0, stack_header
SYSCALL 0x2D        ; stackFree
JC .stack_empty     ; Jump if stack was already empty
; R0 = address of freed block, R1 = size of freed block
```

**Complete Stack Usage Example:**

```assembly
; Initialize stack
LDI R0, 0x9000
LDI R1, 512
SYSCALL 0x2B        ; stackInit
ST.w (stack_hdr), R0

; Allocate 32 bytes
LD.w R0, (stack_hdr)
LDI R1, 32
SYSCALL 0x2C        ; stackAlloc
ST.w (block_a), R0

; Allocate 48 bytes
LD.w R0, (stack_hdr)
LDI R1, 48
SYSCALL 0x2C        ; stackAlloc
ST.w (block_b), R0

; Free block_b (must free in reverse order)
LD.w R0, (stack_hdr)
SYSCALL 0x2D        ; stackFree - frees block_b

; Free block_a
LD.w R0, (stack_hdr)
SYSCALL 0x2D        ; stackFree - frees block_a
```

---

### `ringInit` : Index 0x2E

Initializes a ring buffer (circular queue) for FIFO byte storage. Ring buffers are ideal for buffering serial data, input events, or inter-system communication.

- **Inputs:**
  - `R0`: Base address of the memory region to use for the ring buffer
  - `R1`: Buffer capacity in bytes (maximum number of bytes the buffer can hold)
- **Action:**
  1.  Writes the ring buffer header at the base address:
      - Bytes 0-1: Buffer capacity
      - Bytes 2-3: Current count (initialized to 0)
      - Bytes 4-5: Head index (read position, initialized to 0)
      - Bytes 6-7: Tail index (write position, initialized to 0)
  2.  The buffer data area begins immediately after the 8-byte header.
- **Output:**
  - `R0`: Address of the ring buffer header (same as input, for convenience)
- **Clobbered Registers:** `R1`, `R2`.
- **Memory Layout:**

```
Ring Buffer Header (8 bytes):
  +0: Capacity (2 bytes)
  +2: Count (2 bytes) - current number of bytes in buffer
  +4: Head index (2 bytes) - next read position
  +6: Tail index (2 bytes) - next write position

Buffer Data (immediately following header):
  [Byte 0][Byte 1][Byte 2]...[Byte N-1]
     ^                          ^
     Head (read)                Tail (write)
```

**Example:**

```assembly
; Create a 64-byte ring buffer at address 0xA000
LDI R0, 0xA000
LDI R1, 64
SYSCALL 0x2E        ; ringInit
; Total memory used: 8 + 64 = 72 bytes
ST.w (serial_buffer), R0
```

### `ringPush` : Index 0x2F

Pushes a single byte onto the tail of the ring buffer. Returns an error if the buffer is full.

- **Inputs:**
  - `R0`: Address of the ring buffer header
  - `R1.b`: Byte to push
- **Action:**
  1.  Reads the current count and capacity from the header.
  2.  If count equals capacity, the buffer is full; sets the Carry Flag and returns.
  3.  Writes the byte to `buffer[tail]`.
  4.  Updates tail index: `tail = (tail + 1) % capacity`.
  5.  Increments the count.
- **Output:**
  - **Carry Flag (F.C):** Set to 1 if push failed (buffer full), cleared otherwise.
- **Clobbered Registers:** `R2`, `R3`.

**Example:**

```assembly
; Push a byte to the serial receive buffer
LD.w R0, (serial_buffer)
LD.b R1, (SB_REG)       ; Read byte from serial port
SYSCALL 0x2F            ; ringPush
JC .buffer_overflow     ; Handle overflow if needed
```

### `ringPop` : Index 0x30

Pops a single byte from the head of the ring buffer. Returns an error if the buffer is empty.

- **Inputs:**
  - `R0`: Address of the ring buffer header
- **Action:**
  1.  Reads the current count from the header.
  2.  If count is zero, the buffer is empty; sets the Carry Flag and returns.
  3.  Reads the byte from `buffer[head]`.
  4.  Updates head index: `head = (head + 1) % capacity`.
  5.  Decrements the count.
- **Output:**
  - `R0.b`: The popped byte (low byte of R0), or undefined if buffer was empty.
  - **Carry Flag (F.C):** Set to 1 if pop failed (buffer empty), cleared otherwise.
- **Clobbered Registers:** `R1`, `R2`.

**Example:**

```assembly
; Pop a byte from the input queue
LD.w R0, (input_queue)
SYSCALL 0x30            ; ringPop
JC .queue_empty         ; No input available
; R0.b contains the input byte
```

### `ringPeek` : Index 0x31

Reads the byte at the head of the ring buffer without removing it. Useful for lookahead parsing or checking the next value before deciding to consume it.

- **Inputs:**
  - `R0`: Address of the ring buffer header
- **Action:**
  1.  Reads the current count from the header.
  2.  If count is zero, the buffer is empty; sets the Carry Flag and returns.
  3.  Reads the byte from `buffer[head]` without modifying head or count.
- **Output:**
  - `R0.b`: The byte at the head (low byte of R0), or undefined if buffer was empty.
  - **Carry Flag (F.C):** Set to 1 if peek failed (buffer empty), cleared otherwise.
- **Clobbered Registers:** `R1`.

**Example:**

```assembly
; Check next command byte without consuming it
LD.w R0, (command_queue)
SYSCALL 0x31            ; ringPeek
JC .no_commands
; R0.b contains the next command, still in queue
CMP.b R0, CMD_QUIT
JEQ .handle_quit
; Now actually pop it
LD.w R0, (command_queue)
SYSCALL 0x30            ; ringPop
```

### `ringCount` : Index 0x32

Returns the current number of bytes stored in the ring buffer.

- **Inputs:**
  - `R0`: Address of the ring buffer header
- **Action:**
  1.  Reads the count field from the header.
- **Output:**
  - `R0`: Current number of bytes in the buffer (0 to capacity).
- **Clobbered Registers:** None.

**Example:**

```assembly
; Check how many bytes are waiting in the buffer
LD.w R0, (serial_buffer)
SYSCALL 0x32            ; ringCount
; R0 = number of bytes available
CMP R0, 0
JEQ .no_data
; Process available data...
```

**Complete Ring Buffer Usage Example:**

```assembly
; Initialize a ring buffer for serial communication
LDI R0, 0xA000
LDI R1, 128             ; 128-byte capacity
SYSCALL 0x2E            ; ringInit
ST.w (rx_buffer), R0

; --- In Serial ISR: push received bytes ---
Serial_ISR:
    LD.w R0, (rx_buffer)
    LD.b R1, (SB_REG)   ; Read from serial buffer register
    SYSCALL 0x2F        ; ringPush (ignore overflow for this example)
    RETI

; --- In main loop: process received data ---
ProcessSerial:
    LD.w R0, (rx_buffer)
    SYSCALL 0x32        ; ringCount
    CMP R0, 0
    JEQ .done           ; No data to process

.process_loop:
    LD.w R0, (rx_buffer)
    SYSCALL 0x30        ; ringPop
    JC .done            ; Buffer empty
    ; R0.b = received byte, process it
    CALL HandleByte
    JMP .process_loop

.done:
    RET
```

---

© 2025 Connor Nolan. This work is licensed under a
[Creative Commons Attribution-ShareAlike 4.0 International License](http://creativecommons.org/licenses/by-sa/4.0/).
