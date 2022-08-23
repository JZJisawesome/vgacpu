#!/bin/bash
#Based on script from JZJCoreF

FILES_TO_INCLUDE="-I ../../src/common.sv -I ../../src/rasterizer.sv -I ../../src/framebuffer.sv -I ../../src/vgacpu_top.sv -I ../../src/sound.sv -I ../../src/vga.sv -I ../../src/buttons.sv -I ../../src/cpu/cpu_common.sv  -I ../../src/cpu/vgacpu.sv -I ../../src/cpu/control.sv -I ../../src/cpu/main_mem.sv -I ../../src/cpu/alu.sv -I ../../src/cpu/agu.sv -I ../../src/cpu/reg_file.sv -I ../../src/cpu/rf_mux.sv -I ../../src/cpu/sp.sv -I ../../src/cpu/fetch.sv -I ../../src/cpu/decode.sv -I ../../src/cpu/pr.sv -I ../../src/cpu/rasterizer_controller.sv -I ../../src/cpu/snd_controller.sv -I ../../src/cpu/button_controller.sv"

#Verilate the testbench and vgacpu SystemVerilog files//todo split into multiple commands
verilator $FILES_TO_INCLUDE --timescale 10ns/10ns -Wall -Wno-fatal -sv -cc verilator.sv --exe --trace-fst -O3 --top-module vgacpu_verilator +1800-2017ext+sv --build verilator.cpp
#Run the simulation (creates /tmp/vgacpu_verilator.vcd)
(cd ../../ && ./tb/verilator/obj_dir/Vvgacpu_verilator)
#Open in waveform viewer
gtkwave /tmp/vgacpu_verilator.vcd
#Delete files
rm -rf ./obj_dir
rm /tmp/vgacpu_verilator.vcd
