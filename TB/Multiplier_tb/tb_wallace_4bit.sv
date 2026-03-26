module tb_wallace_4bit;

    localparam APPROX = 0;
    logic   [3:0]   A, B;
    logic   [7:0]   OUT, GOLDEN;

    Wallace_4bit #(
        .APPROX(APPROX)
    ) dut (
        .A(A),
        .B(B),
        .OUT(OUT)
    );

    initial begin
        for(int i=0; i<16; i++) begin
            for(int j=0; j<16; j++) begin
                A = i[3:0]; B = j[3:0];
                GOLDEN = i[3:0] * j[3:0];
                #1;
                if(OUT !== GOLDEN) begin
                    $display("t=%0t FAILED!!! Expected result is %b, Acutal result is %b",$time, GOLDEN, OUT);
                end
                else begin
                    $display("t=%0t PASSED SUCCESSFULLY!!! Expected result is %b, Acutal result is %b",$time, GOLDEN, OUT);
                end
            end
        end

        $stop;
    end

endmodule