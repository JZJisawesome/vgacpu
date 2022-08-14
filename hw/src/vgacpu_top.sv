/* vgacpu_top
 * By: John Jekel
 *
 * Top-level file for the project's hardware.
 *
*/

module vgacpu_top
    import common::raster_command_t;//TEMPORARY just for testing
(
    input logic clk,
    input logic n_rst_async,

    //TODO button inputs

    //VGA Outputs (640x480)
    output logic vga_r, vga_g, vga_b,
    output logic vga_hsync, vga_vsync,

    //Buzzer Output:
    output logic buzzer
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

//Framebuffer-Rasterizer connections
logic [15:0] gpu_fb_addr;
logic gpu_fb_write_en;
logic [2:0] gpu_fb_pixel;

/* Module instantiations */

//Framebuffer
inferred_sram #(
    .INITIALIZE_FROM_FILE(1),//TODO eventually do init this for file (maybe show some default logo/for testing)
    .FILE("src/init_fb.hex"),
	.FILE_TYPE_BIN(1),
    .D_WIDTH(3),
    .TOTAL_WORDS(214 * 160),
    .A_WIDTH(16)//214x160 pixels
) framebuffer (
    .clk(clk_50),

    //Port A
    //Reading
    .read_addr_a(vga_fb_addr),
    .read_a(vga_fb_pixel),
    //Port A writing not used

    //Port B
    //Port B reading not used
    //Writing
    .write_addr_b(gpu_fb_addr),
    .write_en_b(gpu_fb_write_en),
    .write_b(gpu_fb_pixel)
);

//VGA Output Module
vga vga_output_controller (
    .clk(clk_50),
    .rst_async(rst_async),
    .en(1),//TODO may want to control this via some mechanism in the future

    //VGA Outputs (640x480)
    .vga_r(vga_r), .vga_g(vga_g), .vga_b(vga_b),
    .vga_hsync(vga_hsync), .vga_vsync(vga_vsync),

    //Framebuffer access
    .fb_addr(vga_fb_addr),
    .fb_pixel(vga_fb_pixel)
);

//Rasterizer
rasterizer gpu (
    .clk(clk_50),
    .rst_async(rst_async),

    //TODO connections between rasterizer and cpu

    //TESTING
    //.command(common::RASTER_CMD_FILL),
    //.colour(3'b101),
    //.execute_request(1),
    .execute_request(0),

    .fb_addr(gpu_fb_addr),
    .fb_write_en(gpu_fb_write_en),
    .fb_pixel(gpu_fb_pixel)
);

//Sound
sound snd (
    .clk(clk_50),
    .rst_async(rst_async),

    //TESTING
    .freq(0),
    .latch_freq(1),


    .buzzer(buzzer)
);

endmodule
