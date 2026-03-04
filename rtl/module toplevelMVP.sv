`timescale 1ns / 1ps
module toplevelMVP(
    input logic clk,
    input logic reset,
    /* UART pins */
    input logic rx,
    output logic tx,
    /* XADC Pins for AC secition */
    input vauxp15,
    input vauxn15,
    /* Comparator Pins for DC Section */
    input logic pwm_comp,
    /* if we want SSD put outputs here */
    output logic   CA, CB, CC, CD, CE, CF, CG, DP,
    output logic   AN1, AN2, AN3, AN4,
    output logic [15:0] led,
    output logic dc_pwm_out
);
    logic [7:0] adc_out;
    logic [7:0] duty_cycle_test;
    logic [7:0] raw_adc;
    logic [15:0] scaled_data, averaged_data;
    logic [15:0] signal_select_out;
    logic [15:0] bcd_out;
    logic valid_sar;
    logic ready_r_out;

    /* uart wires */
    logic [7:0] tx_data;
    logic       tx_start;
    logic       tx_busy;
    logic [7:0] rx_data;
    logic       rx_valid;
    logic       synch_rx;
    /*bring in all xadc signals needed */
    logic       ready_ac;
    logic[15:0] data;
    logic       ac_enable;
    //logic[4:0] channel_out;
    //logic     eoc_out;
    logic[6:0]  daddr_in;
    logic       eos_out;
    logic       busy_out;
    


    /* synchronize all pin inputs */
    logic synchpwm_comp;
    xadc_wiz_0 ACADC (
        .di_in(16'h0000),        // Not used for reading
        .daddr_in(CHANNEL_ADDR), // Channel address
        .den_in(enable),         // Enable signal
        .dwe_in(1'b0),           // Not writing, so set to 0
        .drdy_out(ac_ready),        // Data ready signal (when high, ADC data is valid)
        .do_out(data),           // ADC data output
        .dclk_in(clk),           // Use system clock
        .reset_in(reset),   // Active-high reset
        .vp_in(1'b0),            // Not used, leave disconnected
        .vn_in(1'b0),            // Not used, leave disconnected
        .vauxp15(vauxp15),       // Auxiliary analog input (positive)
        .vauxn15(vauxn15),       // Auxiliary analog input (negative)
        .channel_out(),          // Current channel being converted
        .eoc_out(enable),        // End of conversion
        .alarm_out(),            // Not used
        .eos_out(eos_out),       // End of sequence
        .busy_out(busy_out)      // XADC busy signal
    );
    
    synchro synchpwmcomp(
        .clk(clk),
        .reset(reset),
        .in(pwm_comp),
        .out(synchpwm_comp)
    );
    synchro synch_uart_rx (
        .clk(clk),
        .reset(reset),
        .in(rx), 
        .out(synch_rx)
    );
    /* synch all buttons */
    /* synch all switches */

    /* correct all inputs if needed */


    /* UART comms instants */

    // Transmit controller
    uart_send_16 UART_CTRL (
        .clk(clk),
        .rst(reset),
        .data_in(signal_select_out),   // 16-bit ADC result
        .data_valid(ready_r_out),      // fires when recorder has new sample
        .tx_data(tx_data),
        .tx_start(tx_start),
        .tx_busy(tx_busy)
    );

    // UART TX
    uart_tx #(.BAUD_DIV(868)) UART_TX_INST (
        .clk(clk),
        .rst(reset),
        .tx_data(tx_data),
        .tx_start(tx_start),
        .tx(tx),
        .tx_busy(tx_busy)
    );

    // UART RX (optional, if you need to receive commands)
    uart_rx #(.BAUD_DIV(868)) UART_RX_INST (
        .clk(clk),
        .rst(reset),
        .rx(synch_rx),
        .rx_data(rx_data),
        .rx_valid(rx_valid)
    );
    
    /* ======== DC PATH ======= */
        /* sar instantiation */
    sar #(.WIDTH(8)) DC_ADC(
        .clk(clk),
        .reset(reset),
        .comparator(synchpwm_comp),
        .adc_out(adc_out),
        .R2R_out(duty_cycle_test),
        .valid(valid_sar)
    );
        /* sar pwm instantiation */
    pwm #(.WIDTH(8)) SAR_PWM (
        .clk(clk),
        .reset(reset),
        .enable(1'b1),
        .duty_cycle(duty_cycle_test),
        .pwm_out(dc_pwm_out)
    );
        /* DC recorder instant */
    recorder SAR_RECORDER (
        .clk(clk),
        .reset(reset),
        .ready(valid_sar),
        .duty_cycle(adc_out),
        .duty_cycle_out(raw_adc),
        .ready_r_out(ready_r_out)
    );
        /* DC processing instant */
    adc_processing #(.SCALING_FACTOR(825), .SHIFT_FACTOR(14)) DC_PROC (
        .clk(clk),
        .reset(reset),
        .ready(ready_r_out),
        .data(raw_adc),
        .averaged_data(averaged_data),
        .scaled_adc_data(scaled_data)
    );
    
    mux21 #(.WIDTH(16)) SIGNAL_SEL (
        .select(1'b0),          // or a switch if you want to toggle
        .d0(scaled_data),
        .d1(averaged_data),
        .y(signal_select_out)
    );
    
    /* bin_to_bcd instant */
    bin_to_bcd BIN2BCD (
        .clk(clk),
        .reset(reset),
        .bin_in(signal_select_out),
        .bcd_out(bcd_out)
    );
    logic [15:0] binbcd_sel_out;
    mux21 #(.WIDTH(16)) BINBCD_SEL (
        .select(1'b1),          // or wire to a switch
        .d0(signal_select_out),
        .d1(bcd_out),
        .y(binbcd_sel_out)
    );
    /* SSD instant*/
    seven_segment_display_subsystem SSD (
        .clk(clk),
        .reset(reset),
        .sec_dig1(binbcd_sel_out[3:0]),
        .sec_dig2(binbcd_sel_out[7:4]),
        .min_dig1(binbcd_sel_out[11:8]),
        .min_dig2(binbcd_sel_out[15:12]),
        .CA(CA), .CB(CB), .CC(CC), .CD(CD),
        .CE(CE), .CF(CF), .CG(CG), .DP(DP),
        .AN1(AN1), .AN2(AN2), .AN3(AN3), .AN4(AN4)
    );
    

endmodule