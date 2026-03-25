`timescale 1ns / 1ps
/* timescale to scale --> based off 1_000_000 SPS
 * 0: 1MHz --> 200
 * 1: 500KHz --> 200
 * 2: 100KHz --> 200
 * 3: 50KHz --> 200
 * 4: 10KHz --> 200
 * 5: 1KHz --> 200
 * 6: 100Hz --> 200
 * 
*/
module ram_buffer #(
    parameter int WIDTH = 16,
    parameter int DEPTH = 480,
    parameter int DEPTH_ADDR = $clog2(DEPTH)
)(
    input logic clk,
    input logic reset,
    input logic [2:0] timescale_in,
    input logic trigger,
    input logic [WIDTH - 1 : 0] sample_in,
    input logic sample_valid,

    input logic uart_ready,
    output logic [WIDTH - 1 : 0] uart_data,
    output logic uart_valid
);

    typedef int unsigned depth_sel_t [7];

    localparam depth_sel_t DEPTH_LUT = '{
        DEPTH, 
        DEPTH,
        DEPTH,
        DEPTH,
        DEPTH,
        DEPTH,
        DEPTH,
    }; 
    logic [WIDTH - 1 : 0] ram [0 : DEPTH - 1];
    logic [DEPTH_ADDR - 1 : 0] waddr;
    logic [DEPTH_ADDR - 1 : 0] raddr;
    int unsigned capture_depth;


    typedef enum logic [1:0] {
        IDLE,
        CAPTURE,
        READOUT
    } state_t;

    state_t state;

    /* write port */

    always_ff@(posedge clk) begin
        if(sample_valid && state == CAPTURE) begin
             ram[waddr] <= sample_in;
        end
    end

    always_ff@(posedge clk) begin
        if(reset) begin
            state <= IDLE;
            waddr <= '0;
            raddr <= '0;
            uart_data <= '0;
            uart_valid <= '0;
            capture_depth <= DEPTH;
        end else begin
            uart_valid <= 1'b0;

            case(state)
                IDLE: begin
                    waddr <= '0;
                    raddr <= '0;
                    if(trigger) begin
                        capture_depth <= DEPTH_LUT[timescale_in];
                        state <= CAPTURE;
                    end
                end
                CAPTURE: begin
                    if(sample_valid) begin
                        if(waddr == capture_depth - 1) begin
                            waddr <= '0;
                            state <= READOUT;
                        end else begin
                            waddr <= waddr + 1;
                        end
                    end
                end

                READOUT: begin
                    if(uart_ready) begin
                        uart_data <= ram[raddr];
                        uart_valid <= 1'b1;
                        if(raddr == capture_depth - 1) begin
                            raddr <= '0;
                            state <= IDLE;
                        end else begin
                            raddr <= raddr + 1;
                        end
                    end
                end
            endcase
        end
    end

endmodule
