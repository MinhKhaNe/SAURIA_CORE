module tb_adder_trua;

  	localparam int A_APPROX = 2;
	localparam int WIDTH_A = 4;
	localparam int WIDTH_B = 8;
	localparam int BITS    = (WIDTH_A > WIDTH_B) ? WIDTH_A : WIDTH_B;

	logic	[WIDTH_A-1:0] 	A;
	logic	[WIDTH_B-1:0]	B;
	logic 			Carry;
	
	logic [BITS-1:0]	OUT;

	Adder_trua #(
      .IGNORE_BIT(A_APPROX),
		.WIDTH_A(WIDTH_A),
		.WIDTH_B(WIDTH_B)
	) dut(
		.A(A),
		.B(B),
		.Carry(Carry),
		.OUT(OUT)		
	);

	task automatic display_result();
		$display(
			"A=%0d, B=%0d, Carry=%b, OUT=%0d", $signed(A), $signed(B), Carry, $signed(OUT)
		);
	endtask

	initial begin
		$dumpfile("adder_ideal.vcd");   
       		$dumpvars(0, tb_adder_ideal);   
		A = 8'sd5;
		B = 12'sd3;
		Carry = 0;
		#1 display_result();

		A = -8'sd5;
        	B = 12'sd3;
        	Carry = 0;
        	#1 display_result();

        	A = -8'sd5;
        	B = -12'sd7;
        	Carry = 0;
        	#1 display_result();

        	A = -8'sd1;
        	B = 12'sd1;
        	Carry = 0;
        	#1 display_result();

        	A = -8'sd1;
        	B = 12'sd1;
        	Carry = 1;
        	#1 display_result();

        	A = 8'sd127;
        	B = 12'sd1;
        	Carry = 0;
        	#1 display_result();

        	A = -8'sd128;
        	B = -12'sd1;
        	Carry = 0;
        	#1 display_result();

       		#1 $finish;
	end	

endmodule