`define max(a,b) ((a) > (b) ? (a) : (b))

module Multiplier_booth #(
	parameter APPROX_TYPE	= 0,
	parameter APPROX_W		= 16,			//Number of bit will approximate
	parameter WIDTH_A 		= 16,
	parameter WIDTH_B 		= 16,
	parameter WIDTH_MUL 	= WIDTH_A + WIDTH_B,
	parameter SIGNED 		= 0,
	parameter STAGE			= 0				//Number of pipeline stage
)(
	input	wire					clk,
	input	wire					rst_n,
	input	wire					pip_en,
	input	wire	[WIDTH_A-1:0]	A,
	input	wire	[WIDTH_B-1:0]	B,

	output	wire	[WIDTH_MUL-1:0]	OUT
);

	//Derived Parameters
	parameter WIDTH = `max(WIDTH_A, WIDTH_B);	
	parameter cnt	= (WIDTH + 1)/2;			//Radix-4 only need n/2

	//Internal Signals
	wire			[2:0]				Q;
	wire	signed	[WIDTH_MUL-1:0]		A_ext;
	wire			[WIDTH_B+2:0]		B_ext;
	wire								done;
	reg									done_reg;
	
	reg 	signed 	[WIDTH_MUL-1:0] 	OUT_final;
	reg		signed	[WIDTH_MUL-1:0]		product;
	reg				[5:0]				i;
	reg 	signed 	[WIDTH_MUL-1:0] 	pipe_reg [0:STAGE];		//Stimulate pipeline
	integer 							p;

	//Take 3 bits from B to calculate and then shift to higher and continue taking bits
	assign 	Q = 	B_ext[2*i +: 3];

	//Sign extend if SIGNED = 1
	assign	A_ext 	= SIGNED ? $signed({{WIDTH_B{A[WIDTH_A-1]}} , A}) : $signed({{WIDTH_B{1'b0}}, A});	
	//If SIGNED, add 1 bit 0 to LSB and 2 bit SIGN of B to MSB, if not add 1 bit 0 to LSB and 2 bit 0 to MSB
	assign 	B_ext 	= SIGNED ? {{2{B[WIDTH_B-1]}}, B, 1'b0} : {2'b0, B, 1'b0};	
	assign	done	= done_reg;

	always @(posedge clk or negedge rst_n) begin
		if(!rst_n) begin
			product		<= {WIDTH_MUL{1'b0}};
			i			<= 6'b0;
			done_reg	<= 1'b0;
		end
		else if (pip_en) begin
			if(i<cnt) begin
				case(Q)
					3'b000: product	<= product;							//Keep product
					3'b001: product	<= product + (A_ext << (2*i));		//product = product + 1 * A
					3'b010: product	<= product + (A_ext << (2*i));		//product = product + 1 * A
					3'b011: product	<= product + (A_ext << (2*i+1));	//product = product + 2 * A
					3'b100: product	<= product - (A_ext << (2*i+1));	//product = product - 2 * A
					3'b101: product	<= product - (A_ext << (2*i));		//product = product - 2 * A
					3'b110: product	<= product - (A_ext << (2*i));		//product = product - 2 * A
					3'b111: product	<= product;							//Keep product
				endcase
				i <= i + 1'b1;		//Increase i to continue loop
				if(i == (cnt -1))	//Finish all counting (0 -> (cnt-1))
					done_reg	<= 1'b1;	//done_reg signal high
				else 
					done_reg	<= 1'b0;
			end
			else begin
				product		<= {WIDTH_MUL{1'b0}};
				i			<= 6'b0;
				done_reg	<= 1'b0;
			end
		end
	end

	//Stimulate pipeline stage
	always @(posedge clk or negedge rst_n) begin
		if (!rst_n) begin
       		for(p = 0; p <= STAGE; p = p + 1) begin
				pipe_reg[p]		<= {WIDTH_MUL{1'b0}};	//Reset all pipeline stage
			end
		end
		else if (pip_en && done) begin
    		if(APPROX_TYPE)
				//Trans approximate bit to 0 to reduce power
				pipe_reg[0] <= {product[WIDTH_MUL-1:APPROX_W], {APPROX_W{1'b0}}};
			else
				pipe_reg[0]	<= product;

    		for (p = 1; p <= STAGE; p = p + 1) begin
        		pipe_reg[p] <= pipe_reg[p-1];			//Stimulate pipeline stage
			end
		end
	end

	assign OUT = pipe_reg[STAGE];						//OUT result when finish all pipeline stages
endmodule

