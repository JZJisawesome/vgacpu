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

module inferred_sram #(
	parameter INITIALIZE_FROM_FILE = 0,//Whether to have default ram contents at boot
	parameter FILE = "rom.mem",
	parameter FILE_TYPE_BIN = 0,//Hex by default
	parameter D_WIDTH = 8,
	parameter A_WIDTH = 8
) (
	input logic clk,
	
	//Port A
	//Reading
	input logic [A_MAX:A_MIN] read_addr_a,
	output logic [D_MAX:D_MIN] read_a,
	//Writing
	input logic [A_MAX:A_MIN] write_addr_a,
	input logic write_en_a,
	input logic [D_MAX:D_MIN] write_a,
	
	//Port B
	//Reading
	input logic [A_MAX:A_MIN] read_addr_b,
	output logic [D_MAX:D_MIN] read_b,
	//Writing
	input logic [A_MAX:A_MIN] write_addr_b,
	input logic write_en_b,
	input logic [D_MAX:D_MIN] write_b
);

//Processing of parameters
localparam D_MAX = D_WIDTH - 1;
localparam D_MIN = 0;
localparam A_MAX = A_WIDTH - 1;
localparam A_MIN = 0;
localparam int NUM_ADDR = 2 ** A_WIDTH;
localparam LAST_ADDR = NUM_ADDR - 1;
localparam FIRST_ADDR = 0;

//The actual inferred SRAM
logic [D_MAX:D_MIN] sram [LAST_ADDR:FIRST_ADDR];

//Address latching and read/write logic for ports A and B

//Port A
always_ff @(posedge clk) begin
	if (write_en_a)
		sram[write_addr_a] <= write_a;

	read_a <= sram[read_addr_a];
end

//Port B
always_ff @(posedge clk) begin
	if (write_en_b)
		sram[write_addr_b] <= write_b;

	read_b <= sram[read_addr_b];
end

//Initialization Code

initial begin
	if (INITIALIZE_FROM_FILE)
	begin
		if (FILE_TYPE_BIN)
		  $readmemb(FILE, ram);
		else
		  $readmemh(FILE, ram);
	end
end

endmodule
