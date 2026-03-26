`timescale 1ns/1ps

module tb_adder_gear_2c;

    localparam int WIDTH_A = 16;
    localparam int WIDTH_B = 16;
    localparam int R = 4;
    localparam int P = 4;

    localparam int BITS = (WIDTH_A > WIDTH_B) ? WIDTH_A : WIDTH_B;

    logic   [WIDTH_A-1:0]  A;
    logic   [WIDTH_B-1:0]  B;
    logic                   Carry;

    logic   [BITS-1:0]      OUT_0, OUT_1;

    adder_gear_2c #(
        .R(R),
        .P(P),
        .IP_W(WIDTH_A),
        .OC_W(WIDTH_B)
    ) dut (
        .i_p(A),
        .i_c(B),
        .i_carry(Carry),
        .o_c(OUT_0)
    );

    Adder_gear_2c #(
        .R(R),
        .P(P),
        .WIDTH_A(WIDTH_A),
        .WIDTH_B(WIDTH_B)
    ) uut (
        .A(A),
        .B(B),
        .Carry(Carry),
        .OUT(OUT_1)
    );

    task automatic display_result(int index);
		if(OUT_0 != OUT_1)
            $display("FAILED!!!! Expected result: %b, Actual result: %b", OUT_0, OUT_1);
        else
            $display("PASSED!!!! Expected result: %d, Actual result: %d", OUT_0, OUT_1);
	endtask

    initial begin
        $dumpfile("tb_adder_gear_2c.vcd");
        $dumpvars(0, tb_adder_gear_2c);

        Carry = 0;

        for (int i = 0; i < 100; i++) begin
            A = $signed($urandom_range(100, -100));
            B = $signed($urandom_range(100, -100));

            #10; 
            display_result(i);
        end
    
        #1 $finish;
    end

endmodule