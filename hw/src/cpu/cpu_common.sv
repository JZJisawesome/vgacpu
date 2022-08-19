/* cpu_common
 * By: John Jekel
 *
 * Common package for the cpu part of vgacpu
 *
*/

package cpu_common;
    typedef enum {ALU_ADD, ALU_SUB, ALU_AND, ALU_OR, ALU_XOR, ALU_MUL, ALU_SR, ALU_SL} alu_operation_t;
    typedef enum {ALU_RX, ALU_IMMEDIATE} alu_operand_t;

    typedef enum {RF_MUX_IMM, RF_MUX_R0, RF_MUX_ALU, RF_MUX_MEM} rf_mux_src_t;
endpackage