`define max(a,b) ((a) > (b) ? (a) : (b))

module Multiplier_bam #(
	parameter WIDTH_A 	= 16,
	parameter WIDTH_B 	= 16,
	parameter WIDTH_OUT	= WIDTH_A + WIDTH_B,
	parameter SIGNED 	= 0,
	parameter VBL		= 0,		//Cut bit along Vertical(x) axis
	parameter HBL		= 0,		//Cut bit along Horizontal(y) axis
	parameter STAGE		= 0	  	
)(
	input	wire					clk,
	input	wire					rst_n,
	input	wire					pip_en,
	input	wire	[WIDTH_A-1:0]	A,
	input	wire	[WIDTH_B-1:0]	B,

	output	wire	[WIDTH_OUT-1:0]	OUT
);
	
	parameter	WIDTH = `max(WIDTH_A, WIDTH_B);

	//Internal signals
	wire	signed	[WIDTH:0]			a, b;
	wire			[WIDTH*2:0]			sum_arr[WIDTH:0];
	wire			[WIDTH*2:0]			carry_arr[WIDTH:0];
	wire								a_sign, b_sign, pro_sign;
	wire			[2*WIDTH-1:0]		product;
	wire 			[2*WIDTH-1:0] 		final_sum, final_carry;
	reg 	signed 	[WIDTH_OUT-1:0]		pipe_reg [0:STAGE];			//Pipeline registers
	wire 	signed 	[2*WIDTH-1:0] 		product_signed;

	integer 							p;

	assign product_signed 	= (SIGNED && pro_sign) ? -$signed(product) : product;

	//Detect operand sign bits
	assign	a_sign		= A[WIDTH_A-1];
	assign	b_sign		= B[WIDTH_B-1];	
	//Resulting product sign
	assign	pro_sign 	= a_sign ^ b_sign;

	//ABS value
	assign a = (SIGNED && a_sign) ? (~{1'b0, A} + 1'b1) : {1'b0, A};
	assign b = (SIGNED && b_sign) ? (~{1'b0, B} + 1'b1) : {1'b0, B};

	genvar x, y;
	generate
		for(x = 0; x < WIDTH; x = x + 1) begin
			for(y = 0; y < WIDTH; y = y + 1) begin
				//Intermediate signal for each cell
				wire current_a = a[x];
				wire current_b = b[y];

				//Diagonal propagation
				wire p_in_sum   = (x == 0) ? 1'b0 : sum_arr[x-1][y+1];
				//Carry propagation
				wire p_in_carry = (x == 0) ? 1'b0 : carry_arr[x-1][y];

				//Cut bit
				if (y >= VBL && x >= HBL) begin
					Bam_cell BC (
						.A(current_a),
						.B(current_b),
						.pre_OUT(p_in_sum),
						.Carry(p_in_carry),
						.OUT(sum_arr[x][y]),
						.Carry_out(carry_arr[x][y])
					);
				end else begin
					//Truncated region
					assign sum_arr[x][y]   = p_in_sum; 
					assign carry_arr[x][y] = 1'b0;
				end
			end
			// Highest bit
			assign sum_arr[x][WIDTH] = carry_arr[x][WIDTH-1];
		end
	endgenerate

	//Final reduction stage
	genvar i;
	generate
		for(i = 0; i < WIDTH; i = i + 1) begin
			//LSB bits
			assign final_sum[i]   = sum_arr[i][0];
			assign final_carry[i] = 1'b0; 
			
			//MSB bits
			assign final_sum[i+WIDTH]   = sum_arr[WIDTH-1][i+1];
			assign final_carry[i+WIDTH] = carry_arr[WIDTH-1][i];
		end
	endgenerate

	//Product of sum and carry
	assign product = final_sum + final_carry;

	//Stimulate pipeline stage
	always @(posedge clk or negedge rst_n) begin
    		if (!rst_n) begin
       			for(p = 0; p <= STAGE; p = p + 1) begin
					pipe_reg[p]		<= {WIDTH_OUT{1'b0}};
				end
			end
			else if(pip_en) begin
    			pipe_reg[0]	<= product_signed;
        		for(p = 1; p <= STAGE; p = p + 1) begin
					pipe_reg[p]		<= pipe_reg[p-1];
				end
			end
	end

	assign OUT 	= pipe_reg[STAGE];

endmodule



