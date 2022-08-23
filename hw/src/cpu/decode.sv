/* decode
 * By: John Jekel
 *
 * Decode unit for the cpu
 *
*/

module decode
    import cpu_common::*;
(
    input clk,

    //Control Signal In
    input logic decode_en,//Decode the instruction; useful for fetching the next instruction while executing this one if disabled

    //Instruction In
    input logic [15:0] inst,

    //Decoded Results Out
    //General
    output logic [7:0] immediate,
    output logic [1:0] inst_type,

    //Register File
    output logic [2:0] rf_write_addr,
    output logic [2:0] rX_addr,

    //ALU
    output alu_operation_t alu_operation,
    output alu_operand_t alu_operand,

    //RF Mux
    output rf_mux_src_t rf_mux_src

    //TODO signals to control logic
);

//Logic to latch the decoded result
logic [2:0] rf_write_addr_internal;
logic [2:0] rX_addr_internal;
alu_operation_t alu_operation_internal;
rf_mux_src_t rf_mux_src_internal;

always_ff @(posedge clk) begin//The decode step takes 1 clock cycle
    if (decode_en) begin
        immediate <= inst[15:8];
        inst_type <= inst[1:0];
        rf_write_addr <= rf_write_addr_internal;
        rX_addr <= rX_addr_internal;
        alu_operation <= alu_operation_internal;
        rf_mux_src <= rf_mux_src_internal;
    end
end

//Determining which registers are being accessed is difficult in this architecture
//Probably could have designed this better, but hey, this is my first stab at a custom arch
always_comb begin
    case (inst[1:0])
        2'b11: begin//We have to deal with the 0TOX and XTO0 instructions
            if (inst[7:2] == 6'b100000) begin//0TOX
                rf_write_addr_internal = inst[10:8];
                rX_addr_internal = 0;
            end else if (inst[7:2] == 6'b100001) begin//XTO0
                rf_write_addr_internal = 0;
                rX_addr_internal = inst[10:8];
            end else begin
                rf_write_addr_internal = 'x;
                rX_addr_internal = 'x;
            end
        end 2'b10: begin//The register to read, or to write, is always in inst[7:5]
            rf_write_addr_internal = inst[7:5];
            rX_addr_internal = inst[7:5];
        end 2'b01: begin//The register to read, or to write, is always in inst[7:5]
            case (inst[4:2])
                3'b000: begin//PUSH
                    rf_write_addr_internal = 'x;//Push does not write to registers
                    rX_addr_internal = inst[7:5];//PUSH always reads from rX
                end 3'b001: begin//POP
                    rf_write_addr_internal = inst[7:5];//Pop writes to rX
                    rX_addr_internal = 'x;//Pop does not read from registers
                end 3'b010, 3'b011, 3'b100, 3'b101, 3'b110, 3'b111: begin//ALU operations...
                    rf_write_addr_internal = 0;//Always write to r0
                    rX_addr_internal = inst[7:5];//And all read from rX
                end
            endcase
        end 2'b00: begin//No register accesses in this instruction type
            rf_write_addr_internal = 'x;
            rX_addr_internal = 'x;
        end
    endcase
end

//ALU decoder
always_comb begin
    case (inst[4:2])//These are the only bits we need to actually check
        3'b000: alu_operation_internal = cpu_common::ALU_SL; //110 000 11 is SL
        3'b001: alu_operation_internal = cpu_common::ALU_SR; //110 001 11 is SR
        3'b010: alu_operation_internal = cpu_common::ALU_ADD;//XXX 010 01 is ADD
        3'b011: alu_operation_internal = cpu_common::ALU_SUB;//XXX 011 01 is SUB
        3'b100: alu_operation_internal = cpu_common::ALU_AND;//XXX 100 01 is AND
        3'b101: alu_operation_internal = cpu_common::ALU_OR; //XXX 101 01 is OR
        3'b110: alu_operation_internal = cpu_common::ALU_XOR;//XXX 110 01 is XOR
        3'b111: alu_operation_internal = cpu_common::ALU_MUL;//XXX 111 01 is MUL
    endcase
end
//TODO handle the operand too

//RF Mux Decoder
always_comb begin
    case (inst[1:0])
        2'b11: begin//TODO will need to handle xto0, 0tox, etc
            rf_mux_src_internal = 'x;//TODO
        end 2'b10: begin
            rf_mux_src_internal = 'x;//TODO
        end 2'b01: begin
            case (inst[4:2])
                3'b000: rf_mux_src_internal = 'x;//We don't write to any registers for PUSH
                3'b001: rf_mux_src_internal = cpu_common::RF_MUX_MEM;//POP
                3'b010, 3'b011, 3'b100, 3'b101, 3'b110, 3'b111: rf_mux_src_internal = cpu_common::RF_MUX_ALU;//ALU operations
            endcase
        end 2'b00: begin//TODO will need to handle the polling commands, etc
            rf_mux_src_internal = 'x;//TODO
        end
    endcase
end

//Noice decode for debugging puposes
//TODO

endmodule
