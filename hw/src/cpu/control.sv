/* control
 * By: John Jekel
 *
 * Control logic for cpu (mealey machine)
 *
*/

module control (
    input logic clk,
    input logic rst_async,

    //Input signals to decide state transitions and outputs
    //Fetch Unit
    input logic fetch_complete

    //Control Lines
    //TODO
);

typedef enum {INIT, FETCH, DECODE, EXECUTE} control_state_t;//TODO additional states for different memory classes
control_state_t current_state;
control_state_t next_state;

//State transition logic
always_ff @(posedge clk, posedge rst_async) begin
    if (rst_async)
        current_state <= INIT;
    else if (clk)
        current_state <= next_state;
end

//Next state logic
always_comb begin
    //TODO actually transition based on signals and not just in a fixed loop
    case (current_state)
        INIT: begin
            next_state = FETCH;
        end FETCH: begin
            if (fetch_complete)
                next_state = DECODE;
            else
                next_state = FETCH;
        end DECODE: begin
            next_state = EXECUTE;
        end EXECUTE: begin
            next_state = FETCH;
        end
    endcase
end

//Output logic
always_comb begin
    case (current_state)
        INIT: begin

        end
        FETCH: begin

        end
        DECODE: begin

        end
        EXECUTE: begin

        end default: begin

        end
    endcase
end

endmodule
