/* 
 * TODO: add commands as localparams
*/
/*
 * standard for timescale
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
 * 14: 0.00001ms --> 100_000_000Hz
*/

`timescale 1ns / 1ps

module rx_handler(
    input logic clk,
    input logic reset,

    input logic [7:0] uart_rx,
    input logic rx_valid,
    /* make this a bus cmd instead */
    output logic [3:0] timescale_set,
    output logic AC
);
    logic [6:0] uart_check;

    assign uart_check = uart_rx[7:1];

    always_ff@(posedge clk) begin
        if(reset) begin
            timescale_set <= 0;
            AC <= 0;
        end else begin
            if(rx_valid) begin
                
                AC <= uart_rx[0];
                if(uart_check <= 7'd14) begin
                    timescale_set <= uart_check[3:0];
                end
            end
        end
    end

endmodule