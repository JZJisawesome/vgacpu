//Intended for use with verilator
//Based on tb from JZJCoreF

module vgacpu_verilator (
    input logic clk,
    input logic n_rst_async,
    input logic [3:0] buttons_async,

    output logic vga_r, vga_g, vga_b,
    output vga_hsync, vga_vsync,

    output buzzer
);

vgacpu_top top (.*);

initial begin
    $dumpfile("/tmp/vgacpu_verilator.vcd");
    $dumpvars(0, vgacpu_verilator);
end

//Clock cycle counter to end simulation
logic [63:0] counter = 0;

always_ff @(posedge clk) begin
    counter <= counter + 1;

    if (counter == 1000000)
        $finish();
end

endmodule
