/* 
 *  synchro.sv
 * only used to synchronize inputs
 * Inputs: clk, reset, in, out
 * Outputs: out
 */
module synchro(
    input logic clk,
    input logic reset,
    input logic in,
    output logic out
);
    logic out_inv;
    assign out = out_inv;
    logic intermediate_wire;

    register #(.WIDTH(1)) REG1 (
        .clk(clk),
        .en(1),
        .reset(reset),
        .d_in(in),
        .q_out(intermediate_wire)
    );
    register #(.WIDTH(1)) REG2 (
        .clk(clk),
        .en(1),
        .reset(reset),
        .d_in(intermediate_wire),
        .q_out(out_inv)
    );

endmodule