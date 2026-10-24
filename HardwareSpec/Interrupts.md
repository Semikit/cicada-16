# **Cicada-16 Interrupt System**

## **1. Introduction**

Interrupts are a mechanism that allows the CPU to pause its current task to handle a high-priority hardware event, such as the PPU finishing a frame (V-Blank). This allows for efficient, event-driven programming and is the primary way that games on the Cicada-16 handle graphical updates, sound, and other timed events.

## **2. The Interrupt Process**

The process for triggering and handling an interrupt or CPU fault is as follows:

1.  A specific hardware event occurs (e.g., the V-Blank period begins) OR a CPU fault condition is detected (e.g., unaligned memory access).
2.  For hardware interrupts, the hardware automatically sets the corresponding flag bit in the **`IF` (Interrupt Flag)** register at `F021`. For CPU faults, the fault condition is directly detected by the CPU.
3.  At the end of each instruction cycle, the CPU checks for pending interrupts or faults.
    - **For Hardware Interrupts:** An interrupt will be serviced if three conditions are met:
      a. The master interrupt switch is enabled (which is done by the `EI` instruction).
      b. The specific interrupt's bit is set to `1` in the **`IE` (Interrupt Enable)** register at `F020`.
      c. The specific interrupt's bit is set to `1` in the **`IF` (Interrupt Flag)** register.
    - **For CPU Faults:** Faults are generally non-maskable and will be serviced immediately, regardless of the master interrupt switch or `IE`/`IF` registers.
4.  If conditions are met, the CPU performs the following actions:
    a. Disables further interrupts (master interrupt switch is cleared).
    b. Pushes the current 16-bit Program Counter (PC) to the stack.
    c. Pushes the current 16-bit Flags register (F) to the stack.
    d. Jumps to the address specified for that interrupt or fault in the **Interrupt Vector Table**.
5.  The code at that address, the Interrupt Service Routine (ISR) or Fault Handler, is executed. Steps 4a-4d take a fixed **16 T-cycles** (two 16-bit stack pushes), measured from the end of the interrupted instruction to the first fetch of the handler. The vector table read is not charged separately, consistent with `SYSCALL`.
6.  Inside the ISR, the programmer is responsible for manually clearing the interrupt flag in the `IF` register by writing a `1` to its bit. This prevents the interrupt from immediately re-triggering after the ISR is complete. (This step is not applicable for CPU Faults, as they are not tied to `IF` bits).
7.  The ISR/Fault Handler must end with the `RETI` (Return from Interrupt) instruction, which pops the original F register, then the PC from the stack, and re-enables the master interrupt switch.

## **3. Interrupt Sources and Registers**

The Cicada-16 has eight hardware interrupt sources, controlled via the `IE` (`F020`) and `IF` (`F021`) registers.

| Bit | Name            | Description                                                                 |
| :-- | :-------------- | :-------------------------------------------------------------------------- |
| 7   | **Joypad**      | Occurs when a joypad button is pressed **(on the 1-to-0 transition only)**. |
| 6   | **Link Status** | Occurs when the serial port `CONNECTED` bit changes state.                  |
| 5   | **Serial**      | Occurs when a serial data transfer is complete.                             |
| 4   | **Timer 1**     | Occurs when the TIMA1 timer overflows.                                      |
| 3   | **Timer 0**     | Occurs when the TIMA timer overflows.                                       |
| 2   | **LYC == LY**   | Occurs when the PPU's `LY` register equals the `LYC` register.              |
| 1   | **H-Blank**     | Occurs when the PPU enters the H-Blank period.                              |
| 0   | **V-Blank**     | Occurs when the PPU enters the V-Blank period.                              |

The three PPU interrupts (V-Blank, H-Blank, and LYC == LY) are gated twice. The PPU only sets the corresponding `IF` bit if the matching enable bit in the PPU's `STAT` register (`VBLK_INT_EN`, `HBLK_INT_EN`, `LYC_INT_EN`) is set. The `IE` bit then controls whether the CPU services the pending flag. See `PPU_Architecture.md` section 9.

### **IE (F020) - Interrupt Enable Register**

This register controls whether a specific hardware interrupt is allowed to trigger the CPU's interrupt sequence. Setting a bit to `1` enables the corresponding interrupt.

