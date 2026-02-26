module Multiplier_2x2 #(
	parameter	APPROX = 0			//Number of approximate bit
)(
	input	wire	[1:0]	A,
	input	wire	[1:0]	B,

	output	reg	[3:0]	OUT
);

	//Partial products
	wire	AND_10, AND_01, AND_11, AND_10_01;

	//Cross partial products
	assign	AND_10		= A[1] & B[0];	
	assign	AND_01		= A[0] & B[1];	
	//MSB partial product
	assign	AND_11		= A[1] & B[1];
	//Carry generated
	assign	AND_10_01	= AND_10 & AND_01;	
	
	always @(*) begin
		//Approximate multiplier
		if(APPROX) begin
			//LSB product
			OUT[0]	= A[0] & B[0];
			//Replace adder with OR gate
	 		OUT[1]	= AND_10 | AND_01;
			//Ignore carry
	 		OUT[2]	= AND_11;
			//Remove highest bit
			OUT[3]	= 1'b0;
		end 
		else begin
			//Bit 0
			OUT[0]	= A[0] & B[0];
			//Half adder sum
	 		OUT[1]	= AND_10 ^ AND_01;
			//Adding carry from previous stage
	 		OUT[2]	= AND_10_01 ^ AND_11;
			//Final carry
			OUT[3]	= AND_10_01 & AND_11;
		end
	end

endmodule

