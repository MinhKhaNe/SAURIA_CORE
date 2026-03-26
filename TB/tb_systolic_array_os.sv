module tb_systolic_array_os;

    localparam  WIDTH_A                     = 16;
    localparam  WIDTH_B                     = 16;
    localparam  WIDTH_MAC                   = 48;
    localparam  WIDTH_T                     = 2;
    localparam  ZERO_GATING_MULT            = 1;
    localparam  ZERO_GATING_ADD             = 1;
    localparam  MM_APPROX                   = 1;
    localparam  M_APPROX                    = 1;
    localparam  AA_APPROX                   = 3;
    localparam  A_APPROX                    = 3;
    localparam  MUL_TYPE                    = 0;    //0. Ideal, 1.Bam, 2.3.4. Booth, 5.6. Log, 7.8.9 Wallace
    localparam  ADD_TYPE                    = 2;    //0. Ideal, 1. Gear, 2. Gear_2c, 3. Loa, 4. Trua, 5. Truah
    localparam  STAGE                       = 0;
    localparam  ARITHMETIC                  = 0;
    localparam  SIGNED                      = 1;
    localparam  INTERMEDIATE_PIPELINE_STAGE = 0;
    localparam  X_AXIS                      = 3;
    localparam  Y_AXIS                      = 3;

    logic                   clk;
    logic                   rst_n;
    logic   [WIDTH_A-1:0]   act [0:Y_AXIS-1];
    logic   [WIDTH_B-1:0]   wei [0:X_AXIS-1];
    logic   [WIDTH_MAC-1:0] MAC_in [0:Y_AXIS-1];

    logic                   pipeline_en;
    logic                   reg_clear;
    logic                   cell_en;
    logic                   cell_sc_en;
    logic                   c_switch;
    logic                   cscan_en;
    logic   [WIDTH_T-1:0]   Thres;

    // Outputs
    logic                   cell_out;
    logic                   c_switch_out;
    logic   [WIDTH_MAC-1:0] MAC_out [0:Y_AXIS-1][0:X_AXIS-1];

    initial begin
        clk = 0;
        forever #25 clk = ~clk;
    end

    systolic_array #(
        .WIDTH_A(WIDTH_A),
        .WIDTH_B(WIDTH_B),
        .WIDTH_MAC(WIDTH_MAC),
        .WIDTH_T(WIDTH_T),
        .ZERO_GATING_MULT(ZERO_GATING_MULT),
        .ZERO_GATING_ADD(ZERO_GATING_ADD),
        .MM_APPROX(MM_APPROX),
        .M_APPROX(M_APPROX),
        .AA_APPROX(AA_APPROX),
        .A_APPROX(A_APPROX),
        .MUL_TYPE(MUL_TYPE),
        .ADD_TYPE(ADD_TYPE),
        .STAGE(STAGE),
        .ARITHMETIC(ARITHMETIC),
        .SIGNED(SIGNED),
        .INTERMEDIATE_PIPELINE_STAGE(INTERMEDIATE_PIPELINE_STAGE),
        .x_axis(X_AXIS),
        .y_axis(Y_AXIS),
        .PE_TYPE(0)      
    ) DUT (
        .clk(clk),
        .rst_n(rst_n),
        .act(act),
        .wei(wei),
        .MAC_IN(MAC_in),
        .pipeline_en(pipeline_en),
        .reg_clear(reg_clear),
        .cell_en(cell_en),
        .cell_sc_en(cell_sc_en),
        .c_switch(c_switch),     
        .cscan_en(cscan_en),      
        .Thres(Thres),            
        .cell_out(cell_out),      
        .c_switch_out(c_switch_out), 
        .MAC_out(MAC_out)
    );

    task automatic check_result;
        input   logic   [15:0]  actual;
        input   logic   [15:0]  expected;

        if(actual != expected) begin
            $display("===== t=%0t FAILED! Values do not match, Expected Result: %0h, Actual Result: %0h =====", $time, expected, actual);
        end
        else begin
            $display("===== t=%0t PASSED SUCCESSFULLY!!! =====", $time);
        end
    endtask

    //Array 1:  [1, 2][3, 4]
    //Array 2:  [5, 6][7, 8]
    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, tb_systolic_array_os);

        //Clear values
        foreach(act[i]) act[i] = 0;
        foreach(wei[i]) wei[i] = 0;
        foreach(MAC_in[i]) MAC_in[i] = 0;
        
        // $monitor("\nValue of 1st PE is: %d, \nValue of 2nd PE is %d, \nValue of 3rd PE is %d, \nValue of 4th PE is %d, \nValue of 5th PE is: %d, \nValue of 6th PE is %d, \nValue of 7th PE is %d, \nValue of 8th PE is %d, \nValue of 9th PE is %d", 
        //         MAC_out[0][0], MAC_out[0][1], MAC_out[0][2], MAC_out[1][0], MAC_out[1][1], MAC_out[1][2], MAC_out[2][0], MAC_out[2][1], MAC_out[2][2]);

        $monitor("\n===== t=%0t =====\n [%d] [%d] [%d] \n [%d] [%d] [%d] \n [%d] [%d] [%d]", $time,
                MAC_out[0][0], MAC_out[0][1], MAC_out[0][2], 
                MAC_out[1][0], MAC_out[1][1], MAC_out[1][2], 
                MAC_out[2][0], MAC_out[2][1], MAC_out[2][2]);

        rst_n = 0;

        @(posedge clk);
        rst_n = 1; pipeline_en = 1; reg_clear = 0; cell_en = 1; cell_sc_en = 1; c_switch = 1; cscan_en = 0; Thres = 0;

        //[1 4 7]     [1 2 3]
        //[2 5 8]     [4 5 6] 
        //[3 6 9]     [7 8 9]
        @(posedge clk); #1;
        act[0] = -16'sd2; act[1] = 16'sd0; act[2] = 16'sd0;
        wei[0] = 16'sd3; wei[1] = 16'sd0; wei[2] = 16'sd0;

        @(posedge clk); #1;
        act[0] = 16'sd6; act[1] = -16'sd4; act[2] = 16'sd0;
        wei[0] = -16'sd7; wei[1] = 16'sd5; wei[2] = 16'sd0;

        @(posedge clk); #1;
        act[0] = -16'sd5; act[1] = -16'sd8; act[2] = -16'sd22;
        wei[0] = 16'sd2; wei[1] = 16'sd9; wei[2] = 16'sd3;

        @(posedge clk); #1;
        act[0] = 16'sd0; act[1] = -16'sd4; act[2] = -16'sd2;
        wei[0] = 16'sd0; wei[1] = 16'sd5; wei[2] = 16'sd7;

        @(posedge clk); #1;
        act[0] = 16'sd0; act[1] = 16'sd0; act[2] = 16'sd8;
        wei[0] = 16'sd0; wei[1] = 16'sd0; wei[2] = -16'sd5;
        
        //Reset Data IN
        @(posedge clk);
        foreach(act[i]) act[i]=0;
        foreach(wei[i]) wei[i]=0;

        repeat(20) @(posedge clk);

        $finish;

    end
endmodule