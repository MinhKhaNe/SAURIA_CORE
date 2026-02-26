`timescale 1ns/1ps

module tb_zero_detection;

    localparam WIDTH_A = 16;
    localparam WIDTH_B = 16;
    localparam WIDTH_T = 2;

    logic [WIDTH_A-1:0] A;
    logic [WIDTH_B-1:0] B;
    logic [WIDTH_T-1:0] Thres;
    logic Zero;

    // DUT
    Zero_detection #(
        .WIDTH_A(WIDTH_A),
        .WIDTH_B(WIDTH_B),
        .WIDTH_T(WIDTH_T)
    ) dut (
        .A(A),
        .B(B),
        .Thres(Thres),
        .Zero(Zero)
    );

    // ===== Helper task =====
    task show;
        $display("T=%0t | Thres=%0d | A=0x%h B=0x%h | Zero=%b",
                 $time, Thres, A, B, Zero);
    endtask

    // ===== Test sequence =====
    initial begin
        $display("===== START ZERO DETECTION FLOAT TB =====");

        // -------------------------------
        // Case 1: Exact zero
        // -------------------------------
        Thres = 1;
        A = 16'h0000;
        B = 16'h3C00; // some non-zero
        #1; show();

        A = 16'h3C00;
        B = 16'h0000;
        #1; show();

        // -------------------------------
        // Case 2: Near-zero exponent
        // exponent bits = [14:10]
        // -------------------------------
        // exponent = 00001
        A = 16'b0_00001_000000000;
        B = 16'b0_00001_111111111;
        Thres = 1;
        #1; show();

        Thres = 2;
        #1; show();

        // -------------------------------
        // Case 3: Not zero (large exponent)
        // exponent = 01111
        // -------------------------------
        A = 16'b0_01111_000000000;
        B = 16'b0_01111_000000000;
        Thres = 1;
        #1; show();

        Thres = 3;
        #1; show();

        // -------------------------------
        // Case 4: Boundary test
        // exponent_min edge
        // -------------------------------
        A = 16'b0_00000_000000001;
        B = 16'b0_00000_000000001;
        Thres = 1;
        #1; show();

        // -------------------------------
        // Case 5: Sweep threshold
        // -------------------------------
        A = 16'b0_00010_000000000;
        B = 16'b0_00010_000000000;

        repeat (4) begin
            Thres = Thres + 1;
            #1; show();
        end

        $display("===== END TB =====");
        $finish;
    end

endmodule
