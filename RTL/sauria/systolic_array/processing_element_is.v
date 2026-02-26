module processing_element_is #(                         //Input Sationary (Store Activation, transfer Weight and MAC)
    parameter   WIDTH_A             = 16,               //Width of A
    parameter   WIDTH_B             = 16,               //Width of B
    parameter   WIDTH_MAC           = 48,               //Width of MAC
    parameter   WIDTH_T             = 2,                //Width of threshold
    parameter   ZERO_GATING_MULT    = 1,                //Skip multiplier if zero
    parameter   ZERO_GATING_ADD     = 1,                //Skip adder if zero
    parameter   MM_APPROX           = 1,                //LSB bits of multiplier if having approximation
    parameter   M_APPROX            = 1,                //MSB bits of multiplier if having approximation
    parameter   AA_APPROX           = 1,                //LSB bits of adder if having approximation
    parameter   A_APPROX            = 1,                //MSB bits of adder if having approximation
    parameter   MUL_TYPE            = 0,                //Choosing Multiplier
    parameter   ADD_TYPE            = 0,                //Choosing Adder
    parameter   STAGE               = 0,                //Number of Stage of pipeline
    parameter   ARITHMETIC          = 0,                //Choosing result between FMA or (multiplier and adder)
    parameter   SIGNED              = 0,                

    parameter   INTERMEDIATE_PIPELINE_STAGE = 0

)(
    input   wire                    clk,
    input   wire                    rst_n,
    input   wire    [WIDTH_A-1:0]   act,                //activation input
    input   wire    [WIDTH_B-1:0]   wei,                //weight input
    input   wire    [WIDTH_MAC-1:0] MAC_IN,             //MAC input

    input   wire                    pipeline_en,        //stimulate pipeline
    input   wire                    reg_clear,          //Clear Registers
    input   wire                    cell_en,            //Enable signal allows PE working
    input   wire                    cell_sc_en,         //Enable signal for next PE to take Activation  
    input   wire                    c_switch,           //Switch value between internal Accumulate and input Accumulate (Off because Output Stationary)
    input   wire                    cscan_en,           //enable push MAC to output

    input   wire    [WIDTH_T-1:0]   Thres,              //Threshold for zero detection

    output  wire                    cell_out,           //Cell_enable output for next PE
    output  wire                    c_switch_out,
    
    output  wire    [WIDTH_A-1:0]   wei_out,            //weight out
    output  wire    [WIDTH_B-1:0]   act_out,            //do not flow out
    output  wire    [WIDTH_MAC-1:0] MAC_out             //MAC out
);

    //Derived Parameters
    //Enable zero detection if any gating enabled
    parameter   ZERO_DETECTION  = ZERO_GATING_ADD | ZERO_GATING_MULT;
    //Multiplier output width
    parameter   MUL_W           = (ARITHMETIC==0)   ?   (WIDTH_A+WIDTH_B) : WIDTH_MAC;

    //Internal Signals
    reg     [WIDTH_A-1:0]           act_reg, act_out_reg;                       //Act go to PE first
    wire    [WIDTH_MAC-1:0]         mac_out_fma, mac_value, mac_out_adder;             
    wire                            pipeline_in;
    wire                            Zero_detected;
    wire    [MUL_W-1:0]             mul_value;
    wire                            mul_mux_sel;
    wire                            mac_is_valid, zero;
    reg     [STAGE:0]               pipe_valid;
    reg     [1:0]                   cell_pipe;
    reg     [WIDTH_MAC-1:0]         mac_buffer;                                 // Output buffer
    //Pipeline registers for MAC and weight
    reg     [WIDTH_MAC-1:0]         pipe_mac [0:STAGE];   
    reg     [WIDTH_B-1:0]           pipe_wei [0:STAGE];
    integer                         i;
    reg                             act_is_valid;                               //Activation already captured

    assign  mul_mux_sel     = 1'b0;                                             
    assign  pipeline_in     = pipeline_en && cell_en;                           //PE runs only when pipeline and cell enabled
    assign  c_switch_out    = 1'b0;                                             
    assign  wei_out         = pipe_wei[STAGE];                                  //Push WEIGHT to next PE
    assign  mac_is_valid    = pipe_valid[STAGE];                                //Mac is ready to push when finish all pipeline stages
    assign  zero            = ZERO_DETECTION    ?   Zero_detected : 1'b0;       //Zero gating enable
    assign  act_out         = act_out_reg;                                      //Push ACTIVATION to nex PE

    //Instantiate Zero detection module
    Zero_detection #(
        .WIDTH_A(WIDTH_A),
        .WIDTH_B(WIDTH_B),
        .WIDTH_T(WIDTH_T)
    ) zd0 (
        .A(act_reg),
        .B(wei),
        .Thres(Thres),
        .Zero(Zero_detected)
    );

    generate
        if (ARITHMETIC) begin                                   //If ARITHMETIC is 1, choosing value from FMA
            fma_wrapper_ofBSC #(
                .MUL_TYPE(MUL_TYPE),
                .M_APPROX(M_APPROX),
                .MM_APPROX(MM_APPROX),
                .ADD_TYPE(ADD_TYPE),
                .A_APPROX(A_APPROX),
                .AA_APPROX(AA_APPROX),
                .STAGES(STAGE),
                .INTERMEDIATE_PIPELINE_STAGE(INTERMEDIATE_PIPELINE_STAGE),
                .ZERO_GATING_MULT(ZERO_GATING_MULT),
                .FP_W(WIDTH_A)
            ) fma_i (
                .i_clk		        (clk),
                .i_rstn		        (rst_n && (!reg_clear)),
                .i_a		        (act_reg),                   
                .i_b		        (wei),                   
                .i_c                (MAC_IN),                
                .i_msel             (mul_mux_sel),
                .i_pipeline_en      (pipeline_in),
                .o_c		        (mac_out_fma)
            );
        end 
        else begin                                              //If ARITHMETIC is 0, choosing value from ADDER and MULTIPLIER
            //Mac_in + Activation * Weight
            Adder_generic #(
                .WIDTH_A(WIDTH_MAC),
                .WIDTH_B(MUL_W),
                .WIDTH_OUT(WIDTH_MAC),
                .AA_APPROX(AA_APPROX),
                .A_APPROX(A_APPROX),
                .ADD_TYPE(ADD_TYPE),
                .SIGNED(SIGNED)
            ) a0 (
                .A(pipe_mac[STAGE]),
                .B(mul_value),
                .Carry(1'b0),
                .OUT(mac_out_adder)
            );

            //Activation * Weight
            Multiplier_generic #(
                .WIDTH_A(WIDTH_A),
                .WIDTH_B(WIDTH_B),
                .MM_APPROX(MM_APPROX),
                .M_APPROX(M_APPROX),
                .MUL_TYPE(MUL_TYPE),
                .WIDTH_MUL(WIDTH_A+WIDTH_B),
                .SIGNED(SIGNED),
                .STAGE(STAGE)
            ) m0 (
                .clk(clk),
                .rst_n(rst_n),
                .pipeline_en(pipeline_in && ~zero),
                .A(act_reg),
                .B(pipe_wei[STAGE]),
                .OUT(mul_value)
            );
        end
    endgenerate

    //A0-cell-sc-en = 1;
    //A0 - A1 - A2 - A3
    //cycle 1-2-3-4
    //Delay 1 cycle for waiting next value to next PE to avoid the same value transfer to next PE
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            cell_pipe  <= {(2){1'b0}};
        end 
        else begin
            if(reg_clear)
                cell_pipe  <= {(2){1'b0}};
            else 
                cell_pipe <= {cell_pipe[1:0], cell_sc_en};
        end
    end

    assign cell_out = cell_pipe[1] && act_is_valid;

    //MAC_out Buffer
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
           mac_buffer  <= {WIDTH_MAC{1'b0}};
        end
        else begin
            if(reg_clear) begin
                mac_buffer  <= {WIDTH_MAC{1'b0}};
            end
            else if(mac_is_valid) begin
                mac_buffer  <= ARITHMETIC ? mac_out_fma : mac_out_adder;    //Using ARITHMETIC value to check value between fma and (mul with adder)    
            end
        end
    end

    assign  MAC_out = mac_buffer;

    //When finish all STAGE, pipe_valid is HIGH
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n || reg_clear) begin
            pipe_valid  <= {(STAGE+1){1'b0}};
        end 
        else begin
            if (STAGE == 0)
                pipe_valid  <= {(STAGE+1){pipeline_in}};
            else begin
                if(pipeline_in)
                    pipe_valid  <= {pipe_valid[STAGE-1:0], pipeline_in};    //Shift bit to check
            end
        end
    end

    //Activation register
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            act_reg         <= {WIDTH_A{1'b0}};
            act_is_valid    <= 1'b0;
        end
        else begin
            if(reg_clear) begin
                act_reg         <= {WIDTH_A{1'b0}};
                act_is_valid    <= 1'b0;
            end
            else if(cell_sc_en && ~act_is_valid) begin                     //When cell_sc_en signal is high, act_reg stores value of act_in
                act_reg         <= act;
                act_is_valid    <= 1'b1;
            end
        end
    end

    //Forward activation to next PE
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            act_out_reg        <= {WIDTH_A{1'b0}};
        end
        else begin
            if(reg_clear) begin
                act_out_reg    <= {WIDTH_A{1'b0}};
            end
            else begin
                act_out_reg    <= act;
            end
        end
    end

    //Stimulate pipeline for MAC and WEIGHT
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            for(i = 0; i < STAGE + 1; i = i + 1) begin
                pipe_mac[i]     <= {WIDTH_MAC{1'b0}};
                pipe_wei[i]     <= {WIDTH_B{1'b0}};
            end
        end
        else if(reg_clear) begin
            for(i = 0; i <= STAGE; i = i + 1) begin
                pipe_mac[i]     <= {WIDTH_MAC{1'b0}};
                pipe_wei[i]     <= {WIDTH_B{1'b0}};
            end
        end
        else if(pipeline_in) begin
            pipe_mac[0] <= MAC_IN;
            pipe_wei[0] <= wei;
            for(i = 1; i < STAGE + 1; i = i + 1) begin                  //Stimulate Pipeline Stage
                pipe_mac[i]    <= pipe_mac[i-1];
                pipe_wei[i]    <= pipe_wei[i-1];
            end
        end
    end

endmodule
