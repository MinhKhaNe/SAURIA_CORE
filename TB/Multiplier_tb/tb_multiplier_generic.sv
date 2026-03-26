module tb_multiplier_generic;

    localparam int WIDTH_A    = 4;
    localparam int WIDTH_B    = 4;

    localparam int MM_APPROX  = 2;
    localparam int M_APPROX   = 2;

    localparam int WIDTH_MUL  = WIDTH_A + WIDTH_B;

    logic clk;
    logic rst_n;
    logic pipeline_en;

    logic [WIDTH_A-1:0] A;
    logic [WIDTH_B-1:0] B;

    logic [WIDTH_MUL-1:0] OUT_0;
    logic [WIDTH_MUL-1:0] OUT_1;
    logic [WIDTH_MUL-1:0] OUT_2;
    logic [WIDTH_MUL-1:0] OUT_3;
    logic [WIDTH_MUL-1:0] OUT_4;
    logic [WIDTH_MUL-1:0] OUT_5;
    logic [WIDTH_MUL-1:0] OUT_6;
    logic [WIDTH_MUL-1:0] OUT_7;
    logic [WIDTH_MUL-1:0] OUT_8;
    logic [WIDTH_MUL-1:0] OUT_9;

    integer i, j;

    always #5 clk = ~clk;

    Multiplier_generic #(
        .WIDTH_A(WIDTH_A),
        .WIDTH_B(WIDTH_B),
        .WIDTH_MUL(WIDTH_MUL),
        .MM_APPROX(MM_APPROX),
        .M_APPROX(M_APPROX),
        .MUL_TYPE(0),
        .SIGNED(0),
        .STAGE(0)
    ) M0 (
        .*,
        .OUT(OUT_0)
    );

    Multiplier_generic #(
        .WIDTH_A(WIDTH_A),
        .WIDTH_B(WIDTH_B),
        .WIDTH_MUL(WIDTH_MUL),
        .MM_APPROX(MM_APPROX),
        .M_APPROX(M_APPROX),
        .MUL_TYPE(1),
        .SIGNED(0),
        .STAGE(0)
    ) M1 (
        .*,
        .OUT(OUT_1)
    );

    Multiplier_generic #(
        .WIDTH_A(WIDTH_A),
        .WIDTH_B(WIDTH_B),
        .WIDTH_MUL(WIDTH_MUL),
        .MM_APPROX(MM_APPROX),
        .M_APPROX(M_APPROX),
        .MUL_TYPE(2),
        .SIGNED(0),
        .STAGE(0)
    ) M2 (
        .*,
        .OUT(OUT_2)
    );

    Multiplier_generic #(
        .WIDTH_A(WIDTH_A),
        .WIDTH_B(WIDTH_B),
        .WIDTH_MUL(WIDTH_MUL),
        .MM_APPROX(MM_APPROX),
        .M_APPROX(M_APPROX),
        .MUL_TYPE(3),
        .SIGNED(0),
        .STAGE(0)
    ) M3 (
        .*,
        .OUT(OUT_3)
    );

    Multiplier_generic #(
        .WIDTH_A(WIDTH_A),
        .WIDTH_B(WIDTH_B),
        .WIDTH_MUL(WIDTH_MUL),
        .MM_APPROX(MM_APPROX),
        .M_APPROX(M_APPROX),
        .MUL_TYPE(4),
        .SIGNED(0),
        .STAGE(0)
    ) M4 (
        .*,
        .OUT(OUT_4)
    );

    Multiplier_generic #(
        .WIDTH_A(WIDTH_A),
        .WIDTH_B(WIDTH_B),
        .WIDTH_MUL(WIDTH_MUL),
        .MM_APPROX(MM_APPROX),
        .M_APPROX(M_APPROX),
        .MUL_TYPE(5),
        .SIGNED(0),
        .STAGE(0)
    ) M5 (
        .*,
        .OUT(OUT_5)
    );

    Multiplier_generic #(
        .WIDTH_A(WIDTH_A),
        .WIDTH_B(WIDTH_B),
        .WIDTH_MUL(WIDTH_MUL),
        .MM_APPROX(MM_APPROX),
        .M_APPROX(M_APPROX),
        .MUL_TYPE(6),
        .SIGNED(0),
        .STAGE(0)
    ) M6 (
        .*,
        .OUT(OUT_6)
    );

    Multiplier_generic #(
        .WIDTH_A(WIDTH_A),
        .WIDTH_B(WIDTH_B),
        .WIDTH_MUL(WIDTH_MUL),
        .MM_APPROX(MM_APPROX),
        .M_APPROX(M_APPROX),
        .MUL_TYPE(7),
        .SIGNED(0),
        .STAGE(0)
    ) M7 (
        .*,
        .OUT(OUT_7)
    );

    Multiplier_generic #(
        .WIDTH_A(WIDTH_A),
        .WIDTH_B(WIDTH_B),
        .WIDTH_MUL(WIDTH_MUL),
        .MM_APPROX(MM_APPROX),
        .M_APPROX(M_APPROX),
        .MUL_TYPE(8),
        .SIGNED(0),
        .STAGE(0)
    ) M8 (
        .*,
        .OUT(OUT_8)
    );

    Multiplier_generic #(
        .WIDTH_A(WIDTH_A),
        .WIDTH_B(WIDTH_B),
        .WIDTH_MUL(WIDTH_MUL),
        .MM_APPROX(MM_APPROX),
        .M_APPROX(M_APPROX),
        .MUL_TYPE(9),
        .SIGNED(0),
        .STAGE(0)
    ) M9 (
        .*,
        .OUT(OUT_9)
    );

    initial begin

        clk = 0;
        rst_n = 0;
        pipeline_en = 1;

        $dumpfile("tb_multiplier_generic.vcd");
        $dumpvars(0, tb_multiplier_generic);

        #20 rst_n = 1;

        $monitor("\n===== t=%0t, Ideal: %0d BAM: %0d Booth0: %0d Booth1: %0d Booth2: %0d Log0: %0d Log1: %0d Wallace0: %0d Wallace1: %0d Wallace2: %0d",
            $time,
            $signed(OUT_0),
            $signed(OUT_1),
            $signed(OUT_2),
            $signed(OUT_3),
            $signed(OUT_4),
            $signed(OUT_5),
            $signed(OUT_6),
            $signed(OUT_7),
            $signed(OUT_8),
            $signed(OUT_9)
        );

        for(i = 0; i < 16; i = i + 1) begin
            for(j = 0; j < 16; j = j + 1) begin
                A = i;
                B = j;
                #10;
            end
        end

        #50 $finish;

    end

endmodule