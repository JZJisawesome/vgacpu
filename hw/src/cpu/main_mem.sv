/* main_mem
 * By: John Jekel
 *
 * Inferred SRAM module for holding the CPU's main memory
 *
*/

/* Inferred SRAM module for a Cyclone IV FPGA
 * Thank you Recommended HDL Coding Styles doc
 * Partly borrowed from jzjcore project/other past projects
 *
*/

module main_mem #(
	parameter INITIALIZE_FROM_FILE = 0,//Whether to have default ram contents at boot
	parameter FILE = "rom.mem",
	parameter FILE_TYPE_BIN = 0,//Hex by default
	parameter A_WIDTH = 13,
	parameter TOTAL_WORDS = 2 ** A_WIDTH
) (
	input logic clk,

	//Instruction Port
	input logic [A_MAX:A_MIN] mem_inst_addr,
	output logic [15:0] mem_instr,

	//Data Port
	//Common
	input logic [A_MAX:A_MIN] mem_data_addr,
	//Reading
	output logic [15:0] mem_data_read,
	//Writing
	input logic mem_data_write_en,
	input logic [1:0] mem_data_write_mask,
	input logic [15:0] mem_data_write
);

//Parameters

//Processing of parameters
localparam A_MAX = A_WIDTH - 1;
localparam A_MIN = 0;
localparam LAST_ADDR = TOTAL_WORDS - 1;
localparam FIRST_ADDR = 0;

//The actual inferred SRAM
logic [1:0][7:0] sram [LAST_ADDR:FIRST_ADDR];

//Address latching and read/write logic for ports A and B

//Instruction Port
always_ff @(posedge clk) begin
	mem_instr <= sram[mem_inst_addr];
end

//Data Port
always_ff @(posedge clk) begin
	if (mem_data_write_en) begin
		if (mem_data_write_mask[0])
            sram[mem_data_addr][0] <= mem_data_write[7:0];
		if (mem_data_write_mask[1])
            sram[mem_data_addr][1] <= mem_data_write[15:8];
    end

	mem_data_read <= sram[mem_data_addr];
end

//Initialization Code

initial begin
	if (INITIALIZE_FROM_FILE)
	begin
		if (FILE_TYPE_BIN)
		  $readmemb(FILE, sram);
		else
		  $readmemh(FILE, sram);
	end
end

endmodule
