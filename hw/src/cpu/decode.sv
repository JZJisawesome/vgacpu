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
    //General (Used by control logic to decide certain things)
    output logic [7:0] immediate,
    output logic [1:0] inst_type,
    output logic [2:0] inst_subtype,
    output core_special_operation_t core_special_op,

    //Register File
    output logic [2:0] rf_write_addr,
    output logic [2:0] rX_addr,

    //ALU
    output alu_operation_t alu_operation,
    output alu_operand_t alu_operand,

    //RF Mux
    output rf_mux_src_t rf_mux_src,

    //External IO
    output common::raster_command_t gpu_command,
    output logic gpu_submit
);

/* Logic to latch the decoded result */
//General
logic [7:0] immediate_internal;
logic [1:0] inst_type_internal;
logic [2:0] inst_subtype_internal;
core_special_operation_t core_special_op_internal;

//Register File
logic [2:0] rf_write_addr_internal;
logic [2:0] rX_addr_internal;

//ALU
alu_operation_t alu_operation_internal;
alu_operand_t alu_operand_internal;

//RF Mux
rf_mux_src_t rf_mux_src_internal;

//External IO
common::raster_command_t gpu_command_internal;
logic gpu_submit_internal;

always_ff @(posedge clk) begin//The decode step takes 1 clock cycle
    if (decode_en) begin
        immediate <= immediate_internal;
        inst_type <= inst_type_internal;
        inst_subtype <= inst_subtype_internal;
        rf_write_addr <= rf_write_addr_internal;
        rX_addr <= rX_addr_internal;
        alu_operation <= alu_operation_internal;
        alu_operand <= alu_operand_internal;
        rf_mux_src <= rf_mux_src_internal;
        core_special_op <= core_special_op_internal;
        gpu_command <= gpu_command_internal;
        gpu_submit <= gpu_submit_internal;
    end
end

//Simple direct-wires decoding
assign immediate_internal = inst[15:8];
assign inst_type_internal = inst[1:0];
assign inst_subtype_internal = inst[4:2];

//Determining which registers are being accessed is difficult in this architecture
//Probably could have designed this better, but hey, this is my first real stab at a custom arch
always_comb begin
    case (inst_type_internal)
        2'b11: begin//No instructions other than SL and SR access the register file, so accomadate them here
            rf_write_addr_internal = 0;//Both SL and SR access the register file, but
            rX_addr_internal = 'x;
        end 2'b10: begin//The register to read, or to write, is always in inst[7:5]
            rf_write_addr_internal = inst[7:5];
            rX_addr_internal = inst[7:5];
        end 2'b01: begin//The register to read, or to write, is always in inst[7:5]
            case (inst_subtype_internal)
                3'b000: begin//0TOX
                    rf_write_addr_internal = inst[7:5];//Always write to rX
                    rX_addr_internal = 0;//And always read from r0
                end 3'b001: begin//XTO0
                    rf_write_addr_internal = 0;//Always write to r0
                    rX_addr_internal = inst[7:5];//And always read from rX
                end 3'b010, 3'b011, 3'b100, 3'b101, 3'b110, 3'b111: begin//ALU operations...
                    rf_write_addr_internal = 0;//Always write to r0
                    rX_addr_internal = inst[7:5];//And all read from rX
                end
            endcase
        end 2'b00: begin//No instructions other than push and pop access the register file, so accomadate them here
            rf_write_addr_internal = 0;//POP writes to r0
            rX_addr_internal = 'x;//PUSH reads from r0, but will always do so from the extra port, so leave it as 'x here
        end
    endcase
end

//ALU decoder
always_comb begin
    case (inst_subtype_internal)//These are the only bits we need to actually check
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
always_comb begin
    case (inst_type_internal)
        2'b11: alu_operand_internal = cpu_common::ALU_IMMEDIATE;//SL and SR
        2'b01: alu_operand_internal = cpu_common::ALU_RX;//Other instructions
        default: alu_operand_internal = alu_operand_t'('x);
    endcase
end

//RF Mux Decoder
always_comb begin
    case (inst_type_internal)
        2'b11: begin
            rf_mux_src_internal = cpu_common::RF_MUX_ALU;//For SL and SR, they must write back the alu's result
        end 2'b10: begin
            rf_mux_src_internal = rf_mux_src_t'('x);//TODO this changes based on the instruction
        end 2'b01: begin
            case (inst_subtype_internal)
                3'b000: rf_mux_src_internal = rf_mux_src_t'('x);//We don't write to any registers for PUSH
                3'b001: rf_mux_src_internal = cpu_common::RF_MUX_MEM;//POP
                3'b010, 3'b011, 3'b100, 3'b101, 3'b110, 3'b111: rf_mux_src_internal = cpu_common::RF_MUX_ALU;//ALU operations
            endcase
        end 2'b00: begin//TODO will need to handle the polling commands, etc
            rf_mux_src_internal = rf_mux_src_t'('x);//TODO
        end
    endcase
end

//Special Core Operation Decoder
always_comb begin
    if ((inst_type_internal == 2'b00) & (inst_subtype_internal == 3'b111)) begin
        case (inst[7:5])
            3'b000:  core_special_op_internal = CORE_NOP;
            3'b001:  core_special_op_internal = CORE_HALT;
            3'b111:  core_special_op_internal = CORE_RESET;
            default: core_special_op_internal = core_special_operation_t'('x);
        endcase
    end else
        core_special_op_internal = cpu_common::CORE_NOP;
end

//Rasterizer Command Decoder
always_comb begin//Assume inst_type is 2'b11 and inst_subtype is 3'b111
    case (inst[7:5])
        3'b000: gpu_command_internal = common::RASTER_CMD_FILL;
        3'b001: gpu_command_internal = common::RASTER_CMD_POINT;
        3'b010: gpu_command_internal = common::RASTER_CMD_LINE;
        3'b011: gpu_command_internal = common::RASTER_CMD_RECT;
        default: gpu_command_internal = common::raster_command_t'('x);
    endcase
end

//Only actually submit a command in this case;
//Note that we don't have to wait for the rasterizer to no longer be busy since the submission dosn't actually go through until it isn't any more
//and the control logic waits until that is the case
assign gpu_submit_internal = (inst_type_internal == 2'b11) & (inst_subtype_internal == 3'b111);


//Decoder just for synthesis
//TODO use enum to get nice output, but keep disconnected from everything else so it is optimized away

endmodule
