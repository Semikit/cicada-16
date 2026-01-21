## **Cicada-16 Cartridge ROM Layout**

This document specifies the internal memory layout of a Cicada-16 game cartridge. It details the mandatory header, the structure of the game data, and the implementation of the hybrid interrupt vector table system.

### **Cartridge Memory Overview**

| Address Range   | Size      | Description                             |
| :-------------- | :-------- | :-------------------------------------- |
| 0x0000 - 0x005F | 96 Bytes  | Cartridge Header (metadata, mode flags) |
| 0x0060 - 0x0079 | 26 Bytes  | Interrupt Vector Table Template         |
| 0x007A - 0x007F | 6 Bytes   | Reserved                                |
| 0x0080          | -         | Game Code Entry Point                   |
| 0x0081 - 0x3FFF | ~16 KiB   | Remainder of Fixed ROM Bank 0           |

### **1. Cartridge Header (0x0000 - 0x005F)**

Every Cicada-16 cartridge must begin with a header. The console's internal boot ROM reads this header on startup to verify the cartridge's integrity and configure the hardware.

| Address Range | Size | Field Name              | Description                                                                                                                       |
| :------------ | :--- | :---------------------- | :-------------------------------------------------------------------------------------------------------------------------------- |
| 0x0000-0x0003 | 4B   | **Boot Animation ID**   | A 4-byte block that specifies the boot animation configuration. See the "Boot Animation Configuration" section below for details. |
| 0x0004-0x0013 | 16B  | **Game Title**          | A null-terminated ASCII string for the game's title.                                                                              |
| 0x0014-0x0023 | 16B  | **Developer**           | A null-terminated ASCII string for the developer or publisher.                                                                    |
| 0x0024        | 1B   | **Game Version**        | A single byte representing the game's version number (e.g., 0x00 for v1.0).                                                       |
| 0x0025        | 1B   | **ROM Size**            | An enum indicating the total size of the physical ROM chip (e.g., 0x00=32KiB, 0x01=64KiB).                                        |
| 0x0026        | 1B   | **RAM Size**            | An enum indicating the size of save RAM on the cartridge. 0x00 = No RAM.                                                          |
| 0x0027        | 1B   | **Cartridge Info**      | A bitfield for hardware revision and region. See table below.                                                                     |
| 0x0028        | 1B   | **Feature Flags**       | A bitfield for hardware features. See the table below for the bit mapping.                                                        |
| 0x0029        | 1B   | **Header Checksum**     | An 8-bit checksum of bytes 0x0000 to 0x0028. Used by the boot ROM to verify header integrity.                                     |
| 0x002A-0x002B | 2B   | **Global ROM Checksum** | A 16-bit checksum of the entire cartridge ROM. Can be used for a full integrity check.                                            |
| 0x002C-0x005F | 52B  | **Reserved**            | Reserved for future expansion. Must be filled with 0x00.                                                                          |

#### **Cartridge Info Byte (0x0027)**

| Bit(s) | Size | Name                  | Description                                                                                             |
| :----- | :--- | :-------------------- | :------------------------------------------------------------------------------------------------------ |
| 7-6    | 2b   | **Hardware Revision** | `00` = Base hardware, `01` = Revision 1. Higher values are reserved.                                    |
| 5-3    | 3b   | **Region / Language** | `000` = All Regions, `001` = Japan, `010` = USA, `011` = Europe. Higher values are reserved.             |
| 2-0    | 3b   | **(Reserved)**        | Reserved for future use. Must be `0`.                                                                   |

#### **Feature Flags Byte (0x0028)**

| Bit(s) | Size | Name            | Description                                                                                                                            |
| :----- | :--- | :-------------- | :------------------------------------------------------------------------------------------------------------------------------------- |
| 7      | 1b   | **Interrupt Mode** | `0` = Standard (vectors in ROM), `1` = Enhanced (vectors in RAM).                                                                      |
| 6-5    | 2b   | **Mapper Type** | An enum specifying the memory bank controller (mapper) hardware on the cartridge. 0x00 = ROM only, 0x01 = Standard Mapper, etc.          |
| 4-0    | 5b   | **(Reserved)**  | Reserved for future use. Must be `0`.                                                                                                  |

### **1.1. Boot Animation Configuration (0x0000-0x0003)**

The Cicada-16 boot ROM displays a customizable animation when the system powers on. Each cartridge can specify its preferred boot animation style by including a 4-byte **Animation ID** block at the start of its ROM header (cartridge addresses **0x0000-0x0003**).

During the boot sequence, the boot ROM temporarily maps the cartridge's ROM Bank 0 to address range `0x4000-0x7FFF` (before the normal memory handoff). This allows the boot ROM to read these animation configuration bytes from addresses `0x4000-0x4003` and customize the boot animation accordingly.

The animation system supports:
- **12 entrance animation effects** (slide, fade, wave, bounce, etc.) plus random selection
- **16 curated color palettes** plus two rainbow animation modes
- **Audio customization** (reserved for future use)

Invalid IDs default to safe values (no animation, black background, white logo).

#### **Animation ID Format**

| Offset | Name | Description |
|--------|------|-------------|
| 0x0000 | `ANIM_ENTRANCE` | Entrance animation effect ID |
| 0x0001 | `ANIM_PALETTE` | Color palette ID (combined bg/logo colors) |
| 0x0002 | `(Reserved)` | Reserved, must be 0x00 |
| 0x0003 | `ANIM_AUDIO` | Boot audio ID (reserved) |

