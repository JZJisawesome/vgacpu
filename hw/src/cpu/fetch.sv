/* fetch
 * By: John Jekel
 *
 * Fetch unit for the CPU
 *
*/

module fetch
    import cpu_common::fetch_operation_t;
(
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

/* Fetch Logic/State Machine */

typedef enum {IDLE, BYTE_1_PREP, BYTE_2_PREP_BYTE_1_FINISH, BYTE_2_FINISH} mem_fetch_state_t;
mem_fetch_state_t current_state;
mem_fetch_state_t next_state;

//State transition logic
always_ff @(posedge clk, posedge rst_async) begin
    if (rst_async)
        current_state <= BYTE_1_PREP;//We need to fetch the first byte at the beginning
    else if (clk)
        current_state <= next_state;
end

//Next state logic
always_comb begin
    case (current_state)
        IDLE: begin
            if (pc_changed)
                next_state = BYTE_1_PREP;
            else
                next_state = IDLE;
        end BYTE_1_PREP: begin
            next_state = BYTE_2_PREP_BYTE_1_FINISH;
        end BYTE_2_PREP_BYTE_1_FINISH: begin
            if (pc[0]) begin
                if (mem_instr[9])//This is a type 2 or type 3 instruction, so it is 2 bytes
                    next_state = BYTE_2_FINISH;//Misaligned, so we need to fetch the 2nd byte
                else
                    next_state = IDLE;//Only 1 byte, no need to fetch a second one
            end else begin
                next_state = IDLE;//No chance for misaligned 2-byte instruction, so we're done!
            end
        end BYTE_2_FINISH: begin
            next_state = IDLE;//This will only take 1 clock cycle
        end
    endcase
end

//Address logic
always_comb begin
    case (current_state)
        IDLE: begin
            mem_inst_addr = 'x;//Don't need to fetch anything while idle
        end BYTE_1_PREP: begin//Prep to recieve the first byte on the next clock edge
            mem_inst_addr = pc[13:1];
        end BYTE_2_PREP_BYTE_1_FINISH: begin//Prep to fetch the next byte (if it exists and we don't already have it) on the next clock edge
            mem_inst_addr = pc[13:1] + 1;
        end BYTE_2_FINISH: begin
            mem_inst_addr = 'x;//No more bytes to fetch
        end default: begin
            mem_inst_addr = 'x;
        end
    endcase
end

//Logic to manage the inst output
logic [15:0] fetch_buffer;

always_ff @(posedge clk) begin
    case (current_state)
        BYTE_1_PREP: begin
            //We don't get the first byte until the next clock cycle
        end BYTE_2_PREP_BYTE_1_FINISH: begin
            //Write the first (or only) byte to the fetch buffer
            if (pc[0]) begin
                fetch_buffer[7:0] <= mem_instr[15:8];
            end else begin
                fetch_buffer <= mem_instr;//No chance for misaligned 2-byte instruction
            end
        end BYTE_2_FINISH: begin
            fetch_buffer[15:8] <= mem_instr[7:0];//Get the last byte of a 2 byte instruction
        end
    endcase
end
always_comb begin//Inst multiplexer and fetch complete logic
    case (current_state)
        IDLE: begin
            inst = fetch_buffer;//inst retains the instruction we already fetched
            fetch_complete = 1;
        end BYTE_1_PREP: begin//Prep to recieve the first byte on the next clock edge
            inst = 'x;//We're in the middle of fetching an instruction, so inst dosn't matter here
            fetch_complete = 0;
        end BYTE_2_PREP_BYTE_1_FINISH: begin
            if (pc[0]) begin
                if (mem_instr[9]) begin//This is a type 2 or type 3 instruction, so it is 2 bytes
                    inst = 'x;//We're in the middle of fetching an instruction, so inst dosn't matter here
                    fetch_complete = 0;
                end else begin
                    inst[15:8] = 'x;//This is only a 1 byte instruction, the upper part dosn't matter
                    inst[7:0] = mem_instr[15:8];//Bypass the fetch buffer to get the instruction out quicker
                    fetch_complete = 1;
                end
            end else begin
                inst = mem_instr;//Bypass the fetch buffer to get the instruction out quicker
                fetch_complete = 1;
            end
        end BYTE_2_FINISH: begin
            inst = {mem_instr[7:0], fetch_buffer[7:0]};//Bypass the fetch buffer to get the instruction out quicker
            fetch_complete = 1;
        end default: begin
            inst = 'x;
            fetch_complete = 'x;
        end
    endcase
end

/* PC Logic */

logic pc_changed;//Used by fetch logic to fetch a new instruction when the pc changes
logic [13:0] pc;

always_ff @(posedge clk, posedge rst_async) begin
    if (rst_async) begin
        pc <= '0;
        pc_changed <= '0;
    end else if (clk) begin
        case (fetch_operation)
            cpu_common::FETCH_NOP: begin
                if (fetch_complete)
                    pc_changed <= 0;
            end cpu_common::FETCH_INC_PC: begin
                if (inst[1])//Current instruction is 2 bytes
                    pc <= pc + 2;//Skip past both bytes
                else
                    pc <= pc + 1;//Just skip past the one
                pc_changed <= 1;
            end
        //TODO handle other operations
        endcase
    end
end

//TODO

endmodule
