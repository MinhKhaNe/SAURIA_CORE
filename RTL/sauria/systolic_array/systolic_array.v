module systolic_array #(
    parameter   WIDTH_A                     = 16,               //Width of A
    parameter   WIDTH_B                     = 16,               //Width of B
    parameter   WIDTH_MAC                   = 48,               //Width of MAC
    parameter   WIDTH_T                     = 2,                //Width of threshold
    parameter   ZERO_GATING_MULT            = 1,                //Skip multiplier if zero
    parameter   ZERO_GATING_ADD             = 1,                //Skip adder if zero
    parameter   MM_APPROX                   = 1,                //LSB bits of multiplier if having approximation
    parameter   M_APPROX                    = 1,                //MSB bits of multiplier if having approximation
    parameter   AA_APPROX                   = 1,                //LSB bits of adder if having approximation
    parameter   A_APPROX                    = 1,                //MSB bits of adder if having approximation
    parameter   MUL_TYPE                    = 0,                //Choosing Multiplier
    parameter   ADD_TYPE                    = 0,                //Choosing Adder
    parameter   STAGE                       = 0,                //Number of Stage of pipeline
    parameter   ARITHMETIC                  = 0,                //Choosing result between FMA or (multiplier and adder)
    parameter   SIGNED                      = 0,                
    parameter   INTERMEDIATE_PIPELINE_STAGE = 1,
    parameter   x_axis                      = 3,                //Width of WEIGHT
    parameter   y_axis                      = 3,                //Width of ACTIVATION
    parameter   PE_TYPE                     = 0
)(
    input   wire                    clk,
    input   wire                    rst_n,
    input   wire    [WIDTH_A-1:0]   act [0:y_axis-1],           //activation input
    input   wire    [WIDTH_B-1:0]   wei [0:x_axis-1],           //weight input
    input   wire    [WIDTH_MAC-1:0] MAC_IN  [0:y_axis-1],       //MAC input

    input   wire                    pipeline_en,                //stimulate pipeline
    input   wire                    reg_clear,                  //Clear Registers
    input   wire                    cell_en,                    //Enable signal allows PE working
    input   wire                    cell_sc_en,                 //Enable signal for next PE to take Activation  
    input   wire                    c_switch,                   //Switch value between internal Accumulate and input Accumulate (Off because Output Stationary)
    input   wire                    cscan_en,                   //enable push MAC to output

    input   wire    [WIDTH_T-1:0]   Thres,                      //Threshold for zero detection

    output  wire                    cell_out,                   //Cell_enable output for next PE
    output  wire                    c_switch_out,
    
    output  wire    [WIDTH_MAC-1:0] MAC_out [0:y_axis-1]        //MAC out
);

    wire    [WIDTH_A-1:0]       act_in[0:y_axis-1][0:x_axis];
    wire    [WIDTH_B-1:0]       wei_in[0:y_axis][0:x_axis-1];    
    wire    [WIDTH_MAC-1:0]     mac_in[0:y_axis-1][0:x_axis];
    wire                        cell_en_in[0:y_axis][0:x_axis-1];
    wire                        c_switch_out_wire[0:y_axis-1][0:x_axis-1];

    assign  cell_out        =   cell_en_in[y_axis][x_axis-1];
    assign  c_switch_out    =   c_switch_out_wire[y_axis-1][x_axis-1];   

    genvar x;
    generate
        for(x = 0; x < x_axis; x = x + 1) begin
            assign  wei_in[0][x]        = wei[x];
            assign  cell_en_in[0][x]    = cell_en;
        end
    endgenerate

    genvar y;
    generate
        for(y = 0; y < y_axis; y = y + 1) begin
            assign  act_in[y][0]        =   act[y];
            assign  mac_in[y][x_axis]   =   MAC_IN[y];

            assign  MAC_out[y]          =   mac_in[y][0];
        end
    endgenerate

    genvar i, j;
    generate
        if(PE_TYPE == 0) begin                  //PE_OS
            for(i = 0; i < y_axis; i = i + 1) begin
                for(j = 0; j < x_axis; j = j + 1) begin
                    processing_element_os #(
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
                        .INTERMEDIATE_PIPELINE_STAGE(INTERMEDIATE_PIPELINE_STAGE)
                    ) PE_OS (
                        .clk(clk),
                        .rst_n(rst_n),
                        .act(act_in[i][j]),
                        .wei(wei_in[i][j]),
                        .MAC_IN(mac_in[i][j+1]),
                        .pipeline_en(pipeline_en),
                        .reg_clear(reg_clear),
                        .cell_en(cell_en_in[i][j]),
                        .cell_sc_en(cell_sc_en),
                        .c_switch(c_switch),
                        .cscan_en(cscan_en),
                        .Thres(Thres),
                        .cell_out(cell_en_in[i+1][j]),
                        .c_switch_out(c_switch_out_wire[i][j]),
                        .wei_out(wei_in[i+1][j]),
                        .act_out(act_in[i][j+1]),
                        .MAC_out(mac_in[i][j])
                    );
                end
            end
        end
        else if(PE_TYPE == 1) begin             //PE_IS
            for(i = 0; i < y_axis; i = i + 1) begin
                for(j = 0; j < x_axis; j = j + 1) begin
                    processing_element_is #(
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
                        .INTERMEDIATE_PIPELINE_STAGE(INTERMEDIATE_PIPELINE_STAGE)
                    ) PE_IS (
                        .clk(clk),
                        .rst_n(rst_n),
                        .act(act_in[i][j]),
                        .wei(wei_in[i][j]),
                        .MAC_IN(mac_in[i][j+1]),
                        .pipeline_en(pipeline_en),
                        .reg_clear(reg_clear),
                        .cell_en(1'b1),
                        .cell_sc_en((i == 0) ? cell_sc_en : cell_en_in[i][j]),
                        .c_switch(c_switch),
                        .cscan_en(cscan_en),
                        .Thres(Thres),
                        .cell_out(cell_en_in[i+1][j]),
                        .c_switch_out(c_switch_out_wire[i][j]),
                        .wei_out(wei_in[i+1][j]),
                        .act_out(act_in[i][j+1]),
                        .MAC_out(mac_in[i][j])
                    );
                end
            end
        end
        else if(PE_TYPE == 2) begin             //PE_WS
            for(i = 0; i < y_axis; i = i + 1) begin
                for(j = 0; j < x_axis; j = j + 1) begin
                    processing_element_ws #(
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
                        .INTERMEDIATE_PIPELINE_STAGE(INTERMEDIATE_PIPELINE_STAGE)
                    ) PE_WS (
                        .clk(clk),
                        .rst_n(rst_n),
                        .act(act_in[i][j]),
                        .wei(wei_in[i][j]),
                        .MAC_IN(mac_in[i][j+1]),
                        .pipeline_en(pipeline_en),
                        .reg_clear(reg_clear),
                        .cell_en(1'b1),
                        .cell_sc_en((i == 0) ? cell_sc_en : cell_en_in[i][j]),
                        .c_switch(c_switch),
                        .cscan_en(cscan_en),
                        .Thres(Thres),
                        .cell_out(cell_en_in[i+1][j]),
                        .c_switch_out(c_switch_out_wire[i][j]),
                        .wei_out(wei_in[i+1][j]),
                        .act_out(act_in[i][j+1]),
                        .MAC_out(mac_in[i][j])
                    );
                end
            end
        end
    endgenerate

endmodule
