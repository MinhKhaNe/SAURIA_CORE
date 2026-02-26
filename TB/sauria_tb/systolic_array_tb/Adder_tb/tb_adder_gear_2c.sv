module tb_adder_gear_2c();

    parameter R     = 4;   
    parameter P     = 4;   
    parameter IP_W  = 16;  
    parameter OC_W  = 16; 

    logic [IP_W-1:0] i_p;
    logic [OC_W-1:0] i_c;
    logic            i_carry;
    logic [OC_W-1:0] o_c;
    logic [OC_W-1:0] expected_sum;

    Adder_gear_2c #(
        .R(R),
        .P(P),
        .WIDTH_A(IP_W),
        .WIDTH_B(OC_W)
    ) dut (
        .A(i_p),
        .B(i_c),
        .Carry(i_carry),
        .OUT(o_c)
    );

    initial begin
        $dumpfile("adder_gear.vcd"); 
        $dumpvars(0, tb_adder_gear_2c);
        i_carry = 1'b0;
        i_p = 16'h0005; i_c = 16'h000A;
        #10;
        check_result();
        i_p = 16'h0FFF; i_c = 16'h0001;
        #10;
        check_result();
        i_p = -16'd10; i_c = 16'd5;
        #10;
        check_result();
        $display("===== Running 20 random tests =====");
        repeat (20) begin
            i_p = $urandom();
            i_c = $urandom();
            #10;
            check_result();
        end
        
        $display("\n===== Running Signed Number Cases =====");
        i_p = 16'sd20;   i_c = -16'sd5;
        #10; check_result();
        i_p = 16'sd10;   i_c = -16'sd30;
        #10; check_result();
        i_p = -16'sd100; i_c = -16'sd50;
        #10; check_result();
        i_p = 16'sh8000; i_c = 16'sd1;
        #10; check_result();
        i_p = -16'sd1234; i_c = 16'sd1234;
        #10; check_result();
        i_p = -16'sd1; i_c = 16'sd1;
        #10; check_result();
        i_p = -16'sd20000; i_c = -16'sd20000;
        #10; check_result();
        i_p = 16'sh8000; i_c = 16'sh8000;
        #10; check_result();
        i_p = 16'sd32767; i_c = -16'sd32767;
        #10; check_result();
        i_p = -16'sd1; i_c = -16'sd1;
        #10; check_result();
        i_p = 16'sd32767; i_c = 16'sd1;
        #10; check_result();
        i_p = -16'sd54321; i_c = 16'sd0;
        #10; check_result();

        $finish;
    end

    task check_result;
        begin
            expected_sum = i_p + i_c;
            if (o_c === expected_sum) begin
                $display("[PASS] %16b + %16b= %16b", i_p, i_c, o_c);
            end else begin
                $display("[FAIL/WARN] %16b + %16b | Expected:%16b | Got: %16b (Diff: %16b)", 
                          i_p, i_c, expected_sum, o_c, (expected_sum - o_c));
            end
        end
    endtask

endmodule
