/* TODO: INC FILE
 * REFACTOR OUTPUTS INTO A BUS
*/


`timescale 1ns / 1ps

module rx_handler(
    input logic clk,
    input logic reset,

    input logic [7:0] uart_rx,
    input logic rx_valid,
    /* make this a bus cmd instead */
    output logic A,
    output logic B,
    output logic C,
    output logic D,
    output logic E
);



    always_ff@(posedge clk) begin
        if(reset) begin
            A <= '0;
            B <= '0;
            C <= '0;
            D <= '0;
        end else begin
            A <= '0;
            B <= '0;
            C <= '0;
            D <= '0;
            E <= '0;
            if(rx_valid) begin
                case(uart_rx) 
                    8'hAA: begin
                        A <= '1;
                    end
                    8'hBB: begin
                        B <= '1;
                    end
                    8'hCC: begin
                        C <= '1;
                    end
                    8'hDD: begin
                        D <= '1;
                    end
                    8'hEE: begin
                        E <= '1;
                    end         
                    default: begin
                        A <= '0;
                        B <= '0;
                        C <= '0;
                        D <= '0;
                        E <= '0;                        
                    end                               
                endcase
            end
        end

    end

endmodule