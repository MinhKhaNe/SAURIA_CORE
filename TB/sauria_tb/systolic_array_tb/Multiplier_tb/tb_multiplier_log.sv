module tb_multiplier_log;

    localparam APPROX       = 0;
    localparam APPROX_W     = 0;
    localparam WIDTH_A      = 8;
    localparam WIDTH_B      = 8;
    localparam WIDTH_MUL    = 16;
    localparam SIGNED       = 1;

    logic                   clk, rst_n;
    logic   [WIDTH_A-1:0]   A;
    logic   [WIDTH_B-1:0]   B;
    logic   [WIDTH_MUL-1:0] OUT;

    Multiplier_log  #(
        .APPROX(APPROX),
        .APPROX_W(APPROX_W),
        .WIDTH_A(WIDTH_A),
        .WIDTH_B(WIDTH_B),
        .WIDTH_MUL(WIDTH_MUL),
        .SIGNED(SIGNED)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .A(A),
        .B(B),
        .OUT(OUT)
    );

    initial begin
        clk = 0;
        forever   #25 clk = ~clk;
    end

    task check_result;
        input signed [WIDTH_MUL-1:0] out_val;
        input signed [WIDTH_MUL-1:0] golden;

        logic signed [WIDTH_MUL:0] diff;
        begin
            diff = out_val - golden;
            if (diff < 0)
                diff = -diff;

            if (diff > 20) begin   
                $display("t=%0t FAIL | OUT=%0d | GOLD=%0d | DIFF=%0d",
                         $time, out_val, golden, diff);
            end else begin
                $display("t=%0t PASS | OUT=%0d | GOLD=%0d | DIFF=%0d",
                         $time, out_val, golden, diff);
            end
        end
    endtask


    initial begin
        rst_n = 0; A = 0; B = 0;
        #10 rst_n = 1;

        A = 8'sd21; B = 8'sd7;
        #1 check_result(OUT, 21*7);

        A = 8'sd13; B = 8'sd11;
        #1 check_result(OUT, 13*11);

        A = -8'sd5; B = 8'sd9;
        #1 check_result(OUT, -5*9);

        A = -8'sd12; B = -8'sd3;
        #1 check_result(OUT, (-12)*(-3));

        A = 8'sd1; B = 8'sd1;
        #1 check_result(OUT, 1*1);

        $stop;
    end

endmodule