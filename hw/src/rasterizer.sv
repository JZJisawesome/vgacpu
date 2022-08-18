/* rasterizer
 * By: John Jekel
 *
 * Hardware to write to the framebuffer based on commands from the CPU.
 *
*/

module rasterizer
    import common::raster_command_t;
(
    input logic clk,//50MHz
    input logic rst_async,

    //TODO interface between CPU and this module

    //CPU-GPU Interface
    input raster_command_t command,
    input logic [7:0] x0, y0, x1, y1,
    input logic [2:0] colour,
    input logic execute_request,//Hold for 1 clock cycle to begin execution; DO NOT ACTIVATE WHILE BUSY
    output logic busy,

    //Framebuffer Access
    //We only ever need to write, so we only wire up stuff for that
    //We have two ports, so we can write to the framebuffer twice as fast!
    output logic [15:0] fb_addr_a,
    output logic fb_write_en_a,
    output logic [2:0] fb_pixel_a,

    output logic [15:0] fb_addr_b,
    output logic fb_write_en_b,
    output logic [2:0] fb_pixel_b

    //TODO write to FB with TWO ports at once for greater speed!!!
    //TODO if you can't avoid multiplication, try to share a multiplier between different parts
);

//TODO do this until we take advantage of the b port
assign fb_addr_b = '0;
assign fb_write_en_b = '0;
assign fb_pixel_b = '0;

/* Internal Signals */

//Done signals
logic nop_done;
logic fill_done;
logic point_done;
logic line_done;
logic rect_done;

//FB Access signals
logic [15:0] nop_fb_addr_a;
logic nop_fb_write_en_a;
logic [2:0] nop_fb_pixel_a;

logic [15:0] fill_fb_addr_a;
logic fill_fb_write_en_a;
logic [2:0] fill_fb_pixel_a;

logic [15:0] point_fb_addr_a;
logic point_fb_write_en_a;
logic [2:0] point_fb_pixel_a;

logic [15:0] line_fb_addr_a;
logic line_fb_write_en_a;
logic [2:0] line_fb_pixel_a;

logic [15:0] rect_fb_addr_a;
logic rect_fb_write_en_a;
logic [2:0] rect_fb_pixel_a;

/* CPU Interface Logic */

//Logic for latching the interface values into registers when the execute_request line is asserted
raster_command_t command_reg;
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
        common::RASTER_CMD_NOP: begin
            fb_addr_a = nop_fb_addr_a;
            fb_write_en_a = nop_fb_write_en_a & busy;
            fb_pixel_a = nop_fb_pixel_a;
            done = nop_done;
        end
        common::RASTER_CMD_FILL: begin
            fb_addr_a = fill_fb_addr_a;
            fb_write_en_a = fill_fb_write_en_a & busy;
            fb_pixel_a = fill_fb_pixel_a;
            done = fill_done;
        end
        common::RASTER_CMD_POINT: begin
            fb_addr_a = point_fb_addr_a;
            fb_write_en_a = point_fb_write_en_a & busy;
            fb_pixel_a = point_fb_pixel_a;
            done = point_done;
        end
        common::RASTER_CMD_LINE: begin
            fb_addr_a = line_fb_addr_a;
            fb_write_en_a = line_fb_write_en_a & busy;
            fb_pixel_a = line_fb_pixel_a;
            done = line_done;
        end
        common::RASTER_CMD_RECT: begin
            fb_addr_a = rect_fb_addr_a;
            fb_write_en_a = rect_fb_write_en_a & busy;
            fb_pixel_a = rect_fb_pixel_a;
            done = rect_done;
        end
        default: begin
            fb_addr_a = 'x;
            fb_write_en_a = 'x;
            fb_pixel_a = 'x;
            done = 'x;
        end
    endcase
end

/* Rasterization HW */
//TODO add fixed-function hardware to deal with (1 section for each command)

//Command: NOP
assign nop_fb_addr_a = 'x;//We never use the fb
assign nop_fb_write_en_a = 0;//We never use the fb
assign nop_fb_pixel_a = 'x;//We never use the fb
assign nop_done = 1;//NOP finishes immediately always

//Command: Fill
assign fill_fb_pixel_a = colour_reg;
assign fill_fb_write_en_a = 1;
logic [15:0] next_seq_fb_addr;
assign next_seq_fb_addr = fill_fb_addr_a + 1;
assign fill_done = next_seq_fb_addr == (214 * 160);//We will wrap around next clock, so we're done!
always_ff @(posedge clk) begin
    if (~busy)//We're waiting to execute
        fill_fb_addr_a <= '0;//Start from the beginning
    else//Continually loop over the entire framebuffer (this should only happen once unless execute_request is held for a long time)
        fill_fb_addr_a <= (next_seq_fb_addr < (214 * 160)) ? next_seq_fb_addr : '0;
end

//Command: Point
assign point_fb_pixel_a = colour_reg;
assign point_fb_write_en_a = 1;
assign point_done = 1;//Only takes 1 clock cycle :)
assign point_fb_addr_a = x0 + (y0 * 214);//FIXME avoid the multiplication

//Command: Line
//Thanks: https://www.geeksforgeeks.org/bresenhams-line-generation-algorithm/
assign line_fb_pixel_a = colour_reg;
assign line_fb_write_en_a = line_init;//Only begin writing pixels when init has finished

logic line_init;
logic [8:0] m_new;
assign line_m_new = {y1 - y0, 1'b0};//2 * (y1 - y0)
logic [8:0] line_slope_error_new;

always_ff @(posedge rst_async, posedge clk) begin
    if (rst_async) begin
        line_init <= '0;
    end else if (clk) begin
        if (busy) begin//A request to draw a line is in progress
            if (~line_init) begin//We haven't initialized things for line drawing yet
                line_slope_error_new <= m_new - (x1 - x0);//Set the initial slope error
                line_init <= 1;
            end else begin
                line_slope_error_new <= line_slope_error_new + m_new;
                //TODO implement
            end
        end else
            line_init <= '0;
    end
end

//Command: Rectangle
logic rect_init;

assign rect_fb_pixel_a = colour_reg;
assign rect_fb_write_en_a = rect_init;//Only begin writing pixels when init has finished

logic [7:0] rect_x_cnt;
logic [7:0] rect_next_seq_x_cnt;
assign rect_next_seq_x_cnt = rect_x_cnt + 1;
logic [7:0] rect_y_cnt;
logic [7:0] rect_next_seq_y_cnt;
assign rect_next_seq_y_cnt = rect_y_cnt + 1;

always_ff @(posedge clk, posedge rst_async) begin
    if (rst_async) begin
        rect_init <= 0;
    end else if (clk) begin
        if (busy) begin//A request to draw a rectangle is in progress
            if (~rect_init) begin//We haven't initialized things for rect drawing yet
                rect_x_cnt <= x0;
                rect_y_cnt <= y0;
                rect_init <= 1;
            end else begin
                rect_x_cnt <= (rect_next_seq_x_cnt < x1) ? rect_next_seq_x_cnt : x0;

                if (rect_next_seq_x_cnt >= x1)
                    rect_y_cnt <= (rect_next_seq_y_cnt < y1) ? rect_next_seq_y_cnt : y0;
            end
        end else
            rect_init <= 0;
    end
end

assign rect_fb_addr_a = rect_x_cnt + (rect_y_cnt * 214);//TODO avoid multiplication

assign rect_done = (rect_x_cnt == x1_reg) & (rect_y_cnt == y1_reg);

endmodule
