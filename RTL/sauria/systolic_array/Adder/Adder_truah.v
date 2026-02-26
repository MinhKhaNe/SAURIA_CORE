//Return max value between a and b
`define max(a,b) ((a) > (b) ? (a) : (b))

module Adder_truah #(
	parameter 	IGNORE_BIT 	= 0,				//LSB BITS
	parameter 	WIDTH_A 	= 16,
	parameter 	WIDTH_B 	= 16
)(
	input	wire	[WIDTH_A-1:0]					A,
	input	wire	[WIDTH_B-1:0]					B,
	input	wire									Carry,	//do not use Carry

	output	wire	[`max(WIDTH_A, WIDTH_B)-1:0]	OUT
);

	//Derived Parameter
	parameter BITS 		= `max(WIDTH_A, WIDTH_B);

	//Internal Signals	parameter BITS 		= `max(WIDTH_A, WIDTH_B);
	wire	signed	[BITS-1:0]			a, b;
	wire	signed	[BITS-1:0]			A_sign, B_sign;
	wire	signed	[BITS-1:0]			sum;

	//Sign Extend
	assign	a = {{{BITS-WIDTH_A}{A[WIDTH_A-1]}}, A};	
	assign	b = {{{BITS-WIDTH_B}{B[WIDTH_B-1]}}, B};	

	generate
		//If having LSB bits 
		if(IGNORE_BIT > 0) begin
			//Keep MSB bits and force LSB bits to 1
			assign A_sign	=	{{a[BITS-1:IGNORE_BIT]}, {IGNORE_BIT{1'b1}}};
			//Keep MSB bits and force LSB bits to 0
			assign B_sign	=	{{b[BITS-1:IGNORE_BIT]}, {IGNORE_BIT{1'b0}}};
		end
		else begin
			//No truncation
			assign A_sign	=	a;
			assign B_sign	=	b;
		end
	endgenerate
	
	//Signed Addition
	assign	sum = A_sign + B_sign;
	assign 	OUT = sum;

endmodule
