`timescale 1ns / 1ps
/*
 * corrector.sv
 * made to invert the signal in order to have accurate processing 
 */
module corrector(
    input logic in,
    output logic out
    );
    assign out = ~in;
endmodule
