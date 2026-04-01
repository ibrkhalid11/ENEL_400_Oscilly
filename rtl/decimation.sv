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

/* timescale to downsample --> based off 60_000_000 Sps
 * 0: 500ms --> 2Hz --> ONLY FOR DC 
 * 1: 100ms --> 10Hz --> only for DC
 * 2: 50ms --> 20Hz
 * 3: 10ms --> 100Hz
 * 4: 5ms --> 200Hz
 * 5: 1ms --> 1KHz
 * 6: 0.1ms --> 10_000Hz
 * 7: 0.05ms --> 20_000Hz
 * 8: 0.01ms --> 100_000Hz
 * 9: 0.005ms --> 200_000Hz
 * 10: 0.001ms --> 1_000_000Hz
 * 11: 0.0005ms --> 2_000_000Hz
 * 12: 0.0001ms --> 10_000_000Hz
 * 13: 0.00005ms --> 20_000_000Hz
 * 14: 0.0000167ms --> 100_000_000Hz
 *
*/
`timescale 1ns / 1ps

module decimation #(
    parameter int SAMPLE_RATE = 1_000_000,
    parameter int DATA_WIDTH = 12
)(
    input logic clk,
    input logic reset,
    
    input logic [3:0] timescale_in,

    input logic [DATA_WIDTH - 1 : 0] adc_data,
    input logic adc_data_valid,

    output logic [DATA_WIDTH - 1 : 0] sample_out,
    output logic sample_valid
);


    typedef int unsigned clk_ratio_t [15];
    
    /* based off 1MSPs*/
    // localparam clk_ratio_t CLK_LUT = '{
    //     1,
    //     2,
    //     10,
    //     20,
    //     100,
    //     1_000,
    //     10_000
    // };
    /* based off 60MSPS*/
    localparam clk_ratio_t CLK_LUT = '{
        30_000_000,  //  0:  2 Hz
         6_000_000,  //  1: 10 Hz
         3_000_000,  //  2: 20 Hz
           600_000,  //  3: 100 Hz
           300_000,  //  4: 200 Hz
            60_000,  //  5: 1 KHz
             6_000,  //  6: 10 KHz
             3_000,  //  7: 20 KHz
               600,  //  8: 100 KHz
               300,  //  9: 200 KHz
                60,  // 10: 1 MHz
                30,  // 11: 2 MHz
                 6,  // 12: 10 MHz
                 3,  // 13: 20 MHz
                 1   // 14: 60 MHz (passthrough)
    };
    logic [3:0] timescale_prev;
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