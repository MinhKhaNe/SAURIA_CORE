`timescale 1ns/1ps

module tb_multiplier_ideal;

	parameter WIDTH_A   = 16;
	parameter WIDTH_B   = 16;
	parameter WIDTH_MUL = WIDTH_A + WIDTH_B;
	parameter SIGNED    = 0;
	parameter STAGE     = 2;

	localparam LATENCY = STAGE + 1;

	logic clk;
	logic rst_n;
	logic pip_en;

	logic [WIDTH_A-1:0] A;
	logic [WIDTH_B-1:0] B;

	wire  [WIDTH_MUL-1:0] OUT;

	// DUT
	Multiplier_ideal #(
		.SIGNED    (SIGNED),
		.WIDTH_A   (WIDTH_A),
		.WIDTH_B   (WIDTH_B),
		.WIDTH_MUL (WIDTH_MUL),
		.STAGE     (STAGE)
	) dut (
		.clk    (clk),
		.rst_n  (rst_n),
		.pip_en (pip_en),
		.A      (A),
		.B      (B),
		.OUT    (OUT)
	);

	always #5 clk = ~clk;

	task run_test(input int a, input int b);
		int exp;
	begin
		A = a;
		B = b;
		pip_en = 1'b1;

		exp = SIGNED ? ($signed(a) * $signed(b)) : (a * b);

		// wait pipeline
		repeat (LATENCY) @(posedge clk);

		if (OUT !== exp) begin
			$display("\n===== FAILED!!! \nA=%0d B=%0d | OUT=%0d EXPECT=%0d =====", a, b, $signed(OUT), exp);
		end
		else begin
			$display("\n===== PASSED SUCCESSFULLY!!! \nA=%0d B=%0d | OUT=%0d =====", a, b, $signed(OUT));
		end
	end
	endtask


	initial begin
		$dumpfile("tb_multiplier_ideal.vcd");
		$dumpvars(0, tb_multiplier_ideal);

		clk   = 0;
		rst_n = 0;
		pip_en = 0;
		A = 0;
		B = 0;

		// reset
		repeat (3) @(posedge clk);
		rst_n = 1;

		// wait after reset
		repeat (2) @(posedge clk);

		run_test(3, 5);
		run_test(7, 9);
		run_test(12, 4);
		run_test(15, 15);

		if (SIGNED) begin
			run_test(-3, 7);
			run_test(-8, -4);
			run_test(6, -5);
		end

		// random tests
		repeat (5) begin
			run_test($urandom_range(0, 100),
			         $urandom_range(0, 100));
		end

		$display("All tests finished");
		#20;
		$finish;
	end

endmodule