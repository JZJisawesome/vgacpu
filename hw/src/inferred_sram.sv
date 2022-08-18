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
	parameter TOTAL_WORDS = 0,//If 0, TOTAL_WORDS is inferred from A_WIDTH (becomes 2 ** A_WIDTH)
	parameter A_WIDTH = 8//Must be large enough to accomodate the number of words
) (
	input logic clk,

	//Port A
	//Common
	input logic [A_MAX:A_MIN] addr_a,
	//Reading
	output logic [D_MAX:D_MIN] read_a,
	//Writing
	input logic write_en_a,
	input logic [D_MAX:D_MIN] write_a,

	//Port B
	//Common
	input logic [A_MAX:A_MIN] addr_b,
	//Reading
	output logic [D_MAX:D_MIN] read_b,
	//Writing
	input logic write_en_b,
	input logic [D_MAX:D_MIN] write_b
);

//Processing of parameters
localparam D_MAX = D_WIDTH - 1;
localparam D_MIN = 0;
localparam A_MAX = A_WIDTH - 1;
localparam A_MIN = 0;
localparam int NUM_ADDR = (TOTAL_WORDS != 0) ? TOTAL_WORDS : (2 ** A_WIDTH);
localparam LAST_ADDR = TOTAL_WORDS - 1;
localparam FIRST_ADDR = 0;

//The actual inferred SRAM
logic [D_MAX:D_MIN] sram [LAST_ADDR:FIRST_ADDR];

//Address latching and read/write logic for ports A and B

//Port A
always_ff @(posedge clk) begin
	if (write_en_a)
		sram[addr_a] <= write_a;

	read_a <= sram[addr_a];
end

//Port B
always_ff @(posedge clk) begin
	if (write_en_b)
		sram[addr_b] <= write_b;

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
