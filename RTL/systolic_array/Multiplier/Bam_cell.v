module Bam_cell(
	input	wire	A,
	input	wire	B,
	input	wire	pre_OUT,
	input	wire	Carry,

	output	wire	Carry_out,
	output	wire	OUT
);

  	wire			and_ab;
	wire	[1:0]	result;

	assign	and_ab 		= A & B;
	assign	result		= and_ab + pre_OUT + Carry;	

	assign	Carry_out	= result[1];
	assign	OUT		= result[0];
	
endmodule
