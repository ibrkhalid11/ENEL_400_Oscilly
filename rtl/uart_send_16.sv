module uart_send_16 (
    input  logic        clk,
    input  logic        rst,
    input  logic        uart_en,
    input  logic [15:0] data_in,
    input  logic        data_valid,   // pulse when new data ready
    output logic [7:0]  tx_data,
    output logic        tx_start,
    output logic        tx_word_busy,  // high while sending either byte
    input  logic        tx_busy
);

    typedef enum logic [2:0] {
        IDLE,
        SEND_HIGH,
        SEND_LOW,
        WAIT_DONE,
        WAIT
    } state_t;

    state_t state;
    logic [15:0] data_latch;

    always_ff @(posedge clk) begin
        if (rst) begin
            state    <= IDLE;
            tx_start <= 0;
            tx_data  <= 0;
            data_latch <= 0;
        end else begin
            tx_start <= 0; // default pulse low

            case (state)
                IDLE: begin
                    if (data_valid && !tx_busy && uart_en) begin
                        data_latch <= data_in;
                        tx_data    <= data_in[7:0];  // low byte first: youssef edition
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
                        tx_data  <= data_latch[15:8];  // high byte second: youssef edition
                        tx_start <= 1;
                        state    <= SEND_LOW;
                    end
                end

                SEND_LOW: begin
                    if (tx_busy) state <= WAIT_DONE;
                end

                WAIT_DONE: begin
                    if (!tx_busy) state <= IDLE;  // byte 2 fully transmitted
                end
            endcase
        end
    end

    assign tx_word_busy = (state != IDLE);

endmodule