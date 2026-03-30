`timescale 1ns / 1ps
module toplevelMVP(
    input logic clk,
    input logic adc_clk,
    input logic reset,
    /* adc pins*/
    input logic [9:0] async_adc,
    /* UART pins */
    input logic uart_en,
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
    logic ac_mode;
    logic [15:0] uart_data_mux;
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
    logic [3:0] timescale_set;
    /* synchronize all pin inputs */
    logic synchpwm_comp;
    logic synch_uart_en;
    synchro synchpwmcomp(
        .clk(clk),
        .reset(reset),
        .in(pwm_comp),
        .out(synchpwm_comp)
    );
    synchro uart_en_sync(
    .clk(clk),
    .reset(reset),
    .in(uart_en),
    .out(synch_uart_en)
    );
    
    logic [9:0] ext_adc_data;
    logic fifo_empty;
    FIFO #(.DSIZE(10),
            .ASIZE(4))
        ADC_FIFO (
        .wclk(adc_clk),
        .wrst_n(1'b1),
        .wdata(async_adc),
        .winc(1'b1),
        .wfull(),               // safe to leave open
    
        .rclk(clk),
        .rrst_n(~reset),
        .rdata(ext_adc_data),
        .rinc(~fifo_empty),
        .rempty(fifo_empty)     // this is your valid signal
    );
    synchro synch_uart_rx (
        .clk(clk),
        .reset(reset),
        .in(rx), 
        .out(synch_rx)
    );

    /* correct all inputs if needed */


    /* UART comms instants */

    // Transmit controller
    uart_send_16 UART_CTRL (
        .clk(clk),
        .rst(reset),
        .data_in(uart_data_mux),   // 16-bit ADC result
        .data_valid(ac_mode ? buf_uart_valid : ready_r_out),      // fires when recorder has new sample
        .uart_en(synch_uart_en),
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
    
    rx_handler RX_HANDLER (
        .clk(clk), .reset(reset),
        .uart_rx(rx_data), 
        .rx_valid(rx_valid),
        .timescale_set(timescale_set),
        .AC(ac_mode)
    );
    mux21 #(.WIDTH(16)) UART_DATA_SEL (
        .select(ac_mode),
        .d0(signal_select_out),  // DC path
        .d1(buf_uart_data),      // AC path
        .y(uart_data_mux)
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
        
        /* TODO: change the scaling factor to fit 0-30000 rather than 0-3300 */
        adc_processing #(.SCALING_FACTOR(825), .SHIFT_FACTOR(14)) DC_PROC (
        .clk(clk),
        .reset(reset),
        .ready(ready_r_out),
        .data({raw_adc, 8'b0}),
        .averaged_data(averaged_data),
        .scaled_adc_data(scaled_data)
    );
    
    
    logic [15:0] async_scaled_data, async_averaged_data;
    logic        async_ready_pulse;
    
    adc_processing #(
        .SCALING_FACTOR(825),
        .SHIFT_FACTOR(14)
    ) ASYNC_ADC_PROC (
        .clk(clk),
        .reset(reset),
        .ready(~fifo_empty),
        .data({ext_adc_data, 6'b0}),      // zero-extend 10-bit to 16-bit
        .averaged_data(async_averaged_data),
        .scaled_adc_data(async_scaled_data),
        .ready_pulse(async_ready_pulse)
    );
    
    logic [15:0] decimated_data;
    logic        decim_valid;
    decimation #(
        .SAMPLE_RATE(60_000_000),
        .DATA_WIDTH(16)
    ) DECIMATOR (
        .clk(clk),
        .reset(reset),
        .timescale_in(timescale_set),
        .adc_data(async_scaled_data),
        .adc_data_valid(~fifo_empty),
        .sample_out(decimated_data),
        .sample_valid(decim_valid)        
    );
    
    /* need to write a trigger file */
    logic [15:0] buf_uart_data;
    logic        buf_uart_valid;
    logic trigger_level, trigger_edge;

    trigger #(.WIDTH(16)) TRIG (
        .clk(clk),
        .reset(reset),
        .sample_in(decimated_data),
        .threshold(16'h8000),
        .sample_valid(decim_valid),
        .trigger_level(trigger_level),
        .trigger_edge(trigger_edge)
    );
    logic [15:0] calc_vmax, calc_vmin, calc_vpp;
    logic [8:0] calc_period;
    logic calc_valid;
    
    calcs #(
        .WIDTH(16),
        .DEPTH(480)
    ) CALCS_INST (
        .clk(clk),
        .reset(reset),
        .start(trigger_edge),
        .sample_in(decimated_data),
        .sample_valid(decim_valid),
        .threshold(16'h8000),
        .vmax(calc_vmax),
        .vmin(calc_vmin),
        .vpp(calc_vpp),
        .period_count(calc_period),
        .high_count(),              // unused for now
        .meas_valid(calc_valid)
    );
    
    ram_buffer #(
        .WIDTH(16),
        .DEPTH(480)
    ) RAM_BUFFER (
        .clk(clk),
        .reset(reset),
        .timescale_in(timescale_set),
        .trigger(trigger_edge),
        .sample_in(decimated_data),
        .sample_valid(decim_valid),
        .uart_ready(~tx_busy),
        .uart_data(buf_uart_data),
        .uart_valid(buf_uart_valid),
        .vmax(calc_vmax),
        .vmin(calc_vmin),
        .vpp(calc_vpp),
        .period_count(calc_period)
    );
    /* TODO ADD SELECT SWITCH/GPIO FOR THIS */
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
    /*TODO: WIRE THIS TO A SWITCH */
    mux21 #(.WIDTH(16)) BINBCD_SEL (
        .select(1'b1),          // or wire to a switch
        .d0(signal_select_out),
        .d1(bcd_out),
        .y(binbcd_sel_out)
    );
    /* SSD instant*/
    /* KEEP THIS ONLY FOR DC */
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
    logic fifo_not_empty_prev;
    logic fifo_read_pulse;
    always_ff @(posedge clk) begin
        fifo_not_empty_prev <= ~fifo_empty;
        fifo_read_pulse     <= (~fifo_empty) & fifo_not_empty_prev ? 1'b0 : (~fifo_empty);
    end
endmodule 
