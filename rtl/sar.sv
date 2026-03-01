`timescale 1ns / 1ps
/* successive approximation algorithm implementation in an FSM
 * Parameter: WIDTH
 * Input: clk, reset, comparaator
 * Output: adc_out, R2R_out, valid
*/

module sar #(parameter int WIDTH = 8)
(
    input logic clk, 
    input logic reset, 
    input logic comparator,
    output logic [WIDTH - 1 : 0] adc_out,
    output logic [WIDTH - 1 : 0] R2R_out, /* this is the duty cycle out */
    output logic valid
);

    logic [16:0] counter;
    logic [WIDTH - 1 : 0] trial;
    logic [WIDTH - 1 : 0] result;
    typedef enum logic [2:0] { START, WAIT_TIME, PROCESS, INDEX, FINISH } state_t;
    state_t state;
    /* state 1: START:      set MSB of compare to 1, zero out the rest */
    /* state 2: WAIT_TIME:       count to 2^17 */
    /* state 3: PROCESS:    ADC processing: check of compare against value */
    /* state 4: INDEX       finish index, change index appropriately */
    /* state 5: FINISH:     Return output ADC_Value */

    logic [$clog2(WIDTH) : 0] index;

    assign R2R_out = trial;
    
    always_ff @(posedge clk) begin
        if(reset) begin     
            state <= START;
            counter <= '0;
            result <= '0;
            trial <= '0;
            index <= '0;
            adc_out <= '0;
            valid <= '0;
        end 
        else begin
            case(state)
                START: begin
                    /* do some setup here */
                    trial <= 1'b1 << (WIDTH - 1);
                    result <= '0;
                    index <= WIDTH - 1;
                    counter <= '0;
                    valid <= 1'b0;
                    /* set the next state*/
                    state <= WAIT_TIME;
                end
                WAIT_TIME: begin 
                    /* do the counting here */
                    counter <= counter + 1;

                    if(counter == 17'h1FFFF) begin 
                        counter <= '0;
                        /* set the next state */
                        state <= PROCESS;
                    end
                end
                PROCESS: begin 
                    /* check comp output */
                    if(~comparator) begin 
                        result <= trial;
                    end
                    else begin
                        trial <= trial & (8'hFF - (1'b1 << index));
                    end
                    
                    state <= INDEX;
                end

                INDEX: begin 
                    /* decrement the index and go back to process*/
                    if(index == 0) begin 
                        state <= FINISH;
                    end
                    else begin 
                        index <= index - 1;
                        trial <= result | (1'b1 << index - 1);
                        
                        state <= WAIT_TIME;
                    end
                end

                FINISH: begin 
                    /*clean up all variables and start over*/
                    adc_out <= result;
                    valid <= 1'b1;

                    state <= START;
                end
                default: state <= START;
            endcase
        end
    end
endmodule
