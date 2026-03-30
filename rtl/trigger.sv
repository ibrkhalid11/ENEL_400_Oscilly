`timescale 1ns / 1ps

module trigger #(
    parameter int WIDTH = 16
)(
    input logic clk,
    input logic reset,
    input logic [WIDTH - 1 : 0] sample_in,
    input logic [WIDTH - 1 : 0] threshold,
    input logic sample_valid,
    
    output logic trigger_level,
    output logic trigger_edge
);

    logic prev_above;
    logic above;
    assign above = (sample_in >= threshold);
    assign trigger_level = above;

    always_ff @(posedge clk) begin 
        if(reset) begin
            prev_above <= 1'b0;
        end else if(sample_valid) begin
            prev_above <= above;
        end
    end
    assign trigger_edge = above & ~prev_above & sample_valid;



endmodule