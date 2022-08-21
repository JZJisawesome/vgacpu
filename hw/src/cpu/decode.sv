/* decode
 * By: John Jekel
 *
 * Decode unit for the cpu
 *
*/

module decode (
    input clk,

    //Control Signal In
    input logic decode_en,//Decode the instruction; useful for fetching the next instruction while executing this one if disabled

    //Instruction In
    input logic [15:0] inst,

    //Decoded Results Out
    output logic [7:0] immediate,
    output logic [1:0] inst_type,
    output logic [2:0] rf_write_addr,
    output logic [2:0] rX_addr

    //TODO signals to control logic
);

logic [2:0] rf_write_addr_internal;
logic [2:0] rX_addr_internal;

always_ff @(posedge clk) begin//The decode step takes 1 clock cycle
    if (decode_en) begin
        immediate <= inst[15:8];
        inst_type <= inst[1:0];
        rf_write_addr <= rf_write_addr_internal;
        rX_addr <= rX_addr_internal;
    end
end

//Determining which registers are being accessed is difficult in this architecture
//Probably could have designed this better, but hey, this is my first stab at a custom arch
always_comb begin
    case (inst[1:0])
        2'b11: begin//We have to deal with the 0TOX and XTO0 instructions
            if (inst[7:2] == 6'b100000) begin//0TOX
                rf_write_addr_internal <= inst[10:8];
                rX_addr_internal <= 0;
            end else if (inst[7:2] == 6'b100001) begin//XTO0
                rf_write_addr_internal <= 0;
                rX_addr_internal <= inst[10:8];
            end else begin
                rf_write_addr_internal <= 'x;
                rX_addr_internal <= 'x;
            end
        end 2'b10: begin;//The register to read, or to write, is always in inst[7:5]
            rf_write_addr_internal <= inst[7:5];
            rX_addr_internal <= inst[7:5];
        end 2'b01: begin//The register to read, or to write, is always in inst[7:5]
            rf_write_addr_internal <= inst[7:5];
            rX_addr_internal <= inst[7:5];
        end 2'b00: begin//No register accesses in this instruction type
            rf_write_addr_internal <= 'x;
            rX_addr_internal <= 'x;
        end default: begin
            rf_write_addr_internal <= 'x;
            rX_addr_internal <= 'x;
        end
    endcase
end

endmodule
