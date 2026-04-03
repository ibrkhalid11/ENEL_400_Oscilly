module uart_rx #(
    parameter int BAUD_DIV = 868
)(
    input  logic clk,
    input  logic rst,
    input  logic rx,
    output logic [7:0] rx_data,
    output logic rx_valid
);
 
    logic [15:0] baud_cnt;
    logic [3:0]  bit_index;
    logic [9:0]  shift_reg;
    logic        busy;
    logic        waiting_half;
 
    always_ff @(posedge clk) begin
        if (rst) begin
            baud_cnt     <= 0;
            bit_index    <= 0;
            busy         <= 0;
            waiting_half <= 0;
            rx_valid     <= 0;
            rx_data      <= 0;
            shift_reg    <= 0;
        end else begin
            rx_valid <= 0;          // default: single-cycle pulse
 
            if (!busy) begin
                /* ---- IDLE: watch for start bit ---- */
                baud_cnt <= 0;
                if (!rx) begin
                    busy         <= 1;
                    waiting_half <= 1;
                    bit_index    <= 0;
                end
 
            end else if (waiting_half) begin
                /* ---- count to BAUD_DIV/2 to reach mid-start-bit ---- */
                if (baud_cnt == (BAUD_DIV/2) - 1) begin
                    baud_cnt     <= 0;
                    waiting_half <= 0;
                    /* false-start check: if rx is high, abort */
                    if (rx) begin
                        busy <= 0;
                    end
                end else begin
                    baud_cnt <= baud_cnt + 1;
                end
 
            end else begin
                /* ---- count full BAUD_DIV periods, sample at each tick ---- */
                if (baud_cnt == BAUD_DIV - 1) begin
                    baud_cnt  <= 0;
                    shift_reg <= {rx, shift_reg[9:1]};
                    bit_index <= bit_index + 1;
 
                    if (bit_index == 9) begin
                        busy     <= 0;
                        rx_data  <= shift_reg[8:1];
                        rx_valid <= 1;
                    end
                end else begin
                    baud_cnt <= baud_cnt + 1;
                end
            end
        end
    end
 
endmodule