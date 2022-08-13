/* rasterizer
 * By: John Jekel
 *
 * Hardware to write to the framebuffer based on commands from the CPU.
 *
*/

typedef enum logic [7:0] {NOP = 0, FILL = 1, POINT = 2 /* TODO add others */} command_t;//TODO move this to some common package

module rasterizer (
    input logic clk,//50MHz
    input logic rst_async,

    //TODO interface between CPU and this module

    //CPU-GPU Interface
    input command_t command,
    input logic [7:0] x0, y0, x1, y1,
    input logic [2:0] colour,
    input logic execute_request,//Hold for 1 clock cycle to begin execution; DO NOT ACTIVATE WHILE BUSY
    output logic busy,

    //Framebuffer Access
    //We only ever need to write, so we only wire up stuff for that
    output logic [15:0] fb_addr,
    output logic fb_write_en,
    output logic [2:0] fb_pixel
);

/* Internal Signals */

//Done signals
logic nop_done;
logic fill_done;
logic point_done;

//FB Access signals
logic [15:0] nop_fb_addr;
logic nop_fb_write_en;
logic [2:0] nop_fb_pixel;

logic [15:0] fill_fb_addr;
logic fill_fb_write_en;
logic [2:0] fill_fb_pixel;

logic [15:0] point_fb_addr;
logic point_fb_write_en;
logic [2:0] point_fb_pixel;

/* CPU Interface Logic */

//Logic for latching the interface values into registers when the execute_request line is asserted
command_t command_reg;
logic [7:0] x0_reg, x1_reg, y0_reg, y1_reg;
logic [2:0] colour_reg;

always_ff @(posedge clk) begin
    if (execute_request) begin
        command_reg <= command;
        x0_reg <= x0;
        x1_reg <= x1;
        y0_reg <= y0;
        y1_reg <= y1;
        colour_reg <= colour;
    end
end

//Busy flag logic
logic done;//We're finished whatever operation is in progress; deassert the busy flag next posedge

always_ff @(posedge rst_async, posedge clk) begin
    if (rst_async) begin
        busy <= 0;
    end else if (clk) begin
        if (execute_request)
            busy <= 1;
        else if (done)
            busy <= 0;
    end
end

/* Multiplexing Between different raster hw */

always_comb begin
    case (command_reg)
        NOP: begin
            fb_addr = nop_fb_addr;
            fb_write_en = nop_fb_write_en;
            fb_pixel = nop_fb_pixel;
            done = nop_done;
        end
        FILL: begin
            fb_addr = fill_fb_addr;
            fb_write_en = fill_fb_write_en;
            fb_pixel = fill_fb_pixel;
            done = fill_done;
        end
        default: begin
            fb_addr = 'x;
            fb_write_en = 'x;
            fb_pixel = 'x;
            done = 'x;
        end
    endcase
end

/* Rasterization HW */
//TODO add fixed-function hardware to deal with (1 section for each command)

//Command: NOP
assign nop_fb_addr = 'x;//We never use the fb
assign nop_fb_write_en = 0;//We never use the fb
assign nop_fb_pixel = 'x;//We never use the fb
assign nop_done = 1;//NOP finishes immediately always

//Command: Fill
assign fill_fb_pixel = colour_reg;
assign fill_fb_write_en = 1;
logic [15:0] next_seq_fb_addr;
assign next_seq_fb_addr = fill_fb_addr + 1;
assign fill_done = next_seq_fb_addr == (214 * 160);//We will wrap around next clock, so we're done!
always_ff @(posedge clk) begin
    if (~busy)//We're waiting to execute
        fill_fb_addr <= '0;//Start from the beginning
    else//Continually loop over the entire framebuffer (this should only happen once unless execute_request is held for a long time)
        fill_fb_addr <= (next_seq_fb_addr < (214 * 160)) ? next_seq_fb_addr : '0;
end

//Command: Point
assign point_fb_pixel = colour_reg;
assign point_fb_write_en = 1;
assign point_done = 1;//Only takes 1 clock cycle :)
assign point_fb_addr = x0 + (y0 * 214);//FIXME avoid the multiplication

//TESTING
//Fun test: Begin by just writing an incrementing value to incrementing addresses of the FB
/*
assign fb_write_en = 1;
always_ff @(posedge rst_async, posedge clk) begin
    if (rst_async) begin
        fb_addr <= '0;
        fb_pixel <= '0;
    end else if (clk) begin
        fb_addr <= fb_addr + 1;
        fb_pixel <= fb_pixel + 1;
    end
end
*/

endmodule
