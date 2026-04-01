`timescale 1ns / 1ps
 
module calcs #(
    parameter int unsigned WIDTH = 16,
    parameter int unsigned DEPTH = 480,
    localparam int unsigned DEPTH_ADDR = $clog2(DEPTH)
)(
    input  logic                  clk,
    input  logic                  reset,
    input  logic                  start,          // pulse: begin new measurement window
    input  logic [WIDTH-1:0]      sample_in,
    input  logic                  sample_valid,
    input  logic [WIDTH-1:0]      threshold,      // midpoint for crossing detection
 
    /* global measurements (full capture) */
    output logic [WIDTH-1:0]      vmax,
    output logic [WIDTH-1:0]      vmin,
    output logic [WIDTH-1:0]      vpp,
 
    /* per-period measurements */
    output logic [DEPTH_ADDR-1:0]  period_count,   // period in # of samples
    output logic [DEPTH_ADDR-1:0]  high_count,     // # samples above threshold in one period
    output logic                  meas_valid       // pulses high for one cycle when a period measurement is ready
);
 
    /*  ── How to derive freq / duty on the host side ──────────────
     *
     *  frequency_hz = sample_rate_hz / period_count
     *  duty_cycle   = high_count     / period_count   (0.0 – 1.0)
     *
     *  Division is intentionally left to software to keep
     *  the fabric small.  period_count and high_count are
     *  latched and stable while meas_valid is high.
     *  ───────────────────────────────────────────────────────────── */
 
    /* ── internal signals ──────────────────────────────────────── */
    logic                  above;
    logic                  prev_above;
    logic                  rising_cross;
    logic                  first_cross_seen;  // need two rising crossings for one full period
    logic                  active;
 
    /* per-period accumulators */
    logic [DEPTH_ADDR-1:0]  per_cnt;           // sample counter within current period
    logic [DEPTH_ADDR-1:0]  per_high;          // above-threshold counter within current period
 
    /* global running extremes */
    logic [WIDTH-1:0]      run_max;
    logic [WIDTH-1:0]      run_min;
 
    /* ── crossing detection (combinational) ────────────────────── */
    assign above        = (sample_in >= threshold);
    assign rising_cross = above & ~prev_above;
 
    /* ── main sequential block ─────────────────────────────────── */
    always_ff @(posedge clk) begin
        if (reset) begin
            run_max          <= '0;
            run_min          <= {WIDTH{1'b1}};
            vmax             <= '0;
            vmin             <= '0;
            vpp              <= '0;
            period_count     <= '0;
            high_count       <= '0;
            per_cnt          <= '0;
            per_high         <= '0;
            prev_above       <= 1'b0;
            first_cross_seen <= 1'b0;
            meas_valid       <= 1'b0;
            active           <= 1'b0;
 
        end else begin
            meas_valid <= 1'b0;                // default: single-cycle pulse
 
            /* ── start pulse resets everything ─────────────────── */
            if (start && !active) begin
                run_max          <= '0;
                run_min          <= {WIDTH{1'b1}};
                per_cnt          <= '0;
                per_high         <= '0;
                prev_above       <= 1'b0;
                first_cross_seen <= 1'b0;
                active           <= 1'b1;
 
            /* ── process each valid sample ─────────────────────── */
            end else if (active && sample_valid) begin
                prev_above <= above;
 
                /* global min / max (updated every sample) */
                if (sample_in > run_max) run_max <= sample_in;
                if (sample_in < run_min) run_min <= sample_in;
 
                /* always publish latest global vmax / vmin / vpp */
                vmax <= (sample_in > run_max) ? sample_in : run_max;
                vmin <= (sample_in < run_min) ? sample_in : run_min;
                vpp  <= ((sample_in > run_max) ? sample_in : run_max)
                      - ((sample_in < run_min) ? sample_in : run_min);
 
                /* ── rising-edge crossing detected ─────────────── */
                if (rising_cross) begin
                    if (!first_cross_seen) begin
                        /* first crossing: start counting from here */
                        first_cross_seen <= 1'b1;
                        per_cnt          <= 1;
                        per_high         <= {{(DEPTH_ADDR-1){1'b0}}, above};
                    end else begin
                        /* second+ crossing: one full period complete */
                        period_count <= per_cnt;
                        high_count   <= per_high;
                        meas_valid   <= 1'b1;
 
                        /* reset accumulators for next period */
                        per_cnt  <= 1;
                        per_high <= {{(DEPTH_ADDR-1){1'b0}}, above};
                    end
                end else if (first_cross_seen) begin
                    /* mid-period: keep counting */
                    per_cnt  <= per_cnt + 1;
                    if (above)
                        per_high <= per_high + 1;
                end
            end
        end
    end
 
endmodule