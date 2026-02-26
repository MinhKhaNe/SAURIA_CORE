`define max(a,b) ((a) > (b) ? (a) : (b))

module Adder_loa #(
	parameter 	IGNORE_BIT = 0,				//LSB BITS
	parameter 	WIDTH_A = 16,
	parameter 	WIDTH_B = 16
)(
	input	wire	[WIDTH_A-1:0]					A,
	input	wire	[WIDTH_B-1:0]					B,
	input	wire									Carry,	//do not use Carry

	output	wire	[`max(WIDTH_A, WIDTH_B)-1:0]	OUT
);

	//Derived Parameters
	parameter BITS 		= `max(WIDTH_A, WIDTH_B);
	parameter HIGH_BITS = `max(WIDTH_A, WIDTH_B) - IGNORE_BIT;

	//Internal Signals
	wire	signed	[HIGH_BITS-1:0]		high_Sum;
	wire	signed	[HIGH_BITS-1:0]		high_a, high_b;
	wire			[IGNORE_BIT - 1:0]	low_Sum;
	wire			[IGNORE_BIT - 1:0] 	low_a, low_b;
	wire								carry_low;
	wire	signed	[BITS - 1:0] 		a;
	wire	signed	[BITS - 1:0] 		b;
	
	//Sign Extend
	assign	a = {{{BITS-WIDTH_A}{A[WIDTH_A-1]}}, A};	
	assign	b = {{{BITS-WIDTH_B}{B[WIDTH_B-1]}}, B};

	generate
		//If having LSB value
		if(IGNORE_BIT > 0) begin
			//LOW BITs of A and B
			assign 	low_a 		= A[IGNORE_BIT - 1:0] ;
			assign 	low_b 		= B[IGNORE_BIT - 1:0] ;
			
			//Using or instead of adding operand to reduce delay
			assign	low_Sum 	= (low_a | low_b) ;

			//Carry of LOW BITs is AND result between 2 highest bits of LOW BITs
			assign 	carry_low 	= low_a[IGNORE_BIT-1] & low_b[IGNORE_BIT-1];
	
			//HIGH_BITs 
			assign 	high_a 		= a[BITS-1:IGNORE_BIT];
			assign 	high_b 		= b[BITS-1:IGNORE_BIT];

			//Using adding operand
			assign 	high_Sum 	= (high_a + high_b + carry_low) ;

			//Concatenate HIGH and LOW BITS to form final output
			assign	OUT		= {high_Sum, low_Sum};
		end
		else begin
			//Ideal Result
			assign 	OUT		= (a + b);
		end
	endgenerate

endmodule


