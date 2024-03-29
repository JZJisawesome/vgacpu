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
r6: x1 coordinate register (for FB access); low extended address register
r7: y1 coordinate register (for FB access); high extended address register
In addition, 3 other registers:
sp: Stack pointer (starts at end of address space) 14 bits
pc: Program counter (starts at start of address space) 14 bits
ps: Data page register 6 bits

### Instructions

#### Encoding

Byte 0: 76543210

Bits [1:0] encodes the instruction format
0 means no-operand instruction (bits 7:2 are the opcode)
1 means 1-operand instruction bits 4:2 are the opcode subtype, bits 7:5 is the operand
2 means 2-byte instruction: bits 4:2 are the opcode subtype, bits 7:5 is the operand, second byte is for instruction-specific use
3 means other 2-byte instructions: bits 7:2 are the opcode subtype, second byte is for instruction-specific use
0 means 0, 1 means 1
If 1 operand,
If no operands, bits 7:1 are the opcode

#### Instruction Summary

May add more instructions (particularly more rendering instructions) in the future

##### [11] Other 2-byte

###### [111] Rasterizer Commands

[000] | FILL IMM         | Fill the entire screen where the lowest 3 bits of IMM contain the colour
[001] | POINT IMM        | Plot a point at [x0, y0] in the FB where the lowest 3 bits of IMM contain the colour
[010] | LINE IMM         | Draw a line between the coordinates [x0, y0] and [x1, y1] where the lowest 3 bits of IMM contain the colour
[011] | RECT IMM         | Fill the rectangle bounded by the coordinates [x0, y0] and [x1, y1] where the lowest 3 bits of IMM contain the colour

###### TODO

TODO assign these propertly

[000000] | PAGE IMM         | Set the current data page to the lower 6 bits in IMM
[000001] | SJUMP IMM        | (Short) Unconditional jump to the address IMM in the current data page
[000010] | SJLT IMM         | (Short) Conditional jump if r0 < r1 to the address IMM in the current data page
[000011] | SJEQ IMM         | (Short) Conditional jump if r0 = r1 to the address IMM in the current data page
[000100] | SJGT IMM         | (Short) Conditional jump if r0 > r1 to the address IMM in the current data page
[001000] | WAIT IMM         | Wait IMM number of clock cycles
[001001] | SCALL IMM        | (Short) Unconditional jump to the address contained IMM in the current data page; current address pushed onto stack (2 bytes)
[001010] | POLLIN IMM       | (Short) Write 1 into r0 if the IMMth input is on, else write 0 (ex. used for getting push button state)s


TODO assign SL and SR so that the lowest 3 bits are 000 and 001

[110000] | SL IMM           | Shift bits in r0 left by IMM
[110001] | SR IMM           | Shift bits in r0 right by IMM

##### [10] 2-byte

[000] | LIM rX, IMM         | Load immediate IMM into rX
[001] | CHAR rX, IMM        | Write the ASCII char in rX to the point [x0, y0] (colour chosen by IMM)
[010] | LOAD rX, IMM        | Load the byte from the address IMM in the current data page into rX
[011] | STORE rX, IMM       | Store the byte in rX to the address IMM in the current data page

##### [01] One operand

TODO swap push and pop with 0TOX and XTO0???

[000] | 0TOX IMM            | Copy the contents of r0 to rX
[001] | XTO0 IMM            | Copy the contents rX to r0
[010] | ADD rX              | Add the register rX to r0 and store in r0
[011] | SUB rX              | Sub the register rX from r0 and store in r0
[100] | AND rX              | And the register rX with r0 and store in r0
[101] | OR rX               | Or the register rX with r0 and store in r0
[110] | XOR rX              | XOR the register rX with r0 and store in r0
[111] | MUL rX              | Multiply the register rX with r0 and store (the lower 8 bits of the result) in r0

##### [00] No operands

###### [000] External Devices

[000] | ENVGA            | Enable VGA output hardware (not the framebuffer, which is always available); disabled at reset
[001] | LOGO             | Write the vgacpu logo to the framebuffer

[100] | POLLBLANK        | Write 1 into r0 if in a blanking period, else write 0
[101] | POLLRENDERBUSY   | Write 1 into r0 if the renderer is busy writing to the framebuffer, etc 0

[110] | NOTONE           | Stop playing a tone
[111] | TONE             | Play the tone contained in r5 (high bits) and r4 (low bits) (195312.5 / desired_freq) //TODO Adjust this to what it ends up being

###### [001] Control Transfer

[000] | RET              | Pop 2 bytes from the stack containing the address to return to
[001] | LCALL            | (LONG) Unconditional jump to the address contained in r7 and r6; current address pushed onto stack (2 bytes)

[010] | JUMP             | (LONG) Unconditional jump to the address contained in r7 and r6

