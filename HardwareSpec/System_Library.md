# **Cicada-16 System Library**

This document describes the architecture of the permanent System Library, which is located in its own dedicated, read-only RAM region at **`E000-EFFF`**.

These functions are copied from the internal Boot ROM to the System Library RAM by the boot process and are available for any game to use. They provide standardized, optimized routines for common tasks. After the boot sequence completes, this memory region is made read-only to protect the library's integrity.

For detailed documentation of each function and data block, see [ProgrammingDocs/System_Library_Reference.md](../ProgrammingDocs/System_Library_Reference.md).

## **System Call Vector Table**

To provide a stable and future-proof API, all System Library functions and data are accessed indirectly through a **System Call Vector Table**. This table is located at the very beginning of the System Library RAM, starting at `E000`.

- **Size**: The table has 128 entries, each being a 16-bit pointer. This provides a total of 128 unique system calls.
- **Memory Footprint**: 128 entries \* 2 bytes/entry = 256 bytes (`E000-E0FF`).
- **Function**: Each entry in the table holds the absolute 16-bit address of a specific system function or data block. To call a function, a developer uses its official vector number (e.g., `SYSCALL_DECOMPRESS_RLE`) to look up the address in the table and then performs an indirect call.
- **Data Blocks**: For library data blocks (such as the Default Font, Note Frequency Table, Default Waveforms, and Percussion Presets), the vector table contains a single entry that points to the beginning address of the respective data block.

This vector table approach ensures that even if the internal layout of the System Library changes in future hardware revisions, the vector numbers for existing functions will remain the same, maintaining backward compatibility for all software.

**Example Usage (Conceptual):**

```assembly
; Assume R0 points to the start of the vector table (E000)
; Assume the vector number for 'fastMultiply16' is 0x2A

; Calculate the address of the vector entry
LDI R1, 0x2A * 2 ; Vector number * 2 bytes per entry
ADD R0, R1       ; R0 now points to the correct entry in the table

; Load the function's actual address from the vector table
LD.w R0, (R0)

; Call the function
CALL (R0)
```

## **Memory Layout and Budget**

The 4 KiB (4096 bytes) of System Library RAM is allocated as follows:

| Component                  | Size (Bytes) | Address Range (Approx.) | Notes                                 |
| :------------------------- | :----------- | :---------------------- | :------------------------------------ |
| **System Call Vectors**    | 256          | `E000-E0FF`             | 128 entries \* 2 bytes each           |
| **Default Font Data**      | 768          | `E100-E3FF`             | 96 characters \* 8 bytes each (1bpp)  |
| **Sine Wave Table**        | 256          | `E400-E4FF`             | 256 samples for wave synthesis        |
| **Note Frequency Table**   | 120          | `E500-E577`             | 5 octaves _ 12 notes _ 2 bytes each   |
| **Default APU Waves**      | 128          | `E578-E5F7`             | 4 waveforms \* 32 bytes each          |
| **APU Percussion Presets** | 24           | `E5F8-E610`             | ADSR/timing for drum sounds           |
| **(Function Code)**        | 2544         | `E611-EFFF`             | Remaining space for library functions |
| **Total**                  | **4096**     | `E000-EFFF`             |                                       |

## **Vector Table Index Map**

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

© 2025 Connor Nolan. This work is licensed under a
[Creative Commons Attribution-ShareAlike 4.0 International License](http://creativecommons.org/licenses/by-sa/4.0/).