| Bit | Name            | Type | Function                                  |
| :-- | :-------------- | :--- | :---------------------------------------- |
| 7   | **Joypad**      | R/W  | Enable Joypad Interrupt                   |
| 6   | **Link Status** | R/W  | Enable Link Status Interrupt              |
| 5   | **Serial**      | R/W  | Enable Serial Transfer Complete Interrupt |
| 4   | **Timer 1**     | R/W  | Enable Timer 1 Overflow Interrupt         |
| 3   | **Timer 0**     | R/W  | Enable Timer 0 Overflow Interrupt         |
| 2   | **LYC == LY**   | R/W  | Enable PPU LYC Interrupt                  |
| 1   | **H-Blank**     | R/W  | Enable PPU H-Blank Interrupt              |
| 0   | **V-Blank**     | R/W  | Enable PPU V-Blank Interrupt              |

### **IF (F021) - Interrupt Flag Register**

This register holds the flags for pending hardware interrupts. When a hardware event occurs, the corresponding bit is set to `1` by the hardware. It is the programmer's responsibility to clear the flag by writing a `1` to the bit inside the ISR.

| Bit | Name            | Type | Function                                                                                     |
| :-- | :-------------- | :--- | :------------------------------------------------------------------------------------------- |
| 7   | **Joypad**      | R/W  | Joypad Interrupt Flag. Set when a joypad button is pressed.                                  |
| 6   | **Link Status** | R/W  | Link Status Interrupt Flag. Set when the `CONNECTED` bit in the `SC` register changes state. |
| 5   | **Serial**      | R/W  | Serial Transfer Complete Flag. Set when a serial data transfer finishes.                     |
| 4   | **Timer 1**     | R/W  | Timer 1 Overflow Flag. Set when the `TIMA1` register overflows.                              |
| 3   | **Timer 0**     | R/W  | Timer 0 Overflow Flag. Set when the `TIMA` register overflows.                               |
| 2   | **LYC == LY**   | R/W  | PPU LYC Flag. Set when `LY` == `LYC`.                                                        |
| 1   | **H-Blank**     | R/W  | PPU H-Blank Flag. Set when the PPU enters the H-Blank period.                                |
| 0   | **V-Blank**     | R/W  | PPU V-Blank Flag. Set when the PPU enters the V-Blank period.                                |

## **4. CPU Faults**

CPU Faults are critical, non-maskable events triggered by illegal or dangerous operations detected by the processor. Unlike hardware interrupts, they are not controlled by the `IE` and `IF` registers and will always be serviced immediately. When a fault occurs, the CPU pushes the PC and Flags register to the stack and jumps to the corresponding fault handler in the Interrupt Vector Table.

- **Bus Error:** Triggered when a 16-bit word (e.g., from an `LD r, (n16)` instruction) is accessed from an odd memory address. All 16-bit memory accesses must be aligned to an even address.
- **Illegal Instruction:** Triggered when the CPU attempts to execute an opcode that is not defined in the instruction set, including any reserved or unused opcode values.
- **Protected Memory:** Triggered when a write operation is attempted on a memory region that is designated as read-only. This includes the cartridge ROM space (`0x0000-0x7FFF`), the System Library RAM (`E000-EFFF`) after boot, the `SYS_CFG` register (`F026`) after boot, and Cartridge RAM (`0x8000-0x8FFF`) while the `WE_LATCH` register is locked or when the cartridge has no RAM. DMA writes are subject to the same rule.
- **Stack Overflow:** Triggered if the Stack Pointer (SP) register decrements below the base of the stack memory region (`0xC000`). This helps catch runaway recursive calls or stack corruption before it overwrites other critical memory.

## **5. The RESET Interrupt**

The console has a physical **Reset button**. Pressing it raises the **RESET** interrupt, which performs a *warm* reset: the boot ROM is **not** re-run, memory is **not** cleared, and the game regains control through its own RESET vector. This mirrors the behavior of the reset button on classic cartridge consoles, where the game itself decides what "reset" means (usually a return to the title screen).

RESET is non-maskable. It has no `IE` or `IF` bit and cannot be disabled or cleared by software. It is edge-triggered: holding the button down does not retrigger it.

When RESET is raised, the CPU performs the following sequence:

1. Exits `HALT` if halted, and discards any instruction in the pipeline.
2. Aborts any DMA transfer in progress and clears the `START` bit in `DMA_CTL`. Data already transferred is left in place.
3. Clears the master interrupt switch (as if `DI` had been executed).
4. Clears any pending CPU fault.
5. Sets the stack pointer (`R7`) to `0xD000`. Nothing is pushed to the stack, as there is nothing to return to.
6. Jumps to the address in the RESET vector (offset `+0x0` of the Interrupt Vector Table).

