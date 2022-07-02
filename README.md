# vgacpu
A small core implementing a custom ISA running on the same clock as a VGA driver. Written in SV, with the purpose of refreshing myself on how to use the HDL (I'm a bit rusty :))

## Design Brainstorm

My FPGA devboard supports 3-bpp VGA so that is what I will base my design around.
Let's aim for a 640x480 output resolution.

My FPGA has 276480 bits of SRAM, which isn't enough for a full 640x480 framebuffer.
Since the core will run at the same frequency the VGA output logic runs, we probably won't be able
to pain all pixels that fast anyways. So let's make the internal resolution a thirdish in each direction:
214x160. So we're already ahead of the Game Boy :).

So we are left with
276480 - 214x160x3 = 173760 bits for instruction memory, data memory, microcode rom (if needed), etc.
Let's do a 16KiB shared I and D mem, leaving another 173760 - 16x1024x8 = 42688 bits of overhead
to give the fitter some breathing room and for any additional purposes.

So we have two address spaces: Framebuffer, and main memory.
I know from past projects, for main memory, the SRAM is dual-ported so reading at the same time we write. For simplicity,
let's make the FB write-only.

We could have instructions to write to individual pixels in the fram buffer. There could also be instructions to
asyncrenously fill an area/clear the screen/etc (while the CPU continues running), or some sort of DMA from main memory into the FB.
We could even do line-drawing in hardware perhaps!

We can also have instructions to read user input (buttons, etc) as well as control other IO devices (perhaps wire up 7seg displays or blink leds)?
We can also have instructions to configure the VGA logic (ex. turn off the display/etc).
****We could do mode switching: 214x160 at 3bpp or 320x240 in monochrome!**** ****Maybe instead 256x240 so we can use 8bit addresses****
It would also be good to avoid screen tearing: perhaps add instructions to poll if we are in HBLANK/VBLANK, or some sort of interrupt system?

We need instructions for sound as well (perhaps a single instruction to specify a frequency to play)

Perhaps also hardware timers would be useful and instructions to configure/query them (or we could just do everything relative to the display refresh rate)

Additionally, we need a good mix of instructions for regular data processing/etc

## ISA

I want to give a variable length/CISC-style ISA a shot (for fun)!
Let's also go with an 8bit design this time around!

### Registers
Let's go with 8 user-accessible registers (8bits each):
r0: accumulator/math register
r1: comparison register for branches
r2: gp register
r3: gp register
r4: x0 coordinate register (for FB access); low tone byte
r5: y0 coordinate register (for FB access); high tone byte
r6: x1 coordinate register (for FB access); low address register
r7: y1 coordinate register (for FB access); high address register
In addition, 3 other registers:
sp: Stack pointer (starts at end of address space) 14 bits
pc: Program counter (starts at start of address space) 14 bits
ps: Data page register 6 bits

### Instructions

#### Encoding

Byte 0: 76543210
Bits [1:0] encodes the instruction format
0 means no-operand instruction (bits 7:2 are the opcode)
1 means 1-operand instruction bits 4:2 are the opcode, bits 7:5 is the operand
2 means 2-byte instruction: bits 4:2 are the opcode, bits 7:5 is the operand, second byte is for instruction-specific use
3 means other 2-byte instructions: bits 7:2 are the opcode, second byte is for instruction-specific use
0 means 0, 1 means 1
If 1 operand,
If no operands, bits 7:1 are the opcode


#### Instruction Summary

May add more instructions (particularly more rendering instructions) in the future

##### [11] Other 2-byte

[000000] | PAGE IMM         | Set the current data page to the lower 6 bits in IMM
[000001] | SJUMP IMM        | (Short) Unconditional jump to the address IMM in the current data page
[000010] | SJLT IMM         | (Short) Conditional jump if r0 < r1 to the address IMM in the current data page
[000011] | SJEQ IMM         | (Short) Conditional jump if r0 = r1 to the address IMM in the current data page
[000100] | SJGT IMM         | (Short) Conditional jump if r0 > r1 to the address IMM in the current data page
[000101] | FILL IMM         | Fill the rectangle bounded by the coordinates [x0, y0] and [x1, y1] where the lowest 3 bits of IMM contain the colour
[000110] | POINT IMM        | Plot a point at [x0, y0] in the FB where the lowest 3 bits of IMM contain the colour
[000111] | LINE IMM         | Draw a line between the coordinates [x0, y0] and [x1, y1] where the lowest 3 bits of IMM contain the colour
[001000] | WAIT IMM         | Wait IMM number of clock cycles
[001001] | SCALL IMM        | (Short) Unconditional jump to the address contained IMM in the current data page; current address pushed onto stack (2 bytes)
[001010] | POLLIN IMM       | (Short) Write 1 into r0 if the IMMth input is on, else write 0 (ex. used for getting push button state)

[100000] | 0TOX IMM         | Copy the contents of r0 to the register specified by bits [2:0] of the second byte
[100001] | XTO0 IMM         | Copy the contents the register specified by bits [2:0] of the second byte to r0

##### [10] 2-byte

[000] | LIM rX, IMM         | Load immediate IMM into rX
[001] | CHAR rX, IMM        | Write the ASCII char in rX to the point [x0, y0] (colour chosen by IMM)
[010] | LOAD rX, IMM        | Load the byte from the address IMM in the current data page into rX
[011] | STORE rX, IMM       | Store the byte in rX to the address IMM in the current data page
[100] | SL rX, IMM          | Shift bits in rX left by IMM
[101] | SR rX, IMM          | Shift bits in rX right by IMM

##### [01] One operand

[000] | PUSH rX             | Push rX onto the stack
[001] | POP rX              | Pop a byte from the stack into rX
[010] | ADD rX              | Add the register rX to r0 and store in r0
[011] | SUB rX              | Sub the register rX from r0 and store in r0
[100] | AND rX              | And the register rX with r0 and store in r0
[101] | OR rX               | Or the register rX with r0 and store in r0
[110] | XOR rX              | XOR the register rX with r0 and store in r0
[111] | MUL rX              | Multiply the register rX with r0 and store (the lower 8 bits of the result) in r0

##### [00] No operands

[000000] | NOP              | No operation
[000001] | ENVGA            | Enable VGA output hardware (not the framebuffer, which is always available); disabled at reset
[000010] | TONE             | Play the frequency contained in r5 (high bits) and r4 (low bits) multiplied by 2
[000011] | NOTONE           | Stop playing a tone
[000100] | JUMP             | (LONG) Unconditional jump to the address contained in r7 and r6
[000101] | JLT              | (LONG) Conditional jump if r0 < r1 to the address contained in r7 and r6
[000110] | JEQ              | (LONG) Conditional jump if r0 = r1 to the address contained in r7 and r6
[000111] | JGT              | (LONG) Conditional jump if r0 > r1 to the address contained in r7 and r6
[001000] | LCALL            | (LONG) Unconditional jump to the address contained in r7 and r6; current address pushed onto stack (2 bytes)
[001001] | LOGO             | Write the vgacpu logo to the framebuffer
[001010] | POLLBLANK        | Write 1 into r0 if in a blanking period, else write 0
[001011] | POLLRENDERBUSY   | Write 1 into r0 if the renderer is busy writing to the framebuffer, etc 0
[001100] | RET              | Pop 2 bytes from the stack containing the address to return to
[001101] | JBEZ             | Jump back to the previous instruction is r0 = 0 (useful for polling)
[001110] | JBNEZ            | Jump back to the previous instruction is r0 != 0 (useful for polling)
[111111] | RESET            | Reset the system
[111110] | HALT             | Spin forever
