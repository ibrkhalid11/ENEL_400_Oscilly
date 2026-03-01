/* capture for the ADC's
 * parameters: DC_WIDTH
 * Input: clk, reset, ready, duty_cycle
 * Output: duty_cycle_out, ready_r_out
 */
module recorder
    #(
        parameter int DC_WIDTH = 8
    )
    (
        input logic clk,
        input logic reset,
        input logic ready,
        input logic [DC_WIDTH - 1 : 0] duty_cycle,
        output logic [DC_WIDTH - 1 : 0] duty_cycle_out,
        output logic ready_r_out
    );
    logic ready_r;
    assign ready_r_out = ready & ~ready_r;
    
    register #(.WIDTH(1)) PULSE0 (
        .clk(clk),
        .en(1),
        .reset(reset),
        .d_in(ready),
        .q_out(ready_r)
    );
    register #(.WIDTH(DC_WIDTH)) PULSE1 (
        .clk(clk),
        .en(ready & ~ready_r),
        .reset(reset),
        .d_in(duty_cycle),
        .q_out(duty_cycle_out)
    );

endmodule