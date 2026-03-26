`timescale 1ns/1ps

module tb_adder_generic;

    localparam int WIDTH_A      = 4;
    localparam int WIDTH_B      = 8;
    localparam int AA_APPROX    = 4;
    localparam int A_APPROX     = 4;

    localparam int WIDTH_OUT = (WIDTH_A > WIDTH_B) ? WIDTH_A : WIDTH_B;


    logic   [WIDTH_A-1:0]   A;
    logic   [WIDTH_B-1:0]   B;
    logic                   Carry;

    logic   [WIDTH_OUT-1:0] OUT_0, OUT_1, OUT_2;
    logic   [WIDTH_OUT-1:0] OUT_3, OUT_4, OUT_5;

    integer i, j;

    Adder_generic #(
        .WIDTH_A(WIDTH_A),
        .WIDTH_B(WIDTH_B),
        .WIDTH_OUT(WIDTH_OUT),
        .AA_APPROX(AA_APPROX),
        .A_APPROX(A_APPROX),
        .ADD_TYPE(0),
        .SIGNED(0)
    ) A0 (  
        .*,
        .OUT(OUT_0)
    );

    Adder_generic #(
        .WIDTH_A(WIDTH_A),
        .WIDTH_B(WIDTH_B),
        .WIDTH_OUT(WIDTH_OUT),
        .AA_APPROX(AA_APPROX),
        .A_APPROX(A_APPROX),
        .ADD_TYPE(1),
        .SIGNED(0)
    ) A1 (
        .*,
        .OUT(OUT_1)
    );

    Adder_generic #(
        .WIDTH_A(WIDTH_A),
        .WIDTH_B(WIDTH_B),
        .WIDTH_OUT(WIDTH_OUT),
        .AA_APPROX(AA_APPROX),
        .A_APPROX(A_APPROX),
        .ADD_TYPE(2),
        .SIGNED(0)
    ) A2 (
        .*,
        .OUT(OUT_2)
    );

    Adder_generic #(
        .WIDTH_A(WIDTH_A),
        .WIDTH_B(WIDTH_B),
        .WIDTH_OUT(WIDTH_OUT),
        .AA_APPROX(AA_APPROX),
        .A_APPROX(A_APPROX),
        .ADD_TYPE(3),
        .SIGNED(0)
    ) A3 (
        .*,
        .OUT(OUT_3)
    );

    Adder_generic #(
        .WIDTH_A(WIDTH_A),
        .WIDTH_B(WIDTH_B),
        .WIDTH_OUT(WIDTH_OUT),
        .AA_APPROX(AA_APPROX),
        .A_APPROX(A_APPROX),
        .ADD_TYPE(4),
        .SIGNED(0)
    ) A4 (
        .*,
        .OUT(OUT_4)
    );

    Adder_generic #(
        .WIDTH_A(WIDTH_A),
        .WIDTH_B(WIDTH_B),
        .WIDTH_OUT(WIDTH_OUT),
        .AA_APPROX(AA_APPROX),
        .A_APPROX(A_APPROX),
        .ADD_TYPE(5),
        .SIGNED(0)
    ) A5 (
        .*,
        .OUT(OUT_5)
    );


    initial begin

        $dumpfile("tb_adder_generic.vcd");
        $dumpvars(0, tb_adder_generic);
        
        $monitor("\n===== t=%0t, Adder Ideal:%0d, Adder Gear:%0d, Adder Gear 2c:%0d, Adder Loa:%0d, Adder Trua:%0d, Adder Truah:%0d =====", 
                $time, $signed(OUT_0), $signed(OUT_1), $signed(OUT_2), $signed(OUT_3), $signed(OUT_4), $signed(OUT_5));

        for(i=0; i<16; i=i+1) begin
            for(j=0; j<16; j=j+1) begin
                A = i; B = j; Carry = 0;
                #1;
            end
        end

        #20 $finish;
    end

endmodule

