`define NEGLIGENCE
`define FLOAT
//`define SIGNED

module  Zero_detection #(
    parameter   WIDTH_A = 16,
    parameter   WIDTH_B = 16,
    parameter   WIDTH_T = 2
)(
    input   wire   [WIDTH_A-1:0]    A,
    input   wire   [WIDTH_B-1:0]    B,

    input   wire   [WIDTH_T-1:0]    Thres,

    output  wire                    Zero
);
    parameter   EXP_W           = 5;
    parameter   exponent_max    = WIDTH_A-2;
    parameter   exponent_min    = WIDTH_A-EXP_W-1;


    wire                                    Zero_exact;
    wire                                    a_chk, b_chk, neg_chk;
    reg     [WIDTH_A-1:0]                   A_zero, A_one;
    reg     [WIDTH_B-1:0]                   B_zero, B_one;
    reg     [exponent_max:exponent_min]     A_exp, B_exp;
    wire                                    Threshold;
    integer                                 i,j,k,m;

    assign  Zero_exact  =   ((A==0) || (B==0))  ? 1 : 0;

//    `ifdef NEGLIGENCE
//            assign A_thres = {A[WIDTH_A-1:Thres],{Thres{1'b0}}};
//            assign B_thres = {B[WIDTH_B-1:Thres],{Thres{1'b0}}};
//    `endif

    `ifdef NEGLIGENCE

        `ifdef SIGNED
            always @(*) begin
                if(Thres != 0) begin
                    A_zero = A;
                    A_one  = A;
                    for(j = 1; j < WIDTH_A; j = j + 1) begin
                        if (j < Thres) begin
                            A_zero[j] = 1'b0;
                            A_one[j]  = 1'b1;
                        end 
                        else begin
                            A_zero[j] = A[j];
                            A_one[j]  = A[j];
                        end
                    end
                end
                else begin
                    A_zero  = {WIDTH_A{1'b1}};
                    A_one   = {WIDTH_A{1'b0}};
                end
            end

            always @(*) begin
                if(Thres != 0) begin
                    B_zero = B;
                    B_one  = B;
                    for(k = 1; k < WIDTH_B; k = k + 1) begin
                        if (k < Thres) begin
                            B_zero[k] = 1'b0;
                            B_one[k]  = 1'b1;
                        end 
                        else begin
                            B_zero[k] = B[k];
                            B_one[k]  = B[k];
                        end
                    end
                end
                else begin
                    B_zero  = {WIDTH_B{1'b1}};
                    B_one   = {WIDTH_B{1'b0}};
                end
            end

            assign  a_chk   = (A_zero == {WIDTH_A{1'b0}}) || (A_one == {WIDTH_A{1'b1}});
            assign  b_chk   = (B_zero == {WIDTH_B{1'b0}}) || (B_one == {WIDTH_B{1'b1}});
            assign  neg_chk = a_chk & b_chk;

        `elsif FLOAT

            always @(*) begin
                if (Thres != 0) begin
                    A_exp   = A[exponent_max:exponent_min];
                    B_exp   = B[exponent_max:exponent_min];
                    for (m = exponent_min; m <= exponent_max && m < exponent_min + Thres; m = m + 1) begin
                        A_exp[m]    = 1'b0;
                        B_exp[m]    = 1'b0;
                    end
                end
                else begin
                    A_exp   = {(exponent_max-exponent_min+1){1'b1}};
                    B_exp   = {(exponent_max-exponent_min+1){1'b1}};
                end
            end

            assign  a_chk   = (A_exp == {(exponent_max-exponent_min+1){1'b0}});
            assign  b_chk   = (B_exp == {(exponent_max-exponent_min+1){1'b0}});
            assign  neg_chk = a_chk & b_chk;
        `else
            assign neg_chk = 1'b0;

        `endif

        assign Zero = Zero_exact | neg_chk;

    `else

        assign Zero = Zero_exact;

    `endif

endmodule