module mux21
    #(
        parameter WIDTH = 1
    )
    (
        input logic select,
        input logic [WIDTH - 1 : 0] d0,
        input logic [WIDTH - 1 : 0] d1,
        output logic [WIDTH - 1 : 0] y
    );
    always_comb begin
        case (select) 
        1'b0 : y = d0;
        1'b1 : y = d1;
        default : y = d0;
        endcase         
    end

endmodule