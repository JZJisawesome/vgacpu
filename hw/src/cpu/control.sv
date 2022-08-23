/* control
 * By: John Jekel
 *
 * Control logic for cpu (mealey machine)
 *
*/

module control
    import cpu_common::*;
(
    input logic clk,
    input logic rst_async,

    //Input signals to decide state transitions and outputs
    input logic [1:0] inst_type,
    input logic [2:0] inst_subtype,
    input core_special_operation_t core_special_op,

    //Fetch Unit
    input logic fetch_complete,

    //Control Lines
    //Register File
    output logic rf_write_en,

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
            /*
            if (inst_type == 2'b01)
                next_state = FETCH;//All of this class of instructions take only 1 clock cycle
            else
                next_state = control_state_t'('x);//TODO number of cycles/the states that occur variy based on the instruction
            */
            next_state = FETCH;//TESTING
        end
    endcase
end

//Output logic
//FIXME Iverilog does not require a cast for 'x to an enum
//Quartus does, but iverilog does not support the case
//So this really sucks lol
//I'm beginning to remember why I used verilator before...

always_comb begin
    case (current_state)
        FETCH: begin
            rf_write_en = 0;
            decode_en = fetch_complete;//Decode the instruction as we make the transition to decode; then from decode we decide what execute state to go to
            //sp_operation = 0;
            fetch_operation = cpu_common::FETCH_NOP;
            pr_write_en = 0;
            rf_write_en = 0;
        end DECODE: begin
            rf_write_en = 0;
            decode_en = 'x;//Already decoded the instruction opon the transition to this state; decoding things again or not won't matter
            //rf_mux_src = 'x;
            //sp_operation = 0;
            fetch_operation = cpu_common::FETCH_NOP;
            pr_write_en = 0;
            rf_write_en = 0;
        end EXECUTE: begin
            rf_write_en = 'x;//TODO
            decode_en = 0;
            //rf_mux_src = 'x;//TODO
            //sp_operation = 'x;//TODO
            fetch_operation = cpu_common::FETCH_INC_PC;//TODO this must change for branches/jumps/etc
            pr_write_en = 'x;//TODO
            //rf_write_en = inst_type == 2'b01;//TODO handle other classes of instrucitons (this is just temporary, only handling some)
            rf_write_en = inst_type == 2'b01 | inst_type == 2'b10;//TESTING
        end default: begin
            rf_write_en = 'x;
            decode_en = 'x;
            //rf_mux_src = 'x;//TODO
            //sp_operation = 'x;//TODO

            //fetch_operation = fetch_operation_t'('x);//iverilog dosn't support this
            fetch_operation = cpu_common::FETCH_NOP;//Not ideal...
            pr_write_en = 'x;
            rf_write_en = 'x;
        end
    endcase
end

endmodule
