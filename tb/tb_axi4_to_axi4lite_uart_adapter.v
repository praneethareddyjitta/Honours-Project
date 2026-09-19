// -----------------------------------------------------------------------------
// tb_axi4_to_axi4lite_uart_adapter.v
// AXI4 master BFM -> axi4_to_axi4lite_uart_adapter -> REAL axi_uart_top
// (uart_tx looped back to uart_rx).  A behavioural pulse-style AXI-Lite stub
// (same handshake style as the real UART) can be muxed in to prove that
// BRESP/RRESP/RDATA from the UART side are propagated.
//
// Run:  ./run_sim.sh
// -----------------------------------------------------------------------------
//`timescale 1ns / 1ps
`default_nettype none

module tb_axi4_to_axi4lite_uart_adapter;

localparam AXI_ID_W = 8;
reg clk = 1'b0;
reg rst = 1'b1;
integer errors = 0;
always #5 clk = ~clk;                 // 100 MHz

// ---------------- AXI4 master side (driven by BFM) -------------------------
reg  [AXI_ID_W-1:0] s_axi_awid = 0;   reg [31:0] s_axi_awaddr = 0;
reg  [7:0] s_axi_awlen = 0;           reg [2:0]  s_axi_awsize = 3'd2;
reg  [1:0] s_axi_awburst = 2'b01;     reg        s_axi_awvalid = 0;
wire       s_axi_awready;
reg  [31:0] s_axi_wdata = 0;          reg [3:0]  s_axi_wstrb = 4'hF;
reg        s_axi_wlast = 0;           reg        s_axi_wvalid = 0;
wire       s_axi_wready;
wire [AXI_ID_W-1:0] s_axi_bid;        wire [1:0] s_axi_bresp;
wire       s_axi_bvalid;              reg        s_axi_bready = 0;
reg  [AXI_ID_W-1:0] s_axi_arid = 0;   reg [31:0] s_axi_araddr = 0;
reg  [7:0] s_axi_arlen = 0;           reg [2:0]  s_axi_arsize = 3'd2;
reg  [1:0] s_axi_arburst = 2'b01;     reg        s_axi_arvalid = 0;
wire       s_axi_arready;
wire [AXI_ID_W-1:0] s_axi_rid;        wire [31:0] s_axi_rdata;
wire [1:0] s_axi_rresp;               wire       s_axi_rlast;
wire       s_axi_rvalid;              reg        s_axi_rready = 0;

`include "axi_bfm.vh"

// ---------------- adapter <-> UART ------------------------------------------
wire        uart_aresetn;
wire [11:0] m_awid, m_arid;   wire [4:0] m_awaddr, m_araddr;
wire        m_awvalid, m_wvalid, m_bready, m_arvalid, m_rready;
wire [31:0] m_wdata;          wire [3:0] m_wstrb;
reg         stub_sel = 1'b0;

wire        u_awready, u_wready, u_bvalid, u_arready, u_rvalid;
wire [11:0] u_bid, u_rid;     wire [1:0] u_bresp, u_rresp;
wire [31:0] u_rdata;
wire        uart_tx, uart_irq;

// pulse-style stub (mimics the real UART's 1-cycle B/R pulses), returns SLVERR
reg  st_w = 0, st_r = 0;
always @(posedge clk) begin
    st_w <= m_awvalid & m_wvalid & stub_sel & ~st_w;
    st_r <= m_arvalid & stub_sel & ~st_r;
end
wire st_awready = st_w & m_awvalid & m_wvalid;
wire st_arready = st_r & m_arvalid;

wire a_awready = stub_sel ? st_awready : u_awready;
wire a_wready  = stub_sel ? st_awready : u_wready;
wire a_bvalid  = stub_sel ? st_w       : u_bvalid;
wire [1:0] a_bresp = stub_sel ? 2'b10  : u_bresp;
wire a_arready = stub_sel ? st_arready : u_arready;
wire a_rvalid  = stub_sel ? st_r       : u_rvalid;
wire [31:0] a_rdata = stub_sel ? 32'hDEADBEEF : u_rdata;
wire [1:0] a_rresp = stub_sel ? 2'b10  : u_rresp;

