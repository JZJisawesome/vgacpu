/* fetch
 * By: John Jekel
 *
 * Fetch unit for the CPU
 *
*/

module fetch (
    input clk,
    input rst_async,

    input fetch_operation_t fetch_operation,

    output logic fetch_complete,

    output logic [15:0] inst,

    //Register Access
    input logic [13:0] sp_addr,
    input logic [7:0] r0,
    input logic [7:0] r1,
    input logic [7:0] r6,
    input logic [7:0] r7,

    //Memory Access
    output logic [12:0] mem_inst_addr,
    input logic [15:0] mem_instr
);

/* Fetch State Machine */

typedef enum {IDLE, BYTE_1, BYTE_2, FINISH} mem_fetch_state_t;
mem_fetch_state_t current_state;
mem_fetch_state_t next_state;

//State transition logic
always_ff @(posedge clk, posedge rst_async) begin
    if (rst_async)
        current_state <= IDLE;
    else if (clk)
        current_state <= next_state;
end

//Next state logic
always_comb begin
    case (current_state)
        IDLE: begin
            if (pc_changed)
                next_state = BYTE_1;
            else
                next_state = IDLE;
        end BYTE_1: begin
        end BYTE_2: begin
        end FINISH: begin
        end
    endcase
end

//Actual fetch logic based on current state
always_comb begin
    case (current_state)
        INIT: begin
            mem_inst_addr = 'x;
        end
        BYTE_1: begin
            mem_inst_addr = pc[13:1];
        end
        BYTE_2: begin

        end
        FINISH: begin
        end default: begin

        end
    endcase
end
always_ff @(posedge clk) begin
    case (current_state)
        INIT: begin
            //Do nothing
        end
        BYTE_1: begin
            mem_inst_addr = pc[13:1];
        end
        DECODE: begin

        end
        EXECUTE: begin

        end default: begin

        end
    endcase
end

/* PC Logic */

logic pc_changed;//Used by fetch logic to fetch a new instruction when the pc changes
logic [13:0] pc;

always_ff @(posedge clk, posedge rst_async) begin
    if (rst_async) begin

    end
end

endmodule
