module processing_element_os #(                         //Output Sationary (Store MAC, transfer Weight and Activation)
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

    parameter   ZERO_DETECTION  = ZERO_GATING_ADD | ZERO_GATING_MULT;
    parameter   MUL_W           = (ARITHMETIC==0)   ?   (WIDTH_A+WIDTH_B) : WIDTH_MAC;

    reg     [WIDTH_MAC-1:0]         mac_reg;            //Always choosing local mac instead of Out MAC because of OS
    wire    [WIDTH_MAC-1:0]         mac_out_fma, mac_value, mac_out_adder;          
    wire    [WIDTH_A-1:0]           act_zd;
    wire    [WIDTH_B-1:0]           wei_zd;
    reg     [WIDTH_A-1:0]           act_reg;
    reg     [WIDTH_B-1:0]           wei_reg;
    reg                             cell_reg;
    wire                            pipeline_in;
    wire                            Zero_detected;
    wire    [MUL_W-1:0]             mul_value;
    wire                            mul_mux_sel;
    wire                            zero, mac_is_valid;
    reg     [STAGE:0]               pipe_valid, zero_pipe;
    wire                            zero_chk;
    wire                            acc_read_en;
    reg     [WIDTH_MAC-1:0]         mac_buffer;
    integer                         i;

    assign  mul_mux_sel     = 1'b0;                             //OUTPUT STATIONARY
    assign  mac_value       = mac_reg;                          //Final MAC value after pipeline
    assign  pipeline_in     = pipeline_en && cell_en;           //Internal pipeline signal
    assign  c_switch_out    = 1'b0;                             //OS so do not need to switch MAC
    assign  wei_out         = wei_reg;                          //Push WEIGHT to next PE
    assign  act_out         = act_reg;                          //Push Activation to next PE
    assign  act_zd          = zero  ? {WIDTH_A{1'b0}} : act;
    assign  wei_zd          = zero  ? {WIDTH_B{1'b0}} : wei;
    assign  mac_is_valid    = pipe_valid[STAGE];                //When finish all stage, mac is valid to push out
    assign  zero            = ZERO_DETECTION    ? Zero_detected : 1'b0;
    assign  acc_read_en     = mac_is_valid && ~zero_chk; 
    assign  zero_chk        = zero_pipe[STAGE];                 //Check whether ACTIVATION or WEIGHT is zero or not


    Zero_detection #(
        .WIDTH_A(WIDTH_A),
        .WIDTH_B(WIDTH_B),
        .WIDTH_T(WIDTH_T)
    ) zd0 (
        .A(act),
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
                .i_a		        (act_zd),                   //after zero detection
                .i_b		        (wei_zd),                   //after zero detection
                .i_c                (mac_reg),                
                .i_msel             (mul_mux_sel),
                .i_pipeline_en      (pipeline_en),
                .o_c		        (mac_out_fma)
            );
        end 
        else begin                                              //If ARITHMETIC is 0, choosing value from ADDER and MULTIPLIER
            Adder_generic #(
                .WIDTH_A(WIDTH_MAC),
                .WIDTH_B(MUL_W),
                .WIDTH_OUT(WIDTH_MAC),
                .AA_APPROX(AA_APPROX),
                .A_APPROX(A_APPROX),
                .ADD_TYPE(ADD_TYPE),
                .SIGNED(1'b1)
            ) a0 (
                .A(mac_reg),
                .B(mul_value),
                .Carry(0),
                .OUT(mac_out_adder)
            );

            Multiplier_generic #(
                .WIDTH_A(WIDTH_A),
                .WIDTH_B(WIDTH_B),
                .MM_APPROX(MM_APPROX),
                .M_APPROX(M_APPROX),
                .MUL_TYPE(MUL_TYPE),
                .WIDTH_MUL(WIDTH_A+WIDTH_B),
                .SIGNED(1'b1),
                .STAGE(STAGE)
            ) m0 (
                .clk(clk),
                .rst_n(rst_n),
                .pipeline_en(pipeline_in),
                .A(act),
                .B(wei),
                .OUT(mul_value)
            );
        end
    endgenerate

    //Handle cell_enable for next PE
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            cell_reg        <= 1'b0;
        end
        else begin
            if(reg_clear)
                cell_reg    <= 1'b0;
            else 
                cell_reg    <= cell_sc_en;
        end
    end

    assign cell_out = cell_reg;

    //Push MAC value out
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            mac_buffer        <= {WIDTH_MAC{1'b0}};
        end
        else begin
            if(reg_clear) 
                mac_buffer    <= {WIDTH_MAC{1'b0}};
            else if(cscan_en)
                mac_buffer    <= MAC_IN;
            else if(mac_is_valid && ~cscan_en && pipeline_in)                                    //Stop update value when pipeline_en or cell_en is low   
                mac_buffer    <= mac_reg;                                                        //Transmit value to MAC Buffer after finish pipeline
        end
    end

    assign  MAC_out = mac_buffer;

    //When finish all STAGE, pipe_valid is HIGH
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            pipe_valid  <= {(STAGE+1){1'b0}};
        end 
        else begin
            if(reg_clear)
                pipe_valid  <= {(STAGE+1){1'b0}};
            else if(pipeline_in)
                pipe_valid  <= {pipe_valid[STAGE-1:0], pipeline_en};    //Shift bit to check
        end
    end

    //Zero pipeline
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            zero_pipe  <= {(STAGE+1){1'b0}};
        end
        else begin
            if(reg_clear)
                zero_pipe  <= {(STAGE+1){1'b0}};
            else if(pipeline_in)
                zero_pipe  <= {zero_pipe[STAGE-1:0], Zero_detected};        //Shift bit to check
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            mac_reg <= {WIDTH_MAC{1'b0}};
        end
        else begin
            if(reg_clear) begin
                mac_reg <= {WIDTH_MAC{1'b0}};
            end
            else if (acc_read_en && pipeline_in) begin
                mac_reg <= ARITHMETIC ? mac_out_fma : mac_out_adder;    //Using ARITHMETIC value to check value between fma and (mul with adder)    
            end
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            act_reg       <= {WIDTH_A{1'b0}};
            wei_reg       <= {WIDTH_B{1'b0}};
        end
        else begin
            if(reg_clear) begin
                act_reg       <= {WIDTH_A{1'b0}};
                wei_reg       <= {WIDTH_B{1'b0}};
            end
            else if(pipeline_in) begin
                act_reg       <= act;                                   //Activation Register
                wei_reg       <= wei;                                   //Weight Register
            end
        end
    end

endmodule
