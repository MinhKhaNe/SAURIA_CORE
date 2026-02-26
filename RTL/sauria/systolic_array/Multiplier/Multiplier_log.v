`define max(a,b) ((a) > (b) ? (a) : (b))

module Multiplier_log #(
    parameter APPROX_TYPE = 0,				//0: exact, 1: approximate
    parameter APPROX_W    = 16,
    parameter WIDTH_A     = 16,
    parameter WIDTH_B     = 16,
    parameter WIDTH_MUL   = 32,
    parameter SIGNED      = 0,
    parameter STAGE       = 0
)(
    input  wire                     clk,
    input  wire                     rst_n,
    input  wire                     pip_en,
    input  wire [WIDTH_A-1:0]       A,
    input  wire [WIDTH_B-1:0]       B,
	
    output wire [WIDTH_MUL-1:0]     OUT
);

	//Calculating Log2 function (use to calculate width of LOG)
    function automatic integer clog2;
        input integer value;
        integer i;
        begin
            clog2 = 0;
            for (i=value-1; i>0; i=i>>1)
                clog2 = clog2 + 1;
        end
    endfunction

	//Derived Parameters
    parameter WIDTH_LOGA = 	clog2(WIDTH_A+1);       //Log's width of A
    parameter WIDTH_LOGB = 	clog2(WIDTH_B+1);       //Log's width of B
    parameter WIDTH_F    = 	`max(WIDTH_A, WIDTH_B);
    parameter LOG_W      = 	`max(WIDTH_A + WIDTH_LOGA + 1, WIDTH_B + WIDTH_LOGB + 1);   //Log width
    parameter X_W        = 	WIDTH_F-1;              //Mantissa width

	//Internal Signals
	wire 			[WIDTH_B-2:0] 		xb;         //Fractional of B
    wire 			[WIDTH_A-2:0] 		xa;         //Fractional of A
	wire 	signed 	[WIDTH_A-1:0] 		A_s = A;
    wire 	signed 	[WIDTH_B-1:0] 		B_s = B;
    wire 			[WIDTH_A-1:0] 		abs_a;
    wire 			[WIDTH_B-1:0] 		abs_b;
    wire 								prod_sign;
	wire 			[WIDTH_LOGA-1:0] 	ka;
    wire 			[WIDTH_LOGB-1:0] 	kb;
	wire 			[WIDTH_LOGA-1:0] 	shift_posA;	
    wire 			[WIDTH_LOGB-1:0] 	shift_posB;
	wire 			[WIDTH_A-1:0] 		shifted_A;
    wire 			[WIDTH_B-1:0] 		shifted_B;
	wire 			[LOG_W-1:0] 		log_a;
	wire 			[LOG_W-1:0] 		log_b;
	wire 			[X_W-1:0] 			xprod;
	wire 			[LOG_W-X_W:0] 		kprod;
	reg  			[LOG_W:0] 			log_sum;
	reg 	signed 	[WIDTH_MUL-1:0] 	product;
    reg 			[X_W:0] 			mantissa;
	reg									carry_low;
	

    assign abs_a 		= 	(SIGNED && A_s < 0) ? -A_s : A_s;           //Absolute value of A
	assign abs_b 		=	(SIGNED && B_s < 0) ? -B_s : B_s;           //Absolute value of B
	assign prod_sign 	= 	SIGNED && (A[WIDTH_A-1] ^ B[WIDTH_B-1]);    //Sign of product  

    //Leading one detector
    lopd #(
        .WIDTH_I(WIDTH_A),
        .WIDTH_L(WIDTH_LOGA)
    ) la (
        .in(abs_a),
        .out(ka)
    );

    lopd #(
        .WIDTH_I(WIDTH_B),
        .WIDTH_L(WIDTH_LOGB)
    ) lb (
        .in(abs_b),
        .out(kb)
    );

    //Normalize number into 1.xxxx form
	assign	shift_posA 	=	WIDTH_A - 1 - ka;
    assign	shift_posB 	=   WIDTH_B - 1 - kb;

    assign	shifted_A	=	abs_a << shift_posA;
    assign	shifted_B 	=   abs_b << shift_posB;

    //Remove leading 1 bit
	assign 	xa 			= 	shifted_A[WIDTH_A-2:0];
	assign 	xb 			= 	shifted_B[WIDTH_B-2:0];

    //Log2(A) ≈ k + x
    assign 	log_a 		= 	{ka, xa};
    assign  log_b 		= 	{kb, xb};

    //Log addition
    always @(*) begin
		log_sum = 0;
        //Approximate mode
        if (APPROX_TYPE) begin
            carry_low					= log_a[APPROX_W] & log_b[APPROX_W];

			log_sum[LOG_W:APPROX_W]		= carry_low + log_a[LOG_W-1:APPROX_W] + log_b[LOG_W-1:APPROX_W];

            //Force approximate bit to 1
            log_sum[APPROX_W-1:0] 		= {APPROX_W{1'b1}};
        end
        else begin
            //Exact mode
            log_sum = log_a + log_b;
        end
    end

    //Split exponent and mantissa
	assign	xprod = log_sum[X_W-1:0];
	assign	kprod = log_sum[LOG_W:X_W];

    always @(*) begin
        //Check whether value is 0 or not
        if ((abs_a==0) || (abs_b==0)) begin
            product = {WIDTH_MUL{1'b0}};
        end
        else begin
            //Restore hidden leading 1
            mantissa = {1'b1, xprod};

            //Scale using exponent
            if (kprod >= X_W)
                product = mantissa << (kprod - X_W);
            else
                product = mantissa >> (X_W - kprod);
        end
    end

    //Restore sign
    assign OUT = (prod_sign) ? -product : product;

endmodule

