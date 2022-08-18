/* buttons
 * By: John Jekel
 *
 * Hardware to synchronize button inputs
 *
*/

module buttons (
    input logic clk,

    input logic [3:0] buttons_async,
    output logic [3:0] buttons_sync
);

//Synchronizers
logic [3:0] stage_1, stage_2;

always_ff @(posedge clk) begin
    stage_1 <= buttons_async;
    stage_2 <= stage_1;
end

assign buttons_sync = stage_2;

endmodule
