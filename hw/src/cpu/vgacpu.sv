/* vgacpu
 * By: John Jekel
 *
 * Main module for the CPU in the hardware.
 *
*/

import common::raster_command_t;//FIXME move into module scope
import cpu_common::*;//FIXME move into module scope

module vgacpu
    //TODO put imports here
(
    input logic clk,//50MHz
    input logic rst_async,

    //Button Inputs
    input logic [3:0] buttons_sync,

    //CPU-GPU Interface
    output raster_command_t gpu_command,
    output logic [7:0] gpu_x0, gpu_y0, gpu_x1, gpu_y1,
    output logic [2:0] gpu_colour,
    output logic gpu_execute_request,//Hold for 1 clock cycle to begin execution; DO NOT ACTIVATE WHILE BUSY
    input logic gpu_busy,

    //CPU-Sound Interface
    output logic [25:0] snd_max_count,//Enough bits for frequencies as low as < 1hz
    output logic snd_latch_max_count//Hold for 1 clock cycle to latch the new max count
);

/* Control Lines */

//Register File
logic rf_write_en;

//ALU
alu_operation_t alu_operation;
alu_operand_t alu_operand;

//RF Mux
rf_mux_src_t rf_mux_src;

/* Data Connections */

//Fetch
logic [15:0] inst;

//Decode
logic [7:0] immediate;

//RF
logic [2:0] rf_write_addr;
logic [2:0] rX_addr;
logic [7:0] rf_in;
logic [7:0] r0;
logic [7:0] r1;
logic [7:0] r4;
logic [7:0] r5;
logic [7:0] r6;
logic [7:0] r7;
logic [7:0] rX;

//ALU
logic [7:0] alu_result;

//SP
logic [13:0] sp_addr;

//Memory
logic [7:0] mem_data_read;

/* Module instantiations */

//Control logic
control ctrl (.*);

//Main memory
main_mem mem (.clk(clk));

//Register File and input mux
rf_mux mux (.*);
reg_file rf (.*);

//ALU
alu the_alu (.*);

//Fetch unit
fetch ifetch (.*);

//Decode unit
decode dec (.*);

//Stack pointer
sp stack_pointer (.*);

//AGU
agu addr_gen_unit (.*);

//TESTING
//assign gpu_command = common::RASTER_CMD_FILL;
//assign gpu_colour = (3'b101;
//assign gpu_execute_request = 1;
//assign gpu_execute_request = 0;

//assign gpu_command = common::RASTER_CMD_POINT;
//assign gpu_x0 = 100;
//assign gpu_y0 = 100;
//assign gpu_colour = 3'b110;
//assign gpu_execute_request = 1;

//assign gpu_colour = 3'b101;
//assign gpu_execute_request = 1;

/*assign gpu_command = common::RASTER_CMD_LINE;
assign gpu_x0 = 10;
assign gpu_y0 = 10;
assign gpu_x1 = 100;
assign gpu_y1 = 100;
assign gpu_colour = 3'b110;
assign gpu_execute_request = 1;
*/

//assign gpu_command = common::RASTER_CMD_RECT;
/*assign gpu_x0 = 10;
assign gpu_y0 = 90;
assign gpu_x1 = 204;
assign gpu_y1 = 130;
assign gpu_colour = 3'b110;
*/
/*
assign gpu_x1 = 214 - gpu_x0;
assign gpu_y1 = 160 - gpu_y0;

logic [23:0] divider;
logic [7:0] x_counter, y_counter;
always @(posedge clk) begin
    divider <= divider + 1;

    if (divider == 0) begin
        gpu_x0 <= gpu_x0 + 1;
        gpu_y0 <= gpu_y0 + 1;
    end
end

*/

/*
logic [27:0] colour_counter;
assign gpu_colour = colour_counter[27:25];
always @(posedge clk) begin
    colour_counter <= colour_counter + 1;
end

assign gpu_execute_request = 1;

assign snd_max_count = (50000000 / 1000) / 2;//1000KHz
assign snd_latch_max_count = 0;//1;
*/

endmodule
