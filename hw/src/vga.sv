/* vga
 * By: John Jekel
 *
 * Module for outputing VGA video from a framebuffer.
 * As planned, this outputs 640x480 video, but the framebuffer it reads from
 * is only 214x160.
 *
 * Useful: http://tinyvga.com/vga-timing/640x480@60Hz
 *
*/
module vga
(
    input logic clk,//50MHz
    input logic rst_async,

    //VGA Outputs (640x480)
    output logic vga_r, vga_g, vga_b,
    output logic vga_hsync, vga_vsync,

    //Framebuffer access
    output logic [15:0] fb_addr,
    input logic [2:0] fb_pixel
);

/* VGA Timing Parameters */
//The pixel clock is 25MHz, but this module runs at 50MHz
//So 1 pixel is 2 clock cycles, which is why we multiply everything by 2 for x
//Numbers from: http://tinyvga.com/vga-timing/640x480@60Hz

localparam X_VISIBLE = 640 * 2;
localparam X_FRONT_PORCH = 16 * 2;
localparam X_SYNC = 96 * 2;
localparam X_BACK_PORCH = 48 * 2;

localparam Y_VISIBLE = 480;
localparam Y_FRONT_PORCH = 10;
localparam Y_SYNC = 2;
localparam Y_BACK_PORCH = 33;

localparam X_SYNC_BEGIN = X_VISIBLE + X_FRONT_PORCH - 1;
localparam X_SYNC_END = X_VISIBLE + X_FRONT_PORCH + X_SYNC - 1;
localparam X_TOTAL = X_VISIBLE + X_FRONT_PORCH + X_SYNC + X_BACK_PORCH;
localparam X_MAX = X_TOTAL - 1;//0 is the first pixel in the counter

localparam Y_SYNC_BEGIN = Y_VISIBLE + Y_FRONT_PORCH - 1;
localparam Y_SYNC_END = Y_VISIBLE + Y_FRONT_PORCH + Y_SYNC - 1;
localparam Y_TOTAL = Y_VISIBLE + Y_FRONT_PORCH + Y_SYNC + Y_BACK_PORCH;
localparam Y_MAX = Y_TOTAL - 1;//0 is the first line in the counter

/* X and Y Counters */
//These DO NOT count pixels, but rather 50MHz clock pulses and lines respectively
logic [10:0] x_cnt;
logic [10:0] y_cnt;

always_ff @(posedge rst_async, posedge clk) begin
    if (rst_async) begin
        x_cnt <= '0;
        y_cnt <= '0;
    end else if (clk) begin
        if (x_cnt == X_MAX) begin//We are at the end of a line
            x_cnt <= '0;//Reset x_cnt
            y_cnt <= (y_cnt == Y_MAX) ? '0 : (y_cnt + 1);//Reset y_cnt if we are currently at y's max too; else increment it
        end else//Otherwise just increment x_cnt
            x_cnt <= (x_cnt + 1);
    end
end

/* HSYNC and VSYNC Outputs */
//Inverted since the sync outputs are active low
//TODO use gtkwave and play around with these a bit (with regards to inclusivity/exclusivity)
//Make sure the periods in GTKwave are correct

assign vga_hsync = ~((x_cnt >= X_SYNC_BEGIN) & (x_cnt <= X_SYNC_END));
assign vga_vsync = ~((y_cnt >= Y_SYNC_BEGIN) & (y_cnt <= Y_SYNC_END));

/* Framebuffer Access and Output Logic */

//Output Logic
logic in_visible_region;

//TODO use gtkwave and play around with this a bit (with regards to inclusivity/exclusivity)
//Make sure the periods in GTKwave are correct
assign in_visible_region = (x_cnt < X_VISIBLE) & (y_cnt < Y_VISIBLE);

assign vga_r = in_visible_region & fb_pixel[0];
assign vga_g = in_visible_region & fb_pixel[1];
assign vga_b = in_visible_region & fb_pixel[2];

//FB Access

//FIXME We must also repeat lines 3 times as well!
//We need slightly more complicated logic for that

//Old method; kept to see an alternative view of what is going on
//logic [15:0] line_offset;
//logic [15:0] pixel;
//assign fb_addr = line_offset + pixel;
//assign pixel = (x_cnt / 2) / 3;
//assign line_offset = y_cnt * 214;//214 pixels per line

//More performance and area-efficient option: using a sub-pixel counter
logic [2:0] sub_pixel_cnt;//We need to count 6 times: 214 is 1/3ish of 640, and the clock is double the pixel clock, so 1/6
logic [15:0] pixel_cnt;

logic [2:0] next_sub_pixel_cnt;
assign next_sub_pixel_cnt = (sub_pixel_cnt == 5) ? '0 : (sub_pixel_cnt + 1);

always_ff @(posedge rst_async, posedge clk) begin
    if (rst_async) begin
        pixel_cnt <= '0;
        sub_pixel_cnt <= '0;
    end else if (clk) begin
        if (in_visible_region) begin
            sub_pixel_cnt <= next_sub_pixel_cnt;

            if (next_sub_pixel_cnt == 0)//Moving to the next pixel
                pixel_cnt <= pixel_cnt + 1;
        end else if (vga_vsync) begin//Now is a good time to reset both counters for the next frame
            pixel_cnt <= '0;
            sub_pixel_cnt <= '0;
        end
    end
end

assign fb_addr = pixel_cnt;

endmodule
