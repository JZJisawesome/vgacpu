/* rasterizer_controller
 * By: John Jekel
 *
 * CPU module for communicating the the rasterizer
 *
*/

module rasterizer_controller
(

    input common::raster_command_t gpu_command,
    input logic [7:0] r4, r5, r6, r7,
    input logic [7:0] immediate,
    input logic gpu_submit,
    output logic gpu_busy,

    //CPU-GPU Interface
    rasterizer_if.cpu gpu_if
);

assign gpu_if.command = gpu_command;
assign gpu_if.x0 = r4;
assign gpu_if.y0 = r5;
assign gpu_if.x1 = r6;
assign gpu_if.y1 = r7;
assign gpu_if.colour = immediate[2:0];//The colour is always taken from an immediate
assign gpu_busy = gpu_if.busy;

assign gpu_if.execute_request = gpu_submit & ~gpu_if.busy;//Avoid executing a request if we're currently busy

endmodule
