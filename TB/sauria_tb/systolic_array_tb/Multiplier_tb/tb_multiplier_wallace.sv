module tb_multiplier_wallace;

    localparam APPROX = 0;
    localparam WIDTH_A = 16;
    localparam WIDTH_B = 16;
    localparam WIDTH_MUL = WIDTH_A + WIDTH_B;
    
    logic   [WIDTH_A-1:0]   A;
    logic   [WIDTH_B-1:0]   B;
    logic   [WIDTH_MUL-1:0] OUT;
    logic   [WIDTH_MUL-1:0] GOLDEN;
    logic                   clk, rst_n;
    integer                 PASS, FAIL;

    Multiplier_wallace #(
        .APPROX(APPROX)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .A(A),
        .B(B),
        .OUT(OUT)
    );

    initial begin
        clk = 0;
        forever #25 clk = ~clk;
    end

    initial begin
        PASS = 0; FAIL = 0;
        rst_n = 0;
        #10;
        rst_n = 1;
        for(int i=0; i<1024; i++) begin
            for(int j=0; j<1024; j++) begin
                A = i[15:0]; B = j[15:0];
                GOLDEN = i[15:0] * j[15:0];
                @(posedge clk);
                #1;
                if(OUT !== GOLDEN) begin
                    $display("t=%0t FAILED!!! Expected result is %b, Acutal result is %b",$time, GOLDEN, OUT);
                    PASS = PASS + 1;
                end
                else begin
                    $display("t=%0t PASSED SUCCESSFULLY!!! Expected result is %b, Acutal result is %b",$time, GOLDEN, OUT);
                    FAIL = FAIL + 1;
                end
            end
        end
        $display("Pass = %d, FAILED = %d",PASS,FAIL);
        $stop;
    end

endmodule