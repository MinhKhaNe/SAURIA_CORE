module Wallace_16bit #(
    parameter   APPROX = 0
)(
    input   wire    [15:0]   A,
    input   wire    [15:0]   B,

    output  wire    [31:0]   OUT        //only low bit right
);

    wire    [7:0]    A1, A2, B1, B2;
    wire    [15:0]   A1_B1, A1_B2, A2_B1, A2_B2;
    wire    [15:0]   partial_1, partial_2, partial_3;

    assign  A1 = A[7:0];
    assign  A2 = A[15:8];
    assign  B1 = B[7:0];
    assign  B2 = B[15:8];

    Wallace_8bit #(
        .APPROX(APPROX)
    ) m0 (
        .A(A1),
        .B(B1),
        .OUT(A1_B1)         //Low BIT of OUTPUT
    );

    Wallace_8bit #(
        .APPROX(APPROX)
    ) m1 (
        .A(A1),
        .B(B2),
        .OUT(A1_B2)
    );

    Wallace_8bit #(
        .APPROX(APPROX)
    ) m2 (
        .A(A2),
        .B(B1),
        .OUT(A2_B1)
    );

    Wallace_8bit #(
        .APPROX(APPROX)
    ) m3 (
        .A(A2),
        .B(B2),
        .OUT(A2_B2)
    );
    
    //Carry region between partial products
    assign  partial_1 = A1_B1[15:8] + A2_B1[7:0] + A1_B2[7:0];
    //Combine next aligned bytes
    assign  partial_2 = partial_1[15:8] + A2_B1[15:8] + A1_B2[15:8] + A2_B2[7:0];
    //Highest carry region
    assign  partial_3 = A2_B2[15:8] + partial_2[15:8];
    //Final product
    assign OUT = {partial_3[7:0], partial_2[7:0], partial_1[7:0], A1_B1[7:0]};

endmodule
