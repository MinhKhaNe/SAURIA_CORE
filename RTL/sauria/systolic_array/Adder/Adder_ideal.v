`define max(a,b) ((a) > (b) ? (a) : (b))

module Adder_ideal #(
	parameter 	WIDTH_A = 16,
	parameter 	WIDTH_B = 16
)(
	input	wire	[WIDTH_A-1:0]					A,
	input	wire	[WIDTH_B-1:0]					B,
	input	wire									Carry,

	output	wire	[`max(WIDTH_A, WIDTH_B)-1:0]	OUT
);
	parameter BITS = `max(WIDTH_A, WIDTH_B);

	wire	signed	[BITS-1:0]			a;
	wire	signed	[BITS-1:0]			b;
	wire	signed						carry;
	wire	signed	[BITS-1:0]			sum;

	//Sign Extend
	assign	a = {{{BITS-WIDTH_A}{A[WIDTH_A-1]}}, A};	
	assign	b = {{{BITS-WIDTH_B}{B[WIDTH_B-1]}}, B};	

	//Carry in
	assign	carry = Carry;

	//Sum = A + B + Carry_in
	assign 	sum = a + b + carry;

	//Truncate internal result to output
	assign	OUT = sum;
endmodule
