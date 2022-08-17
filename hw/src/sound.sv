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
    //The max_count should be (50000000 / desired_frequency) / 2 (for a 50% duty cycle)
    input logic [25:0] max_count,//Enough bits for frequencies as low as < 1hz
    input logic latch_max_count,//Hold for 1 clock cycle to latch the new max count

    //Old way (nice but no way of avoiding division in hardware)
    //input logic [14:0] freq,//We won't really need more than 32KHzish, so this is wide enough
    //input logic latch_freq,//Hold for 1 clock cycle to latch the new frequency

    output logic buzzer
);

//New Max Count latching logic
logic [14:0] max_count_reg;

always_ff @(posedge clk, posedge rst_async) begin
    if (rst_async)
        max_count_reg <= '0;//Start disabled
    else if (clk) begin
        if (latch_max_count)
            max_count_reg <= max_count;
    end
end

//OLD Frequency latching logic
/*
logic [14:0] freq_reg;

always_ff @(posedge clk, posedge rst_async) begin
    if (rst_async)
        freq_reg <= '0;
    else if (clk) begin
        if (latch_freq)
            freq_reg <= freq;
    end
end
*/

//Frequency generation logic
logic toggle;
assign buzzer = toggle & (max_count_reg != 0);//A max count of 0 means don't play anything

//OLD
//assign buzzer = toggle & (freq != 0);//A frequency of 0 means don't play anything
//logic [25:0] max_count;
//assign max_count = (50000000 / freq_reg) / 2;//We divide by 2 since we want a 50% duty cycle//OLD WAY OF DOING THIS

logic [25:0] counter;
logic [25:0] next_seq_cnt;
assign next_seq_cnt = counter + 1;

always_ff @(posedge clk, posedge rst_async) begin
    counter <= (next_seq_cnt < max_count) ? next_seq_cnt : '0;

    //New
    if (next_seq_cnt == max_count_reg)//Counter is about to flip
        toggle = ~toggle;//Toggle the buzzer

    //OLD
    //if (next_seq_cnt == max_count)//Counter is about to flip
    //    toggle = ~toggle;//Toggle the buzzer
end

endmodule
