module Adder_generic #(
    parameter   WIDTH_A         = 16,
    parameter   WIDTH_B         = 16,
    parameter   WIDTH_OUT       = 16,
    parameter   AA_APPROX       = 1,
    parameter   A_APPROX        = 1,
    parameter   ADD_TYPE        = 0,
    parameter   SIGNED          = 0
)(
    input   wire    [WIDTH_A-1:0]   A,
    input   wire    [WIDTH_B-1:0]   B,
    input   wire                    Carry,

    output  wire    [WIDTH_OUT-1:0] OUT

);

    generate
        if(ADD_TYPE == 0) begin
            Adder_ideal #(
                .WIDTH_A(WIDTH_A),
                .WIDTH_B(WIDTH_B)
            ) a0 (
                .A(A),
                .B(B),
                .Carry(Carry),
                .OUT(OUT)
            );
        end
        else if(ADD_TYPE == 1) begin
            Adder_gear #(
                .R(A_APPROX),
                .P(AA_APPROX),
                .WIDTH_A(WIDTH_A),
                .WIDTH_B(WIDTH_B)
            ) a1 (
                .A(A),
                .B(B),
                .Carry(Carry),
                .OUT(OUT)
            );
        end
        else if(ADD_TYPE == 2) begin
            Adder_gear_2c #(
                .R(A_APPROX),
                .P(AA_APPROX),
                .WIDTH_A(WIDTH_A),
                .WIDTH_B(WIDTH_B)
            ) a2 (
                .A(A),
                .B(B),
                .Carry(Carry),
                .OUT(OUT)
            );
        end
        else if(ADD_TYPE == 3) begin
            Adder_loa #(
                .IGNORE_BIT(A_APPROX),
                .WIDTH_A(WIDTH_A),
                .WIDTH_B(WIDTH_B)
            ) a3 (
                .A(A),
                .B(B),
                .Carry(Carry),
                .OUT(OUT)
            );
        end
        else if(ADD_TYPE == 4) begin
            Adder_trua #(
                .IGNORE_BIT(A_APPROX),
                .WIDTH_A(WIDTH_A),
                .WIDTH_B(WIDTH_B)
            ) a4 (
                .A(A),
                .B(B),
                .Carry(Carry),
                .OUT(OUT)
            );
        end
        else if(ADD_TYPE == 5) begin
            Adder_truah #(
                .IGNORE_BIT(A_APPROX),
                .WIDTH_A(WIDTH_A),
                .WIDTH_B(WIDTH_B)
            ) a4 (
                .A(A),
                .B(B),
                .Carry(Carry),
                .OUT(OUT)
            );
        end
    endgenerate

endmodule
