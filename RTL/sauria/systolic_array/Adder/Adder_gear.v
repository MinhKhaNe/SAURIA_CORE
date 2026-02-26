`define max(a,b) ((a) > (b) ? (a) : (b))

module Adder_gear #(
	parameter 	R = 16,					//number of shifted bit
	parameter 	P = 16,					//overlap bit
	parameter 	WIDTH_A = 16,
	parameter 	WIDTH_B = 16
)(
	input	wire	[WIDTH_A-1:0]					A,
	input	wire	[WIDTH_B-1:0]					B,
	input	wire									Carry,	//do not use Carry

	output	wire	[`max(WIDTH_A, WIDTH_B)-1:0]	OUT
);

	parameter 			BITS 	= `max(WIDTH_A, WIDTH_B);
	parameter 			L 		= R + P;								//sub-adder length
	parameter 	integer k 		= 1 + ((BITS - L + R - 1) / R);			//number of loops
	parameter 			N		= L + (k-1)*R;							//real width of sum

	wire	signed	[N-1:0]			Sum;
	wire	signed	[BITS-1:0] 		a;
	wire	signed	[BITS-1:0] 		b;
	wire	signed	[L-1:0]			subadd_A [k-1:0]; 
	wire	signed	[L-1:0]			subadd_B [k-1:0]; 
	wire	signed	[N:0]			subadd_sum [k-1:0];
	
	assign	a = {{{BITS-WIDTH_A}{A[WIDTH_A-1]}}, A};	//sign extend
	assign	b = {{{BITS-WIDTH_B}{B[WIDTH_B-1]}}, B};	//sign extend

	genvar i;
	generate
		for(i=0; i<k; i=i+1) begin
			//Create Sub-Adder
			assign subadd_A[i] = a[i*R+:L];
			assign subadd_B[i] = b[i*R+:L];

			//Sum the sub-adder
			assign subadd_sum[i] = subadd_A[i] + subadd_B[i];

			if(i==0) begin
				assign Sum[L-1:0] = subadd_sum[0][L-1:0];
			end
			else begin
				assign Sum[P + i*R +:R] = subadd_sum[i][L-1:P];
			end
		end
	endgenerate

	assign OUT = Sum;
endmodule