#### **Entrance Animations (Byte 0x0000)**

| ID | Name | Description |
|----|------|-------------|
| 0x00 | `ENTRANCE_NONE` | Logo appears instantly centered |
| 0x01 | `ENTRANCE_SLIDE_DOWN` | Logo slides in from top |
| 0x02 | `ENTRANCE_SLIDE_UP` | Logo slides in from bottom |
| 0x03 | `ENTRANCE_SLIDE_LEFT` | Logo slides in from right |
| 0x04 | `ENTRANCE_SLIDE_RIGHT` | Logo slides in from left |
| 0x05 | `ENTRANCE_FADE_IN` | Logo fades in from black |
| 0x06 | `ENTRANCE_FADE_WHITE` | Logo fades in from white |
| 0x07 | `ENTRANCE_WAVE_HORZ` | Horizontal scanline wave |
| 0x08 | `ENTRANCE_WAVE_VERT` | Vertical wave distortion |
| 0x09 | `ENTRANCE_ZOOM_IN` | Simulated zoom effect |
| 0x0A | `ENTRANCE_DROP_BOUNCE` | Drop from top and bounce |
| 0x0B | `ENTRANCE_SPIN_IN` | Spin in effect |
| 0xFF | `ENTRANCE_RANDOM` | Random entrance animation |

#### **Boot Palettes (Byte 0x0001)**

The selected 16-color palette is copied from Boot ROM to CRAM sub-palette 0 at boot time (32 bytes). Each palette contains 16 colors arranged for the boot animation.

**Palette Color Layout:**
| Color Index | Purpose |
|-------------|---------|
| 0 | Background color |
| 1-13 | Gradient colors (BG to FG transition) |
| 14 | Foreground (logo) color |
| 15 | Accent color |

**Available Palettes:**

| ID | Name | Background | Foreground | Notes |
|----|------|------------|------------|-------|
| 0x00 | Classic | Black | White | Default safe fallback |
| 0x01 | Inverted | White | Black | High contrast |
| 0x02 | Night Sky | Navy | White | |
| 0x03 | Ocean | Dark Blue | Cyan | |
| 0x04 | Forest | Dark Green | Lime | |
| 0x05 | Sunset | Dark Red | Orange | |
| 0x06 | Royal | Dark Purple | Gold | |
| 0x07 | Arcade | Black | Green | Retro terminal |
| 0x08 | Neon | Black | Magenta | |
| 0x09 | Ice | Sky Blue | White | |
| 0x0A | Fire | Maroon | Yellow | |
| 0x0B | Earth | Brown | Gold | |
| 0x0C | Grape | Purple | Pink | |
| 0x0D | Mint | Dark Green | Cyan | |
| 0x0E | Steel | Dark Gray | Silver | |
| 0x0F | Coral Reef | Dark Blue | Coral | |
| 0x10 | Rainbow Dark | Black | Animated | Rainbow FG on black BG |
| 0x11 | Rainbow Light | White | Animated | Rainbow FG on white BG |

**Rainbow Mode Details:**

IDs 0x10 and 0x11 enable animated rainbow effects:
- **Rainbow Dark (0x10)**: Uses palette 0 (Classic) as the base, with color 14 (FG) animated through rainbow colors at runtime
- **Rainbow Light (0x11)**: Uses palette 1 (Inverted) as the base, with color 14 (FG) animated through rainbow colors at runtime

The rainbow animation cycles through 8 colors (red, orange, yellow, green, cyan, blue, indigo, violet) by replacing the foreground color slot during V-Blank.

#### **Audio (Byte 0x0003)**

| ID | Name | Description |
|----|------|-------------|
| 0x00 | `AUDIO_DEFAULT` | Default boot chime |
| 0x01 | `AUDIO_SILENT` | No audio |
| 0xFF | `AUDIO_RANDOM` | Random boot audio |

### **2. Game Code and Data (0x0080 onwards)**

The rest of the cartridge ROM is dedicated to the game's program code, graphics data, sound data, and other assets.

- **Entry Point (0x0080)**: After the boot sequence, the CPU begins executing game code starting at address 0x0080.
- **ROM Bank 0 (0x0081 - 0x3FFF)**: This area contains the rest of the fixed, non-switchable portion of the game's code. It typically holds the main game loop and critical subroutines that need to be accessible at all times.
- **Switchable ROM Banks (Mapped to 0x4000 - 0x7FFF)**: The remainder of the physical ROM chip contains the switchable banks. The game can map these banks into the CPU's address space to access additional code and data, such as level maps, enemy sprites, and music.

### **3. Interrupt Vector Table**

The 26-byte block from `0x0060` to `0x0079` is reserved for the Interrupt Vector Table. This table contains the starting addresses for the game's interrupt service routines.

The Cicada-16 supports two different modes for handling interrupts ("Standard" and "Enhanced"), which control whether this table is used directly from ROM or copied to RAM for dynamic modification. The desired mode is selected via a flag in the cartridge header (Bit 7 of byte `0x0028`).

For a complete explanation of the interrupt system, vector table layout, and handling modes, see the **`Interrupts.md`** document.


---

© 2025 Connor Nolan. This work is licensed under a
[Creative Commons Attribution-ShareAlike 4.0 International License](http://creativecommons.org/licenses/by-sa/4.0/).