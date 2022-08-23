/* sound
 * By: John Jekel
 *
 * Hardware to manage the system's sound
 *
*/

module sound (
    input logic clk,//50MHz
    input logic rst_async,

    //CPU-Sound Interface
    //The max_count should be (50000000 / desired_frequency) / 2, aka 25000000 / desired_frequency
    input logic [25:0] max_count,//Enough bits for frequencies as low as < 1hz
    input logic latch_max_count,//Hold for 1 clock cycle to latch the new max count

    output logic buzzer
);

//Max Count latching logic
logic [25:0] max_count_reg;

always_ff @(posedge clk, posedge rst_async) begin
    if (rst_async)
        max_count_reg <= '0;//Start disabled
    else if (clk) begin
        if (latch_max_count)
            max_count_reg <= max_count;
    end
end

//Frequency generation logic
logic toggle;
assign buzzer = toggle & (max_count_reg != 0);//A max count of 0 means don't play anything

logic [25:0] counter;
logic max_count_reached;
assign max_count_reached = counter >= max_count_reg;

always_ff @(posedge clk) begin
    counter <= max_count_reached ? '0: (counter + 1);//Count up to max_count_reg inclusive

    if (max_count_reached)//Counter is about to flip
        toggle <= ~toggle;//Toggle the buzzer
end

endmodule
