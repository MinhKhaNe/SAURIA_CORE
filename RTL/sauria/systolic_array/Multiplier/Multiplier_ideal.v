module Multiplier_ideal #(
	parameter	SIGNED = 0,
	parameter	WIDTH_A = 16,
	parameter	WIDTH_B = 16,
	parameter	WIDTH_MUL = WIDTH_A + WIDTH_B,
	parameter	STAGE = 0
)(
	input	wire					clk,
	input	wire					rst_n,
	input	wire					pip_en,
	input	wire	[WIDTH_A-1:0]	A,
	input	wire	[WIDTH_B-1:0]	B,
	
	output	wire	[WIDTH_MUL-1:0]	OUT
);

	//Internal signals
	wire	signed	[WIDTH_A-1:0]			A_sign;
	wire	signed	[WIDTH_B-1:0]			B_sign;
	reg				[WIDTH_MUL-1:0]			Buffer [0:STAGE];
	reg		signed	[WIDTH_MUL-1:0]			OUT_sign;

	always @(*) begin
		if(SIGNED)
			Buffer[0] = $signed(A) * $signed(B);
		else 
			Buffer[0] = A * B;
	end

	//Stimulate Pipeline
	genvar i;
	generate
		for(i=1; i<STAGE+1; i=i+1) begin
			always @(posedge clk or negedge rst_n) begin
				if(!rst_n) begin
					Buffer[i] <= '0;
				end
				else if(pip_en) begin
					Buffer[i] <= Buffer[i-1];
				end
			end
		end
	endgenerate

	assign OUT = Buffer[STAGE];

endmodule

