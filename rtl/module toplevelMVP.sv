`timescale 1ns / 1ps
module toplevelMVP(
    input logic clk,
    input logic adc_clk,
    input logic reset,
    /* adc pins*/
    input logic [9:0] async_adc,
    /* UART pins */
    input logic uart_en,
    output logic mpreg,
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
    logic       tx_word_busy;   // high for entire 2-byte word
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
        .wfull(),

        .rclk(clk),
        .rrst_n(~reset),
        .rdata(ext_adc_data),
        .rinc(~fifo_empty),
        .rempty(fifo_empty)
    );
    synchro synch_uart_rx (
        .clk(clk),
        .reset(reset),
        .in(rx), 
        .out(synch_rx)
    );

//    /* ============================================================
//     *  DEBUG HEARTBEAT - sends 0xBEEF every ~0.5 s (100 MHz)
//     *  Proves the UART PHY + wiring work independently of the
//     *  SAR / AC data paths.  Remove once the real path is live.
//     * ============================================================ */
//    logic [25:0] dbg_cnt;
//    logic        dbg_pulse;
//    logic [15:0] dbg_data;

//    always_ff @(posedge clk) begin
//        if (reset) begin
//            dbg_cnt   <= '0;
//            dbg_pulse <= 1'b0;
//        end else begin
//            dbg_pulse <= 1'b0;
//            if (dbg_cnt == 26'd49_999_999) begin
//                dbg_cnt   <= '0;
//                dbg_pulse <= 1'b1;
//            end else begin
//                dbg_cnt <= dbg_cnt + 1;
//            end
//        end
//    end
//    assign dbg_data = 16'hBEEF;
    logic real_data_valid;
    assign real_data_valid = ac_mode ? buf_uart_valid : dc_buf_uart_valid;
    /* UART comms */

    // Transmit controller
    uart_send_16 UART_CTRL (
        .clk(clk),
        .rst(reset),
        .data_in(uart_data_mux),
        .data_valid(real_data_valid),
        .uart_en(synch_uart_en),
        .tx_data(tx_data),
        .tx_start(tx_start),
        .tx_word_busy(tx_word_busy),
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

    // UART RX
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
        .d0(dc_buf_uart_data),   // DC path - now from DC RAM buffer
        .d1(buf_uart_data),      // AC path
        .y(uart_data_mux)
    );
    
    /* ======== DC PATH ======= */
    logic nsynchpwm_comp;
    corrector CORRECTOR(
        .in(synchpwm_comp),
        .out(nsynchpwm_comp)
    );
    sar #(.WIDTH(8)) DC_ADC(
        .clk(clk),
        .reset(reset),
        .comparator(nsynchpwm_comp),
        .adc_out(adc_out),
        .R2R_out(duty_cycle_test),
        .valid(valid_sar)
    );
    pwm #(.WIDTH(8)) SAR_PWM (
        .clk(clk),
        .reset(reset),
        .enable(1'b1),
        .duty_cycle(duty_cycle_test),
        .pwm_out(dc_pwm_out)
    );
    recorder SAR_RECORDER (
        .clk(clk),
        .reset(reset),
        .ready(valid_sar),
        .duty_cycle(adc_out),
        .duty_cycle_out(raw_adc),
        .ready_r_out(ready_r_out)
    );

    xadc_processing #(.SCALING_FACTOR(7_500), .SHIFT_FACTOR(14)) DC_PROC (
        .clk(clk),
        .reset(reset),
        .ready(ready_r_out),                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            
        .data({raw_adc, 8'b0}),
        .averaged_data(averaged_data),
        .scaled_adc_data(scaled_data)
    );

    /* ======== DC RAM BUFFER ======= */
    logic [15:0] dc_buf_uart_data;
    logic        dc_buf_uart_valid;
    logic        dc_buffer_full;
    logic        dc_buffer_done;

    /* DC re-arm / force-trigger: periodically re-triggers when in DC mode */
    logic        dc_force_trigger;
    logic [19:0] dc_rearm_cnt;
    always_ff @(posedge clk) begin
        if (reset || ac_mode) begin
            dc_rearm_cnt     <= '0;
            dc_force_trigger <= 1'b0;
        end else begin
            dc_force_trigger <= 1'b0;
            dc_rearm_cnt     <= dc_rearm_cnt + 1;
            if (dc_rearm_cnt == '1) begin
                dc_force_trigger <= 1'b1;
            end
        end
    end

    ram_buffer #(
        .WIDTH(16),
        .DEPTH(480)
    ) DC_RAM_BUFFER (
        .clk(clk),
        .reset(reset),
        .timescale_in(4'd0),
        .trigger(dc_force_trigger),
        .sample_in(scaled_data),
        .sample_valid(ready_r_out),
        .uart_ready(synch_uart_en & ~tx_word_busy),
        .uart_data(dc_buf_uart_data),
        .uart_valid(dc_buf_uart_valid),
        .buffer_full(dc_buffer_full),
        .buffer_done(dc_buffer_done),
        .vmax(16'h0),
        .vmin(16'h0),
        .vpp(16'h0),
        .period_count(9'h0)
    );
    
    /* ======== ASYNC (EXTERNAL) ADC PATH ======= */
    logic [15:0] async_scaled_data, async_averaged_data;
    logic        async_ready_pulse;
    
    xadc_processing #(
        .SCALING_FACTOR(2500),
        .SHIFT_FACTOR(14)
    ) ASYNC_ADC_PROC (
        .clk(clk),
        .reset(reset),
        .ready(~fifo_empty),
        .data({ext_adc_data, 6'b0}),
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
    
    /* ======== AC TRIGGER + BUFFER PATH ======= */
    logic [15:0] buf_uart_data;
    logic        buf_uart_valid;
    logic        ac_buffer_full;
    logic        ac_buffer_done;
    logic trigger_level, trigger_edge;

    trigger #(.WIDTH(16)) TRIG (
        .clk(clk),
        .reset(reset),
        .sample_in(decimated_data),
        .threshold(16'h0672),
        .sample_valid(decim_valid),
        .trigger_level(trigger_level),
        .trigger_edge(trigger_edge)
    );

    // Bypass trigger: capture immediately on AC mode entry
    logic force_trigger;
    logic [19:0] rearm_cnt;
    always_ff @(posedge clk) begin
        if (reset || !ac_mode) begin
            rearm_cnt     <= '0;
            force_trigger <= 0;
        end else begin
            force_trigger <= 0;
            rearm_cnt <= rearm_cnt + 1;
            if (rearm_cnt == '1) begin
                force_trigger <= 1;
            end
        end
    end
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
        .threshold(16'h0672),
        .vmax(calc_vmax),
        .vmin(calc_vmin),
        .vpp(calc_vpp),
        .period_count(calc_period),
        .high_count(),
        .meas_valid(calc_valid)
    );
    
    /* Gate uart_ready with synch_uart_en so the buffer only
       drains when the host has UART enabled.                  */
    ram_buffer #(
        .WIDTH(16),
        .DEPTH(480)
    ) RAM_BUFFER (
        .clk(clk),
        .reset(reset),
        .timescale_in(timescale_set),
        .trigger(trigger_edge | force_trigger),
        .sample_in(decimated_data),
        .sample_valid(decim_valid),
        .uart_ready(synch_uart_en & ~tx_word_busy),
        .uart_data(buf_uart_data),
        .uart_valid(buf_uart_valid),
        .buffer_full(ac_buffer_full),
        .buffer_done(ac_buffer_done),
        .vmax(calc_vmax),
        .vmin(calc_vmin),
        .vpp(calc_vpp),
        .period_count(calc_period)
    );

    /* ======== mpreg handshake ========
     *  SET   when the active buffer finishes capturing (buffer_full pulse)
     *  CLEAR when the buffer finishes draining (buffer_done pulse)
     *  mpreg stays HIGH the entire readout so the host can see it.        */
    logic active_buffer_full;
    logic active_buffer_done;
    assign active_buffer_full = ac_mode ? ac_buffer_full : dc_buffer_full;
    assign active_buffer_done = ac_mode ? ac_buffer_done : dc_buffer_done;

    always_ff @(posedge clk) begin
        if (reset)
            mpreg <= 1'b0;
        else if (active_buffer_full)
            mpreg <= 1'b1;          // buffer just filled → tell host
        else if (active_buffer_done)
            mpreg <= 1'b0;          // drain complete → ready for next capture
    end

    /* ======== DC DISPLAY PATH ======= */
    mux21 #(.WIDTH(16)) SIGNAL_SEL (
        .select(1'b0),
        .d0(scaled_data),
        .d1(averaged_data),
        .y(signal_select_out)
    );
    
    bin_to_bcd BIN2BCD (
        .clk(clk),
        .reset(reset),
        .bin_in(signal_select_out),
        .bcd_out(bcd_out)
    );
    logic [15:0] binbcd_sel_out;
    mux21 #(.WIDTH(16)) BINBCD_SEL (
        .select(1'b1),
        .d0(signal_select_out),
        .d1(bcd_out),
        .y(binbcd_sel_out)
    );
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

    /* ======== LED debug ======= */
    assign led[0]    = 0;
    assign led[1]    = synch_uart_en;     // uart_en recognised
    assign led[2]    = ac_mode;           // AC mode active
    assign led[3]    = real_data_valid;   // real data path is firing
    assign led[4]    = tx_word_busy;      // UART transmitting a word
    assign led[5]    = mpreg;             // buffer full indicator
    assign led[15:6] = '0;

endmodule