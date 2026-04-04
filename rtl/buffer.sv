`timescale 1ns / 1ps
module ram_buffer #(
    parameter int WIDTH = 16,
    parameter int DEPTH = 480,
    parameter int DEPTH_ADDR = $clog2(DEPTH)
)(
    input logic clk,
    input logic reset,
    input logic [3:0] timescale_in,
    input logic trigger,
    input logic [WIDTH - 1 : 0] sample_in,
    input logic sample_valid,
    input logic uart_ready,
    output logic [WIDTH - 1 : 0] uart_data,
    output logic uart_valid,
    output logic buffer_full,
    output logic buffer_done,
    // calc inputs
    input logic [WIDTH-1:0]       vmax,
    input logic [WIDTH-1:0]       vmin,
    input logic [WIDTH-1:0]       vpp,
    input logic [DEPTH_ADDR-1:0]  period_count
);
    typedef int unsigned depth_sel_t [15];
    localparam depth_sel_t DEPTH_LUT = '{
        480,  //  0: 500    ms/div
        480,  //  1: 100    ms/div
        480,  //  2:  50    ms/div
        480,  //  3:  10    ms/div
        480,  //  4:   5    ms/div
        480,  //  5:   1    ms/div
        480,  //  6:   0.5  ms/div
        480,  //  7:   0.1  ms/div
        480,  //  8:   0.05 ms/div
        480,  //  9:   0.01 ms/div
        480,  // 10:   0.005 ms/div
        480,  // 11:   0.001 ms/div
        240,  // 12:   2x zoom
        120,  // 13:   4x zoom
         60   // 14:   8x zoom
    };

    typedef int unsigned repeat_sel_t [15];
    localparam repeat_sel_t REPEAT_LUT = '{
        1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
        2,    // 12: 240 samples × 2 = 480
        4,    // 13: 120 samples × 4 = 480
        8     // 14:  60 samples × 8 = 480
    };
    logic [23:0] wait_counter;
    logic [WIDTH - 1 : 0] ram [0 : DEPTH - 1];
    logic [DEPTH_ADDR - 1 : 0] waddr;
    logic [DEPTH_ADDR - 1 : 0] raddr;
    int unsigned capture_depth;
    int unsigned repeat_factor;
    logic [3:0]  repeat_cnt;

    // latched calc values
    logic [WIDTH-1:0] lat_vmax, lat_vmin, lat_vpp;
    logic [WIDTH-1:0] lat_period;
    logic [1:0] append_idx;

    typedef enum logic [2:0] {
        IDLE,
        CAPTURE,
        READOUT,
        APPEND,
        WAIT_ACK
    } state_t;
    state_t state;

    /* buffer_full: one-cycle pulse when capture completes */
    assign buffer_full = (state == CAPTURE) && sample_valid
                         && (waddr == capture_depth - 1);

    /* buffer_done: one-cycle pulse when drain (APPEND) finishes */
    assign buffer_done = (state == APPEND) && uart_ready
                         && (append_idx == 2'd3);

    /* write port */
    always_ff @(posedge clk) begin
        if (sample_valid && state == CAPTURE) begin
             ram[waddr] <= sample_in;
        end
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            state         <= IDLE;
            waddr         <= '0;
            raddr         <= '0;
            uart_data     <= '0;
            uart_valid    <= '0;
            wait_counter  <= '0;
            capture_depth <= DEPTH;
            repeat_factor <= 1;
            repeat_cnt    <= '0;
            lat_vmax      <= '0;
            lat_vmin      <= '0;
            lat_vpp       <= '0;
            lat_period    <= '0;
            append_idx    <= '0;
        end else begin
            uart_valid <= 1'b0;
            case (state)
                IDLE: begin
                    waddr      <= '0;
                    raddr      <= '0;
                    repeat_cnt <= '0;
                    if (trigger) begin
                        capture_depth <= DEPTH_LUT[timescale_in];
                        repeat_factor <= REPEAT_LUT[timescale_in];
                        state <= CAPTURE;
                    end
                end
                CAPTURE: begin
                    if (sample_valid) begin
                        if (waddr == capture_depth - 1) begin
                            waddr      <= '0;
                            lat_vmax   <= vmax;
                            lat_vmin   <= vmin;
                            lat_vpp    <= vpp;
                            lat_period <= {{(WIDTH - DEPTH_ADDR){1'b0}}, period_count};
                            append_idx <= '0;
                            repeat_cnt <= '0;
                            state      <= READOUT;
                        end else begin
                            waddr <= waddr + 1;
                        end
                    end
                end
                READOUT: begin
                    if (uart_ready) begin
                        uart_data  <= ram[raddr];
                        uart_valid <= 1'b1;

                        if (repeat_cnt == repeat_factor - 1) begin
                            /* Last repeat of this sample - advance to next */
                            repeat_cnt <= '0;
                            if (raddr == capture_depth - 1) begin
                                raddr      <= '0;
                                append_idx <= '0;
                                state      <= APPEND;
                            end else begin
                                raddr <= raddr + 1;
                            end
                        end else begin
                            /* Same sample again */
                            repeat_cnt <= repeat_cnt + 1;
                        end
                    end
                end
                APPEND: begin
                    if (uart_ready) begin
                        uart_valid <= 1'b1;
                        case (append_idx)
                            2'd0: uart_data <= lat_period;
                            2'd1: uart_data <= lat_vmax;
                            2'd2: uart_data <= lat_vmin;
                            2'd3: uart_data <= lat_vpp;
                        endcase
                        if (append_idx == 2'd3)
                            state <= WAIT_ACK;
                        else
                            append_idx <= append_idx + 1;
                    end
                end
                WAIT_ACK: begin
                    wait_counter <= wait_counter + 1;
                    if (wait_counter >= 24'd10_000_000) begin
                        wait_counter <= 0;
                        state <= IDLE;
                    end
                end
            endcase
        end
    end
endmodule