/* control
 * By: John Jekel
 *
 * Control logic for cpu (moore machine)
 *
*/

module control (
    input logic clk,
    input logic rst_async

    //TODO figure out other signals
);

typedef enum {INIT, FETCH, DECODE, EXECUTE} control_state_t;
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
    case (current_state)
        INIT: begin
            next_state = FETCH;
        end
        FETCH: begin
            next_state = 'x;//TODO
        end
        DECODE: begin
            next_state = 'x;//TODO
        end
        EXECUTE: begin
            next_state = 'x;//TODO
        end default: begin
            next_state = 'x;
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
