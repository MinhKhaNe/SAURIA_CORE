module ram_top #(
    parameter   HOST_W      = 32,
    parameter   HOST_ADDR_W = 32,
    parameter   SRAMA_ADR_W = 10,
    parameter   SRAMA_W     = 128,
    parameter   SRAMB_ADR_W = 10,
    parameter   SRAMB_W     = 128,
    parameter   SRAMC_ADR_W = 10,
    parameter   SRAMC_W     = 128,

    parameter   SRAMC_MW    = 8
)(
    input   wire                                clk,
    input   wire                                rst_n,
    input   wire    [2:0]                       sram_sel,   //Each bit represents a SRAM
    //HOST value
    input   wire    [HOST_W-1:0]                hdata,
    input   wire    [HOST_ADDR_W-1:0]           haddr,
    input   wire    [HOST_W/8-1:0]              hwmask,
    input   wire                                hrd_en,
    input   wire                                hwr_en,
    output  wire    [HOST_W-1:0]                data_out,
    //SRAM A
    input   wire    [SRAMA_ADR_W-1:0]           srama_addr,
    input   wire                                srama_rd_en,
    output  wire    [SRAMA_W-1:0]               srama_data,
    //SRAM B
    input   wire    [SRAMB_ADR_W-1:0]           sramb_addr,
    input   wire                                sramb_rd_en,
    output  wire    [SRAMB_W-1:0]               sramb_data,
    //SRAM C
    input   wire    [SRAMC_W-1:0]               sramc_data_in,
    input   wire    [SRAMC_ADR_W-1:0]           sramc_addr,
    input   wire                                sramc_rd_en,
    input   wire                                sramc_wr_en,
    input   wire    [SRAMC_MW-1:0]              sramc_wmask,
    output  wire    [SRAMC_W-1:0]               sramc_data
);

    function integer log2;
        input integer value;
        integer i;
        begin
            value = value - 1;
            for (i = 0; value > 0; i = i + 1)
                value = value >> 1;
            log2 = i;
        end
    endfunction

    parameter   SAURIA_MEM_ADDR_MASK    = 32'h003C_0000;
    parameter   SRAMA_OFFSET            = 32'h0004_0000;
    parameter   SRAMB_OFFSET            = 32'h0008_0000;
    parameter   SRAMC_OFFSET            = 32'h000C_0000;
    parameter   HOST_LSB                = log2(HOST_W/8);

    wire    [HOST_ADDR_W-1:0]   host_sram_sel;
    reg     [HOST_ADDR_W-1:0]   host_sram_sel_r;
    wire    [HOST_W-1:0]        host_out;
    reg     [HOST_W-1:0]        host_out_data;
    //SRAM A
    wire                        host_srama_wr, host_srama_rd;
    wire    [HOST_W-1:0]        host_srama_data;
    wire    [SRAMA_W-1:0]       srama_out;
    reg     [SRAMA_W-1:0]       srama_out_r;

    //SRAMB
    wire                        host_sramb_wr, host_sramb_rd;
    wire    [HOST_W-1:0]        host_sramb_data;
    wire    [SRAMB_W-1:0]       sramb_out;
    reg     [SRAMB_W-1:0]       sramb_out_r;

    //SRAMC
    wire                        host_sramc_wr, host_sramc_rd;
    wire    [HOST_W-1:0]        host_sramc_data;
    wire    [SRAMC_W-1:0]       sramc_out;
    reg     [SRAMC_W-1:0]       sramc_out_r;

    //Check value of Address 
    assign  host_sram_sel   = haddr & SAURIA_MEM_ADDR_MASK; //Only take value from [21:18]
    //Check SRAMA read, write signals
    assign  host_srama_wr   = (host_sram_sel == SRAMA_OFFSET) ? hwr_en : 1'b0;
    assign  host_srama_rd   = (host_sram_sel == SRAMA_OFFSET) ? hrd_en : 1'b0;
    //Check SRAMB read, write signals
    assign  host_sramb_wr   = (host_sram_sel == SRAMB_OFFSET) ? hwr_en : 1'b0;
    assign  host_sramb_rd   = (host_sram_sel == SRAMB_OFFSET) ? hrd_en : 1'b0;
    //Check SRAMC read, write signals
    assign  host_sramc_wr   = (host_sram_sel == SRAMC_OFFSET) ? hwr_en : 1'b0;
    assign  host_sramc_rd   = (host_sram_sel == SRAMC_OFFSET) ? hrd_en : 1'b0;
    //Output value to host
    assign  host_out        = (host_sram_sel_r == SRAMA_OFFSET) ? host_srama_data : 
                              (host_sram_sel_r == SRAMB_OFFSET) ? host_sramb_data :
                              (host_sram_sel_r == SRAMC_OFFSET) ? host_sramc_data :
                                                                {HOST_W{1'b0}};

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            host_out_data   <= {HOST_W{1'b0}};
            host_sram_sel_r <= 1'b0;
            srama_out_r     <= {SRAMA_W{1'b0}};
            sramb_out_r     <= {SRAMB_W{1'b0}};
            sramc_out_r     <= {SRAMC_W{1'b0}};
        end
        else begin
            // host_sram_sel_r <= host_sram_sel;
            //if(hrd_en) begin
                host_out_data   <= host_out;
                host_sram_sel_r <= host_sram_sel;
            //end

            if(srama_rd_en) begin
                srama_out_r     <= srama_out;
            end

            if(sramb_rd_en) begin
                sramb_out_r     <= sramb_out;
            end

            if(sramc_rd_en) begin
                sramc_out_r     <= sramc_out;
            end
        end
    end

    assign  data_out    = host_out_data;
    assign  srama_data  = srama_out_r;
    assign  sramb_data  = sramb_out_r;
    assign  sramc_data  = sramc_out_r;

    //SRAM A
    ram_wrapper #(
        .HOST_W(HOST_W),
        .HOST_ADR_W(HOST_ADDR_W),
        .SRAM_ADR_W(SRAMA_ADR_W),
        .SRAM_W(SRAMA_W)
    ) srama (
        .clk(clk),
        .rst_n(rst_n),
        .ram_sel(sram_sel[0]),
        .hdata(hdata),
        .haddr(haddr[HOST_ADDR_W-1:HOST_LSB]),
        .hwmask(hwmask),
        .hwr_en(host_srama_wr),
        .hrd_en(host_srama_rd),
        .hdata_out(host_srama_data),
        //.adata(),
        .aaddr(srama_addr),
        // .awmask(),
        // .awr_en(),
        .ard_en(srama_rd_en),
        .adata_out(srama_out)
    );

    //SRAM B
    ram_wrapper #(
        .HOST_W(HOST_W),
        .HOST_ADR_W(HOST_ADDR_W),
        .SRAM_ADR_W(SRAMB_ADR_W),
        .SRAM_W(SRAMB_W)
    ) sramb (
        .clk(clk),
        .rst_n(rst_n),
        .ram_sel(sram_sel[1]),
        .hdata(hdata),
        .haddr(haddr[HOST_ADDR_W-1:HOST_LSB]),
        .hwmask(hwmask),
        .hwr_en(host_sramb_wr),
        .hrd_en(host_sramb_rd),
        .hdata_out(host_sramb_data),
        //.adata(),
        .aaddr(sramb_addr),
        // .awmask(),
        // .awr_en(),
        .ard_en(sramb_rd_en),
        .adata_out(sramb_out)
    );

    //SRAM C
    ram_wrapper #(
        .HOST_W(HOST_W),
        .HOST_ADR_W(HOST_ADDR_W),
        .SRAM_ADR_W(SRAMC_ADR_W),
        .SRAM_W(SRAMC_W),
        .SRAM_MASK_W(SRAMC_MW)
    ) sramc (
        .clk(clk),
        .rst_n(rst_n),
        .ram_sel(sram_sel[2]),
        .hdata(hdata),
        .haddr(haddr[HOST_ADDR_W-1:HOST_LSB]),
        .hwmask(hwmask),
        .hwr_en(host_sramc_wr),
        .hrd_en(host_sramc_rd),
        .hdata_out(host_sramc_data),
        .adata(sramc_data_in),
        .aaddr(sramc_addr),
        .awmask(sramc_wmask),
        .awr_en(sramc_wr_en),
        .ard_en(sramc_rd_en),
        .adata_out(sramc_out)
    );

endmodule