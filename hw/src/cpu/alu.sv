/* alu
 * By: John Jekel
 *
 * ALU for the cpu
 *
*/

module alu
    import cpu_common::alu_operation_t;
    import cpu_common::alu_operand_t;
(
    input alu_operation_t alu_operation,
    input alu_operand_t alu_operand,

    input logic [7:0] r0, rX, immediate,
    output logic [7:0] alu_result
);

//Second operand mux
logic [7:0] operand_2;

always_comb begin
    case (alu_operand)
        cpu_common::ALU_RX:         operand_2 = rX;
        cpu_common::ALU_IMMEDIATE:  operand_2 = immediate;
        default:                    operand_2 = 'x;
    endcase
end

//Actual ALU
always_comb begin
    case (alu_operation)
        cpu_common::ALU_ADD:    alu_result = r0 + operand_2;
        cpu_common::ALU_SUB:    alu_result = r0 - operand_2;
        cpu_common::ALU_AND:    alu_result = r0 & operand_2;
        cpu_common::ALU_OR:     alu_result = r0 | operand_2;
        cpu_common::ALU_XOR:    alu_result = r0 ^ operand_2;
        cpu_common::ALU_MUL:    alu_result = r0 * operand_2;
        cpu_common::ALU_SR:     alu_result = r0 >> operand_2;
        cpu_common::ALU_SL:     alu_result = r0 << operand_2;
        default:                alu_result = 'x;
    endcase
end

endmodule
