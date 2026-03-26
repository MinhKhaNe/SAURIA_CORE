module ram_inferred #(
    parameter   ADR_W     = 10,
    parameter   SRAM_W    = 128
)(
    input   wire                    clk,
    input   wire                    rst_n,
    input   wire                    cen,        //Active low chip enable
    input   wire                    rd_en,
    input   wire                    wr_en,
    input   wire    [ADR_W-1:0]     addr,
    input   wire    [SRAM_W-1:0]    in_data,
    input   wire    [SRAM_W/8-1:0]  wmask,      //Each time write 8 bits

    output  reg     [SRAM_W-1:0]    outdata
);
    integer i;
    reg [SRAM_W-1:0]    mem [(2**ADR_W)-1:0];   //1024 registers

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            outdata <= {SRAM_W{1'b0}};

            for (i = 0; i < (1<<ADR_W); i = i + 1) begin
                mem[i] <= 0;
            end
        end
        else if(!cen) begin
            if(wr_en) begin
                for(i = 0; i < SRAM_W/8; i = i + 1) begin
                    if(wmask[i]) begin
                        mem[addr][8*i +: 8] <= in_data[8*i +: 8];
                    end
                end
            end
            else if(rd_en) begin
                outdata <= mem[addr];
            end
        end
    end

endmodule