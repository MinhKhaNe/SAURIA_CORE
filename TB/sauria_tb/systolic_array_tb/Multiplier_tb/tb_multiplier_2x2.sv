module tb_multiplier_2x2;

    logic [1:0] A, B;
    logic [3:0] OUT_exact;
    logic [3:0] OUT_approx;

    logic [3:0] GOLD;

    Multiplier_2x2 #(.APPROX(0)) dut_exact (
        .A(A),
        .B(B),
        .OUT(OUT_exact)
    );

    Multiplier_2x2 #(.APPROX(1)) dut_approx (
        .A(A),
        .B(B),
        .OUT(OUT_approx)
    );

    initial begin
        $dumpfile("tb_multiplier_2x2.vcd");
        $dumpvars(0, tb_multiplier_2x2);

        $display(" A  B | GOLD | EXACT | APPROX");

        for (int i = 0; i < 4; i++) begin
            for (int j = 0; j < 4; j++) begin
                A = i[1:0];
                B = j[1:0];
                #1;

                GOLD = i * j;

                $display("%2d %2d |  %2d  |   %2d  |   %2d", i, j, GOLD, OUT_exact, OUT_approx);

                if (OUT_exact !== GOLD) begin
                  	$display("FAIL!!");
                    $stop;
                end
            end
        end

      $display("PASSED SUCCESSFULLY!!");
      $finish;
    end

endmodule


