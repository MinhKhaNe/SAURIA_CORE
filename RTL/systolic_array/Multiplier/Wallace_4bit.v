module Wallace_4bit #(
    parameter   APPROX = 0
)(
    input   wire    [3:0]   A,
    input   wire    [3:0]   B,

    output  wire    [7:0]   OUT
);

    wire    [1:0]   A1, A2, B1, B2;
    wire    [3:0]   A1_B1, A1_B2, A2_B1, A2_B2;
    wire    [3:0]   partial_1, partial_2, partial_3;

    assign  A1 = A[1:0];
    assign  A2 = A[3:2];
    assign  B1 = B[1:0];
    assign  B2 = B[3:2];

    Multiplier_2x2 #(
        .APPROX(APPROX)
    ) m0 (
        .A(A1),
        .B(B1),
        .OUT(A1_B1)         //Low BIT of OUTPUT
    );

    Multiplier_2x2 #(
        .APPROX(APPROX)
    ) m1 (
        .A(A1),
        .B(B2),
        .OUT(A1_B2)
    );

    Multiplier_2x2 #(
        .APPROX(APPROX)
    ) m2 (
        .A(A2),
        .B(B1),
        .OUT(A2_B1)
    );

    Multiplier_2x2 #(
        .APPROX(APPROX)
    ) m3 (
        .A(A2),
        .B(B2),
        .OUT(A2_B2)
    );

    assign  partial_1 = A1_B1[3:2] + A2_B1[1:0] + A1_B2[1:0];

    assign  partial_2 = partial_1[3:2] + A2_B1[3:2] + A1_B2[3:2] + A2_B2[1:0];

    assign  partial_3 = A2_B2[3:2] + partial_2[3:2];

    assign OUT = {partial_3[1:0], partial_2[1:0], partial_1[1:0], A1_B1[1:0]};

endmodule