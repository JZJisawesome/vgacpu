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
    input logic fetch_complete,

    //Control Lines
    //Register File
    output logic rf_write_en,

    //ALU
    output alu_operation_t alu_operation,
    output alu_operand_t alu_operand,

    //RF Mux
    output rf_mux_src_t rf_mux_src,

    //SP
    output sp_operation_t sp_operation,

    //Fetch Unit
    output fetch_operation_t fetch_operation,

    //Decode
    output logic decode_en,

    //Page Register
    output logic pr_write_en,

    //Memory
    output logic mem_data_write_en,

    //AGU
    output agu_operation_t agu_operation
);

typedef enum {FETCH, DECODE, EXECUTE} control_state_t;//TODO additional states for different instructions (a single execute state likely won't be enough)
control_state_t current_state;
control_state_t next_state;

//State transition logic
always_ff @(posedge clk, posedge rst_async) begin
    if (rst_async)
        current_state <= FETCH;
    else if (clk)
        current_state <= next_state;
end

//Next state logic
always_comb begin
    //TODO actually transition based on signals and not just in a fixed loop
    case (current_state)
        FETCH: begin
            if (fetch_complete)
                next_state = DECODE;
            else
                next_state = FETCH;
        end DECODE: begin//The decode unit always takes exactly 1 clock cycle
            next_state = EXECUTE;
        end EXECUTE: begin
            next_state = FETCH;
        end
    endcase
end

//Output logic
always_comb begin
    case (current_state)
        FETCH: begin
            rf_write_en = 0;
            decode_en = 'x;
            rf_mux_src = 'x;
            //alu_operation = 'x;
            //alu_operand = 'x;
        end DECODE: begin
            rf_write_en = 0;
            decode_en = 1;
            rf_mux_src = 'x;
            //alu_operation = 'x;
            //alu_operand = 'x;
        end EXECUTE: begin
            rf_write_en = 'x;//TODO
            decode_en = 0;
            rf_mux_src = 'x;//TODO
            //alu_operation = //TODO
            //alu_operand = //TODO
        end default: begin
            rf_write_en = 'x;
            decode_en = 'x;
            rf_mux_src = 'x;//TODO
            //alu_operation = 'x;
            //alu_operand = 'x;
        end
    endcase
end

endmodule
