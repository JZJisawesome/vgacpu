/* vgacpu_top
 * By: John Jekel
 *
 * Top-level file for the project's hardware.
 *
*/

module vgacpu_top
    import common::raster_command_t;
(
    input logic clk,
    input logic n_rst_async,

    //Button Inputs
    input logic [3:0] buttons_async,

    //VGA Outputs (640x480)
    output logic vga_r, vga_g, vga_b,
    output logic vga_hsync, vga_vsync,

    //Buzzer Output
    output logic buzzer

    //TODO add PS2 keyboard as input perhaps???
);

/* Clocking And Reset */

logic rst_async;
assign rst_async = ~n_rst_async;

//This system expects a 50MHz clock. In the case that clk is not 50MHz, you can setup a PLL
//or some sort of simple divider here. For me I'm just passing thru clk.
logic clk_50;
assign clk_50 = clk;

/* Connections Between CPU, Rasterizer, VGA Module, Framebuffer, Sound, etc */

//Synchronized Buttons
logic [3:0] buttons_sync;

//CPU-GPU connections
raster_command_t gpu_command;
logic [7:0] gpu_x0, gpu_y0, gpu_x1, gpu_y1;
logic [2:0] gpu_colour;
logic gpu_execute_request;
logic gpu_busy;

//CPU-Sound connections
logic [25:0] snd_max_count;//Enough bits for frequencies as low as < 1hz
logic snd_latch_max_count;//Hold for 1 clock cycle to latch the new max count

//Framebuffer-VGA Output Module connections
logic [15:0] vga_fb_addr;
logic [2:0] vga_fb_pixel;

//Framebuffer-Rasterizer connections
logic [15:0] gpu_fb_addr;
logic gpu_fb_write_en;
logic [2:0] gpu_fb_pixel;

/* Module instantiations */

//Framebuffer
framebuffer #(
    .INITIALIZE_FROM_FILE(1),//TODO eventually do init this for file (maybe show some default logo/for testing)
    .FILE("src/init_fb.hex"),
    .FILE_TYPE_BIN(1)
) fb (
    .clk(clk_50),

    //Port A (For VGA module)
    .addr_a(vga_fb_addr),
    .read_a(vga_fb_pixel),

    //Port B (For rasterizer)
    .addr_b(gpu_fb_addr),
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

    //CPU-GPU Interface
    .command(gpu_command),
    .x0(gpu_x0),
    .y0(gpu_y0),
    .x1(gpu_x1),
    .y1(gpu_y1),
    .colour(gpu_colour),
    .execute_request(gpu_execute_request),
    .busy(gpu_busy),

    //Framebuffer Access
    .fb_addr(gpu_fb_addr),
    .fb_write_en(gpu_fb_write_en),
    .fb_pixel(gpu_fb_pixel)
);

//Sound
sound snd (
    .clk(clk_50),
    .rst_async(rst_async),

    .max_count(snd_max_count),
    .latch_max_count(snd_latch_max_count),

    .buzzer(buzzer)
);

//Synchronizers
buttons synchronizers (.clk(clk_50), .*);

//CPU
vgacpu cpu (.clk(clk_50), .*);

endmodule
