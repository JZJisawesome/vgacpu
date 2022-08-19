/* rf_mux
 * By: John Jekel
 *
 * Input multiplexer for the register file
 *
*/

import cpu_common::*;//Man iscarus verilog is pickey about this//TODO only import what is necessary and only

module rf_mux
(
    //Mux input selection
    input rf_mux_src_t rf_mux_src,

    //Mux inputs
    input logic [7:0] immediate,
    input logic [7:0] r0,
    input logic [7:0] alu_result,
    input logic [7:0] mem_data_read,

    //Output to register file
    output logic [7:0] rf_in
);

//The multiplexer
always_comb begin
    case (rf_mux_src)
        RF_MUX_IMM: rf_in = immediate;
        RF_MUX_R0:  rf_in = r0;
        RF_MUX_ALU: rf_in = alu_result;
        RF_MUX_MEM: rf_in = mem_data_read;
    endcase
end

endmodule
