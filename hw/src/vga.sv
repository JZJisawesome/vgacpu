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

//TODO defining 640x480 VGA timings as parameters here
//localparam X_DRAW_PERIOD = TODO;//In counter ticks (equivalent to clock cycles)
//localparam X_BLANK_PERIOD = TODO;//In counter ticks (equivalent to clock cycles)

//localparam X_

//X and Y length are INCLUSIVE
//localparam X_MAX = X_DRAW_PERIOD + X_BLANK_PERIOD - 1;
//localparam Y_MAX = Y_DRAW_PERIOD + X_BLANK_PERIOD - 1;

//TESTING values just to try things out
localparam X_MAX = 420;
localparam Y_MAX = 69;

/* X and Y Counters */
//These DO NOT count pixels, but rather 50MHz clock pulses
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

//TESTING
assign fb_addr = x_cnt;

//TODO

//TODO plan out the timing of this (need to fetch pixel data from framebuffer in time for VGA timing/etc)
//Perhaps have independent x and y counters continuously incrementing + wrapping after the corrent count
//HSYNC and YSYNC can be directly driven based off of those
//Those counters can serve as inputs to a state machine that deals with actually drawing pixels/driving the r g and b lines,
//accessing the FB, etc

//So the pixel clock for our desired VGA signal is 25MHz, and we have double that. This gives us more breathing room!


//TESTING ensuring FPGA can support only 3 bit wide sram (unlikely, will likely need to rethink things)


endmodule
