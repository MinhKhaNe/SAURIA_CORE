module Multiplier_wallace #(
    parameter APPROX_TYPE	= 0,
	parameter APPROX_W		= 16,
	parameter WIDTH_A 		= 16,
	parameter WIDTH_B 		= 16,
	parameter WIDTH_MUL 	= 32,
	parameter SIGNED		= 0, 
	parameter STAGE			= 0
)(
    input	wire 					clk,
	input	wire					rst_n,
	input	wire					pip_en,
	input	wire	[WIDTH_A-1:0]	A,
	input	wire	[WIDTH_B-1:0]	B,

	output	wire	[WIDTH_MUL-1:0]	OUT
);

	wire			[WIDTH_A-1:0]	a_abs;
	wire			[WIDTH_B-1:0]	b_abs;
	wire			[15:0]			a_wall;
	wire			[15:0]			b_wall;
	wire			[31:0]			product;
	reg				[WIDTH_MUL-1:0]	product_out;
	wire							a_sign, b_sign, pro_sign;
	reg 	signed 	[WIDTH_MUL-1:0] pipe_reg [0:STAGE];
	integer 						p;

	assign	a_sign		= A[WIDTH_A-1];		//1st bit of A
	assign	b_sign		= B[WIDTH_B-1];		//1st bit of B
	assign 	pro_sign	= a_sign ^ b_sign;

	assign 	a_abs	= 	(!SIGNED) 	? 	A :			//Unsigned mode -> Keep A
						(a_sign)	? 	(0-A) :		//Signed mode -> Take 2's complement
						A;
	
	assign 	b_abs	= 	(!SIGNED) 	? 	B :			//Unsigned mode -> Keep B
						(b_sign)	? 	(0-B) :		//Signed mode -> Take 2's complement
						B;

	//MSB forced = 0 to avoid sign-extension
	assign	a_wall	=	{1'b0, a_abs[WIDTH_A-2:0]};	
	assign	b_wall	=	{1'b0, b_abs[WIDTH_B-2:0]};

	//Wallace Tree Multiplier
	Wallace_16bit #(
		.APPROX(APPROX_TYPE)
	) w0 (
		.A(a_wall),
		.B(b_wall),
		.OUT(product)
	);

	//Restore sign after multiplication
	always @(posedge clk or negedge rst_n) begin
		if(!rst_n) begin
			product_out	<= {WIDTH_MUL{1'b0}};	
		end
		else begin
			if(SIGNED && pro_sign)
				product_out	<= (0 - product);	//Negate result
			else
				product_out	<= product;
		end
	end

	//Stimulate pipeline stage
	always @(posedge clk or negedge rst_n) begin
		if (!rst_n) begin
       		for(p = 0; p <= STAGE; p = p + 1) begin
				pipe_reg[p]		<= {WIDTH_MUL{1'b0}};
			end
		end
		else if (pip_en) begin
    		pipe_reg[0] <= product_out;
    		for (p = 1; p <= STAGE; p = p + 1) begin
        		pipe_reg[p] <= pipe_reg[p-1];
			end
		end
	end

	assign OUT = pipe_reg[STAGE];

endmodule
