/* rf_mux
 * By: John Jekel
 *
 * Input multiplexer for the register file
 *
*/

module rf_mux
    import cpu_common::rf_mux_src_t;
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
        cpu_common::RF_MUX_IMM: rf_in = immediate;
        cpu_common::RF_MUX_R0:  rf_in = r0;
        cpu_common::RF_MUX_ALU: rf_in = alu_result;
        cpu_common::RF_MUX_MEM: rf_in = mem_data_read;
    endcase
end

endmodule
