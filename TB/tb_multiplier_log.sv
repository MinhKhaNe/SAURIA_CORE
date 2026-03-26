`timescale 1ns/1ps

module tb_multiplier_log;

    localparam WIDTH_A   = 16;
    localparam WIDTH_B   = 16;
    localparam WIDTH_MUL = 32;
    localparam SIGNED    = 1;
    localparam STAGE     = 0;


    logic clk;
    logic rst_n;
    logic pip_en;

    logic [WIDTH_A-1:0] A;
    logic [WIDTH_B-1:0] B;

    logic [WIDTH_MUL-1:0] OUT_dut;

    logic signed [WIDTH_MUL-1:0] GOLDEN;

    integer i;


    always #5 clk = ~clk;


    Multiplier_log #(
        .APPROX_TYPE(0),
        .APPROX_W   (0),
        .WIDTH_A    (WIDTH_A),
        .WIDTH_B    (WIDTH_B),
        .WIDTH_MUL  (WIDTH_MUL),
        .SIGNED     (SIGNED),
        .STAGE      (STAGE)
    ) dut (
        .clk    (clk),
        .rst_n  (rst_n),
        .pip_en (pip_en),
        .A      (A),
        .B      (B),
        .OUT    (OUT_dut)
    );


    task automatic run_test(
        input signed [WIDTH_A-1:0] a_in,
        input signed [WIDTH_B-1:0] b_in
    );
        begin

            A = a_in;
            B = b_in;
            pip_en = 1'b1;

            GOLDEN = a_in * b_in;

            @(posedge clk);
            repeat (STAGE) @(posedge clk);

            $display("--------------------------------------------------");
            $display("A = %0d | B = %0d", a_in, b_in);
            $display("DUT     = %0d (%b)", $signed(OUT_dut), OUT_dut);
            $display("GOLDEN  = %0d (%b)", GOLDEN, GOLDEN);

            if ($signed(OUT_dut) !== GOLDEN) begin
                $display("ERROR | DIFF = %0d",
                         GOLDEN - $signed(OUT_dut));
            end
            else begin
                $display("CORRECT");
            end
        end
    endtask


    initial begin
        clk   = 0;
        rst_n = 0;
        pip_en = 0;
        A = 0;
        B = 0;

        repeat (3) @(posedge clk);
        rst_n = 1;

        run_test(10, 5);
        run_test(-10, 5);
        run_test(7, -3);
        run_test(-8, -9);
        run_test(0, 1234);
        run_test(1, -1);

        run_test(32767, 2);
        run_test(-32768, 1);

        for (i = 0; i < 20; i++) begin
            run_test($random, $random);
        end

        $display("\n==== TEST FINISHED ====");
        $finish;
    end

endmodule
