module Multiplier_2x2 #(
	parameter	APPROX = 0
)(
	input	wire	[1:0]	A,
	input	wire	[1:0]	B,

	output	reg	[3:0]	OUT
);

	wire	AND_10, AND_01, AND_11, AND_10_01;
	
	assign	AND_10		= A[1] & B[0];	
	assign	AND_01		= A[0] & B[1];	
	assign	AND_11		= A[1] & B[1];
	assign	AND_10_01	= AND_10 & AND_01;	
	
	always @(*) begin
		if(APPROX) begin
			OUT[0]	= A[0] & B[0];
	 		OUT[1]	= AND_10 | AND_01;
	 		OUT[2]	= AND_11;
			OUT[3]	= 1'b0;
		end 
		else begin
			OUT[0]	= A[0] & B[0];
	 		OUT[1]	= AND_10 ^ AND_01;
	 		OUT[2]	= AND_10_01 ^ AND_11;
			OUT[3]	= AND_10_01 & AND_11;
		end
	end

endmodule