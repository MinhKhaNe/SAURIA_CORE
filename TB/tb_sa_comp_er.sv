module tb_sa_comp_er;

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
    localparam  MUL_TYPE                    = 2;    //0. Ideal, 1.Bam, 2.3.4. Booth, 5.6. Log, 7.8.9 Wallace
    localparam  ADD_TYPE                    = 0;    //0. Ideal, 1. Gear, 2. Gear_2c, 3. Loa, 4. Trua, 5. Truah
    localparam  STAGE                       = 0;
    localparam  ARITHMETIC                  = 0;
    localparam  SIGNED                      = 0;
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
    logic                                  cell_out, cell_out_ideal;
    logic                                  c_switch_out, c_switch_out_ideal;
    logic               [WIDTH_MAC-1:0]    MAC_out_ideal[0:Y_AXIS-1][0:X_AXIS-1];
    logic               [WIDTH_MAC-1:0]    MAC_out[0:Y_AXIS-1][0:X_AXIS-1];
    real                                   err[0:Y_AXIS-1][0:X_AXIS-1];
    real                                   mac_out_max, mac_out_min;
    integer                                i;
    real                                   error, ideal, approx, mred;
    real                                   total_error_distance;
    real                                   total_ideal_sum;
    logic   signed      [WIDTH_MAC-1:0]    ideal_int, approx_int;
    real                                   samples_count, ed, abs_ideal, abs_approx;

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
        .MUL_TYPE(0),
        .ADD_TYPE(0),
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
        .cell_out(cell_out_ideal),      
        .c_switch_out(c_switch_out_ideal), 
        .MAC_out(MAC_out_ideal)
    );

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
    ) UUT (
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
    
    // function automatic real abs_real(real val);
    //     return (val < 0) ? -val : val;
    // endfunction

    // always @(posedge clk) begin
    //     real ideal_val, actual_val;

    //     for(int i=0; i<Y_AXIS; i++) begin
    //         for(int j=0; j<X_AXIS; j++) begin
            
    //             ideal_val  = $itor((MAC_out_ideal[i][j]));
    //             actual_val = $itor((MAC_out[i][j]));

    //             if (ideal_val != actual_val) begin      
    //                 error   =   error + 1;
    //             end 
    //         end
    //     end
    // end

    //Array 1:  [1, 2][3, 4]
    //Array 2:  [5, 6][7, 8]
    initial begin
        // 1. Đưa tất cả khai báo lên ĐẦU khối initial
        real total_error_distance;
        real total_ideal_sum;
        real ideal, approx;
        real mred; // Mean Relative Error Distance

        $dumpfile("wave.vcd");
        $dumpvars(0, tb_sa_comp_er);

        // Khởi tạo giá trị
        total_error_distance = 0;
        total_ideal_sum = 0;
        error = 0;
        foreach(act[i]) act[i] = 0;
        foreach(wei[i]) wei[i] = 0;
        foreach(MAC_in[i]) MAC_in[i] = 0;
        
        rst_n = 0;
        repeat(2) @(posedge clk);
        rst_n = 1; cell_sc_en = 1; pipeline_en = 1; reg_clear = 0; cell_en = 1; cell_sc_en = 1; c_switch = 1; cscan_en = 0; Thres = 0;

        // // FOR UNSIGNED
        // $display("===== STARTING SIMULATION (SIGNED=%0d) =====", SIGNED);
        // reg_clear = 1;
        // @(posedge clk);
        // reg_clear = 0; 

        // for (i = 0; i < 1000; i = i + 1) begin
        //     @(posedge clk);
        //     #1;

        //     foreach (act[j]) act[j] = $urandom();
        //     foreach (wei[j]) wei[j] = $urandom();
            
        //     // Chờ dữ liệu đi qua pipeline
        //     repeat(8) @(posedge clk);

        //     for(int y=0; y<Y_AXIS; y++) begin
        //         for(int x=0; x<X_AXIS; x++) begin
        //             // Ép kiểu để tính toán số thực
        //             ideal  = $itor(MAC_out_ideal[y][x]);
        //             approx = $itor(MAC_out[y][x]);
                    
        //             if (ideal != approx) begin
        //                 error = error + 1; 
        //                 total_error_distance += (ideal > approx) ? (ideal - approx) : (approx - ideal);
        //             end
        //             total_ideal_sum += (ideal > 0) ? ideal : -ideal;
        //         end
        //     end
        // end

        //FOR BOOTH
        $display("===== STARTING SIMULATION (SIGNED=%0d) =====", SIGNED);
        reg_clear = 1;
        @(posedge clk);
        reg_clear = 0; 

        for (i = 0; i < 1000; i = i + 1) begin
            @(posedge clk);
            #1;

            foreach (act[j]) act[j] = $urandom();
            repeat(8) @(posedge clk);
            foreach (wei[j]) wei[j] = $urandom();
            repeat(8) @(posedge clk);

            for(int y=0; y<Y_AXIS; y++) begin
                for(int x=0; x<X_AXIS; x++) begin
                    // Ép kiểu để tính toán số thực
                    ideal  = $itor(MAC_out_ideal[y][x]);
                    approx = $itor(MAC_out[y][x]);
                    
                    if (ideal != approx) begin
                        error = error + 1; 
                        ed = (ideal > approx) ? (ideal - approx)/ideal : (approx - ideal)/ideal;
                        total_error_distance += ed;

                        if(ed > 1000)
                            $display("%b %b %f",ideal,approx,ed);
                    end
                    total_ideal_sum += (ideal > 0) ? ideal : -ideal;
                end
            end
        end

        // FOR SIGNED
        // total_error_distance = 0;
        // samples_count = 0;
        // error = 0;
        
        // foreach(act[i]) act[i] = 0;
        // foreach(wei[i]) wei[i] = 0;
        // foreach(MAC_in[i]) MAC_in[i] = 0;
        
        // rst_n = 0;
        // repeat(2) @(posedge clk);
        // rst_n = 1; cell_sc_en = 1; pipeline_en = 1; reg_clear = 0; cell_en = 1; cell_sc_en = 1; c_switch = 1; cscan_en = 0; Thres = 0;

        // $display("===== STARTING SIGNED SIMULATION (MUL_TYPE=%0d) =====", MUL_TYPE);
        // reg_clear = 1;
        // repeat(2) @(posedge clk);
        // reg_clear = 0; 

        // for (int sim_step = 0; sim_step < 1000; sim_step++) begin
        //     @(posedge clk);
        //     #1; 

        //     foreach (act[j]) act[j] = $urandom() & ((1<<WIDTH_A)-1);
        //     foreach (wei[j]) wei[j] = $urandom() & ((1<<WIDTH_B)-1);
            
        //     repeat(10) @(posedge clk);

        //     for(int y=0; y<Y_AXIS; y++) begin
        //         for(int x=0; x<X_AXIS; x++) begin
                    
        //             ideal_int  = MAC_out_ideal[y][x];
        //             approx_int = MAC_out[y][x];

        //             repeat(8) @(posedge clk);

        //             ideal  = $itor(ideal_int);
        //             approx = $itor(approx_int);

        //             if (ideal_int != approx_int) begin
        //                 error = error + 1;
        //             end

        //             abs_approx  = (approx < 0)   ? -approx : approx;
        //             abs_ideal   = (ideal < 0)   ? -ideal : ideal;
        //             ed          = (abs_ideal > abs_approx) ? (abs_ideal - abs_approx)/abs_ideal : (abs_approx - abs_ideal)/abs_ideal;

        //             if(ed > 1000)
        //                 $display("%f %f %f",ideal,approx,ed);

        //             total_error_distance += ed;
        //             samples_count += 1.0; 
        //         end
        //     end
        //     //$display("ED=%f, TOTAL ED=%f, sample count=%d", ed, total_error_distance,samples_count);
        //     //$display("%d %d",ideal, approx);
        // end

        @(posedge clk);
        foreach(act[i]) act[i]=0;
        foreach(wei[i]) wei[i]=0;
        repeat(10) @(posedge clk);
    
        mred = (total_error_distance / 9000) * 100.0;

        $display("\n========================================");
        $display("  Total Samples : 9000");
        $display("  Mismatches    : %.0f", error);
        $display("  Error Rate    : %.2f %%", (error / 9000.0) * 100.0);
        $display("  MRED          : %.6f", mred);
        $display("========================================\n");

        $finish;
    end
endmodule