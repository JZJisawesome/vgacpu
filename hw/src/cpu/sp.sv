/* sp
 * By: John Jekel
 *
 * Stack pointer and the SP ALU for the cpu
 *
*/

module sp
    import cpu_common::sp_operation_t;
(
    input clk,
    input rst_async,

    input sp_operation_t sp_operation,

    output logic [13:0] sp_addr
);

always_ff @(posedge clk, posedge rst_async) begin
    if (rst_async)
        sp_addr <= '1;//Start at end of address space
    else if (clk) begin
        case (sp_operation)
            cpu_common::SP_NOP: begin end//Do nothing
            cpu_common::SP_INC_1: sp_addr <= sp_addr + 1;
            cpu_common::SP_INC_2: sp_addr <= sp_addr + 2;
            cpu_common::SP_DEC_1: sp_addr <= sp_addr - 1;
            cpu_common::SP_DEC_2: sp_addr <= sp_addr - 2;
            default: sp_addr <= 'x;
        endcase
    end
end

endmodule
