`timescale 1ns/1ps

module tb_pe_is;

//////////////////////////////////////////////////
// PARAMETERS
//////////////////////////////////////////////////

localparam WIDTH_A   = 16;
localparam WIDTH_B   = 16;
localparam WIDTH_MAC = 48;

//////////////////////////////////////////////////
// CLOCK
//////////////////////////////////////////////////

reg clk;
initial clk = 0;
always #5 clk = ~clk;

//////////////////////////////////////////////////
// RESET
//////////////////////////////////////////////////

reg rst_n;
initial begin
    rst_n = 0;
    #25;
    rst_n = 1;
end

//////////////////////////////////////////////////
// INPUT STREAM
//////////////////////////////////////////////////

reg  [WIDTH_A-1:0] act_in;
reg                 sc_in;

//////////////////////////////////////////////////
// COMMON SIGNALS
//////////////////////////////////////////////////

wire pipeline_en = 1'b1;
wire reg_clear   = 1'b0;
wire cell_en     = 1'b1;
wire c_switch    = 1'b0;
wire cscan_en    = 1'b0;

//////////////////////////////////////////////////
// DEBUG DATA (different per PE)
//////////////////////////////////////////////////

wire [WIDTH_B-1:0] wei0 = 16'h0101;
wire [WIDTH_B-1:0] wei1 = 16'h0202;
wire [WIDTH_B-1:0] wei2 = 16'h0303;

wire [WIDTH_MAC-1:0] mac0_in = 48'h000000000001;
wire [WIDTH_MAC-1:0] mac1_in = 48'h000000000002;
wire [WIDTH_MAC-1:0] mac2_in = 48'h000000000003;

//////////////////////////////////////////////////
// PE CONNECTIONS
//////////////////////////////////////////////////

wire [WIDTH_A-1:0] act_0_out, act_1_out;
wire sc_0_out, sc_1_out;

wire [WIDTH_A-1:0] act_reg0, act_reg1, act_reg2;

wire [WIDTH_MAC-1:0] mac0_out, mac1_out, mac2_out;

//////////////////////////////////////////////////
// PE0
//////////////////////////////////////////////////

processing_element_is #(
    .WIDTH_A(WIDTH_A),
    .WIDTH_B(WIDTH_B),
    .WIDTH_MAC(WIDTH_MAC),
    .STAGE(0)
) PE0 (

    .clk(clk),
    .rst_n(rst_n),

    .act(act_in),
    .wei(wei0),
    .MAC_IN(mac0_in),

    .pipeline_en(pipeline_en),
    .reg_clear(reg_clear),
    .cell_en(cell_en),
    .cell_sc_en(sc_in),

    .c_switch(c_switch),
    .cscan_en(cscan_en),
    .Thres(0),

    .cell_out(sc_0_out),
    .c_switch_out(),

    .act_reg_out(act_reg0),
    .wei_out(),
    .act_out(act_0_out),
    .MAC_out(mac0_out)
);

//////////////////////////////////////////////////
// PE1
//////////////////////////////////////////////////

processing_element_is #(
    .WIDTH_A(WIDTH_A),
    .WIDTH_B(WIDTH_B),
    .WIDTH_MAC(WIDTH_MAC),
    .STAGE(0)
) PE1 (

    .clk(clk),
    .rst_n(rst_n),

    .act(act_0_out),
    .wei(wei1),
    .MAC_IN(mac0_out),

    .pipeline_en(pipeline_en),
    .reg_clear(reg_clear),
    .cell_en(cell_en),
    .cell_sc_en(sc_0_out),

    .c_switch(c_switch),
    .cscan_en(cscan_en),
    .Thres(0),

    .cell_out(sc_1_out),
    .c_switch_out(),

    .act_reg_out(act_reg1),
    .wei_out(),
    .act_out(act_1_out),
    .MAC_out(mac1_out)
);

//////////////////////////////////////////////////
// PE2
//////////////////////////////////////////////////

processing_element_is #(
    .WIDTH_A(WIDTH_A),
    .WIDTH_B(WIDTH_B),
    .WIDTH_MAC(WIDTH_MAC),
    .STAGE(0)
) PE2 (

    .clk(clk),
    .rst_n(rst_n),

    .act(act_1_out),
    .wei(wei2),
    .MAC_IN(mac1_out),

    .pipeline_en(pipeline_en),
    .reg_clear(reg_clear),
    .cell_en(cell_en),
    .cell_sc_en(sc_1_out),

    .c_switch(c_switch),
    .cscan_en(cscan_en),
    .Thres(0),

    .cell_out(),
    .c_switch_out(),

    .act_reg_out(act_reg2),
    .wei_out(),
    .act_out(),
    .MAC_out(mac2_out)
);

//////////////////////////////////////////////////
// STIMULUS
//////////////////////////////////////////////////

initial begin
    act_in = 0;
    sc_in  = 0;

    @(posedge rst_n);
    repeat(2) @(posedge clk);

    // start scan chain
    sc_in = 1;

    act_in = 16'hA0; @(posedge clk);
    act_in = 16'hA1; @(posedge clk);
    act_in = 16'hA2; @(posedge clk);
    act_in = 16'hA3; @(posedge clk);
    act_in = 16'hA4; @(posedge clk);
    act_in = 16'hA5; @(posedge clk);

    sc_in = 0;

    repeat(10) @(posedge clk);

    $finish;
end

//////////////////////////////////////////////////
// MONITOR
//////////////////////////////////////////////////

always @(posedge clk) begin
    if(rst_n) begin
        $display(
"\nT=%0t | IN=%h | sc=%b%b%b || PE0[A=%h W=%h MAC_IN=%h MAC_OUT=%h] || PE1[A=%h W=%h MAC_IN=%h MAC_OUT=%h] || PE2[A=%h W=%h MAC_IN=%h MAC_OUT=%h]",
            $time,
            act_in,
            sc_1_out,
            sc_0_out,
            sc_in,

            act_reg0, wei0, mac0_in, mac0_out,
            act_reg1, wei1, mac0_out, mac1_out,
            act_reg2, wei2, mac1_out, mac2_out
        );
    end
end

endmodule