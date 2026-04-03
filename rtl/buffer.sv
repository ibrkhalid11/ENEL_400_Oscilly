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
    typedef int unsigned depth_sel_t [7];
    localparam depth_sel_t DEPTH_LUT = '{
        DEPTH, 
        DEPTH,
        DEPTH,
        DEPTH,
        DEPTH,
        DEPTH,
        DEPTH
    }; 
    logic [WIDTH - 1 : 0] ram [0 : DEPTH - 1];
    logic [DEPTH_ADDR - 1 : 0] waddr;
    logic [DEPTH_ADDR - 1 : 0] raddr;
    int unsigned capture_depth;

    // latched calc values
    logic [WIDTH-1:0] lat_vmax, lat_vmin, lat_vpp;
    logic [WIDTH-1:0] lat_period;
    logic [1:0] append_idx;

    typedef enum logic [2:0] {
        IDLE,
        CAPTURE,
        READOUT,
        APPEND
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
            state        <= IDLE;
            waddr        <= '0;
            raddr        <= '0;
            uart_data    <= '0;
            uart_valid   <= '0;
            capture_depth <= DEPTH;
            lat_vmax     <= '0;
            lat_vmin     <= '0;
            lat_vpp      <= '0;
            lat_period   <= '0;
            append_idx   <= '0;
        end else begin
            uart_valid <= 1'b0;
            case (state)
                IDLE: begin
                    waddr <= '0;
                    raddr <= '0;
                    if (trigger) begin
                        capture_depth <= DEPTH_LUT[timescale_in];
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
                        if (raddr == capture_depth - 1) begin
                            raddr      <= '0;
                            append_idx <= '0;
                            state      <= APPEND;
                        end else begin
                            raddr <= raddr + 1;
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
                            state <= IDLE;
                        else
                            append_idx <= append_idx + 1;
                    end
                end
            endcase
        end
    end
endmodule