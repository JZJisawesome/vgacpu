/* main_mem
 * By: John Jekel
 *
 * Inferred SRAM module for holding the CPU's main memory
 *
*/

/* Inferred SRAM module for a Cyclone IV FPGA
 * Thank you Recommended HDL Coding Styles doc
 * Partly borrowed from jzjcore project/other past projects

 * Note: The Cyclone IV's SRAM supports masking bytes from being written
 * The original version of this module exposed this behaviour since, in jzjcore,
 * the memory was always known to be 32 bits wide.
 * Here however this is of less utility, and we can't really implement it anyways
 * since we don't know the D_WIDTH of the sram ahead of time; we are given it as a parameter
 *
*/

module main_mem #(
	parameter INITIALIZE_FROM_FILE = 0,//Whether to have default ram contents at boot
	parameter FILE = "rom.mem",
	parameter FILE_TYPE_BIN = 0//Hex by default
) (
	input logic clk,

	//Port A
	//Common
	input logic [A_MAX:A_MIN] addr_a,
	//Reading
	output logic [15:0] read_a,
	//Writing
	input logic write_en_a,
	input logic [1:0] write_mask_a,
	input logic [15:0] write_a,

	//Port B
	//Common
	input logic [A_MAX:A_MIN] addr_b,
	//Reading
	output logic [15:0] read_b,
	//Writing
	input logic write_en_b,
	input logic [1:0] write_mask_b,
	input logic [15:0] write_b
);

//Parameters
localparam A_WIDTH = 13;

//Processing of parameters
localparam A_MAX = A_WIDTH - 1;
localparam A_MIN = 0;
localparam int NUM_ADDR = 2 ** A_WIDTH;
localparam LAST_ADDR = NUM_ADDR - 1;
localparam FIRST_ADDR = 0;

//The actual inferred SRAM
logic [1:0][7:0] sram [LAST_ADDR:FIRST_ADDR];

//Address latching and read/write logic for ports A and B

//Port A
always_ff @(posedge clk) begin
	if (write_en_a) begin
		if (write_mask_a[0])
            sram[addr_a][0] <= write_a[7:0];
		if (write_mask_a[1])
            sram[addr_a][1] <= write_a[15:8];
    end

	read_a <= sram[addr_a];
end

//Port B
always_ff @(posedge clk) begin
	if (write_en_b) begin
		if (write_mask_b[0])
            sram[addr_b][0] <= write_b[7:0];
		if (write_mask_b[1])
            sram[addr_b][1] <= write_b[15:8];
    end

	read_b <= sram[addr_b];
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