Everything else is left untouched: all RAM (WRAM, HRAM, VRAM, OAM, CRAM, Wave RAM, the DSP buffer), every PPU, APU, timer, DMA, serial, and bank register, the `WE_LATCH` and `SYS_CFG` registers, and the RTC. The RESET handler is responsible for re-initializing whatever the game needs. Because RAM survives, a handler can inspect a signature value left in RAM to distinguish a warm reset from a cold power-on, and choose to skip an intro or preserve session data.

The RESET vector is fetched from the active vector table like any other vector. In Standard Mode that is the cartridge ROM copy at `0x0060`; in Enhanced Mode it is the WRAM copy at `0xBFE0`, which the game may modify at runtime like any other vector. If the Reset button is pressed while the boot ROM is still running, the boot ROM's internal vector table is used and the boot sequence restarts.

There is no software-initiated cold reset. Once the boot ROM has handed over to the game, it cannot be re-entered without a power cycle. A game that wants to reset itself warm can simply read the RESET vector and jump to it.

## **6. Interrupt Vector Table**

The Interrupt Vector Table is a 26-byte block of memory containing the 16-bit addresses for each ISR or Fault Handler. The layout below is defined by its offset from the table's base address. The order also determines priority if multiple interrupts or faults occur simultaneously.

| Vector Address Offset | Interrupt Source        | Priority  |
| :-------------------- | :---------------------- | :-------- |
| `+0x0`                | `RESET`                 | Highest   |
| `+0x2`                | **Bus Error**           | **Fault** |
| `+0x4`                | **Illegal Instruction** | **Fault** |
| `+0x6`                | **Protected Memory**    | **Fault** |
| `+0x8`                | **Stack Overflow**      | **Fault** |
| `+0xA`                | `V-Blank`               | 1         |
| `+0xC`                | `H-Blank`               | 2         |
| `+0xE`                | `LYC == LY`             | 3         |
| `+0x10`               | `Timer 0`               | 4         |
| `+0x12`               | `Timer 1`               | 5         |
| `+0x14`               | `Serial`                | 6         |
| `+0x16`               | `Link Status`           | 7         |
| `+0x18`               | `Joypad`                | 8         |

## **7. Vector Table Location Modes**

The Cicada-16 supports two modes for the location of the interrupt vector table, determined by a flag in the cartridge header and configured via the **`SYS_CFG`** register at `F026`. This provides a choice between simplicity and advanced functionality.

### **The SYS_CFG Register**

The **`SYS_CFG`** register (`F026`) controls the interrupt vector table mode at runtime. Bit 0 (`IVT_MODE`) determines where the CPU fetches interrupt vectors from:

- **IVT_MODE = 0:** Standard Mode (vectors in ROM)
- **IVT_MODE = 1:** Enhanced Mode (vectors in RAM)

This register is **writeable only during boot** and becomes **read-only after the boot sequence completes**. The boot ROM sets this bit based on the cartridge header flag. See **`IO_Peripherals.md`** for full register documentation.

### **Standard Mode (ROM-Based)**

This is the default and simplest mode.

- **Cartridge Header Flag**: The "Interrupt Mode" bit (Bit 7 of byte `0x0028`) is set to `0`.
- **Boot Behavior**: The boot ROM writes `0x00` to `SYS_CFG`, setting `IVT_MODE` to 0.
- **Runtime Behavior**: The CPU fetches interrupt vectors from the cartridge ROM at **`0x0060 - 0x0079`** (26 bytes).
- **Implementation**: The game developers place a static list of 16-bit addresses at this location in their ROM file. The interrupt handlers are fixed for the lifetime of the game.

### **Enhanced Mode (RAM-Based)**

This mode enables advanced programming techniques by allowing the game to modify its interrupt handlers on the fly.

- **Cartridge Header Flag**: The "Interrupt Mode" bit is set to `1`.
- **Boot Behavior**: The boot ROM reads this flag and performs two actions:
  1.  It writes `0x01` to `SYS_CFG`, setting `IVT_MODE` to 1. This configures the CPU to fetch interrupt vectors from Work RAM Bank 0 (WRAM0) at **`0xBFE0 - 0xBFF9`** (26 bytes).
  2.  It uses the DMA controller to automatically copy the 26-byte vector table from the cartridge ROM (`0x0060`, mapped to `0x4060` during boot) to WRAM (`0xBFE0`) as a default starting point.
- **Flexibility**: Because the interrupt table is in RAM, the game can overwrite any of these vector addresses at any time to point to different handler routines, allowing for dynamic, state-based interrupt handling.

---

© 2025 Connor Nolan. This work is licensed under a
[Creative Commons Attribution-ShareAlike 4.0 International License](http://creativecommons.org/licenses/by-sa/4.0/).
