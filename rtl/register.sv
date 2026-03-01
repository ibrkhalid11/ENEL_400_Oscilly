/* 
 * register.sv
 *  made to act as a D Flip Flop
 * Inputs: CLK, en, reset, d_in
 * Output: q_out
*/
module register 
    #(
        parameter int WIDTH = 8
    )
    (
        input logic clk,
        input logic en,
        input logic reset,
        input logic [WIDTH - 1 : 0] d_in,
        output logic [WIDTH - 1 : 0] q_out
    );
    
    always_ff @(posedge clk) begin
        if(reset)
            q_out <= 0;
        else if(en)
            q_out <= d_in;
    end

endmodule