module tb_systolic_array_ws;

    localparam  WIDTH_A                     = 16;
    localparam  WIDTH_B                     = 16;
    localparam  WIDTH_MAC                   = 48;
    localparam  WIDTH_T                     = 2;
    localparam  ZERO_GATING_MULT            = 1;
    localparam  ZERO_GATING_ADD             = 1;
    localparam  MM_APPROX                   = 1;
    localparam  M_APPROX                    = 1;
    localparam  AA_APPROX                   = 1;
    localparam  A_APPROX                    = 1;
    localparam  MUL_TYPE                    = 0;    //0. Ideal, 1.Bam, 2.3.4. Booth, 5.6. Log, 7.8.9 Wallace
    localparam  ADD_TYPE                    = 0;    //0. Ideal, 1. Gear, 2. Gear_2c, 3. Loa, 4. Trua, 5. Truah
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
        .PE_TYPE(2)      
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
        $dumpvars(0, tb_systolic_array_ws);

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

        $display("\n===== Case 1: Reset Chk =====");
        rst_n = 0; pipeline_en = 1; reg_clear = 0; cell_en = 1; cell_sc_en = 1; c_switch = 1; cscan_en = 1; Thres = 0;

        @(posedge clk);
        #1;
        wei[0] = 16'h5; wei[1] = 16'h7; wei[2] = 16'h0;
        act[0] = 16'h1; act[1] = 16'h2; act[2] = 16'h0;

        @(posedge clk);
        #1;
        wei[0] = 16'h6; wei[1] = 16'h8; wei[2]  = 16'h0;
        act[0] = 16'h3; act[1] = 16'h4; act[2] = 16'h0;

        @(posedge clk);
        foreach(act[i]) act[i]=0;
        foreach(wei[i]) wei[i]=0;

        //[3 1]     [7 8]
        //[4 2]     [5 6]
        @(posedge clk);
        #1;
        $display("\n===== Case 2: Reset Off Chk =====");
        rst_n = 1; cell_sc_en = 1;
        
        wei[0] = 16'd7; wei[1] = 16'd8; wei[2] = 16'd0; 
        @(posedge clk); #1;

        wei[0] = 16'd5; wei[1] = 16'd6; wei[2] = 16'd0;
        @(posedge clk); #1;

        wei[0] = 16'd0; wei[1] = 16'd0; wei[2] = 16'd0;
        @(posedge clk); #1;

        @(posedge clk); #1;
        act[0] = 16'd1; act[1] = 16'd0; act[2] = 16'd0;

        @(posedge clk); #1;
        act[0] = 16'd3; act[1] = 16'd2; act[2] = 16'd0;

        @(posedge clk); #1;
        act[0] = 16'd0; act[1] = 16'd4; act[2] = 16'd0;

        @(posedge clk); #1;
        act[0] = 16'd0; act[1] = 16'd0; act[2] = 16'd0;

        @(posedge clk); #1;
        act[0] = 16'd0; act[1] = 16'd0; act[2] = 16'd0;

        //Reset Data IN
        @(posedge clk);
        foreach(act[i]) act[i]=0;
        foreach(wei[i]) wei[i]=0;

        //Check whether PE receive new Weight or lock Weight
        wei[0] = 16'd2; wei[1] = 16'd9; wei[2] = 16'd0; 
        @(posedge clk); #1;

        wei[0] = 16'd3; wei[1] = 16'd7; wei[2] = 16'd0;
        @(posedge clk); #1;

        wei[0] = 16'd0; wei[1] = 16'd0; wei[2] = 16'd0;
        @(posedge clk); #1;

        repeat(20) @(posedge clk);

        @(posedge clk);
        #1;
        $display("\n===== Case 3: Check Reg_Clear Signal Chk =====");
        
        reg_clear = 1;

        @(posedge clk);
        reg_clear = 0;

        //[6 2]     [7 9]
        //[8 4]     [3 5]
        wei[0] = 16'd7; wei[1] = 16'd9; wei[2] = 16'd0; 
        @(posedge clk); #1;

        wei[0] = 16'd3; wei[1] = 16'd5; wei[2] = 16'd0;
        @(posedge clk); #1;

        wei[0] = 16'd0; wei[1] = 16'd0; wei[2] = 16'd0;
        @(posedge clk); #1;


        @(posedge clk); #1;
        act[0] = 16'd6; act[1] = 16'd0; act[2] = 16'd0;

        @(posedge clk); #1;
        act[0] = 16'd8; act[1] = 16'd2; act[2] = 16'd0;

        @(posedge clk); #1;
        act[0] = 16'd0; act[1] = 16'd4; act[2] = 16'd0;

        //Reset Data IN
        @(posedge clk);
        foreach(act[i]) act[i]=0;
        foreach(wei[i]) wei[i]=0;

        repeat(20) @(posedge clk);

        @(posedge clk);
        reg_clear = 1;

        @(posedge clk);
        reg_clear = 0;

        //[2 4]     [3 5]
        //[6 8]     [7 9]
        wei[0] = 16'd3; wei[1] = 16'd5; wei[2] = 16'd0; 
        @(posedge clk); #1;

        wei[0] = 16'd7; wei[1] = 16'd9; wei[2] = 16'd0;
        @(posedge clk); #1;

        wei[0] = 16'd0; wei[1] = 16'd0; wei[2] = 16'd0;
        @(posedge clk); #1;

        @(posedge clk); #1;
        act[0] = 16'd2; act[1] = 16'd0; act[2] = 16'd0;

        @(posedge clk); #1;
        act[0] = 16'd6; act[1] = 16'd4; act[2] = 16'd0;

        @(posedge clk); #1;
        act[0] = 16'd0; act[1] = 16'd8; act[2] = 16'd0;

        //Reset Data IN
        @(posedge clk);
        foreach(act[i]) act[i]=0;
        foreach(wei[i]) wei[i]=0;

        repeat(20) @(posedge clk);

        @(posedge clk);
        reg_clear = 1;

        @(posedge clk);
        reg_clear = 0;
        
        //[3 2 1]     [7 4 1]
        //[6 5 4]     [8 5 2] 
        //[9 8 7]     [9 6 3]
        wei[0] = 16'd7; wei[1] = 16'd4; wei[2] = 16'd1; 
        @(posedge clk); #1;

        wei[0] = 16'd8; wei[1] = 16'd5; wei[2] = 16'd2;
        @(posedge clk); #1;

        wei[0] = 16'd9; wei[1] = 16'd6; wei[2] = 16'd3;
        @(posedge clk); #1;

        @(posedge clk); #1;
        act[0] = 16'd3; act[1] = 16'd0; act[2] = 16'd0;

        @(posedge clk); #1;
        act[0] = 16'd6; act[1] = 16'd2; act[2] = 16'd0;

        @(posedge clk); #1;
        act[0] = 16'd9; act[1] = 16'd5; act[2] = 16'd1;

        @(posedge clk); #1;
        act[0] = 16'd0; act[1] = 16'd8; act[2] = 16'd4;

        @(posedge clk); #1;
        act[0] = 16'd0; act[1] = 16'd0; act[2] = 16'd7;

        //Reset Data IN
        @(posedge clk);
        foreach(act[i]) act[i]=0;
        foreach(wei[i]) wei[i]=0;

        repeat(10) @(posedge clk);

        @(posedge clk);
        #1;
        $display("\n===== Case 4: Pipeline_en Signal Chk =====");
        
        reg_clear = 1;

        @(posedge clk);
        #1;
        reg_clear = 0;

        //[3 2 1]     [7 4 1]
        //[6 5 4]     [8 5 2] 
        //[9 8 7]     [9 6 3]
        wei[0] = 16'd7; wei[1] = 16'd4; wei[2] = 16'd1; 
        @(posedge clk); #1;

        wei[0] = 16'd8; wei[1] = 16'd5; wei[2] = 16'd2;
        @(posedge clk); #1;

        wei[0] = 16'd9; wei[1] = 16'd6; wei[2] = 16'd3;
        @(posedge clk); #1;

        @(posedge clk); #1;
        act[0] = 16'd3; act[1] = 16'd0; act[2] = 16'd0;

        @(posedge clk); #1;
        act[0] = 16'd6; act[1] = 16'd2; act[2] = 16'd0;

        @(posedge clk); #1;
        act[0] = 16'd9; act[1] = 16'd5; act[2] = 16'd1;

        @(posedge clk); #1;
        act[0] = 16'd0; act[1] = 16'd8; act[2] = 16'd4;

        @(posedge clk); #1;
        act[0] = 16'd0; act[1] = 16'd0; act[2] = 16'd7;

        //Reset Data IN
        @(posedge clk);
        foreach(act[i]) act[i]=0;
        foreach(wei[i]) wei[i]=0;

        @(posedge clk);
        #1;
        $display("\n===== Pipeline OFF =====");
        pipeline_en = 0;
        repeat(10) begin
            @(posedge clk);
            #1;
            $display("\n [%d] [%d] [%d] \n [%d] [%d] [%d] \n [%d] [%d] [%d]", 
                MAC_out[0][0], MAC_out[0][1], MAC_out[0][2], 
                MAC_out[1][0], MAC_out[1][1], MAC_out[1][2], 
                MAC_out[2][0], MAC_out[2][1], MAC_out[2][2]);
        end

        @(posedge clk);
        #1;
        $display("\n===== Pipeline ON =====");
        pipeline_en = 1;

        repeat(10) @(posedge clk);

        @(posedge clk);
        #1;
        $display("\n===== Case 5: Cell_en Signal Chk =====");
        
        reg_clear = 1;

        @(posedge clk);
        #1;
        reg_clear = 0;

        //[1 4 7]     [1 2 3]
        //[2 5 8]     [4 5 6] 
        //[3 6 9]     [7 8 9]
        wei[0] = 16'd1; wei[1] = 16'd2; wei[2] = 16'd3; 
        @(posedge clk); #1;

        wei[0] = 16'd4; wei[1] = 16'd5; wei[2] = 16'd6;
        @(posedge clk); #1;

        wei[0] = 16'd7; wei[1] = 16'd8; wei[2] = 16'd9;
        @(posedge clk); #1;

        @(posedge clk); #1;
        act[0] = 16'd1; act[1] = 16'd0; act[2] = 16'd0;     //Most Right of First Row of the 1st Matrix Start: 7

        @(posedge clk); #1;
        act[0] = 16'd2; act[1] = 16'd4; act[2] = 16'd0;     //Most Right of Second Row of the 1st Matrix Start: 8

        @(posedge clk); #1;
        act[0] = 16'd3; act[1] = 16'd5; act[2] = 16'd7;     //Most Right of Last Row of the 1st Matrix Start: 9

        @(posedge clk); #1;
        act[0] = 16'd0; act[1] = 16'd6; act[2] = 16'd8;

        @(posedge clk); #1;
        act[0] = 16'd0; act[1] = 16'd0; act[2] = 16'd9;

        //Reset Data IN
        @(posedge clk);
        foreach(act[i]) act[i]=0;
        foreach(wei[i]) wei[i]=0;

        @(posedge clk);
        #1;
        $display("\n===== Cell_en OFF =====");
        cell_en = 0;
        repeat(10) begin
            @(posedge clk);
            #1;
            $display("\n [%d] [%d] [%d] \n [%d] [%d] [%d] \n [%d] [%d] [%d]", 
                MAC_out[0][0], MAC_out[0][1], MAC_out[0][2], 
                MAC_out[1][0], MAC_out[1][1], MAC_out[1][2], 
                MAC_out[2][0], MAC_out[2][1], MAC_out[2][2]);
        end

        @(posedge clk);
        #1;
        $display("\n===== Cell_en ON =====");
        cell_en = 1;

        repeat(10) @(posedge clk);

        $finish;

    end
endmodule