axi4_to_axi4lite_uart_adapter #(.ID_WIDTH(AXI_ID_W)) dut (
    .clk(clk), .rst(rst),
    .s_axi_awid(s_axi_awid), .s_axi_awaddr(s_axi_awaddr), .s_axi_awlen(s_axi_awlen),
    .s_axi_awsize(s_axi_awsize), .s_axi_awburst(s_axi_awburst), .s_axi_awlock(1'b0),
    .s_axi_awcache(4'd0), .s_axi_awprot(3'd0), .s_axi_awqos(4'd0), .s_axi_awregion(4'd0),
    .s_axi_awuser(1'b0), .s_axi_awvalid(s_axi_awvalid), .s_axi_awready(s_axi_awready),
    .s_axi_wdata(s_axi_wdata), .s_axi_wstrb(s_axi_wstrb), .s_axi_wlast(s_axi_wlast),
    .s_axi_wuser(1'b0), .s_axi_wvalid(s_axi_wvalid), .s_axi_wready(s_axi_wready),
    .s_axi_bid(s_axi_bid), .s_axi_bresp(s_axi_bresp), .s_axi_buser(),
    .s_axi_bvalid(s_axi_bvalid), .s_axi_bready(s_axi_bready),
    .s_axi_arid(s_axi_arid), .s_axi_araddr(s_axi_araddr), .s_axi_arlen(s_axi_arlen),
    .s_axi_arsize(s_axi_arsize), .s_axi_arburst(s_axi_arburst), .s_axi_arlock(1'b0),
    .s_axi_arcache(4'd0), .s_axi_arprot(3'd0), .s_axi_arqos(4'd0), .s_axi_arregion(4'd0),
    .s_axi_aruser(1'b0), .s_axi_arvalid(s_axi_arvalid), .s_axi_arready(s_axi_arready),
    .s_axi_rid(s_axi_rid), .s_axi_rdata(s_axi_rdata), .s_axi_rresp(s_axi_rresp),
    .s_axi_rlast(s_axi_rlast), .s_axi_ruser(), .s_axi_rvalid(s_axi_rvalid),
    .s_axi_rready(s_axi_rready),
    .uart_aresetn(uart_aresetn),
    .m_axil_awid(m_awid), .m_axil_awaddr(m_awaddr), .m_axil_awvalid(m_awvalid),
    .m_axil_awready(a_awready),
    .m_axil_wdata(m_wdata), .m_axil_wstrb(m_wstrb), .m_axil_wvalid(m_wvalid),
    .m_axil_wready(a_wready),
    .m_axil_bid(u_bid), .m_axil_bresp(a_bresp), .m_axil_bvalid(a_bvalid),
    .m_axil_bready(m_bready),
    .m_axil_arid(m_arid), .m_axil_araddr(m_araddr), .m_axil_arvalid(m_arvalid),
    .m_axil_arready(a_arready),
    .m_axil_rid(u_rid), .m_axil_rdata(a_rdata), .m_axil_rresp(a_rresp),
    .m_axil_rvalid(a_rvalid), .m_axil_rready(m_rready)
);

axi_uart_top uart (
    .fixed_clk_i  (clk),
    .axi_aclk_i   (clk),
    .axi_aresetn_i(uart_aresetn),
    .axi_arid_i   (m_arid),
    .axi_araddr_i (m_araddr),
    .axi_arvalid_i(m_arvalid & ~stub_sel),
    .axi_arready_o(u_arready),
    .axi_rid_o    (u_rid),
    .axi_rdata_o  (u_rdata),
    .axi_rresp_o  (u_rresp),
    .axi_rvalid_o (u_rvalid),
    .axi_rready_i (m_rready),
    .axi_awid_i   (m_awid),
    .axi_awaddr_i (m_awaddr),
    .axi_awvalid_i(m_awvalid & ~stub_sel),
    .axi_awready_o(u_awready),
    .axi_wdata_i  (m_wdata),
    .axi_wstrb_i  (m_wstrb),
    .axi_wvalid_i (m_wvalid & ~stub_sel),
    .axi_wready_o (u_wready),
    .axi_bid_o    (u_bid),
    .axi_bresp_o  (u_bresp),
    .axi_bvalid_o (u_bvalid),
    .axi_bready_i (m_bready),
    .read_interrupt_o(uart_irq),
    .uart_rx_i    (uart_tx),      // loopback
    .uart_tx_o    (uart_tx)
);

// =============================================================================
// Protocol / integrity checkers
// =============================================================================
reg        p_awv=0, p_awr=0, p_wv=0, p_wr=0, p_arv=0, p_arr=0, p_bv=0, p_br=0, p_rv=0, p_rr=0;
reg [4:0]  p_awa=0, p_ara=0;  reg [31:0] p_wd=0;  reg [3:0] p_ws=0;
reg [7:0]  p_bid=0, p_rid=0;  reg [1:0] p_bresp=0, p_rresp=0; reg [31:0] p_rdata=0; reg p_rlast=0;
integer aw_cnt=0, wl_cnt=0, b_cnt=0;               // AXI4 side handshakes
integer u_aw_hs=0, u_w_hs=0, u_ar_hs=0;             // UART side handshakes
integer u_b_seen=0, u_r_seen=0;

always @(posedge clk) begin
    if (!rst) begin
        // ---- AXI4-Lite side: VALID stays until READY, payload stable ----------
        if (p_awv && !p_awr) begin
            check(m_awvalid, "UART-side AWVALID dropped before AWREADY");
            check(m_awaddr == p_awa, "UART-side AWADDR changed while AWVALID");
        end
        if (p_wv && !p_wr) begin
            check(m_wvalid, "UART-side WVALID dropped before WREADY");
            check(m_wdata == p_wd && m_wstrb == p_ws, "UART-side WDATA/WSTRB changed");
        end
        if (p_arv && !p_arr) begin
            check(m_arvalid, "UART-side ARVALID dropped before ARREADY");
            check(m_araddr == p_ara, "UART-side ARADDR changed while ARVALID");
        end
        // UART requires AW and W presented together
        check(m_awvalid === m_wvalid, "AWVALID/WVALID to UART not presented together");
        // B / R pulse must be accepted (BREADY/RREADY high while pulse present)
        if (a_bvalid) begin check(m_bready, "UART B pulse while BREADY low (would be lost)"); u_b_seen = u_b_seen + 1; end
        if (a_rvalid) begin check(m_rready, "UART R pulse while RREADY low (would be lost)"); u_r_seen = u_r_seen + 1; end

        // ---- AXI4 side: responses held until READY --------------------------
        if (p_bv && !p_br) begin
            check(s_axi_bvalid && s_axi_bid == p_bid && s_axi_bresp == p_bresp,
                  "AXI4 B channel not held/stable until BREADY");
        end
        if (p_rv && !p_rr) begin
            check(s_axi_rvalid && s_axi_rid == p_rid && s_axi_rdata == p_rdata &&
                  s_axi_rresp == p_rresp && s_axi_rlast == p_rlast,
                  "AXI4 R channel not held/stable until RREADY");
        end
        // ---- B may only appear after both AW and WLAST were accepted ---------
        if (s_axi_bvalid) check(aw_cnt > b_cnt && wl_cnt > b_cnt, "BVALID before AW+W complete");
        if (s_axi_awvalid && s_axi_awready) aw_cnt = aw_cnt + 1;
        if (s_axi_wvalid && s_axi_wready && s_axi_wlast) wl_cnt = wl_cnt + 1;
        if (s_axi_bvalid && s_axi_bready) b_cnt = b_cnt + 1;
        // ---- UART-side handshake counters -----------------------------------
        if (m_awvalid && a_awready) u_aw_hs = u_aw_hs + 1;
        if (m_wvalid  && a_wready)  u_w_hs  = u_w_hs + 1;
        if (m_arvalid && a_arready) u_ar_hs = u_ar_hs + 1;
    end
    p_awv <= m_awvalid; p_awr <= a_awready; p_wv <= m_wvalid; p_wr <= a_wready;
    p_arv <= m_arvalid; p_arr <= a_arready; p_awa <= m_awaddr; p_ara <= m_araddr;
    p_wd <= m_wdata; p_ws <= m_wstrb;
    p_bv <= s_axi_bvalid; p_br <= s_axi_bready; p_bid <= s_axi_bid; p_bresp <= s_axi_bresp;
    p_rv <= s_axi_rvalid; p_rr <= s_axi_rready; p_rid <= s_axi_rid; p_rdata <= s_axi_rdata;
    p_rresp <= s_axi_rresp; p_rlast <= s_axi_rlast;
end

// =============================================================================
// Stimulus
// =============================================================================
reg [1:0]  rsp;  reg [31:0] rd;  reg [7:0] bid;  integer nb;
integer    exp_wr = 0, exp_rd = 0;             // expected UART-side transactions
integer    k, timeout;

localparam REG_RBR = 32'h00, REG_THR = 32'h00, REG_IER = 32'h04, REG_DIV = 32'h08,
           REG_LCR = 32'h0C, REG_LSR = 32'h14;

task wr32(input [31:0] a, input [31:0] d, input integer awd, input integer wd, input integer bd);
    begin axi_write(8'hA5, a, 0, 3'd2, d, 4'hF, awd, wd, bd, rsp, bid);
          check(rsp == 2'b00, "write expected OKAY");
          check(bid == 8'hA5, "BID mismatch"); exp_wr = exp_wr + 1; end
endtask

task rd32(input [31:0] a, input integer rdly, output [31:0] d);
    begin axi_read(8'h5A, a, 0, 3'd2, 0, rdly, rsp, d, nb);
          check(rsp == 2'b00 && nb == 1, "read expected OKAY, 1 beat"); exp_rd = exp_rd + 1; end
endtask

task wait_rx_ready(input integer maxpoll);
    integer n; reg [31:0] l;
    begin
        n = 0; l = 0;
        while (!l[0] && n < maxpoll) begin rd32(REG_LSR, 0, l); n = n + 1; end
        check(l[0], "timeout waiting for UART LSR data-ready");
    end
endtask

initial begin
    $dumpfile("tb_adapter.vcd"); $dumpvars(0, tb_axi4_to_axi4lite_uart_adapter);
    repeat (5) @(posedge clk);
    rst <= 1'b0;
    repeat (10) @(posedge clk);

    // ---- 1. UART configuration: DLAB=1, DIV=16, DLAB=0, IER=1 ---------------
    $display("--- T1: configure UART");
    wr32(REG_LCR, 32'h80, 0, 0, 0);
    wr32(REG_DIV, 32'd16, 0, 0, 0);
    wr32(REG_LCR, 32'h00, 0, 0, 0);
    wr32(REG_IER, 32'h01, 0, 0, 0);
    rd32(REG_LSR, 0, rd);
    check(rd[0] == 1'b0, "LSR data-ready should be 0 after reset");

    // ---- 2. write THR, AW first / W late; loopback; read RBR ----------------
    $display("--- T2: AW before W, loopback readback");
    wr32(REG_THR, 32'h41, 0, 6, 0);
    wait_rx_ready(2000);
    rd32(REG_RBR, 0, rd);
    check(rd[7:0] == 8'h41, "RBR expected 0x41 (T2)");

    // ---- 3. W before AW ------------------------------------------------------
    $display("--- T3: W before AW");
    wr32(REG_THR, 32'h42, 7, 0, 0);
    wait_rx_ready(2000);
    rd32(REG_RBR, 3, rd);
    check(rd[7:0] == 8'h42, "RBR expected 0x42 (T3)");

    // ---- 4. no transaction loss: burst of back-to-back writes ---------------
    $display("--- T4: back-to-back writes, delayed BREADY");
    wr32(REG_THR, 32'h11, 0, 0, 0);
    wr32(REG_THR, 32'h22, 0, 0, 5);
    wr32(REG_THR, 32'h33, 2, 0, 0);
    wr32(REG_THR, 32'h44, 0, 3, 9);
    repeat (1000) @(posedge clk);
    for (k = 0; k < 4; k = k + 1) begin
        wait_rx_ready(2000);
        rd32(REG_RBR, k, rd);
        case (k)
            0: check(rd[7:0] == 8'h11, "RBR expected 0x11");
            1: check(rd[7:0] == 8'h22, "RBR expected 0x22");
            2: check(rd[7:0] == 8'h33, "RBR expected 0x33");
            3: check(rd[7:0] == 8'h44, "RBR expected 0x44");
        endcase
    end
    rd32(REG_LSR, 0, rd);
    check(rd[0] == 1'b0, "RX FIFO should be empty after 4 reads");
    check(rd[6:5] == 2'b11, "LSR THRE/TEMT expected set when idle");

    // ---- 5. unsupported bursts must be rejected, UART untouched -------------
    $display("--- T5: burst rejection");
    axi_write(8'h3C, REG_THR, 8'd3, 3'd2, 32'h90, 4'hF, 0, 0, 4, rsp, bid);   // 4-beat write
    check(rsp == 2'b10, "write burst expected SLVERR");
    check(bid == 8'h3C, "BID mismatch after burst");
    axi_write(8'h3D, REG_THR, 8'd1, 3'd2, 32'h95, 4'hF, 3, 0, 0, rsp, bid);   // 2-beat, AW late
    check(rsp == 2'b10, "2-beat write burst expected SLVERR");
    wr32(REG_THR, 32'h77, 0, 0, 0);                                            // real char afterwards
    wait_rx_ready(2000);
    axi_read(8'h11, REG_RBR, 8'd3, 3'd2, 0, 2, rsp, rd, nb);                   // 4-beat read burst
    exp_rd = exp_rd + 0;                                                       // must NOT reach UART
    check(rsp == 2'b10 && nb == 4, "read burst expected 4 beats SLVERR");
    rd32(REG_RBR, 0, rd);
    check(rd[7:0] == 8'h77, "burst read must not consume RX FIFO; expected 0x77");
    rd32(REG_LSR, 0, rd);
    check(rd[0] == 1'b0, "no stray char (rejected burst writes must not reach THR)");
    axi_read(8'h12, REG_LSR, 8'd0, 3'd3, 0, 0, rsp, rd, nb);                   // AxSIZE > bus width
    check(rsp == 2'b10 && nb == 1, "ARSIZE=3 on 32-bit bus expected SLVERR");

    // ---- 6. unmapped registers / out-of-window / strobes ---------------------
    $display("--- T6: unmapped, range, strobe policy");
    axi_read(8'h21, REG_IER, 0, 3'd2, 0, 0, rsp, rd, nb);  check(rsp == 2'b10 && nb == 1, "read IER expected SLVERR (no hang)");
    axi_read(8'h22, REG_DIV, 0, 3'd2, 0, 0, rsp, rd, nb);  check(rsp == 2'b10 && nb == 1, "read DIV expected SLVERR (no hang)");
    axi_read(8'h23, REG_LCR, 0, 3'd2, 0, 0, rsp, rd, nb);  check(rsp == 2'b10 && nb == 1, "read LCR expected SLVERR (no hang)");
    axi_read(8'h24, 32'h10,  0, 3'd2, 0, 0, rsp, rd, nb);  check(rsp == 2'b10 && nb == 1, "read reg4 expected SLVERR (no hang)");
    axi_read(8'h25, 32'h1C,  0, 3'd2, 0, 0, rsp, rd, nb);  check(rsp == 2'b10 && nb == 1, "read reg7 expected SLVERR (no hang)");
    axi_read(8'h26, 32'h100, 0, 3'd2, 0, 0, rsp, rd, nb);  check(rsp == 2'b11 && nb == 1, "read beyond UART block expected DECERR");
    axi_write(8'h27, 32'h100, 0, 3'd2, 32'h0, 4'hF, 0, 0, 0, rsp, bid); check(rsp == 2'b11, "write beyond UART block expected DECERR");
    axi_write(8'h28, REG_LSR, 0, 3'd2, 32'h0, 4'hF, 0, 0, 0, rsp, bid); check(rsp == 2'b10, "write to LSR expected SLVERR");
    axi_write(8'h29, REG_THR, 0, 3'd0, 32'h5500, 4'b0010, 0, 0, 0, rsp, bid);  check(rsp == 2'b10, "THR write without lane-0 strobe expected SLVERR");
    axi_write(8'h2A, REG_DIV, 0, 3'd0, 32'h1, 4'b0001, 0, 0, 0, rsp, bid);     check(rsp == 2'b10, "partial DIV write expected SLVERR");
    axi_write(8'h2B, REG_THR, 0, 3'd2, 32'h5A, 4'b0000, 0, 0, 0, rsp, bid);    check(rsp == 2'b00, "WSTRB=0 write expected OKAY no-op");
    axi_write(8'h2C, REG_THR, 0, 3'd0, 32'h5B, 4'b0001, 0, 0, 0, rsp, bid);    check(rsp == 2'b00, "byte write lane 0 expected OKAY");
    exp_wr = exp_wr + 1;                                                        // only this one reaches UART
    wait_rx_ready(2000);
    rd32(REG_RBR, 0, rd);
    check(rd[7:0] == 8'h5B, "expected 0x5B (only the strobe-legal write may reach THR)");
    rd32(REG_LSR, 0, rd);
    check(rd[0] == 1'b0, "no stray chars after rejected/no-op writes");

    // ---- 7. UART-side response propagation (stub returns SLVERR) ------------
    $display("--- T7: BRESP / RRESP / RDATA propagation from AXI-Lite side");
    stub_sel = 1'b1; repeat (3) @(posedge clk);
    axi_write(8'hE1, REG_THR, 0, 3'd2, 32'h1, 4'hF, 0, 2, 6, rsp, bid);
    check(rsp == 2'b10 && bid == 8'hE1, "UART BRESP=SLVERR must reach AXI4 master with same ID");
    axi_read(8'hE2, REG_RBR, 0, 3'd2, 0, 5, rsp, rd, nb);
    check(rsp == 2'b10 && rd == 32'hDEADBEEF && nb == 1, "UART RRESP/RDATA must reach AXI4 master");
    stub_sel = 1'b0; repeat (3) @(posedge clk);

    // ---- 8. reset in the middle of nothing / recovery -----------------------
    $display("--- T8: mid-run reset recovery");
    rst <= 1'b1; repeat (3) @(posedge clk); rst <= 1'b0; repeat (10) @(posedge clk);
    wr32(REG_LCR, 32'h80, 0, 0, 0);  wr32(REG_DIV, 32'd16, 0, 0, 0); wr32(REG_LCR, 32'h00, 0, 0, 0);
    wr32(REG_IER, 32'h01, 0, 0, 0);
    wr32(REG_THR, 32'hC3, 0, 0, 0);
    wait_rx_ready(2000);
    rd32(REG_RBR, 0, rd);
    check(rd[7:0] == 8'hC3, "loopback after reset expected 0xC3");

    // ---- final scoreboard ----------------------------------------------------
    repeat (20) @(posedge clk);
    // UART-side handshakes only for legal transactions (stub ones bypass UART counters too)
    check(u_aw_hs == exp_wr + 1 && u_w_hs == exp_wr + 1,   // +1 : stub write of T7
          "UART-side write handshakes != expected (lost or leaked write)");
    check(u_ar_hs == exp_rd + 1, "UART-side read handshakes != expected (lost or leaked read)"); // +1 : stub read
    check(aw_cnt == b_cnt && wl_cnt == b_cnt, "AW/W/B counts differ (lost transaction)");
    if (errors == 0) $display("\n*** TB PASS: all checks passed ***");
    else             $display("\n*** TB FAIL: %0d check(s) failed ***", errors);
    $finish;
end

initial begin
    #20_000_000;
    $display("*** TB FAIL: global timeout (bus hang) ***");
    $finish;
end

endmodule
`default_nettype wire
