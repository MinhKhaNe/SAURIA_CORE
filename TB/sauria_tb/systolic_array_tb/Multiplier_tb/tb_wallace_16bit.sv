module tb_wallace_16bit;

    localparam APPROX = 0;
    logic   [15:0]   A, B;
    logic   [31:0]   OUT, GOLDEN;

    Wallace_8bit #(
        .APPROX(APPROX)
    ) dut (
        .A(A),
        .B(B),
        .OUT(OUT)
    );

    initial begin
        for(int i=0; i<1024; i++) begin
            for(int j=0; j<1024; j++) begin
                A = i[15:0]; B = j[15:0];
                GOLDEN = i[15:0] * j[15:0];
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