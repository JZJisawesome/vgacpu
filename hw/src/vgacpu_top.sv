/* vgacpu_top
 * By: John Jekel
 *
 * Top-level file for the project's hardware.
 *
*/
module vgacpu_top (
    input logic clk,
    input logic n_rst,

    //TODO button inputs, VGA outputs

    //VGA Outputs (640x480)
    output logic vga_r, vga_g, vga_b,
    output logic vga_hsync, vga_vsync
);

//Clocking
//This system expects a 50MHz clock. In the case that clk is not 50MHz, you can setup a PLL
//or some sort of simple divider here. For me I'm just passing thru clk.
logic clk_50;
assign clk_50 = clk;


//Connections Between CPU, Rasterizer, VGA Module, etc
//TODO


//TESTING sram
inferred_sram #(
    .INITIALIZE_FROM_FILE(0),
	.D_WIDTH(8),
	.A_WIDTH(8)
) test_sram (
    .clk(clk_50)
);

endmodule
