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
    input logic en,

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

assign vga_hsync = ~((x_cnt >= X_SYNC_BEGIN) & (x_cnt <= X_SYNC_END) & en);
assign vga_vsync = ~((y_cnt >= Y_SYNC_BEGIN) & (y_cnt <= Y_SYNC_END) & en);

/* Framebuffer Access and Output Logic */

//Output Logic
logic in_visible_region;
assign in_visible_region = (x_cnt < X_VISIBLE) & (y_cnt < Y_VISIBLE);

assign vga_r = en & in_visible_region & fb_pixel[2];
assign vga_g = en & in_visible_region & fb_pixel[1];
assign vga_b = en & in_visible_region & fb_pixel[0];

//FB Access

//Old method; kept to see an alternative view of what is going on
//NOTE: DON'T USE THIS: It relies on division which is not good
/*logic [15:0] line_offset;
logic [15:0] pixel;
assign fb_addr = line_offset + pixel;
assign pixel = (x_cnt / 2) / 3;
assign line_offset = (y_cnt / 3) * 214;//214 pixels per line; lines last 3 real lines
*/

//More performant and area-efficient option: using seperate counters instead
//TODO make this even more efficient and faster

//Subpixel Counter
logic [2:0] sub_pixel_cnt;//We need to count 6 times: 214 is 1/3ish of 640, and the clock is double the pixel clock (50MHz), so 1/6
logic [2:0] next_sub_pixel_cnt;
assign next_sub_pixel_cnt = (sub_pixel_cnt == 5) ? '0 : (sub_pixel_cnt + 1);
always_ff @(posedge rst_async, posedge clk) begin
    if (rst_async) begin
        sub_pixel_cnt <= '0;
    end else if (clk) begin
        if (in_visible_region)
            sub_pixel_cnt <= next_sub_pixel_cnt;
        else begin
            //A line is not quite 214 pixels (really 213.333...)
            //So we end up partially counting at the end of a line which is an issue
            //So we reset the subpixel count at the end of each line
            //We can just use the hsync signal to determine when that is
            sub_pixel_cnt <= '0;
        end
    end
end

//Pixel Counter (Horizontal)
logic [7:0] pixel_cnt;

always_ff @(posedge rst_async, posedge clk) begin
    if (rst_async) begin
        pixel_cnt <= '0;
    end else if (clk) begin
        if (in_visible_region) begin
            if (next_sub_pixel_cnt == '0)//We're moving to the next pixel
                pixel_cnt <= pixel_cnt + 1;
        end else
            pixel_cnt <= '0;//Reset the pixel count in prep for the next line
    end
end

//Line Repeating/Counting Logic
logic [15:0] line_offset;

logic [1:0] line_cnt;//We repeat lines 3 times to divide the vertical rez by 3
logic [1:0] next_line_cnt;
assign next_line_cnt = (line_cnt == 2) ? '0 : (line_cnt + 1);

always_ff @(posedge rst_async, posedge clk) begin
    if (rst_async) begin
        line_offset <= '0;
        line_cnt <= '0;
    end else if (clk) begin
        if (y_cnt == Y_MAX) begin //End of frame; reset the offset and line count
            line_cnt <= '0;
            line_offset <= '0;
        end else if (x_cnt == X_MAX) begin//End of line; increment the line count and adjust the offset
            line_cnt <= next_line_cnt;

            if (next_line_cnt == '0)//We repeated the line 3 times, so go to the next one in the FB
                line_offset <= line_offset + 214;
        end
    end
end

//Combine the current line and the pixel on the line to get the desired address
assign fb_addr = line_offset + pixel_cnt;

endmodule
