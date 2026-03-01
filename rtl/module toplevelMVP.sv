`timescale 1ns / 1ps
module toplevelMVP(
    input logic clk,
    input logic reset,

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
    /*bring in all xadc signals needed */



    /* synchronize all pin inputs */
    logic synchpwm_comp;
    synchro synchpwmcomp(
        .clk(clk),
        .reset(reset),
        .in(pwm_comp),
        .out(synchpwm_comp)
    );

    /* synch all buttons */
    /* synch all switches */

    /* correct all inputs if needed */

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