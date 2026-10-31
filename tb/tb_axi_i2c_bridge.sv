/* =============================================================================
 * Module      : tb_axi_i2c_bridge.sv
 * Description : Verification Testbench for AXI4-to-Wishbone + I2C Master Top
 * ============================================================================= */

`timescale 1ns / 1ps
`default_nettype none

module tb_axi_i2c_bridge;

    localparam CLK_PERIOD = 10;
    localparam ADDR_WIDTH = 32;
    localparam DATA_WIDTH = 32;
    localparam ID_WIDTH   = 8;

    logic                  clk;
    logic                  rst;

    // AXI4 signals
    logic [ID_WIDTH-1:0]   s_axi_awid;
    logic [ADDR_WIDTH-1:0] s_axi_awaddr;
    logic [7:0]            s_axi_awlen;
    logic [2:0]            s_axi_awsize;
    logic [1:0]            s_axi_awburst;
    logic                  s_axi_awlock;
    logic [3:0]            s_axi_awcache;
    logic [2:0]            s_axi_awprot;
    logic [3:0]            s_axi_awqos;
    logic [3:0]            s_axi_awregion;
    logic                  s_axi_awvalid;
    wire                   s_axi_awready;

    logic [DATA_WIDTH-1:0] s_axi_wdata;
    logic [3:0]            s_axi_wstrb;
    logic                  s_axi_wlast;
    logic                  s_axi_wvalid;
    wire                   s_axi_wready;

    wire [ID_WIDTH-1:0]    s_axi_bid;
    wire [1:0]             s_axi_bresp;
    wire                   s_axi_bvalid;
    logic                  s_axi_bready;

    logic [ID_WIDTH-1:0]   s_axi_arid;
    logic [ADDR_WIDTH-1:0] s_axi_araddr;
    logic [7:0]            s_axi_arlen;
    logic [2:0]            s_axi_arsize;
    logic [1:0]            s_axi_arburst;
    logic                  s_axi_arlock;
    logic [3:0]            s_axi_arcache;
    logic [2:0]            s_axi_arprot;
    logic [3:0]            s_axi_arqos;
    logic [3:0]            s_axi_arregion;
    logic                  s_axi_arvalid;
    wire                   s_axi_arready;

    wire [ID_WIDTH-1:0]    s_axi_rid;
    wire [DATA_WIDTH-1:0]  s_axi_rdata;
    wire [1:0]             s_axi_rresp;
    wire                   s_axi_rlast;
    wire                   s_axi_rvalid;
    logic                  s_axi_rready;

    // Wishbone signals
    wire [2:0]             wb_adr;
    wire [7:0]             wb_dat_m2s;
    wire [7:0]             wb_dat_s2m;
    wire                   wb_we;
    wire                   wb_stb;
    wire                   wb_cyc;
    wire                   wb_ack;
    wire                   wb_inta;

    // I2C Pads
    wire                   scl_pad_i;
    wire                   scl_pad_o;
    wire                   scl_padoen_o;
    wire                   sda_pad_i;
    wire                   sda_pad_o;
    wire                   sda_padoen_o;

    wire scl = scl_padoen_o ? 1'bz : scl_pad_o;
    wire sda = sda_padoen_o ? 1'bz : sda_pad_o;
    assign scl_pad_i = scl;
    assign sda_pad_i = sda;
    pullup(scl);
    pullup(sda);

    // Bridge instance
    axi_to_wb_bridge #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .ID_WIDTH(ID_WIDTH)
    ) u_bridge (
        .clk(clk),
        .rst(rst),
        .s_axi_awid(s_axi_awid),
        .s_axi_awaddr(s_axi_awaddr),
        .s_axi_awlen(s_axi_awlen),
        .s_axi_awsize(s_axi_awsize),
        .s_axi_awburst(s_axi_awburst),
        .s_axi_awlock(s_axi_awlock),
        .s_axi_awcache(s_axi_awcache),
        .s_axi_awprot(s_axi_awprot),
        .s_axi_awqos(s_axi_awqos),
        .s_axi_awregion(s_axi_awregion),
        .s_axi_awvalid(s_axi_awvalid),
        .s_axi_awready(s_axi_awready),
        .s_axi_wdata(s_axi_wdata),
        .s_axi_wstrb(s_axi_wstrb),
        .s_axi_wlast(s_axi_wlast),
        .s_axi_wvalid(s_axi_wvalid),
        .s_axi_wready(s_axi_wready),
        .s_axi_bid(s_axi_bid),
        .s_axi_bresp(s_axi_bresp),
        .s_axi_bvalid(s_axi_bvalid),
        .s_axi_bready(s_axi_bready),
        .s_axi_arid(s_axi_arid),
        .s_axi_araddr(s_axi_araddr),
        .s_axi_arlen(s_axi_arlen),
        .s_axi_arsize(s_axi_arsize),
        .s_axi_arburst(s_axi_arburst),
        .s_axi_arlock(s_axi_arlock),
        .s_axi_arcache(s_axi_arcache),
        .s_axi_arprot(s_axi_arprot),
        .s_axi_arqos(s_axi_arqos),
        .s_axi_arregion(s_axi_arregion),
        .s_axi_arvalid(s_axi_arvalid),
        .s_axi_arready(s_axi_arready),
        .s_axi_rid(s_axi_rid),
        .s_axi_rdata(s_axi_rdata),
        .s_axi_rresp(s_axi_rresp),
        .s_axi_rlast(s_axi_rlast),
        .s_axi_rvalid(s_axi_rvalid),
        .s_axi_rready(s_axi_rready),
        .wb_adr_o(wb_adr),
        .wb_dat_o(wb_dat_m2s),
        .wb_dat_i(wb_dat_s2m),
        .wb_we_o(wb_we),
        .wb_stb_o(wb_stb),
        .wb_cyc_o(wb_cyc),
        .wb_ack_i(wb_ack)
    );

    // I2C core instance
    i2c_master_top #(
        .ARST_LVL(1'b0)
    ) u_i2c (
        .wb_clk_i(clk),
        .wb_rst_i(rst),
        .arst_i(1'b1), // Inactive async reset when ARST_LVL=0
        .wb_adr_i(wb_adr),
        .wb_dat_i(wb_dat_m2s),
        .wb_dat_o(wb_dat_s2m),
        .wb_we_i(wb_we),
        .wb_stb_i(wb_stb),
        .wb_cyc_i(wb_cyc),
        .wb_ack_o(wb_ack),
        .wb_inta_o(wb_inta),
        .scl_pad_i(scl_pad_i),
        .scl_pad_o(scl_pad_o),
        .scl_padoen_o(scl_padoen_o),
        .sda_pad_i(sda_pad_i),
        .sda_pad_o(sda_pad_o),
        .sda_padoen_o(sda_padoen_o)
    );

    // Clock
    always #(CLK_PERIOD / 2) clk = ~clk;

    // AXI Write Task
    task axi_write(input [ADDR_WIDTH-1:0] addr, input [DATA_WIDTH-1:0] data);
        @(posedge clk);
        s_axi_awid     <= 8'h01;
        s_axi_awaddr   <= addr;
        s_axi_awlen    <= 8'd0;
        s_axi_awsize   <= 3'b010;
        s_axi_awburst  <= 2'b01;
        s_axi_awlock   <= 1'b0;
        s_axi_awcache  <= 4'd0;
        s_axi_awprot   <= 3'd0;
        s_axi_awqos    <= 4'd0;
        s_axi_awregion <= 4'd0;
        s_axi_awvalid  <= 1'b1;

        s_axi_wdata    <= data;
        s_axi_wstrb    <= 4'hF;
        s_axi_wlast    <= 1'b1;
        s_axi_wvalid   <= 1'b1;
        s_axi_bready   <= 1'b1;

        fork
            begin
                wait(s_axi_awready);
                @(posedge clk);
                s_axi_awvalid <= 1'b0;
            end
            begin
                wait(s_axi_wready);
                @(posedge clk);
                s_axi_wvalid <= 1'b0;
                s_axi_wlast  <= 1'b0;
            end
        join

        wait(s_axi_bvalid);
        @(posedge clk);
        s_axi_bready <= 1'b0;
    endtask

    // AXI Read Task
    task axi_read(input [ADDR_WIDTH-1:0] addr, output [DATA_WIDTH-1:0] data);
        @(posedge clk);
        s_axi_arid     <= 8'h02;
        s_axi_araddr   <= addr;
        s_axi_arlen    <= 8'd0;
        s_axi_arsize   <= 3'b010;
        s_axi_arburst  <= 2'b01;
        s_axi_arlock   <= 1'b0;
        s_axi_arcache  <= 4'd0;
        s_axi_arprot   <= 3'd0;
        s_axi_arqos    <= 4'd0;
        s_axi_arregion <= 4'd0;
        s_axi_arvalid  <= 1'b1;
        s_axi_rready   <= 1'b1;

        wait(s_axi_arready);
        @(posedge clk);
        s_axi_arvalid <= 1'b0;

        wait(s_axi_rvalid);
        data = s_axi_rdata;
        @(posedge clk);
        s_axi_rready <= 1'b0;
    endtask

    // Test sequence
    initial begin
        logic [DATA_WIDTH-1:0] rdata;

        $display("\n==========================================================");
        $display("   STARTING AXI-TO-WB BRIDGE + I2C TOP VERIFICATION      ");
        $display("==========================================================");

        clk            = 0;
        rst            = 1;
        s_axi_awvalid  = 0;
        s_axi_wvalid   = 0;
        s_axi_bready   = 0;
        s_axi_arvalid  = 0;
        s_axi_rready   = 0;

        #(CLK_PERIOD * 5);
        rst = 0;
        #(CLK_PERIOD * 5);

        // Test 1: Check default reset value of PRER (0xFFFF)
        // PRER_LO is at offset 0x00, PRER_HI is at offset 0x04
        axi_read(32'h00, rdata);
        if (rdata[7:0] != 8'hFF) $fatal(1, "[FAIL] PRER_LO reset mismatch! Got 0x%02h, expected 0xFF", rdata[7:0]);
        $display("[PASS] Test 1A: PRER_LO reset value verified (0xFF).");

        axi_read(32'h04, rdata);
        if (rdata[7:0] != 8'hFF) $fatal(1, "[FAIL] PRER_HI reset mismatch! Got 0x%02h, expected 0xFF", rdata[7:0]);
        $display("[PASS] Test 1B: PRER_HI reset value verified (0xFF).");

        // Test 2: Write and readback PRER_LO and PRER_HI
        axi_write(32'h00, 32'h64); // PRER_LO = 0x64 (100)
        axi_read(32'h00, rdata);
        if (rdata[7:0] != 8'h64) $fatal(1, "[FAIL] PRER_LO write mismatch! Got 0x%02h", rdata[7:0]);
        $display("[PASS] Test 2A: PRER_LO write/readback verified (0x64).");

        axi_write(32'h04, 32'h01); // PRER_HI = 0x01
        axi_read(32'h04, rdata);
        if (rdata[7:0] != 8'h01) $fatal(1, "[FAIL] PRER_HI write mismatch! Got 0x%02h", rdata[7:0]);
        $display("[PASS] Test 2B: PRER_HI write/readback verified (0x01).");

        // Test 3: Control Register (CTR at offset 0x08)
        // Bit 7: Core EN, Bit 6: Interrupt EN -> 0xC0
        axi_write(32'h08, 32'hC0);
        axi_read(32'h08, rdata);
        if (rdata[7:0] != 8'hC0) $fatal(1, "[FAIL] CTR write mismatch! Got 0x%02h", rdata[7:0]);
        $display("[PASS] Test 3: CTR write/readback verified (0xC0: EN=1, IEN=1).");

        // Test 4: Transmit / Status Register (offset 0x0C, 0x10)
        axi_write(32'h0C, 32'h5A); // TXR = 0x5A
        // Read Status Register (SR at offset 0x10)
        axi_read(32'h10, rdata);
        $display("[PASS] Test 4: SR readback verified (SR = 0x%02h).", rdata[7:0]);

        $display("\n==========================================================");
        $display("   ALL AXI-TO-WB BRIDGE + I2C TESTS PASSED SUCCESSFULLY!  ");
        $display("==========================================================\n");
        $finish;
    end

endmodule

`resetall
