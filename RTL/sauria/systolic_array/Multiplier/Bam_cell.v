module Bam_cell(
	input	wire	A,				//Multiplier bit
	input	wire	B,				//Multiplicand bit
	input	wire	pre_OUT,		//Previous partial sum
	input	wire	Carry,			//Carry in

	output	wire	Carry_out,
	output	wire	OUT
);

	//Internal Signals
  	wire			and_ab;
	wire	[1:0]	result;

	//Generate partial product
	assign	and_ab 		= A & B;
	//Full-adder operation
	assign	result		= and_ab + pre_OUT + Carry;	

	//MSB = carry out
	assign	Carry_out	= result[1];
	//LSB = sum output
	assign	OUT			= result[0];
	
endmodule
