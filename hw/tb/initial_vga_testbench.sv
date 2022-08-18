//To use, run these commands from the /hw directory:
//iverilog ./src/common.sv ./src/vgacpu_top.sv ./src/inferred_sram.sv ./src/sound.sv ./src/rasterizer.sv ./src/vga.sv ./src/buttons.sv ./src/cpu/vgacpu.sv ./src/cpu/control.sv ./tb/initial_vga_testbench.sv -g2012 -o /tmp/initial_vga_testbench.out
//vvp /tmp/initial_vga_testbench.out
//gtkwave /tmp/initial_vga_testbench.vcd

`timescale 10ns/1ns//Makes it nice for a 50MHz clock
module initial_vga_testbench;

logic clk;
logic n_rst_async;

logic [3:0] buttons_async;

logic vga_r, vga_g, vga_b;
logic vga_hsync, vga_vsync;

logic buzzer;

vgacpu_top top (.*);


initial begin
    $dumpfile("/tmp/initial_vga_testbench.vcd");
    $dumpvars(0, initial_vga_testbench);

    //Reset everything
    n_rst_async = 0;
    #1
    n_rst_async = 1;

    clk = 0;
    for (int i = 0; i < 2000000; i = i + 1)//2M clock cycles is a little over 1 frame
    begin
        #1;//50MHz
        clk = ~clk;
    end
end

endmodule
