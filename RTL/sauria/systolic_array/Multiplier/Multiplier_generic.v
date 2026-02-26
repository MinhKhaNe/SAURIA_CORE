module Multiplier_generic #(
    parameter   WIDTH_A     = 16,
    parameter   WIDTH_B     = 16,
    parameter   MM_APPROX   = 1,
    parameter   M_APPROX    = 1,
    parameter   MUL_TYPE    = 0,
    parameter   WIDTH_MUL   = WIDTH_A + WIDTH_B,
    parameter   SIGNED      = 0,
    parameter   STAGE       = 0
)(
    input   wire                    clk,
    input   wire                    rst_n,

    input   wire                    pipeline_en,
    input   wire    [WIDTH_A-1:0]   A,
    input   wire    [WIDTH_B-1:0]   B,

    output  wire    [WIDTH_MUL-1:0] OUT
);

    generate
        if(MUL_TYPE == 0) begin
            Multiplier_ideal #(
                .SIGNED(SIGNED),
                .WIDTH_A(WIDTH_A),
                .WIDTH_B(WIDTH_B),
                .WIDTH_MUL(WIDTH_MUL),
                .STAGE(STAGE)
            ) m0 (
                .clk(clk),
                .rst_n(rst_n),
                .pip_en(pipeline_en),
                .A(A),
                .B(B),
                .OUT(OUT)
            );
        end
        else if(MUL_TYPE == 1) begin
            Multiplier_bam #(
                .WIDTH_A(WIDTH_A),
                .WIDTH_B(WIDTH_B),
                .WIDTH_OUT(WIDTH_MUL),
                .SIGNED(SIGNED),
                .VBL(M_APPROX),
                .HBL(MM_APPROX),
                .STAGE(STAGE)
            ) m1 (
                .clk(clk),
                .rst_n(rst_n),
                .pip_en(pipeline_en),
                .A(A),
                .B(B),
                .OUT(OUT)
            );
        end
        else if(MUL_TYPE == 2) begin
            Multiplier_booth #(
                .APPROX_TYPE(0),
                .APPROX_W(M_APPROX),
                .WIDTH_A(WIDTH_A),
                .WIDTH_B(WIDTH_B),
                .WIDTH_MUL(WIDTH_MUL),
                .SIGNED(SIGNED),
                .STAGE(STAGE)
            ) m2 (
                .clk(clk),
                .rst_n(rst_n),
                .pip_en(pipeline_en),
                .A(A),
                .B(B),
                .OUT(OUT)
            );
        end
        else if(MUL_TYPE == 3) begin
            Multiplier_booth #(
                .APPROX_TYPE(1),
                .APPROX_W(M_APPROX),
                .WIDTH_A(WIDTH_A),
                .WIDTH_B(WIDTH_B),
                .WIDTH_MUL(WIDTH_MUL),
                .SIGNED(SIGNED),
                .STAGE(STAGE)
            ) m2 (
                .clk(clk),
                .rst_n(rst_n),
                .pip_en(pipeline_en),
                .A(A),
                .B(B),
                .OUT(OUT)
            );
        end
        else if(MUL_TYPE == 4) begin
            Multiplier_booth #(
                .APPROX_TYPE(2),
                .APPROX_W(M_APPROX),
                .WIDTH_A(WIDTH_A),
                .WIDTH_B(WIDTH_B),
                .WIDTH_MUL(WIDTH_MUL),
                .SIGNED(SIGNED),
                .STAGE(STAGE)
            ) m2 (
                .clk(clk),
                .rst_n(rst_n),
                .pip_en(pipeline_en),
                .A(A),
                .B(B),
                .OUT(OUT)
            );
        end
        else if(MUL_TYPE == 5) begin
            Multiplier_log #(
                .APPROX_TYPE(0),
                .APPROX_W(M_APPROX),
                .WIDTH_A(WIDTH_A),
                .WIDTH_B(WIDTH_B),
                .WIDTH_MUL(WIDTH_MUL),
                .SIGNED(SIGNED),
                .STAGE(STAGE)
            ) m3 (
                .clk(clk),
                .rst_n(rst_n),
                .pip_en(pipeline_en),
                .A(A),
                .B(B),
                .OUT(OUT)
            );
        end
        else if(MUL_TYPE == 6) begin
            Multiplier_log #(
                .APPROX_TYPE(1),
                .APPROX_W(M_APPROX),
                .WIDTH_A(WIDTH_A),
                .WIDTH_B(WIDTH_B),
                .WIDTH_MUL(WIDTH_MUL),
                .SIGNED(SIGNED),
                .STAGE(STAGE)
            ) m3 (
                .clk(clk),
                .rst_n(rst_n),
                .pip_en(pipeline_en),
                .A(A),
                .B(B),
                .OUT(OUT)
            );
        end
        else if(MUL_TYPE == 7) begin
            Multiplier_wallace #(
                .APPROX_TYPE(0),
                .APPROX_W(M_APPROX),
                .WIDTH_A(WIDTH_A),
                .WIDTH_B(WIDTH_B),
                .WIDTH_MUL(WIDTH_MUL),
                .SIGNED(SIGNED),
                .STAGE(STAGE)
            ) m3 (
                .clk(clk),
                .rst_n(rst_n),
                .pip_en(pipeline_en),
                .A(A),
                .B(B),
                .OUT(OUT)
            );
        end
        else if(MUL_TYPE == 8) begin
            Multiplier_wallace #(
                .APPROX_TYPE(1),
                .APPROX_W(M_APPROX),
                .WIDTH_A(WIDTH_A),
                .WIDTH_B(WIDTH_B),
                .WIDTH_MUL(WIDTH_MUL),
                .SIGNED(SIGNED),
                .STAGE(STAGE)
            ) m3 (
                .clk(clk),
                .rst_n(rst_n),
                .pip_en(pipeline_en),
                .A(A),
                .B(B),
                .OUT(OUT)
            );
        end
        else if(MUL_TYPE == 9) begin
            Multiplier_wallace #(
                .APPROX_TYPE(2),
                .APPROX_W(M_APPROX),
                .WIDTH_A(WIDTH_A),
                .WIDTH_B(WIDTH_B),
                .WIDTH_MUL(WIDTH_MUL),
                .SIGNED(SIGNED),
                .STAGE(STAGE)
            ) m3 (
                .clk(clk),
                .rst_n(rst_n),
                .pip_en(pipeline_en),
                .A(A),
                .B(B),
                .OUT(OUT)
            );
        end
    endgenerate

endmodule
