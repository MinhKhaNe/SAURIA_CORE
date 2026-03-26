`timescale 1ns/1ps

module tb_ram_top;

    // Parameters
    parameter HOST_W      = 32;
    parameter HOST_ADDR_W = 32;
    parameter SRAMA_ADR_W = 10;
    parameter SRAMA_W     = 128;
    parameter SRAMB_ADR_W = 10;
    parameter SRAMB_W     = 128;
    parameter SRAMC_ADR_W = 10;
    parameter SRAMC_W     = 128;
    parameter SRAMC_MW    = 16;   

    // Clock & Reset
    reg clk;
    reg rst_n;

    // Host interface
    reg  [HOST_W-1:0]      hdata;
    reg  [HOST_ADDR_W-1:0] haddr;
    reg  [HOST_W/8-1:0]    hwmask;
    reg                    hrd_en;
    reg                    hwr_en;
    wire [HOST_W-1:0]      data_out;

    // SRAM select
    reg [2:0] sram_sel;

    // DUT
    ram_top #(
        .HOST_W(HOST_W),
        .HOST_ADDR_W(HOST_ADDR_W),
        .SRAMA_ADR_W(SRAMA_ADR_W),
        .SRAMA_W(SRAMA_W),
        .SRAMB_ADR_W(SRAMB_ADR_W),
        .SRAMB_W(SRAMB_W),
        .SRAMC_ADR_W(SRAMC_ADR_W),
        .SRAMC_W(SRAMC_W),
        .SRAMC_MW(SRAMC_MW)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .sram_sel(sram_sel),

        .hdata(hdata),
        .haddr(haddr),
        .hwmask(hwmask),
        .hrd_en(hrd_en),
        .hwr_en(hwr_en),
        .data_out(data_out),

        // SRAM A
        .srama_addr('0),
        .srama_rd_en(1'b0),
        .srama_data(),

        // SRAM B
        .sramb_addr('0),
        .sramb_rd_en(1'b0),
        .sramb_data(),

        // SRAM C (FIX FULL WIDTH)
        .sramc_data_in('0),
        .sramc_addr('0),
        .sramc_rd_en(1'b0),
        .sramc_wr_en(1'b0),
        .sramc_wmask('0),
        .sramc_data()
    );

    always #5 clk = ~clk;

    localparam SRAMA_OFFSET = 32'h0004_0000;
    localparam SRAMB_OFFSET = 32'h0008_0000;
    localparam SRAMC_OFFSET = 32'h000C_0000;

    task host_write(input [31:0] addr, input [31:0] data);
    begin
        @(posedge clk);
        haddr  <= addr;
        hdata  <= data;
        hwr_en <= 1;
        hrd_en <= 0;

        @(posedge clk);
        hwr_en <= 0;

        @(posedge clk);
    end
    endtask

    task host_write_mask(
        input [31:0] addr,
        input [31:0] data,
        input [3:0]  mask   // 4 byte mask
    );
    begin
        @(posedge clk);
        haddr   <= addr;
        hdata   <= data;
        hwmask  <= mask;
        hwr_en  <= 1;
        hrd_en  <= 0;

        @(posedge clk);
        hwr_en <= 0;

        @(posedge clk);
    end
    endtask

    task write_byte_by_byte(input [31:0] addr);
    begin
        host_write_mask(addr, 32'h0000_0000, 4'b1111);
        host_write_mask(addr, 32'h0000_00AA, 4'b0001);
        host_write_mask(addr, 32'h0000_BB00, 4'b0010);
        host_write_mask(addr, 32'h00CC_0000, 4'b0100);
        host_write_mask(addr, 32'hDD00_0000, 4'b1000);

        host_read(addr);
    end
    endtask

    task write_halfword(input [31:0] addr);
    begin
        host_write_mask(addr, 32'h0000_0000, 4'b1111);
        host_write_mask(addr, 32'h0000_AAAA, 4'b0011);
        host_write_mask(addr, 32'hBBBB_0000, 4'b1100);
        host_read(addr); 
    end
    endtask

    task overwrite_partial(input [31:0] addr);
    begin
        host_write_mask(addr, 32'hDEAD_BEEF, 4'b1111);
        host_write_mask(addr, 32'h00AA_BB00, 4'b0110);
        host_read(addr); 
    end
    endtask

    task write_unaligned_line(input [31:0] base_addr);
    begin
        host_write_mask(base_addr + 0, 32'h1111_1111, 4'b1111);
        host_write_mask(base_addr + 4, 32'h2222_2222, 4'b0011);
        host_write_mask(base_addr + 8, 32'h3333_3333, 4'b1111);
        host_write_mask(base_addr + 12, 32'h4444_4444, 4'b1100);
        read_128(base_addr);
    end
    endtask

    task random_mask_test(input [31:0] addr);
        reg [31:0] rand_data;
        reg [3:0]  rand_mask;
    begin
        repeat (10) begin
            rand_data = $random;
            rand_mask = $random;

            host_write_mask(addr, rand_data, rand_mask);
            host_read(addr);
        end
    end
    endtask

    task host_read(input [31:0] addr);
    begin
        @(posedge clk);
        haddr  <= addr;
        hrd_en <= 1;      
        hwr_en <= 0;

        @(posedge clk);
        hrd_en <= 0;      

        repeat(1) @(posedge clk);
        hrd_en <= 1;             
        @(posedge clk);
        hrd_en <= 0;

        $display("[READ] addr=%h data=%h", addr, data_out);
    end
    endtask

    task write_128(input [31:0] base_addr);
    begin
        host_write(base_addr + 0 , 32'hAAAA_1111); // word 0
        host_write(base_addr + 4 , 32'hBBBB_2222); // word 1
        host_write(base_addr + 8 , 32'hCCCC_3333); // word 2
        host_write(base_addr + 12 , 32'hDDDD_4444); // word 3
    end
    endtask

    task read_128(input [31:0] base_addr);
    begin
        host_read(base_addr + 0 );
        host_read(base_addr + 4 );
        host_read(base_addr + 8 );
        host_read(base_addr + 12 );
    end
    endtask

    always @(posedge clk) begin
        if (hwr_en)
            $display("\n===== WRITE addr=%h data=%h mask=%b sel=%b =====",
                    haddr, hdata, hwmask, sram_sel);

        if (hrd_en)
            $display("\n===== READ  addr=%h sel=%b =====", haddr, sram_sel);
    end

    initial begin
        clk = 0;
        rst_n = 0;

        hdata = 0;
        haddr = 0;
        hwmask = '1;
        hrd_en = 0;
        hwr_en = 0;

        sram_sel = 3'b000; // HOST control

        #20;
        rst_n = 1;
        #1;
        $display("==== SRAM A ====");
        write_128(SRAMA_OFFSET);
        read_128 (SRAMA_OFFSET);

        $display("==== SRAM B ====");
        write_128(SRAMB_OFFSET);
        read_128 (SRAMB_OFFSET);

        $display("==== SRAM C ====");
        write_128(SRAMC_OFFSET);
        read_128 (SRAMC_OFFSET);

        $display("==== MASK TEST SRAM A ====");
        write_byte_by_byte(SRAMA_OFFSET);
        write_halfword(SRAMA_OFFSET + 4);
        overwrite_partial(SRAMA_OFFSET + 8);
        write_unaligned_line(SRAMA_OFFSET);
        random_mask_test(SRAMA_OFFSET + 12);

        sram_sel = 3'b111;
        #20;
        rst_n = 1;
        #1;
        $display("==== SRAM A ====");
        write_128(SRAMA_OFFSET);
        read_128 (SRAMA_OFFSET);

        $display("==== SRAM B ====");
        write_128(SRAMB_OFFSET);
        read_128 (SRAMB_OFFSET);

        $display("==== SRAM C ====");
        write_128(SRAMC_OFFSET);
        read_128 (SRAMC_OFFSET);

        $display("==== MASK TEST SRAM A ====");
        write_byte_by_byte(SRAMA_OFFSET);
        write_halfword(SRAMA_OFFSET + 4);
        overwrite_partial(SRAMA_OFFSET + 8);
        write_unaligned_line(SRAMA_OFFSET);
        random_mask_test(SRAMA_OFFSET + 12);


        #100;
        $finish;
    end

endmodule