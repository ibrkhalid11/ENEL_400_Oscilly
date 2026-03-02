module uart_send_16 (
    input  logic        clk,
    input  logic        rst,
    input  logic [15:0] data_in,
    input  logic        data_valid,   // pulse when new data ready
    output logic [7:0]  tx_data,
    output logic        tx_start,
    input  logic        tx_busy
);

    typedef enum logic [1:0] {
        IDLE,
        SEND_HIGH,
        SEND_LOW,
        WAIT
    } state_t;

    state_t state;
    logic [15:0] data_latch;

    always_ff @(posedge clk) begin
        if (rst) begin
            state    <= IDLE;
            tx_start <= 0;
            tx_data  <= 0;
        end else begin
            tx_start <= 0; // default pulse low

            case (state)
                IDLE: begin
                    if (data_valid && !tx_busy) begin
                        data_latch <= data_in;
                        tx_data    <= data_in[15:8];  // high byte first
                        tx_start   <= 1;
                        state      <= SEND_HIGH;
                    end
                end

                SEND_HIGH: begin
                    // wait for TX to go busy, then wait for it to finish
                    if (tx_busy) state <= WAIT;
                end

                WAIT: begin
                    if (!tx_busy) begin
                        tx_data  <= data_latch[7:0];  // low byte
                        tx_start <= 1;
                        state    <= SEND_LOW;
                    end
                end

                SEND_LOW: begin
                    if (tx_busy) state <= IDLE;
                end
            endcase
        end
    end

endmodule