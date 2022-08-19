/* decode
 * By: John Jekel
 *
 * Decode unit for the cpu
 *
*/

module decode (
    input clk,

    input [15:0] inst,

    output [7:0] immediate

    //TODO signals to control logic
);

assign immediate = inst[15:8];

endmodule
