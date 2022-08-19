/* reg_file
 * By: John Jekel
 *
 * Register file for the CPU
 *
*/

module reg_file (
    input logic clk,

    //Control Lines
    input logic rf_write_en,

    //Data lines
    input logic [2:0] rf_write_addr,
    input logic [2:0] rX_addr,
    input logic [7:0] rf_in,
    output logic [7:0] r0,
    output logic [7:0] r1,
    output logic [7:0] r4,
    output logic [7:0] r5,
    output logic [7:0] r6,
    output logic [7:0] r7,
    output logic [7:0] rX
);

//The actual register file
logic [7:0] rf [8];

//Writing logic
always_ff @(posedge clk) begin
    if (rf_write_en)
        rf[rf_write_addr] <= rf_in;
end

//rX multiplexer
assign rX = rf[rX_addr];

//Special register assignments
assign r0 = rf[0];
assign r1 = rf[1];
assign r4 = rf[4];
assign r5 = rf[5];
assign r6 = rf[6];
assign r7 = rf[7];

endmodule
