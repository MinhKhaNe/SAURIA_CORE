`timescale 1ns/1ps

module tb_multiplier_booth;

	localparam WIDTH_A   = 16;
	localparam WIDTH_B   = 16;
	localparam WIDTH_MUL = WIDTH_A + WIDTH_B;
	localparam SIGNED    = 1;
	localparam STAGE     = 0;

	reg                     clk;
	reg                     rst_n;
	reg                     pip_en;
	reg     [WIDTH_A-1:0]   A;
	reg     [WIDTH_B-1:0]   B;
	wire    [WIDTH_MUL-1:0] OUT;

	Multiplier_booth #(
		.WIDTH_A(WIDTH_A),
		.WIDTH_B(WIDTH_B),
		.WIDTH_MUL(WIDTH_MUL),
		.SIGNED(SIGNED),
		.STAGE(STAGE),
		.APPROX_TYPE(0),
		.APPROX_W(8)
	) dut (
		.clk(clk),
		.rst_n(rst_n),
		.pip_en(pip_en),
		.A(A),
		.B(B),
		.OUT(OUT)
	);

	always #5 clk = ~clk;

	task run_test;
        input signed [WIDTH_A-1:0] a_in;
        input signed [WIDTH_B-1:0] b_in;
        reg   signed [WIDTH_MUL-1:0] expected;
    begin
        A = a_in;
        B = b_in;
        pip_en = 1'b1;
        repeat (12) @(posedge clk);
        
        expected = a_in * b_in;
        $display("--------------------------------------------------");
        $display("A        = %b", a_in);
        $display("B        = %b", b_in);
        $display("OUT      = %b", OUT);
        $display("EXPECTED = %b", expected);
        
        if (OUT === expected)
            $display("===== PASSED SUCCESSFULLY!!! =====");
        else
            $display("===== FAILED!!! =====");
        rst_n = 0;
        #10;
        rst_n = 1;
        pip_en = 0;
        #10;
    end
    endtask

	integer i_test;
    reg signed [WIDTH_A-1:0] rand_a;
    reg signed [WIDTH_B-1:0] rand_b;

    initial begin
        clk = 0;
        rst_n = 0;
        pip_en = 0;
        A = 0;
        B = 0;

        repeat(3) @(posedge clk);
        rst_n = 1;

        $display("\n===== BOUNDARY CASES =====");
        run_test(16'sh7FFF, 16'sh7FFF); 
        run_test(16'sh8000, 16'sh8000); 
        run_test(16'sh8000, -16'sh7FFF); 
        run_test(-16'shFFFF, -16'shFFFF); 
        run_test(-16'sh0001, -16'shFFFF); 

        $display("\n===== POWER OF 2 =====");
        run_test(16'sd1024, -16'sd16);   
        run_test(16'sd2,    -16'sd4096); 
        run_test(-16'sd2,   16'sd2048);

        $display("\n===== BIT PATTERN STRESS =====");
        run_test(16'hAAAA, 16'h5555); 
        run_test(16'hFFFF, 16'h0001);

        $display("\n===== RANDOM TESTING - 100 CASES =====");
        for (i_test = 0; i_test < 100; i_test = i_test + 1) begin
            rand_a = $random;
            rand_b = $random;
            run_test(rand_a, rand_b);
        end
        
        $finish;
    end

endmodule
