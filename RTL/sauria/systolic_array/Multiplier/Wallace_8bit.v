module Wallace_8bit #(
    parameter   APPROX = 0
)(
    input   wire    [7:0]   A,
    input   wire    [7:0]   B,

    output  wire    [15:0]   OUT
);

    wire    [3:0]   A1, A2, B1, B2;
    wire    [7:0]   A1_B1, A1_B2, A2_B1, A2_B2;
    wire    [7:0]   partial_1, partial_2, partial_3;

    assign  A1 = A[3:0];
    assign  A2 = A[7:4];
    assign  B1 = B[3:0];
    assign  B2 = B[7:4];

    Wallace_4bit #(
        .APPROX(APPROX)
    ) m0 (
        .A(A1),
        .B(B1),
        .OUT(A1_B1)         //Low BIT of OUTPUT
    );

    Wallace_4bit #(
        .APPROX(APPROX)
    ) m1 (
        .A(A1),
        .B(B2),
        .OUT(A1_B2)
    );

    Wallace_4bit #(
        .APPROX(APPROX)
    ) m2 (
        .A(A2),
        .B(B1),
        .OUT(A2_B1)
    );

    Wallace_4bit #(
        .APPROX(APPROX)
    ) m3 (
        .A(A2),
        .B(B2),
        .OUT(A2_B2)
    );

    assign  partial_1 = A1_B1[7:4] + A2_B1[3:0] + A1_B2[3:0];

    assign  partial_2 = partial_1[7:4] + A2_B1[7:4] + A1_B2[7:4] + A2_B2[4:0];

    assign  partial_3 = A2_B2[7:4] + partial_2[7:4];

    assign OUT = {partial_3[3:0], partial_2[3:0], partial_1[3:0], A1_B1[3:0]};

endmodule