[011] | JLT              | (LONG) Conditional jump if r0 < r1 to the address contained in r7 and r6
[100] | JEQ              | (LONG) Conditional jump if r0 = r1 to the address contained in r7 and r6
[101] | JGT              | (LONG) Conditional jump if r0 > r1 to the address contained in r7 and r6
[110] | JBEZ             | Jump back to the previous instruction if r0 == 0 (useful for polling)
[111] | JBNEZ            | Jump back to the previous instruction if r0 != 0 (useful for polling)

###### [100] Memory Access

[000] | PUSH             | Push r0 onto the stack
[001] | POP              | Pop a byte from the stack into r0

###### [111] Special

[000] | NOP              | No operation
[001] | HALT             | Spin forever
[111] | RESET            | Reset the system

## Implementation Brainstorming/Details

## Instruction Cycle

### Old

TODO rename FETCH to FETCH_DECODE since we can only transition between states on the positive edge but don't know the fetch is done until the posedge too. Also rename DECODE to EXECUTE

After reset, control is in the FETCH state and the fetch unit is in the BYTE_1_PREP state.

Posedge 1:
    When the first posedge occurs, the first word of memory is fetched into the memory's output registers,
    and the fetch unit transitions to BYTE_2_PREP_BYTE_1_FINISH. Control's state is still FETCH since it does not
    yet know the fetch is complete

In Between:
    Combinational logic in the fetch unit indicates that the instruction fetch is finished, and bypasses the
    fetch buffer to connect the memory's output register to the instruction output of the fetch unit.
    Since the instruction fetch is finished, the decoder is enabled and combinationally decodes the instruction now.

Posedge 2:
    The memory's output is latched into the fetch buffer, and the decoder's result is latched into it's output.
    Now the control logic sees that the FETCH has finished, and transitions to DECODE.

In Between:
    Using the decoded result, the instruction is mostly executed, but since the control logic is still in DECODE, not everything is completed.
    Also the instruction output of the fetch unit switches to outputting the contents of the fetch buffer instead of bypassing it.

Posedge 3: The control logic transitions to EXECUTE. Some things were latched due to decode's signals now, but not everything

In Between: Nothing really happens

Posedge 4: Things that depended on the control being in EXECUTE occur now.

In between: Transition to fetch

Posedge 5: ???

### New

After reset, control is in the FETCH_DECODE state and the fetch unit is in the BYTE_1_PREP state.
In this state, the initial addresses are configured for the memory so that when the first posedge arrives,
the first instruction can be fetched.

Posedge 1:
    When the first posedge occurs, the first word of memory is fetched into the memory's output registers,
    and the fetch unit transitions to BYTE_2_PREP_BYTE_1_FINISH. Control's state is still FETCH_DECODE since it does not
    yet know the fetch is complete (and the decode step isn't complete yet anyways).

In Between:
    Combinational logic in the fetch unit indicates that the instruction fetch is finished, and bypasses the
    fetch buffer to connect the memory's output register to the instruction output of the fetch unit.
    Since the instruction fetch is finished, the decoder is enabled and combinationally decodes the instruction now.

Posedge 2:
    The memory's output is latched into the fetch buffer, and the decoder's result is latched into its output.
    Now the control logic sees that the fetch has finished, and transitions to EXECUTE. This is okay since the decode step
    always takes exactly one clock cycle, so even though the control logic only sees the fetch finished 1 clock cycle later,
    during that time decode has also finished. So it is safe to jump right to EXECUTE.

In Between:
    The instruction is executed.
    We also increment the PC on this step. TODO could we do this during the second clock cycle of FETCH_DECODE so we save a cycle on the next instruction? (depending on the instruction). Then we change the address properly if it turns out the instruction would change the PC during execute?

NOTE: EXECUTE may last several clock cycles depending on the instruction. Regardless, by the end, the PC should we setup and (potentially) the next instruction already fetched on or before "Posedge 3"

Posedge 3: Control transitions to FETCH_DECODE, seeing a changed PC, the fetch unit transitions to BYTE_1_PREP, and the cycle repeats.

### Control Signals For Modules

#### Register File
rf_write_en | Write enable

#### ALU

alu_operation | ALU operation
alu_operand   | ALU second operand

#### RF Mux
rf_mux_src    | Source for register file input

#### Stack Pointer
sp_operation  | The operation to perform with the stack pointer

#### Fetch Unit/PC
fetch_operation | What to do with the PC (after which point the inst is fetched)

#### Decode Unit
decode_en       | Perform the decode (1) or hold the prev output (0)

#### AGU
agu_operation   | Type of mem address to generate

#### Page Register
pr_write_en     | Copy the lower 6 bits of the immediate to the register, else hold the prev value

#### Memory
mem_data_write_en | Write data to memory or not
