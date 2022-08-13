/* vgacpu_top
 * By: John Jekel
 *
 * Top-level file for the project's hardware.
 *
*/
module vgacpu_top (
    input logic clk,
    input logic n_rst_async,

    //TODO button inputs, VGA outputs

    //VGA Outputs (640x480)
    output logic vga_r, vga_g, vga_b,
    output logic vga_hsync, vga_vsync
);

/* Clocking And Reset */

logic rst_async;
assign rst_async = ~n_rst_async;

//This system expects a 50MHz clock. In the case that clk is not 50MHz, you can setup a PLL
//or some sort of simple divider here. For me I'm just passing thru clk.
logic clk_50;
assign clk_50 = clk;

/* Connections Between CPU, Rasterizer, VGA Module, etc */

//TODO

//Framebuffer-VGA Output Module connections
logic [15:0] vga_fb_addr;
logic [2:0] vga_fb_pixel;

/* Module instantiations */

//Framebuffer
inferred_sram #(
    .INITIALIZE_FROM_FILE(0),//TODO eventually do init this for file (maybe show some default logo/for testing)
	.D_WIDTH(3),
	.TOTAL_WORDS(214 * 160),
	.A_WIDTH(16)//214x160 pixels
) framebuffer (
    .clk(clk_50),
    .read_addr_a(vga_fb_addr),
    .read_a(vga_fb_pixel)
    //TODO other connections
);

//VGA Output Module
vga vga_output_controller (
    .clk(clk_50),
    .rst_async(rst_async),

    //VGA Outputs (640x480)
    .vga_r(vga_r), .vga_g(vga_g), .vga_b(vga_b),
    .vga_hsync(vga_hsync), .vga_vsync(vga_vsync),

    //Framebuffer access
    .fb_addr(vga_fb_addr),
    .fb_pixel(vga_fb_pixel)
);

endmodule
