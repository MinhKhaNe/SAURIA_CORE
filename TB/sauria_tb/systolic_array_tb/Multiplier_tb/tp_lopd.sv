`timescale 1ns/1ps

module tb_lopd;

    localparam WIDTH_I = 16;
    localparam WIDTH_L = $clog2(WIDTH_I);

    reg  [WIDTH_I-1:0] in;
    wire [WIDTH_L-1:0] out;

    lopd #(
        .WIDTH_I(WIDTH_I),
        .WIDTH_L(WIDTH_L)
    ) dut (
        .in(in),
        .out(out)
    );

    task check;
        input [WIDTH_I-1:0] value;
        integer i;
        reg [WIDTH_L-1:0] golden;
    begin
        in = value;
        #1;

        golden = 0;
        for (i = 0; i < WIDTH_I; i = i + 1)
            if (value[i])
                golden = i;

        $display("IN = %b | OUT = %0d | GOLD = %0d %s",
                 in, out, golden,
                 (out === golden) ? "OK" : "FAIL");

        if (out !== golden)
            $stop;
    end
    endtask

    initial begin
        $dumpfile("tb_lopd.vcd");
        $dumpvars(0, tb_lopd);

        check(16'b0000_0000_0000_0001);
        check(16'b0000_0000_0000_1000);
        check(16'b0000_0001_0100_0000);
        check(16'b1000_0000_0000_0000);

        check(16'b0000_0000_1111_0000);
        check(16'b0101_0101_0101_0101);

        check(16'b0);

        repeat (20)
            check($random);

        $display("=== ALL TEST PASSED ===");
        $finish;
    end

endmodule
