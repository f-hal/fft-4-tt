module edge_detector(
	input clk,
	input rst,
  
	input in,
	output out);
 
	reg [1:0] s_reg;
	
	always @(posedge clk) begin
		if (rst)
			s_reg <= 2'b0;
		else begin
			s_reg[1] <= s_reg[0];
			s_reg[0] <= in;
		end
	end
  
	assign out = ~s_reg[1] && s_reg[0];

endmodule