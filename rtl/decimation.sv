/* timescale to downsample --> based off 1_000_000 SPS
 * 0: 1MHz
 * 1: 500KHz
 * 2: 100KHz
 * 3: 50KHz
 * 4: 10KHz
 * 5: 1KHz
 * 6: 100Hz
 * 
*/

`timescale 1ns / 1ps

module decimation #(
    parameter int SAMPLE_RATE = 1_000_000,
    parameter int DATA_WIDTH = 12
)(
    input logic clk,
    input logic reset,
    
    input logic [2:0] timescale_in,

    input logic [DATA_WIDTH - 1 : 0] adc_data,
    input logic adc_data_valid,

    output logic [DATA_WIDTH - 1 : 0] sample_out,
    output logic sample_valid
);


    typedef int unsigned clk_ratio_t [7];

    localparam clk_ratio_t CLK_LUT = '{
        1,
        2,
        10,
        20,
        100,
        1_000,
        10_000
    };
    logic [2:0] timescale_prev;
    int unsigned decim_ratio;
    int unsigned decim_counter;

    /* divider clk generation*/
    always_ff@(posedge clk) begin
        if(reset) begin
            decim_ratio <= CLK_LUT[0];
            timescale_prev <= '0;
        end else begin
            timescale_prev <= timescale_in;
            decim_ratio <= CLK_LUT[timescale_in];
        end
    end

    always_ff@(posedge clk) begin
        if(reset) begin
            decim_counter <= 0;
            sample_out <= '0;
            sample_valid <= 1'b0;
        end else begin
            sample_valid <= 1'b0;

            if(timescale_in != timescale_prev) begin
                decim_counter <= '0;
            end else if(adc_data_valid) begin
                if(decim_counter >= decim_ratio - 1) begin
                    decim_counter <= '0;
                    sample_out <= adc_data;
                    sample_valid <= 1'b1;
                end else begin
                    decim_counter <= decim_counter + 1;
                end
            end
        end
    end 
endmodule