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
    //TODO we'll probably have to replace this with a max_counter_val instead to avoid division
    //We could still keep the tone instruction, and just have the assembler perform the division ahead of time :)
    input [14:0] freq,//We won't really need more than 32KHzish, so this is wide enough
    input logic latch_freq,//Hold for 1 clock cycle to latch the new frequency

    output logic buzzer
);

//Frequency latching logic
logic [14:0] freq_reg;

always_ff @(posedge clk, posedge rst_async) begin
    if (rst_async)
        freq_reg <= '0;
    else if (clk) begin
        if (latch_freq)
            freq_reg <= freq;
    end
end

//Frequency generation logic
logic toggle;
assign buzzer = toggle & (freq != 0);//A frequency of 0 means don't play anything

logic [25:0] max_count;
assign max_count = (50000000 / freq_reg) / 2;//We divide by 2 since we want a 50% duty cycle//TODO avoid division here
logic [25:0] counter;
logic [25:0] next_seq_cnt;
assign next_seq_cnt = counter + 1;

always_ff @(posedge clk) begin
    counter <= (next_seq_cnt < max_count) ? next_seq_cnt : '0;

    if (next_seq_cnt == max_count)//Counter is about to flip
        toggle = ~toggle;//Toggle the buzzer
end

endmodule
