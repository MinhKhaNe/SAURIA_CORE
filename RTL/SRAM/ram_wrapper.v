`define max(a,b)    ((a) > (b) ? (a) : (b))

module ram_wrapper #(
    parameter   HOST_W      = 32,   //
    parameter   HOST_ADR_W  = 32,   //

    parameter   SRAM_ADR_W  = 10,   //
    parameter   SRAM_W      = 128,  //
    parameter   SRAM_MASK_W = 8     //Bit mask width
)(
    input   wire                        clk,        
    input   wire                        rst_n,      
    input   wire                        ram_sel,        //
    //HOST values
    input   wire    [HOST_W-1:0]        hdata,          //
    input   wire    [HOST_ADR_W-1:0]    haddr,          //
    input   wire    [HOST_W/8-1:0]        hwmask,         //16x8 = 128
    input   wire                        hwr_en,         //
    input   wire                        hrd_en,         //
    output  wire    [HOST_W-1:0]        hdata_out,      //
    //Accelerator values
    input   wire    [SRAM_W-1:0]        adata,
    input   wire    [SRAM_ADR_W-1:0]    aaddr,
    input   wire    [SRAM_MASK_W-1:0]   awmask,         //Each time write 8 bits
    input   wire                        awr_en,
    input   wire                        ard_en,
    output  wire    [SRAM_W-1:0]        adata_out
);
    //Log2 function
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

    //Rounding floating result
    function integer ceil;
        input integer a;
        input integer b;
        begin
            ceil = (a + b - 1) / b;
        end
    endfunction

    parameter   ACTUAL_W        = `max(HOST_W, SRAM_W);
    parameter   HOST_WORD       = ceil(ACTUAL_W, HOST_W);   //Number of WORD
    parameter   HOST_WORD_L     = (log2(HOST_WORD) > 0) ? log2(HOST_WORD) : 1;          //WORD length

    parameter   ACC_WORD        = ceil(ACTUAL_W, SRAM_W);   //Number of WORD
    parameter   ACC_WORD_L      = (log2(ACC_WORD) > 0) ? log2(ACC_WORD) : 1;           //WORD length
    
    parameter   MASK_W          = ACTUAL_W / 8;
    parameter   ACC_MASK        = SRAM_W / 8;             //Each mask write 8 bits
    parameter   HOST_MASK       = HOST_W / 8;

    parameter   ACTUAL_ADDR_W   = (SRAM_W >= HOST_W) ? SRAM_ADR_W : (SRAM_ADR_W - ACC_WORD_L);

    integer     j;

    //ACCELERATOR internal signal
    reg     [ACC_WORD_L-1:0]    acc_word_value_shim;
    wire    [ACC_WORD_L-1:0]    acc_word_value;
    wire    [SRAM_ADR_W-1:0]    acc_addr;
    wire    [SRAM_W-1:0]        acc_out_data;
    wire    [SRAM_W-1:0]        acc_data_arr[ACC_WORD-1:0];

    //HOST internal signal
    reg     [HOST_WORD_L-1:0]   host_word_value_shim;
    wire    [HOST_WORD_L-1:0]   host_word_value;
    wire    [HOST_ADR_W-1:0]    host_addr;
    wire    [HOST_W-1:0]        host_out_data;
    wire    [HOST_W-1:0]        host_data_arr[HOST_WORD-1:0];
    
    //
    wire    [ACTUAL_ADDR_W-1:0] addr_0, addr_1;
    wire    [ACTUAL_W-1:0]      data_0, data_1;
    wire    [ACTUAL_W-1:0]      out_data_0, out_data_1;
    wire    [MASK_W-1:0]        mask_0, mask_1;
    wire                        rd_en_0, rd_en_1, wr_en_0, wr_en_1;
    wire                        cen_0, cen_1;
    wire    [ACTUAL_W-1:0]      host_data, acc_data, host_out, acc_out;
    reg     [MASK_W-1:0]        host_phys_wmask, acc_phys_wmask;

    //Shimming for HOST read enable signal
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            host_word_value_shim    <= {HOST_WORD_L{1'b0}};
        end
        else begin
            host_word_value_shim    <= host_word_value;   //Delay 1 cycle
        end
    end

    //Shimming for ACCELERATOR read enable signal
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            acc_word_value_shim     <= {ACC_WORD_L{1'b0}};
        end
        else if(ard_en) begin
            acc_word_value_shim     <= acc_word_value;   //Delay 1 cycle
        end
    end

    genvar i;
    generate
        if(SRAM_W > HOST_W) begin       //ACCELERATOR ENOUGH BIT
            assign  acc_addr        = aaddr;
            assign  acc_data        = adata;
            
            assign  host_word_value = haddr[HOST_WORD_L-1:0];
            assign  host_addr       = haddr[HOST_WORD_L+ACTUAL_ADDR_W-1:HOST_WORD_L];

            // assign  host_data       = {ACTUAL_W{1'b0}};
            for(i = 0; i < HOST_WORD; i = i + 1) begin
                //Write host data to RAM
                assign  host_data[i*HOST_W +: HOST_W] = hdata;
                //Read value 
                assign  host_data_arr[i]    = host_out[i*HOST_W +: HOST_W];
            end

            always @(*) begin
                host_phys_wmask = {MASK_W{1'b0}};
                acc_phys_wmask  = awmask;
                for (j = 0; j < HOST_WORD; j = j + 1) begin
                    if(j == host_word_value) begin
                        host_phys_wmask[j*HOST_MASK+:HOST_MASK]     = hwmask[HOST_MASK-1:0];
                    end
                end
            end

            assign  host_out_data   = host_data_arr[host_word_value_shim];
        end
        else if(SRAM_W < HOST_W) begin
            assign  host_addr       = haddr;
            assign  host_data       = hdata;

            assign  acc_word_value  = aaddr[ACC_WORD_L-1:0];
            assign  acc_addr        = aaddr[ACC_WORD_L+ACTUAL_ADDR_W-1:ACC_WORD_L];

            // assign  acc_data        = {ACTUAL_W{1'b0}};
            for(i = 0; i < ACC_WORD; i = i + 1) begin
                //Write host data to RAM
                assign  acc_data[i*SRAM_W +: SRAM_W] = adata;
                //Read value 
                assign  acc_data_arr[i]    = acc_out[i*SRAM_W +: SRAM_W];
            end

            always @(*) begin
                acc_phys_wmask  = {MASK_W{1'b0}};
                host_phys_wmask = hwmask;
                for (j = 0; j < ACC_WORD; j = j + 1) begin
                    if(j == acc_word_value) begin
                        acc_phys_wmask[j*ACC_MASK+:ACC_MASK]    = awmask[ACC_MASK-1:0];
                    end
                end
            end
            
            assign  acc_out_data    = acc_data_arr[acc_word_value_shim];
        end
        else if(SRAM_W == HOST_W) begin
            assign  host_addr       = haddr;
            assign  host_data       = hdata;
            assign  host_out_data   = host_out;

            assign  acc_addr        = aaddr;
            assign  acc_data        = adata;
            assign  acc_out_data    = acc_out;

            always @(*) begin
                host_phys_wmask     = hwmask;
                acc_phys_wmask      = awmask;
            end
        end
    endgenerate

    //FOR HOST
    assign  mask_0      =   (!ram_sel)  ? host_phys_wmask   : acc_phys_wmask;
    assign  data_0      =   (!ram_sel)  ? host_data         : acc_data;
    assign  addr_0      =   (!ram_sel)  ? host_addr         : acc_addr;
    assign  rd_en_0     =   (!ram_sel)  ? hrd_en            : ard_en;
    assign  wr_en_0     =   (!ram_sel)  ? hwr_en            : awr_en;
    //FOR ACCELERATOR
    assign  mask_1      =   (ram_sel)   ? host_phys_wmask   : acc_phys_wmask;
    assign  data_1      =   (ram_sel)   ? host_data         : acc_data;
    assign  addr_1      =   (ram_sel)   ? host_addr         : acc_addr;
    assign  rd_en_1     =   (ram_sel)   ? hrd_en            : ard_en;
    assign  wr_en_1     =   (ram_sel)   ? hwr_en            : awr_en;

    assign  acc_out     =   (ram_sel)   ? out_data_0        : out_data_1;
    assign  host_out    =   (!ram_sel)  ? out_data_0        : out_data_1;

    assign  cen_0       =   !(rd_en_0 | wr_en_0);  
    assign  cen_1       =   !(rd_en_1 | wr_en_1);   

    assign  hdata_out   =   host_out_data;
    assign  adata_out   =   acc_out_data;

    //HOST RAM
    ram_inferred #(
        .ADR_W(ACTUAL_ADDR_W),
        .SRAM_W(ACTUAL_W)
    ) sram_0 (
        .clk(clk),
        .rst_n(rst_n),
        .cen(cen_0),
        .rd_en(rd_en_0),
        .wr_en(wr_en_0),
        .addr(addr_0),
        .in_data(data_0),
        .wmask(mask_0),
        .outdata(out_data_0)
    );

    //ACCELERATOR RAM
    ram_inferred #(
        .ADR_W(ACTUAL_ADDR_W),
        .SRAM_W(ACTUAL_W)
    ) sram_1 (
        .clk(clk),
        .rst_n(rst_n),
        .cen(cen_1),
        .rd_en(rd_en_1),
        .wr_en(wr_en_1),
        .addr(addr_1),
        .in_data(data_1),
        .wmask(mask_1),
        .outdata(out_data_1)
    );

endmodule