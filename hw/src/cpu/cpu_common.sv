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

    typedef enum {SP_NOP, SP_INC_1, SP_INC_2, SP_DEC_1, SP_DEC_2} sp_operation_t;

    typedef enum {FETCH_NOP, FETCH_INC_PC, FETCH_RET} fetch_operation_t;

    typedef enum {AGU_PUSH_POP, AGU_SHORT_IMM} agu_operation_t;
endpackage
