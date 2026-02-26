`timescale 1ns/1ps

module tb_multiplier_bam;

  localparam WIDTH_A   = 8;
  localparam WIDTH_B   = 8;
  localparam WIDTH_OUT = 16;
  localparam STAGE     = 5;   

  localparam LATENCY = STAGE + 1;

  reg clk;
  reg rst_n;
  reg pip_en;
  reg  signed [WIDTH_A-1:0] A;
  reg  signed [WIDTH_B-1:0] B;
  wire signed [WIDTH_OUT-1:0] OUT;

  Multiplier_bam #(
    .WIDTH_A (WIDTH_A),
    .WIDTH_B (WIDTH_B),
    .WIDTH_OUT (WIDTH_OUT),
    .SIGNED (1),
    .VBL (0),
    .HBL (0),
    .STAGE (STAGE)
  ) dut (
    .clk   (clk),
    .rst_n (rst_n),
    .pip_en(pip_en),
    .A     (A),
    .B     (B),
    .OUT   (OUT)
  );

  // Clock
  always #5 clk = ~clk;

  // Queue lưu golden
  integer golden_q [$];

  // Task drive input
  task send;
    input signed [WIDTH_A-1:0] a;
    input signed [WIDTH_B-1:0] b;
    begin
      @(posedge clk);
      pip_en = 1;
      A = a;
      B = b;
      golden_q.push_back(a * b);
    end
  endtask

  // Check output theo pipeline
  always @(posedge clk) begin
    if (rst_n && pip_en) begin
      if (golden_q.size() > LATENCY) begin
        integer golden;
        golden = golden_q.pop_front();

        $display("A*B expected=%0d | OUT=%0d %s", golden, OUT, (OUT === golden) ? "OK" : "FAIL");

        if (OUT !== golden) begin
          $error("FAILED!!!!");
        end
      end
    end
  end

  initial begin
    $dumpfile("tb_multiplier_bam.vcd");
    $dumpvars(0, tb_multiplier_bam);

    clk    = 0;
    rst_n  = 0;
    pip_en = 0;
    A      = 0;
    B      = 0;

    repeat (3) @(posedge clk);
    rst_n = 1;

    // Basic tests
    send(5, 3);
    send(7, 2);
    send(15, 1);
    send(-5, 3);
    send(-5, -7);
    send(-1, 1);
    send(1, -1);

    // Random tests
    repeat (20) begin
      send($random, $random);
    end

    // Drain pipeline
    repeat (LATENCY + 2) @(posedge clk);
    $finish;
  end

endmodule
