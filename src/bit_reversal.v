module bit_reverse #(parameter BIT_WIDTH = 8)
					  (input [BIT_WIDTH-1:0] orig,   
                       output reg [BIT_WIDTH-1:0] rev
                      );
                      
    always @(orig) begin : reversing_block // Adjusted for Verilog compatability
        integer n;
        for (n=0; n < BIT_WIDTH; n=n+1) begin
            rev[n] <= orig[BIT_WIDTH-n-1];
        end
    end                  

endmodule 
