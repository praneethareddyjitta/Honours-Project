// -----------------------------------------------------------------------------
// tb_axi_soc_top_smoke.v : smoke test for the generated axi_soc_top wrapper.
// Drives S00 with the BFM, exercises TEST1 (write 0x41 -> UART local 0x00) and
// TEST7 (decode uart_tx_o), and confirms S01/S02 and the 9 other Mxx ports are
// cleanly passed through (tied off here, unused).
// -----------------------------------------------------------------------------
//`timescale 1ns / 1ps
`default_nettype none

module tb_axi_soc_top_smoke;

localparam DATA_WIDTH = 32, ADDR_WIDTH = 32, STRB_WIDTH = 4, ID_WIDTH = 8;
localparam AWUSER_WIDTH = 1, WUSER_WIDTH = 1, BUSER_WIDTH = 1, ARUSER_WIDTH = 1, RUSER_WIDTH = 1;
localparam [31:0] UART_BASE = 32'h0300_0000;

reg clk = 1'b0;  reg rst = 1'b1;  integer errors = 0;
always #5 clk = ~clk;

// ---- S00 (BFM-driven master) --------------------------------------------------
reg  [ID_WIDTH-1:0] s_axi_awid = 0;
reg  [ADDR_WIDTH-1:0] s_axi_awaddr = 0;
reg  [7:0] s_axi_awlen = 0;
reg  [2:0] s_axi_awsize = 0;
reg  [1:0] s_axi_awburst = 0;
reg  s_axi_awlock = 0;
reg  [3:0] s_axi_awcache = 0;
reg  [2:0] s_axi_awprot = 0;
reg  [3:0] s_axi_awqos = 0;
reg  [AWUSER_WIDTH-1:0] s_axi_awuser = 0;
reg  s_axi_awvalid = 0;
wire s_axi_awready;
reg  [DATA_WIDTH-1:0] s_axi_wdata = 0;
reg  [STRB_WIDTH-1:0] s_axi_wstrb = 0;
reg  s_axi_wlast = 0;
reg  [WUSER_WIDTH-1:0] s_axi_wuser = 0;
reg  s_axi_wvalid = 0;
wire s_axi_wready;
wire [ID_WIDTH-1:0] s_axi_bid;
wire [1:0] s_axi_bresp;
wire [BUSER_WIDTH-1:0] s_axi_buser;
wire s_axi_bvalid;
reg  s_axi_bready = 0;
reg  [ID_WIDTH-1:0] s_axi_arid = 0;
reg  [ADDR_WIDTH-1:0] s_axi_araddr = 0;
reg  [7:0] s_axi_arlen = 0;
reg  [2:0] s_axi_arsize = 0;
reg  [1:0] s_axi_arburst = 0;
reg  s_axi_arlock = 0;
reg  [3:0] s_axi_arcache = 0;
reg  [2:0] s_axi_arprot = 0;
reg  [3:0] s_axi_arqos = 0;
reg  [ARUSER_WIDTH-1:0] s_axi_aruser = 0;
reg  s_axi_arvalid = 0;
wire s_axi_arready;
wire [ID_WIDTH-1:0] s_axi_rid;
wire [DATA_WIDTH-1:0] s_axi_rdata;
wire [1:0] s_axi_rresp;
wire s_axi_rlast;
wire [RUSER_WIDTH-1:0] s_axi_ruser;
wire s_axi_rvalid;
reg  s_axi_rready = 0;

// ---- S01, S02 (tied idle/unused) -----------------------------------------------
reg  [ID_WIDTH-1:0] s01_axi_awid = 0;
reg  [ADDR_WIDTH-1:0] s01_axi_awaddr = 0;
reg  [7:0] s01_axi_awlen = 0;
reg  [2:0] s01_axi_awsize = 0;
reg  [1:0] s01_axi_awburst = 0;
reg  s01_axi_awlock = 0;
reg  [3:0] s01_axi_awcache = 0;
reg  [2:0] s01_axi_awprot = 0;
reg  [3:0] s01_axi_awqos = 0;
reg  [AWUSER_WIDTH-1:0] s01_axi_awuser = 0;
reg  s01_axi_awvalid = 0;
wire s01_axi_awready;
reg  [DATA_WIDTH-1:0] s01_axi_wdata = 0;
reg  [STRB_WIDTH-1:0] s01_axi_wstrb = 0;
reg  s01_axi_wlast = 0;
reg  [WUSER_WIDTH-1:0] s01_axi_wuser = 0;
reg  s01_axi_wvalid = 0;
wire s01_axi_wready;
wire [ID_WIDTH-1:0] s01_axi_bid;
wire [1:0] s01_axi_bresp;
wire [BUSER_WIDTH-1:0] s01_axi_buser;
wire s01_axi_bvalid;
reg  s01_axi_bready = 0;
reg  [ID_WIDTH-1:0] s01_axi_arid = 0;
reg  [ADDR_WIDTH-1:0] s01_axi_araddr = 0;
reg  [7:0] s01_axi_arlen = 0;
reg  [2:0] s01_axi_arsize = 0;
reg  [1:0] s01_axi_arburst = 0;
reg  s01_axi_arlock = 0;
reg  [3:0] s01_axi_arcache = 0;
reg  [2:0] s01_axi_arprot = 0;
reg  [3:0] s01_axi_arqos = 0;
reg  [ARUSER_WIDTH-1:0] s01_axi_aruser = 0;
reg  s01_axi_arvalid = 0;
wire s01_axi_arready;
wire [ID_WIDTH-1:0] s01_axi_rid;
wire [DATA_WIDTH-1:0] s01_axi_rdata;
wire [1:0] s01_axi_rresp;
wire s01_axi_rlast;
wire [RUSER_WIDTH-1:0] s01_axi_ruser;
wire s01_axi_rvalid;
reg  s01_axi_rready = 0;

reg  [ID_WIDTH-1:0] s02_axi_awid = 0;
reg  [ADDR_WIDTH-1:0] s02_axi_awaddr = 0;
reg  [7:0] s02_axi_awlen = 0;
reg  [2:0] s02_axi_awsize = 0;
reg  [1:0] s02_axi_awburst = 0;
reg  s02_axi_awlock = 0;
reg  [3:0] s02_axi_awcache = 0;
reg  [2:0] s02_axi_awprot = 0;
reg  [3:0] s02_axi_awqos = 0;
reg  [AWUSER_WIDTH-1:0] s02_axi_awuser = 0;
reg  s02_axi_awvalid = 0;
wire s02_axi_awready;
reg  [DATA_WIDTH-1:0] s02_axi_wdata = 0;
reg  [STRB_WIDTH-1:0] s02_axi_wstrb = 0;
reg  s02_axi_wlast = 0;
reg  [WUSER_WIDTH-1:0] s02_axi_wuser = 0;
reg  s02_axi_wvalid = 0;
wire s02_axi_wready;
wire [ID_WIDTH-1:0] s02_axi_bid;
wire [1:0] s02_axi_bresp;
wire [BUSER_WIDTH-1:0] s02_axi_buser;
wire s02_axi_bvalid;
reg  s02_axi_bready = 0;
reg  [ID_WIDTH-1:0] s02_axi_arid = 0;
reg  [ADDR_WIDTH-1:0] s02_axi_araddr = 0;
reg  [7:0] s02_axi_arlen = 0;
reg  [2:0] s02_axi_arsize = 0;
reg  [1:0] s02_axi_arburst = 0;
reg  s02_axi_arlock = 0;
reg  [3:0] s02_axi_arcache = 0;
reg  [2:0] s02_axi_arprot = 0;
reg  [3:0] s02_axi_arqos = 0;
reg  [ARUSER_WIDTH-1:0] s02_axi_aruser = 0;
reg  s02_axi_arvalid = 0;
wire s02_axi_arready;
wire [ID_WIDTH-1:0] s02_axi_rid;
wire [DATA_WIDTH-1:0] s02_axi_rdata;
wire [1:0] s02_axi_rresp;
wire s02_axi_rlast;
wire [RUSER_WIDTH-1:0] s02_axi_ruser;
wire s02_axi_rvalid;
reg  s02_axi_rready = 0;

// ---- M00-M02, M04-M09 (tied to a dummy always-ready sink) ----------------------
wire [ID_WIDTH-1:0] m00_axi_awid;
wire [ADDR_WIDTH-1:0] m00_axi_awaddr;
wire [7:0] m00_axi_awlen;
wire [2:0] m00_axi_awsize;
wire [1:0] m00_axi_awburst;
wire m00_axi_awlock;
wire [3:0] m00_axi_awcache;
wire [2:0] m00_axi_awprot;
wire [3:0] m00_axi_awqos;
wire [3:0] m00_axi_awregion;
wire [AWUSER_WIDTH-1:0] m00_axi_awuser;
wire m00_axi_awvalid;
reg  m00_axi_awready;
wire [DATA_WIDTH-1:0] m00_axi_wdata;
wire [STRB_WIDTH-1:0] m00_axi_wstrb;
wire m00_axi_wlast;
wire [WUSER_WIDTH-1:0] m00_axi_wuser;
wire m00_axi_wvalid;
reg  m00_axi_wready;
reg  [ID_WIDTH-1:0] m00_axi_bid;
reg  [1:0] m00_axi_bresp;
reg  [BUSER_WIDTH-1:0] m00_axi_buser;
reg  m00_axi_bvalid;
wire m00_axi_bready;
wire [ID_WIDTH-1:0] m00_axi_arid;
wire [ADDR_WIDTH-1:0] m00_axi_araddr;
wire [7:0] m00_axi_arlen;
wire [2:0] m00_axi_arsize;
wire [1:0] m00_axi_arburst;
wire m00_axi_arlock;
wire [3:0] m00_axi_arcache;
wire [2:0] m00_axi_arprot;
wire [3:0] m00_axi_arqos;
wire [3:0] m00_axi_arregion;
wire [ARUSER_WIDTH-1:0] m00_axi_aruser;
wire m00_axi_arvalid;
reg  m00_axi_arready;
reg  [ID_WIDTH-1:0] m00_axi_rid;
reg  [DATA_WIDTH-1:0] m00_axi_rdata;
reg  [1:0] m00_axi_rresp;
reg  m00_axi_rlast;
reg  [RUSER_WIDTH-1:0] m00_axi_ruser;
reg  m00_axi_rvalid;
wire m00_axi_rready;

wire [ID_WIDTH-1:0] m01_axi_awid;
wire [ADDR_WIDTH-1:0] m01_axi_awaddr;
wire [7:0] m01_axi_awlen;
wire [2:0] m01_axi_awsize;
wire [1:0] m01_axi_awburst;
wire m01_axi_awlock;
wire [3:0] m01_axi_awcache;
wire [2:0] m01_axi_awprot;
wire [3:0] m01_axi_awqos;
wire [3:0] m01_axi_awregion;
wire [AWUSER_WIDTH-1:0] m01_axi_awuser;
wire m01_axi_awvalid;
reg  m01_axi_awready;
wire [DATA_WIDTH-1:0] m01_axi_wdata;
wire [STRB_WIDTH-1:0] m01_axi_wstrb;
wire m01_axi_wlast;
wire [WUSER_WIDTH-1:0] m01_axi_wuser;
wire m01_axi_wvalid;
reg  m01_axi_wready;
reg  [ID_WIDTH-1:0] m01_axi_bid;
reg  [1:0] m01_axi_bresp;
reg  [BUSER_WIDTH-1:0] m01_axi_buser;
reg  m01_axi_bvalid;
wire m01_axi_bready;
wire [ID_WIDTH-1:0] m01_axi_arid;
wire [ADDR_WIDTH-1:0] m01_axi_araddr;
wire [7:0] m01_axi_arlen;
wire [2:0] m01_axi_arsize;
wire [1:0] m01_axi_arburst;
wire m01_axi_arlock;
wire [3:0] m01_axi_arcache;
wire [2:0] m01_axi_arprot;
wire [3:0] m01_axi_arqos;
wire [3:0] m01_axi_arregion;
wire [ARUSER_WIDTH-1:0] m01_axi_aruser;
wire m01_axi_arvalid;
reg  m01_axi_arready;
reg  [ID_WIDTH-1:0] m01_axi_rid;
reg  [DATA_WIDTH-1:0] m01_axi_rdata;
reg  [1:0] m01_axi_rresp;
reg  m01_axi_rlast;
reg  [RUSER_WIDTH-1:0] m01_axi_ruser;
reg  m01_axi_rvalid;
wire m01_axi_rready;

wire [ID_WIDTH-1:0] m02_axi_awid;
wire [ADDR_WIDTH-1:0] m02_axi_awaddr;
wire [7:0] m02_axi_awlen;
wire [2:0] m02_axi_awsize;
wire [1:0] m02_axi_awburst;
wire m02_axi_awlock;
wire [3:0] m02_axi_awcache;
wire [2:0] m02_axi_awprot;
wire [3:0] m02_axi_awqos;
wire [3:0] m02_axi_awregion;
wire [AWUSER_WIDTH-1:0] m02_axi_awuser;
wire m02_axi_awvalid;
reg  m02_axi_awready;
wire [DATA_WIDTH-1:0] m02_axi_wdata;
wire [STRB_WIDTH-1:0] m02_axi_wstrb;
wire m02_axi_wlast;
wire [WUSER_WIDTH-1:0] m02_axi_wuser;
wire m02_axi_wvalid;
reg  m02_axi_wready;
reg  [ID_WIDTH-1:0] m02_axi_bid;
reg  [1:0] m02_axi_bresp;
reg  [BUSER_WIDTH-1:0] m02_axi_buser;
reg  m02_axi_bvalid;
wire m02_axi_bready;
wire [ID_WIDTH-1:0] m02_axi_arid;
wire [ADDR_WIDTH-1:0] m02_axi_araddr;
wire [7:0] m02_axi_arlen;
wire [2:0] m02_axi_arsize;
wire [1:0] m02_axi_arburst;
wire m02_axi_arlock;
wire [3:0] m02_axi_arcache;
wire [2:0] m02_axi_arprot;
wire [3:0] m02_axi_arqos;
wire [3:0] m02_axi_arregion;
wire [ARUSER_WIDTH-1:0] m02_axi_aruser;
wire m02_axi_arvalid;
reg  m02_axi_arready;
reg  [ID_WIDTH-1:0] m02_axi_rid;
reg  [DATA_WIDTH-1:0] m02_axi_rdata;
reg  [1:0] m02_axi_rresp;
reg  m02_axi_rlast;
reg  [RUSER_WIDTH-1:0] m02_axi_ruser;
reg  m02_axi_rvalid;
wire m02_axi_rready;

wire [ID_WIDTH-1:0] m04_axi_awid;
wire [ADDR_WIDTH-1:0] m04_axi_awaddr;
wire [7:0] m04_axi_awlen;
wire [2:0] m04_axi_awsize;
wire [1:0] m04_axi_awburst;
wire m04_axi_awlock;
wire [3:0] m04_axi_awcache;
wire [2:0] m04_axi_awprot;
wire [3:0] m04_axi_awqos;
wire [3:0] m04_axi_awregion;
wire [AWUSER_WIDTH-1:0] m04_axi_awuser;
wire m04_axi_awvalid;
reg  m04_axi_awready;
wire [DATA_WIDTH-1:0] m04_axi_wdata;
wire [STRB_WIDTH-1:0] m04_axi_wstrb;
wire m04_axi_wlast;
wire [WUSER_WIDTH-1:0] m04_axi_wuser;
wire m04_axi_wvalid;
reg  m04_axi_wready;
reg  [ID_WIDTH-1:0] m04_axi_bid;
reg  [1:0] m04_axi_bresp;
reg  [BUSER_WIDTH-1:0] m04_axi_buser;
reg  m04_axi_bvalid;
wire m04_axi_bready;
wire [ID_WIDTH-1:0] m04_axi_arid;
wire [ADDR_WIDTH-1:0] m04_axi_araddr;
wire [7:0] m04_axi_arlen;
wire [2:0] m04_axi_arsize;
wire [1:0] m04_axi_arburst;
wire m04_axi_arlock;
wire [3:0] m04_axi_arcache;
wire [2:0] m04_axi_arprot;
wire [3:0] m04_axi_arqos;
wire [3:0] m04_axi_arregion;
wire [ARUSER_WIDTH-1:0] m04_axi_aruser;
wire m04_axi_arvalid;
reg  m04_axi_arready;
reg  [ID_WIDTH-1:0] m04_axi_rid;
reg  [DATA_WIDTH-1:0] m04_axi_rdata;
reg  [1:0] m04_axi_rresp;
reg  m04_axi_rlast;
reg  [RUSER_WIDTH-1:0] m04_axi_ruser;
reg  m04_axi_rvalid;
wire m04_axi_rready;

wire [ID_WIDTH-1:0] m05_axi_awid;
wire [ADDR_WIDTH-1:0] m05_axi_awaddr;
wire [7:0] m05_axi_awlen;
wire [2:0] m05_axi_awsize;
wire [1:0] m05_axi_awburst;
wire m05_axi_awlock;
wire [3:0] m05_axi_awcache;
wire [2:0] m05_axi_awprot;
wire [3:0] m05_axi_awqos;
wire [3:0] m05_axi_awregion;
wire [AWUSER_WIDTH-1:0] m05_axi_awuser;
wire m05_axi_awvalid;
reg  m05_axi_awready;
wire [DATA_WIDTH-1:0] m05_axi_wdata;
wire [STRB_WIDTH-1:0] m05_axi_wstrb;
wire m05_axi_wlast;
wire [WUSER_WIDTH-1:0] m05_axi_wuser;
wire m05_axi_wvalid;
reg  m05_axi_wready;
reg  [ID_WIDTH-1:0] m05_axi_bid;
reg  [1:0] m05_axi_bresp;
reg  [BUSER_WIDTH-1:0] m05_axi_buser;
reg  m05_axi_bvalid;
wire m05_axi_bready;
wire [ID_WIDTH-1:0] m05_axi_arid;
wire [ADDR_WIDTH-1:0] m05_axi_araddr;
wire [7:0] m05_axi_arlen;
wire [2:0] m05_axi_arsize;
wire [1:0] m05_axi_arburst;
wire m05_axi_arlock;
wire [3:0] m05_axi_arcache;
wire [2:0] m05_axi_arprot;
wire [3:0] m05_axi_arqos;
wire [3:0] m05_axi_arregion;
wire [ARUSER_WIDTH-1:0] m05_axi_aruser;
wire m05_axi_arvalid;
reg  m05_axi_arready;
reg  [ID_WIDTH-1:0] m05_axi_rid;
reg  [DATA_WIDTH-1:0] m05_axi_rdata;
reg  [1:0] m05_axi_rresp;
reg  m05_axi_rlast;
reg  [RUSER_WIDTH-1:0] m05_axi_ruser;
reg  m05_axi_rvalid;
wire m05_axi_rready;

wire [ID_WIDTH-1:0] m06_axi_awid;
wire [ADDR_WIDTH-1:0] m06_axi_awaddr;
wire [7:0] m06_axi_awlen;
wire [2:0] m06_axi_awsize;
wire [1:0] m06_axi_awburst;
wire m06_axi_awlock;
wire [3:0] m06_axi_awcache;
wire [2:0] m06_axi_awprot;
wire [3:0] m06_axi_awqos;
wire [3:0] m06_axi_awregion;
wire [AWUSER_WIDTH-1:0] m06_axi_awuser;
wire m06_axi_awvalid;
reg  m06_axi_awready;
wire [DATA_WIDTH-1:0] m06_axi_wdata;
wire [STRB_WIDTH-1:0] m06_axi_wstrb;
wire m06_axi_wlast;
wire [WUSER_WIDTH-1:0] m06_axi_wuser;
wire m06_axi_wvalid;
reg  m06_axi_wready;
reg  [ID_WIDTH-1:0] m06_axi_bid;
reg  [1:0] m06_axi_bresp;
reg  [BUSER_WIDTH-1:0] m06_axi_buser;
reg  m06_axi_bvalid;
wire m06_axi_bready;
wire [ID_WIDTH-1:0] m06_axi_arid;
wire [ADDR_WIDTH-1:0] m06_axi_araddr;
wire [7:0] m06_axi_arlen;
wire [2:0] m06_axi_arsize;
wire [1:0] m06_axi_arburst;
wire m06_axi_arlock;
wire [3:0] m06_axi_arcache;
wire [2:0] m06_axi_arprot;
wire [3:0] m06_axi_arqos;
wire [3:0] m06_axi_arregion;
wire [ARUSER_WIDTH-1:0] m06_axi_aruser;
wire m06_axi_arvalid;
reg  m06_axi_arready;
reg  [ID_WIDTH-1:0] m06_axi_rid;
reg  [DATA_WIDTH-1:0] m06_axi_rdata;
reg  [1:0] m06_axi_rresp;
reg  m06_axi_rlast;
reg  [RUSER_WIDTH-1:0] m06_axi_ruser;
reg  m06_axi_rvalid;
wire m06_axi_rready;

wire [ID_WIDTH-1:0] m07_axi_awid;
wire [ADDR_WIDTH-1:0] m07_axi_awaddr;
wire [7:0] m07_axi_awlen;
wire [2:0] m07_axi_awsize;
wire [1:0] m07_axi_awburst;
wire m07_axi_awlock;
wire [3:0] m07_axi_awcache;
wire [2:0] m07_axi_awprot;
wire [3:0] m07_axi_awqos;
wire [3:0] m07_axi_awregion;
wire [AWUSER_WIDTH-1:0] m07_axi_awuser;
wire m07_axi_awvalid;
reg  m07_axi_awready;
wire [DATA_WIDTH-1:0] m07_axi_wdata;
wire [STRB_WIDTH-1:0] m07_axi_wstrb;
wire m07_axi_wlast;
wire [WUSER_WIDTH-1:0] m07_axi_wuser;
wire m07_axi_wvalid;
reg  m07_axi_wready;
reg  [ID_WIDTH-1:0] m07_axi_bid;
reg  [1:0] m07_axi_bresp;
reg  [BUSER_WIDTH-1:0] m07_axi_buser;
reg  m07_axi_bvalid;
wire m07_axi_bready;
wire [ID_WIDTH-1:0] m07_axi_arid;
wire [ADDR_WIDTH-1:0] m07_axi_araddr;
wire [7:0] m07_axi_arlen;
wire [2:0] m07_axi_arsize;
wire [1:0] m07_axi_arburst;
wire m07_axi_arlock;
wire [3:0] m07_axi_arcache;
wire [2:0] m07_axi_arprot;
wire [3:0] m07_axi_arqos;
wire [3:0] m07_axi_arregion;
wire [ARUSER_WIDTH-1:0] m07_axi_aruser;
wire m07_axi_arvalid;
reg  m07_axi_arready;
reg  [ID_WIDTH-1:0] m07_axi_rid;
reg  [DATA_WIDTH-1:0] m07_axi_rdata;
reg  [1:0] m07_axi_rresp;
reg  m07_axi_rlast;
reg  [RUSER_WIDTH-1:0] m07_axi_ruser;
reg  m07_axi_rvalid;
wire m07_axi_rready;

wire [ID_WIDTH-1:0] m08_axi_awid;
wire [ADDR_WIDTH-1:0] m08_axi_awaddr;
wire [7:0] m08_axi_awlen;
wire [2:0] m08_axi_awsize;
wire [1:0] m08_axi_awburst;
wire m08_axi_awlock;
wire [3:0] m08_axi_awcache;
wire [2:0] m08_axi_awprot;
wire [3:0] m08_axi_awqos;
wire [3:0] m08_axi_awregion;
wire [AWUSER_WIDTH-1:0] m08_axi_awuser;
wire m08_axi_awvalid;
reg  m08_axi_awready;
wire [DATA_WIDTH-1:0] m08_axi_wdata;
wire [STRB_WIDTH-1:0] m08_axi_wstrb;
wire m08_axi_wlast;
wire [WUSER_WIDTH-1:0] m08_axi_wuser;
wire m08_axi_wvalid;
reg  m08_axi_wready;
reg  [ID_WIDTH-1:0] m08_axi_bid;
reg  [1:0] m08_axi_bresp;
reg  [BUSER_WIDTH-1:0] m08_axi_buser;
reg  m08_axi_bvalid;
wire m08_axi_bready;
wire [ID_WIDTH-1:0] m08_axi_arid;
wire [ADDR_WIDTH-1:0] m08_axi_araddr;
wire [7:0] m08_axi_arlen;
wire [2:0] m08_axi_arsize;
wire [1:0] m08_axi_arburst;
wire m08_axi_arlock;
wire [3:0] m08_axi_arcache;
wire [2:0] m08_axi_arprot;
wire [3:0] m08_axi_arqos;
wire [3:0] m08_axi_arregion;
wire [ARUSER_WIDTH-1:0] m08_axi_aruser;
wire m08_axi_arvalid;
reg  m08_axi_arready;
reg  [ID_WIDTH-1:0] m08_axi_rid;
reg  [DATA_WIDTH-1:0] m08_axi_rdata;
reg  [1:0] m08_axi_rresp;
reg  m08_axi_rlast;
reg  [RUSER_WIDTH-1:0] m08_axi_ruser;
reg  m08_axi_rvalid;
wire m08_axi_rready;

wire [ID_WIDTH-1:0] m09_axi_awid;
wire [ADDR_WIDTH-1:0] m09_axi_awaddr;
wire [7:0] m09_axi_awlen;
wire [2:0] m09_axi_awsize;
wire [1:0] m09_axi_awburst;
wire m09_axi_awlock;
wire [3:0] m09_axi_awcache;
wire [2:0] m09_axi_awprot;
wire [3:0] m09_axi_awqos;
wire [3:0] m09_axi_awregion;
wire [AWUSER_WIDTH-1:0] m09_axi_awuser;
wire m09_axi_awvalid;
reg  m09_axi_awready;
wire [DATA_WIDTH-1:0] m09_axi_wdata;
wire [STRB_WIDTH-1:0] m09_axi_wstrb;
wire m09_axi_wlast;
wire [WUSER_WIDTH-1:0] m09_axi_wuser;
wire m09_axi_wvalid;
reg  m09_axi_wready;
reg  [ID_WIDTH-1:0] m09_axi_bid;
reg  [1:0] m09_axi_bresp;
reg  [BUSER_WIDTH-1:0] m09_axi_buser;
reg  m09_axi_bvalid;
wire m09_axi_bready;
wire [ID_WIDTH-1:0] m09_axi_arid;
wire [ADDR_WIDTH-1:0] m09_axi_araddr;
wire [7:0] m09_axi_arlen;
wire [2:0] m09_axi_arsize;
wire [1:0] m09_axi_arburst;
wire m09_axi_arlock;
wire [3:0] m09_axi_arcache;
wire [2:0] m09_axi_arprot;
wire [3:0] m09_axi_arqos;
wire [3:0] m09_axi_arregion;
wire [ARUSER_WIDTH-1:0] m09_axi_aruser;
wire m09_axi_arvalid;
reg  m09_axi_arready;
reg  [ID_WIDTH-1:0] m09_axi_rid;
reg  [DATA_WIDTH-1:0] m09_axi_rdata;
reg  [1:0] m09_axi_rresp;
reg  m09_axi_rlast;
reg  [RUSER_WIDTH-1:0] m09_axi_ruser;
reg  m09_axi_rvalid;
wire m09_axi_rready;

wire uart_tx, uart_irq;

integer gi;
initial begin
    // ready-high / valid-low sink defaults for every exposed Mxx port
    m00_axi_awready = 1'b1; m00_axi_wready = 1'b1; m00_axi_arready = 1'b1;
    m00_axi_bvalid  = 1'b0; m00_axi_rvalid = 1'b0; m00_axi_rlast  = 1'b1;
    m00_axi_bid = 0; m00_axi_bresp = 0; m00_axi_buser = 0;
    m00_axi_rid = 0; m00_axi_rdata = 0; m00_axi_rresp = 0; m00_axi_ruser = 0;
    m01_axi_awready = 1'b1; m01_axi_wready = 1'b1; m01_axi_arready = 1'b1;
    m01_axi_bvalid  = 1'b0; m01_axi_rvalid = 1'b0; m01_axi_rlast  = 1'b1;
    m01_axi_bid = 0; m01_axi_bresp = 0; m01_axi_buser = 0;
    m01_axi_rid = 0; m01_axi_rdata = 0; m01_axi_rresp = 0; m01_axi_ruser = 0;
    m02_axi_awready = 1'b1; m02_axi_wready = 1'b1; m02_axi_arready = 1'b1;
    m02_axi_bvalid  = 1'b0; m02_axi_rvalid = 1'b0; m02_axi_rlast  = 1'b1;
    m02_axi_bid = 0; m02_axi_bresp = 0; m02_axi_buser = 0;
    m02_axi_rid = 0; m02_axi_rdata = 0; m02_axi_rresp = 0; m02_axi_ruser = 0;
    m04_axi_awready = 1'b1; m04_axi_wready = 1'b1; m04_axi_arready = 1'b1;
    m04_axi_bvalid  = 1'b0; m04_axi_rvalid = 1'b0; m04_axi_rlast  = 1'b1;
    m04_axi_bid = 0; m04_axi_bresp = 0; m04_axi_buser = 0;
    m04_axi_rid = 0; m04_axi_rdata = 0; m04_axi_rresp = 0; m04_axi_ruser = 0;
    m05_axi_awready = 1'b1; m05_axi_wready = 1'b1; m05_axi_arready = 1'b1;
    m05_axi_bvalid  = 1'b0; m05_axi_rvalid = 1'b0; m05_axi_rlast  = 1'b1;
    m05_axi_bid = 0; m05_axi_bresp = 0; m05_axi_buser = 0;
    m05_axi_rid = 0; m05_axi_rdata = 0; m05_axi_rresp = 0; m05_axi_ruser = 0;
    m06_axi_awready = 1'b1; m06_axi_wready = 1'b1; m06_axi_arready = 1'b1;
    m06_axi_bvalid  = 1'b0; m06_axi_rvalid = 1'b0; m06_axi_rlast  = 1'b1;
    m06_axi_bid = 0; m06_axi_bresp = 0; m06_axi_buser = 0;
    m06_axi_rid = 0; m06_axi_rdata = 0; m06_axi_rresp = 0; m06_axi_ruser = 0;
    m07_axi_awready = 1'b1; m07_axi_wready = 1'b1; m07_axi_arready = 1'b1;
    m07_axi_bvalid  = 1'b0; m07_axi_rvalid = 1'b0; m07_axi_rlast  = 1'b1;
    m07_axi_bid = 0; m07_axi_bresp = 0; m07_axi_buser = 0;
    m07_axi_rid = 0; m07_axi_rdata = 0; m07_axi_rresp = 0; m07_axi_ruser = 0;
    m08_axi_awready = 1'b1; m08_axi_wready = 1'b1; m08_axi_arready = 1'b1;
    m08_axi_bvalid  = 1'b0; m08_axi_rvalid = 1'b0; m08_axi_rlast  = 1'b1;
    m08_axi_bid = 0; m08_axi_bresp = 0; m08_axi_buser = 0;
    m08_axi_rid = 0; m08_axi_rdata = 0; m08_axi_rresp = 0; m08_axi_ruser = 0;
    m09_axi_awready = 1'b1; m09_axi_wready = 1'b1; m09_axi_arready = 1'b1;
    m09_axi_bvalid  = 1'b0; m09_axi_rvalid = 1'b0; m09_axi_rlast  = 1'b1;
    m09_axi_bid = 0; m09_axi_bresp = 0; m09_axi_buser = 0;
    m09_axi_rid = 0; m09_axi_rdata = 0; m09_axi_rresp = 0; m09_axi_ruser = 0;
end

`include "axi_bfm.vh"

axi_soc_top u_top (
    .clk(clk), .rst(rst),
    .s00_axi_awid(s_axi_awid),
    .s00_axi_awaddr(s_axi_awaddr),
    .s00_axi_awlen(s_axi_awlen),
    .s00_axi_awsize(s_axi_awsize),
    .s00_axi_awburst(s_axi_awburst),
    .s00_axi_awlock(s_axi_awlock),
    .s00_axi_awcache(s_axi_awcache),
    .s00_axi_awprot(s_axi_awprot),
    .s00_axi_awqos(s_axi_awqos),
    .s00_axi_awuser(s_axi_awuser),
    .s00_axi_awvalid(s_axi_awvalid),
    .s00_axi_awready(s_axi_awready),
    .s00_axi_wdata(s_axi_wdata),
    .s00_axi_wstrb(s_axi_wstrb),
    .s00_axi_wlast(s_axi_wlast),
    .s00_axi_wuser(s_axi_wuser),
    .s00_axi_wvalid(s_axi_wvalid),
    .s00_axi_wready(s_axi_wready),
    .s00_axi_bid(s_axi_bid),
    .s00_axi_bresp(s_axi_bresp),
    .s00_axi_buser(s_axi_buser),
    .s00_axi_bvalid(s_axi_bvalid),
    .s00_axi_bready(s_axi_bready),
    .s00_axi_arid(s_axi_arid),
    .s00_axi_araddr(s_axi_araddr),
    .s00_axi_arlen(s_axi_arlen),
    .s00_axi_arsize(s_axi_arsize),
    .s00_axi_arburst(s_axi_arburst),
    .s00_axi_arlock(s_axi_arlock),
    .s00_axi_arcache(s_axi_arcache),
    .s00_axi_arprot(s_axi_arprot),
    .s00_axi_arqos(s_axi_arqos),
    .s00_axi_aruser(s_axi_aruser),
    .s00_axi_arvalid(s_axi_arvalid),
    .s00_axi_arready(s_axi_arready),
    .s00_axi_rid(s_axi_rid),
    .s00_axi_rdata(s_axi_rdata),
    .s00_axi_rresp(s_axi_rresp),
    .s00_axi_rlast(s_axi_rlast),
    .s00_axi_ruser(s_axi_ruser),
    .s00_axi_rvalid(s_axi_rvalid),
    .s00_axi_rready(s_axi_rready),
    .s01_axi_awid(s01_axi_awid),
    .s01_axi_awaddr(s01_axi_awaddr),
    .s01_axi_awlen(s01_axi_awlen),
    .s01_axi_awsize(s01_axi_awsize),
    .s01_axi_awburst(s01_axi_awburst),
    .s01_axi_awlock(s01_axi_awlock),
    .s01_axi_awcache(s01_axi_awcache),
    .s01_axi_awprot(s01_axi_awprot),
    .s01_axi_awqos(s01_axi_awqos),
    .s01_axi_awuser(s01_axi_awuser),
    .s01_axi_awvalid(s01_axi_awvalid),
    .s01_axi_awready(s01_axi_awready),
    .s01_axi_wdata(s01_axi_wdata),
    .s01_axi_wstrb(s01_axi_wstrb),
    .s01_axi_wlast(s01_axi_wlast),
    .s01_axi_wuser(s01_axi_wuser),
    .s01_axi_wvalid(s01_axi_wvalid),
    .s01_axi_wready(s01_axi_wready),
    .s01_axi_bid(s01_axi_bid),
    .s01_axi_bresp(s01_axi_bresp),
    .s01_axi_buser(s01_axi_buser),
    .s01_axi_bvalid(s01_axi_bvalid),
    .s01_axi_bready(s01_axi_bready),
    .s01_axi_arid(s01_axi_arid),
    .s01_axi_araddr(s01_axi_araddr),
    .s01_axi_arlen(s01_axi_arlen),
    .s01_axi_arsize(s01_axi_arsize),
    .s01_axi_arburst(s01_axi_arburst),
    .s01_axi_arlock(s01_axi_arlock),
    .s01_axi_arcache(s01_axi_arcache),
    .s01_axi_arprot(s01_axi_arprot),
    .s01_axi_arqos(s01_axi_arqos),
    .s01_axi_aruser(s01_axi_aruser),
    .s01_axi_arvalid(s01_axi_arvalid),
    .s01_axi_arready(s01_axi_arready),
    .s01_axi_rid(s01_axi_rid),
    .s01_axi_rdata(s01_axi_rdata),
    .s01_axi_rresp(s01_axi_rresp),
    .s01_axi_rlast(s01_axi_rlast),
    .s01_axi_ruser(s01_axi_ruser),
    .s01_axi_rvalid(s01_axi_rvalid),
    .s01_axi_rready(s01_axi_rready),
    .s02_axi_awid(s02_axi_awid),
    .s02_axi_awaddr(s02_axi_awaddr),
    .s02_axi_awlen(s02_axi_awlen),
    .s02_axi_awsize(s02_axi_awsize),
    .s02_axi_awburst(s02_axi_awburst),
    .s02_axi_awlock(s02_axi_awlock),
    .s02_axi_awcache(s02_axi_awcache),
    .s02_axi_awprot(s02_axi_awprot),
    .s02_axi_awqos(s02_axi_awqos),
    .s02_axi_awuser(s02_axi_awuser),
    .s02_axi_awvalid(s02_axi_awvalid),
    .s02_axi_awready(s02_axi_awready),
    .s02_axi_wdata(s02_axi_wdata),
    .s02_axi_wstrb(s02_axi_wstrb),
    .s02_axi_wlast(s02_axi_wlast),
    .s02_axi_wuser(s02_axi_wuser),
    .s02_axi_wvalid(s02_axi_wvalid),
    .s02_axi_wready(s02_axi_wready),
    .s02_axi_bid(s02_axi_bid),
    .s02_axi_bresp(s02_axi_bresp),
    .s02_axi_buser(s02_axi_buser),
    .s02_axi_bvalid(s02_axi_bvalid),
    .s02_axi_bready(s02_axi_bready),
    .s02_axi_arid(s02_axi_arid),
    .s02_axi_araddr(s02_axi_araddr),
    .s02_axi_arlen(s02_axi_arlen),
    .s02_axi_arsize(s02_axi_arsize),
    .s02_axi_arburst(s02_axi_arburst),
    .s02_axi_arlock(s02_axi_arlock),
    .s02_axi_arcache(s02_axi_arcache),
    .s02_axi_arprot(s02_axi_arprot),
    .s02_axi_arqos(s02_axi_arqos),
    .s02_axi_aruser(s02_axi_aruser),
    .s02_axi_arvalid(s02_axi_arvalid),
    .s02_axi_arready(s02_axi_arready),
    .s02_axi_rid(s02_axi_rid),
    .s02_axi_rdata(s02_axi_rdata),
    .s02_axi_rresp(s02_axi_rresp),
    .s02_axi_rlast(s02_axi_rlast),
    .s02_axi_ruser(s02_axi_ruser),
    .s02_axi_rvalid(s02_axi_rvalid),
    .s02_axi_rready(s02_axi_rready),
    .m00_axi_awid(m00_axi_awid),
    .m00_axi_awaddr(m00_axi_awaddr),
    .m00_axi_awlen(m00_axi_awlen),
    .m00_axi_awsize(m00_axi_awsize),
    .m00_axi_awburst(m00_axi_awburst),
    .m00_axi_awlock(m00_axi_awlock),
    .m00_axi_awcache(m00_axi_awcache),
    .m00_axi_awprot(m00_axi_awprot),
    .m00_axi_awqos(m00_axi_awqos),
    .m00_axi_awregion(m00_axi_awregion),
    .m00_axi_awuser(m00_axi_awuser),
    .m00_axi_awvalid(m00_axi_awvalid),
    .m00_axi_awready(m00_axi_awready),
    .m00_axi_wdata(m00_axi_wdata),
    .m00_axi_wstrb(m00_axi_wstrb),
    .m00_axi_wlast(m00_axi_wlast),
    .m00_axi_wuser(m00_axi_wuser),
    .m00_axi_wvalid(m00_axi_wvalid),
    .m00_axi_wready(m00_axi_wready),
    .m00_axi_bid(m00_axi_bid),
    .m00_axi_bresp(m00_axi_bresp),
    .m00_axi_buser(m00_axi_buser),
    .m00_axi_bvalid(m00_axi_bvalid),
    .m00_axi_bready(m00_axi_bready),
    .m00_axi_arid(m00_axi_arid),
    .m00_axi_araddr(m00_axi_araddr),
    .m00_axi_arlen(m00_axi_arlen),
    .m00_axi_arsize(m00_axi_arsize),
    .m00_axi_arburst(m00_axi_arburst),
    .m00_axi_arlock(m00_axi_arlock),
    .m00_axi_arcache(m00_axi_arcache),
    .m00_axi_arprot(m00_axi_arprot),
    .m00_axi_arqos(m00_axi_arqos),
    .m00_axi_arregion(m00_axi_arregion),
    .m00_axi_aruser(m00_axi_aruser),
    .m00_axi_arvalid(m00_axi_arvalid),
    .m00_axi_arready(m00_axi_arready),
    .m00_axi_rid(m00_axi_rid),
    .m00_axi_rdata(m00_axi_rdata),
    .m00_axi_rresp(m00_axi_rresp),
    .m00_axi_rlast(m00_axi_rlast),
    .m00_axi_ruser(m00_axi_ruser),
    .m00_axi_rvalid(m00_axi_rvalid),
    .m00_axi_rready(m00_axi_rready),
    .m01_axi_awid(m01_axi_awid),
    .m01_axi_awaddr(m01_axi_awaddr),
    .m01_axi_awlen(m01_axi_awlen),
    .m01_axi_awsize(m01_axi_awsize),
    .m01_axi_awburst(m01_axi_awburst),
    .m01_axi_awlock(m01_axi_awlock),
    .m01_axi_awcache(m01_axi_awcache),
    .m01_axi_awprot(m01_axi_awprot),
    .m01_axi_awqos(m01_axi_awqos),
    .m01_axi_awregion(m01_axi_awregion),
    .m01_axi_awuser(m01_axi_awuser),
    .m01_axi_awvalid(m01_axi_awvalid),
    .m01_axi_awready(m01_axi_awready),
    .m01_axi_wdata(m01_axi_wdata),
    .m01_axi_wstrb(m01_axi_wstrb),
    .m01_axi_wlast(m01_axi_wlast),
    .m01_axi_wuser(m01_axi_wuser),
    .m01_axi_wvalid(m01_axi_wvalid),
    .m01_axi_wready(m01_axi_wready),
    .m01_axi_bid(m01_axi_bid),
    .m01_axi_bresp(m01_axi_bresp),
    .m01_axi_buser(m01_axi_buser),
    .m01_axi_bvalid(m01_axi_bvalid),
    .m01_axi_bready(m01_axi_bready),
    .m01_axi_arid(m01_axi_arid),
    .m01_axi_araddr(m01_axi_araddr),
    .m01_axi_arlen(m01_axi_arlen),
    .m01_axi_arsize(m01_axi_arsize),
    .m01_axi_arburst(m01_axi_arburst),
    .m01_axi_arlock(m01_axi_arlock),
    .m01_axi_arcache(m01_axi_arcache),
    .m01_axi_arprot(m01_axi_arprot),
    .m01_axi_arqos(m01_axi_arqos),
    .m01_axi_arregion(m01_axi_arregion),
    .m01_axi_aruser(m01_axi_aruser),
    .m01_axi_arvalid(m01_axi_arvalid),
    .m01_axi_arready(m01_axi_arready),
    .m01_axi_rid(m01_axi_rid),
    .m01_axi_rdata(m01_axi_rdata),
    .m01_axi_rresp(m01_axi_rresp),
    .m01_axi_rlast(m01_axi_rlast),
    .m01_axi_ruser(m01_axi_ruser),
    .m01_axi_rvalid(m01_axi_rvalid),
    .m01_axi_rready(m01_axi_rready),
    .m02_axi_awid(m02_axi_awid),
    .m02_axi_awaddr(m02_axi_awaddr),
    .m02_axi_awlen(m02_axi_awlen),
    .m02_axi_awsize(m02_axi_awsize),
    .m02_axi_awburst(m02_axi_awburst),
    .m02_axi_awlock(m02_axi_awlock),
    .m02_axi_awcache(m02_axi_awcache),
    .m02_axi_awprot(m02_axi_awprot),
    .m02_axi_awqos(m02_axi_awqos),
    .m02_axi_awregion(m02_axi_awregion),
    .m02_axi_awuser(m02_axi_awuser),
    .m02_axi_awvalid(m02_axi_awvalid),
    .m02_axi_awready(m02_axi_awready),
    .m02_axi_wdata(m02_axi_wdata),
    .m02_axi_wstrb(m02_axi_wstrb),
    .m02_axi_wlast(m02_axi_wlast),
    .m02_axi_wuser(m02_axi_wuser),
    .m02_axi_wvalid(m02_axi_wvalid),
    .m02_axi_wready(m02_axi_wready),
    .m02_axi_bid(m02_axi_bid),
    .m02_axi_bresp(m02_axi_bresp),
    .m02_axi_buser(m02_axi_buser),
    .m02_axi_bvalid(m02_axi_bvalid),
    .m02_axi_bready(m02_axi_bready),
    .m02_axi_arid(m02_axi_arid),
    .m02_axi_araddr(m02_axi_araddr),
    .m02_axi_arlen(m02_axi_arlen),
    .m02_axi_arsize(m02_axi_arsize),
    .m02_axi_arburst(m02_axi_arburst),
    .m02_axi_arlock(m02_axi_arlock),
    .m02_axi_arcache(m02_axi_arcache),
    .m02_axi_arprot(m02_axi_arprot),
    .m02_axi_arqos(m02_axi_arqos),
    .m02_axi_arregion(m02_axi_arregion),
    .m02_axi_aruser(m02_axi_aruser),
    .m02_axi_arvalid(m02_axi_arvalid),
    .m02_axi_arready(m02_axi_arready),
    .m02_axi_rid(m02_axi_rid),
    .m02_axi_rdata(m02_axi_rdata),
    .m02_axi_rresp(m02_axi_rresp),
    .m02_axi_rlast(m02_axi_rlast),
    .m02_axi_ruser(m02_axi_ruser),
    .m02_axi_rvalid(m02_axi_rvalid),
    .m02_axi_rready(m02_axi_rready),
    .m04_axi_awid(m04_axi_awid),
    .m04_axi_awaddr(m04_axi_awaddr),
    .m04_axi_awlen(m04_axi_awlen),
    .m04_axi_awsize(m04_axi_awsize),
    .m04_axi_awburst(m04_axi_awburst),
    .m04_axi_awlock(m04_axi_awlock),
    .m04_axi_awcache(m04_axi_awcache),
    .m04_axi_awprot(m04_axi_awprot),
    .m04_axi_awqos(m04_axi_awqos),
    .m04_axi_awregion(m04_axi_awregion),
    .m04_axi_awuser(m04_axi_awuser),
    .m04_axi_awvalid(m04_axi_awvalid),
    .m04_axi_awready(m04_axi_awready),
    .m04_axi_wdata(m04_axi_wdata),
    .m04_axi_wstrb(m04_axi_wstrb),
    .m04_axi_wlast(m04_axi_wlast),
    .m04_axi_wuser(m04_axi_wuser),
    .m04_axi_wvalid(m04_axi_wvalid),
    .m04_axi_wready(m04_axi_wready),
    .m04_axi_bid(m04_axi_bid),
    .m04_axi_bresp(m04_axi_bresp),
    .m04_axi_buser(m04_axi_buser),
    .m04_axi_bvalid(m04_axi_bvalid),
    .m04_axi_bready(m04_axi_bready),
    .m04_axi_arid(m04_axi_arid),
    .m04_axi_araddr(m04_axi_araddr),
    .m04_axi_arlen(m04_axi_arlen),
    .m04_axi_arsize(m04_axi_arsize),
    .m04_axi_arburst(m04_axi_arburst),
    .m04_axi_arlock(m04_axi_arlock),
    .m04_axi_arcache(m04_axi_arcache),
    .m04_axi_arprot(m04_axi_arprot),
    .m04_axi_arqos(m04_axi_arqos),
    .m04_axi_arregion(m04_axi_arregion),
    .m04_axi_aruser(m04_axi_aruser),
    .m04_axi_arvalid(m04_axi_arvalid),
    .m04_axi_arready(m04_axi_arready),
    .m04_axi_rid(m04_axi_rid),
    .m04_axi_rdata(m04_axi_rdata),
    .m04_axi_rresp(m04_axi_rresp),
    .m04_axi_rlast(m04_axi_rlast),
    .m04_axi_ruser(m04_axi_ruser),
    .m04_axi_rvalid(m04_axi_rvalid),
    .m04_axi_rready(m04_axi_rready),
    .m05_axi_awid(m05_axi_awid),
    .m05_axi_awaddr(m05_axi_awaddr),
    .m05_axi_awlen(m05_axi_awlen),
    .m05_axi_awsize(m05_axi_awsize),
    .m05_axi_awburst(m05_axi_awburst),
    .m05_axi_awlock(m05_axi_awlock),
    .m05_axi_awcache(m05_axi_awcache),
    .m05_axi_awprot(m05_axi_awprot),
    .m05_axi_awqos(m05_axi_awqos),
    .m05_axi_awregion(m05_axi_awregion),
    .m05_axi_awuser(m05_axi_awuser),
    .m05_axi_awvalid(m05_axi_awvalid),
    .m05_axi_awready(m05_axi_awready),
    .m05_axi_wdata(m05_axi_wdata),
    .m05_axi_wstrb(m05_axi_wstrb),
    .m05_axi_wlast(m05_axi_wlast),
    .m05_axi_wuser(m05_axi_wuser),
    .m05_axi_wvalid(m05_axi_wvalid),
    .m05_axi_wready(m05_axi_wready),
    .m05_axi_bid(m05_axi_bid),
    .m05_axi_bresp(m05_axi_bresp),
    .m05_axi_buser(m05_axi_buser),
    .m05_axi_bvalid(m05_axi_bvalid),
    .m05_axi_bready(m05_axi_bready),
    .m05_axi_arid(m05_axi_arid),
    .m05_axi_araddr(m05_axi_araddr),
    .m05_axi_arlen(m05_axi_arlen),
    .m05_axi_arsize(m05_axi_arsize),
    .m05_axi_arburst(m05_axi_arburst),
    .m05_axi_arlock(m05_axi_arlock),
    .m05_axi_arcache(m05_axi_arcache),
    .m05_axi_arprot(m05_axi_arprot),
    .m05_axi_arqos(m05_axi_arqos),
    .m05_axi_arregion(m05_axi_arregion),
    .m05_axi_aruser(m05_axi_aruser),
    .m05_axi_arvalid(m05_axi_arvalid),
    .m05_axi_arready(m05_axi_arready),
    .m05_axi_rid(m05_axi_rid),
    .m05_axi_rdata(m05_axi_rdata),
    .m05_axi_rresp(m05_axi_rresp),
    .m05_axi_rlast(m05_axi_rlast),
    .m05_axi_ruser(m05_axi_ruser),
    .m05_axi_rvalid(m05_axi_rvalid),
    .m05_axi_rready(m05_axi_rready),
    .m06_axi_awid(m06_axi_awid),
    .m06_axi_awaddr(m06_axi_awaddr),
    .m06_axi_awlen(m06_axi_awlen),
    .m06_axi_awsize(m06_axi_awsize),
    .m06_axi_awburst(m06_axi_awburst),
    .m06_axi_awlock(m06_axi_awlock),
    .m06_axi_awcache(m06_axi_awcache),
    .m06_axi_awprot(m06_axi_awprot),
    .m06_axi_awqos(m06_axi_awqos),
    .m06_axi_awregion(m06_axi_awregion),
    .m06_axi_awuser(m06_axi_awuser),
    .m06_axi_awvalid(m06_axi_awvalid),
    .m06_axi_awready(m06_axi_awready),
    .m06_axi_wdata(m06_axi_wdata),
    .m06_axi_wstrb(m06_axi_wstrb),
    .m06_axi_wlast(m06_axi_wlast),
    .m06_axi_wuser(m06_axi_wuser),
    .m06_axi_wvalid(m06_axi_wvalid),
    .m06_axi_wready(m06_axi_wready),
    .m06_axi_bid(m06_axi_bid),
    .m06_axi_bresp(m06_axi_bresp),
    .m06_axi_buser(m06_axi_buser),
    .m06_axi_bvalid(m06_axi_bvalid),
    .m06_axi_bready(m06_axi_bready),
    .m06_axi_arid(m06_axi_arid),
    .m06_axi_araddr(m06_axi_araddr),
    .m06_axi_arlen(m06_axi_arlen),
    .m06_axi_arsize(m06_axi_arsize),
    .m06_axi_arburst(m06_axi_arburst),
    .m06_axi_arlock(m06_axi_arlock),
    .m06_axi_arcache(m06_axi_arcache),
    .m06_axi_arprot(m06_axi_arprot),
    .m06_axi_arqos(m06_axi_arqos),
    .m06_axi_arregion(m06_axi_arregion),
    .m06_axi_aruser(m06_axi_aruser),
    .m06_axi_arvalid(m06_axi_arvalid),
    .m06_axi_arready(m06_axi_arready),
    .m06_axi_rid(m06_axi_rid),
    .m06_axi_rdata(m06_axi_rdata),
    .m06_axi_rresp(m06_axi_rresp),
    .m06_axi_rlast(m06_axi_rlast),
    .m06_axi_ruser(m06_axi_ruser),
    .m06_axi_rvalid(m06_axi_rvalid),
    .m06_axi_rready(m06_axi_rready),
    .m07_axi_awid(m07_axi_awid),
    .m07_axi_awaddr(m07_axi_awaddr),
    .m07_axi_awlen(m07_axi_awlen),
    .m07_axi_awsize(m07_axi_awsize),
    .m07_axi_awburst(m07_axi_awburst),
    .m07_axi_awlock(m07_axi_awlock),
    .m07_axi_awcache(m07_axi_awcache),
    .m07_axi_awprot(m07_axi_awprot),
    .m07_axi_awqos(m07_axi_awqos),
    .m07_axi_awregion(m07_axi_awregion),
    .m07_axi_awuser(m07_axi_awuser),
    .m07_axi_awvalid(m07_axi_awvalid),
    .m07_axi_awready(m07_axi_awready),
    .m07_axi_wdata(m07_axi_wdata),
    .m07_axi_wstrb(m07_axi_wstrb),
    .m07_axi_wlast(m07_axi_wlast),
    .m07_axi_wuser(m07_axi_wuser),
    .m07_axi_wvalid(m07_axi_wvalid),
    .m07_axi_wready(m07_axi_wready),
    .m07_axi_bid(m07_axi_bid),
    .m07_axi_bresp(m07_axi_bresp),
    .m07_axi_buser(m07_axi_buser),
    .m07_axi_bvalid(m07_axi_bvalid),
    .m07_axi_bready(m07_axi_bready),
    .m07_axi_arid(m07_axi_arid),
    .m07_axi_araddr(m07_axi_araddr),
    .m07_axi_arlen(m07_axi_arlen),
    .m07_axi_arsize(m07_axi_arsize),
    .m07_axi_arburst(m07_axi_arburst),
    .m07_axi_arlock(m07_axi_arlock),
    .m07_axi_arcache(m07_axi_arcache),
    .m07_axi_arprot(m07_axi_arprot),
    .m07_axi_arqos(m07_axi_arqos),
    .m07_axi_arregion(m07_axi_arregion),
    .m07_axi_aruser(m07_axi_aruser),
    .m07_axi_arvalid(m07_axi_arvalid),
    .m07_axi_arready(m07_axi_arready),
    .m07_axi_rid(m07_axi_rid),
    .m07_axi_rdata(m07_axi_rdata),
    .m07_axi_rresp(m07_axi_rresp),
    .m07_axi_rlast(m07_axi_rlast),
    .m07_axi_ruser(m07_axi_ruser),
    .m07_axi_rvalid(m07_axi_rvalid),
    .m07_axi_rready(m07_axi_rready),
    .m08_axi_awid(m08_axi_awid),
    .m08_axi_awaddr(m08_axi_awaddr),
    .m08_axi_awlen(m08_axi_awlen),
    .m08_axi_awsize(m08_axi_awsize),
    .m08_axi_awburst(m08_axi_awburst),
    .m08_axi_awlock(m08_axi_awlock),
    .m08_axi_awcache(m08_axi_awcache),
    .m08_axi_awprot(m08_axi_awprot),
    .m08_axi_awqos(m08_axi_awqos),
    .m08_axi_awregion(m08_axi_awregion),
    .m08_axi_awuser(m08_axi_awuser),
    .m08_axi_awvalid(m08_axi_awvalid),
    .m08_axi_awready(m08_axi_awready),
    .m08_axi_wdata(m08_axi_wdata),
    .m08_axi_wstrb(m08_axi_wstrb),
    .m08_axi_wlast(m08_axi_wlast),
    .m08_axi_wuser(m08_axi_wuser),
    .m08_axi_wvalid(m08_axi_wvalid),
    .m08_axi_wready(m08_axi_wready),
    .m08_axi_bid(m08_axi_bid),
    .m08_axi_bresp(m08_axi_bresp),
    .m08_axi_buser(m08_axi_buser),
    .m08_axi_bvalid(m08_axi_bvalid),
    .m08_axi_bready(m08_axi_bready),
    .m08_axi_arid(m08_axi_arid),
    .m08_axi_araddr(m08_axi_araddr),
    .m08_axi_arlen(m08_axi_arlen),
    .m08_axi_arsize(m08_axi_arsize),
    .m08_axi_arburst(m08_axi_arburst),
    .m08_axi_arlock(m08_axi_arlock),
    .m08_axi_arcache(m08_axi_arcache),
    .m08_axi_arprot(m08_axi_arprot),
    .m08_axi_arqos(m08_axi_arqos),
    .m08_axi_arregion(m08_axi_arregion),
    .m08_axi_aruser(m08_axi_aruser),
    .m08_axi_arvalid(m08_axi_arvalid),
    .m08_axi_arready(m08_axi_arready),
    .m08_axi_rid(m08_axi_rid),
    .m08_axi_rdata(m08_axi_rdata),
    .m08_axi_rresp(m08_axi_rresp),
    .m08_axi_rlast(m08_axi_rlast),
    .m08_axi_ruser(m08_axi_ruser),
    .m08_axi_rvalid(m08_axi_rvalid),
    .m08_axi_rready(m08_axi_rready),
    .m09_axi_awid(m09_axi_awid),
    .m09_axi_awaddr(m09_axi_awaddr),
    .m09_axi_awlen(m09_axi_awlen),
    .m09_axi_awsize(m09_axi_awsize),
    .m09_axi_awburst(m09_axi_awburst),
    .m09_axi_awlock(m09_axi_awlock),
    .m09_axi_awcache(m09_axi_awcache),
    .m09_axi_awprot(m09_axi_awprot),
    .m09_axi_awqos(m09_axi_awqos),
    .m09_axi_awregion(m09_axi_awregion),
    .m09_axi_awuser(m09_axi_awuser),
    .m09_axi_awvalid(m09_axi_awvalid),
    .m09_axi_awready(m09_axi_awready),
    .m09_axi_wdata(m09_axi_wdata),
    .m09_axi_wstrb(m09_axi_wstrb),
    .m09_axi_wlast(m09_axi_wlast),
    .m09_axi_wuser(m09_axi_wuser),
    .m09_axi_wvalid(m09_axi_wvalid),
    .m09_axi_wready(m09_axi_wready),
    .m09_axi_bid(m09_axi_bid),
    .m09_axi_bresp(m09_axi_bresp),
    .m09_axi_buser(m09_axi_buser),
    .m09_axi_bvalid(m09_axi_bvalid),
    .m09_axi_bready(m09_axi_bready),
    .m09_axi_arid(m09_axi_arid),
    .m09_axi_araddr(m09_axi_araddr),
    .m09_axi_arlen(m09_axi_arlen),
    .m09_axi_arsize(m09_axi_arsize),
    .m09_axi_arburst(m09_axi_arburst),
    .m09_axi_arlock(m09_axi_arlock),
    .m09_axi_arcache(m09_axi_arcache),
    .m09_axi_arprot(m09_axi_arprot),
    .m09_axi_arqos(m09_axi_arqos),
    .m09_axi_arregion(m09_axi_arregion),
    .m09_axi_aruser(m09_axi_aruser),
    .m09_axi_arvalid(m09_axi_arvalid),
    .m09_axi_arready(m09_axi_arready),
    .m09_axi_rid(m09_axi_rid),
    .m09_axi_rdata(m09_axi_rdata),
    .m09_axi_rresp(m09_axi_rresp),
    .m09_axi_rlast(m09_axi_rlast),
    .m09_axi_ruser(m09_axi_ruser),
    .m09_axi_rvalid(m09_axi_rvalid),
    .m09_axi_rready(m09_axi_rready),
    .uart_rx_i(uart_tx),
    .uart_tx_o(uart_tx),
    .read_interrupt_o(uart_irq)
);

reg [1:0] rsp;  reg [31:0] rd;  reg [7:0] bid;  integer nb;
task wr32(input [31:0] a, input [31:0] d);
    begin axi_write(8'hC1, UART_BASE + a, 0, 3'd2, d, 4'hF, 0, 0, 0, rsp, bid);
          check(rsp == 2'b00, "top: write expected OKAY"); end
endtask
task rd32(input [31:0] a, output [31:0] d);
    begin axi_read(8'hD2, UART_BASE + a, 0, 3'd2, 0, 0, rsp, d, nb);
          check(rsp == 2'b00 && nb == 1, "top: read expected OKAY, 1 beat"); end
endtask

integer BIT_PERIOD_NS; integer n;
reg [7:0] tx_byte; reg tx_ok;
task capture_tx_byte(output [7:0] byte_out, output frame_ok);
    integer i;
    begin
        @(negedge uart_tx);
        #(BIT_PERIOD_NS/2);
        frame_ok = (uart_tx == 1'b0);
        byte_out = 8'h00;
        for (i = 0; i < 8; i = i + 1) begin
            #(BIT_PERIOD_NS);
            byte_out[i] = uart_tx;
        end
        #(BIT_PERIOD_NS);
        if (uart_tx !== 1'b1) frame_ok = 1'b0;
    end
endtask

initial begin
    $dumpfile("tb_top_smoke.vcd"); $dumpvars(0, tb_axi_soc_top_smoke);
    repeat (5) @(posedge clk); rst <= 1'b0; repeat (10) @(posedge clk);

    $display("--- top smoke: configure UART through axi_soc_top (S00 -> M03 -> adapter -> UART)");
    wr32(32'h0C, 32'h80); wr32(32'h08, 32'd16); wr32(32'h0C, 32'h00); wr32(32'h04, 32'h01);
    BIT_PERIOD_NS = 170;

    $display("--- TEST1 (through top): write 0x0300_0000 = 0x41");
    wr32(32'h00, 32'h0000_0041);
    rd = 0; n = 0;
    while (!rd[0] && n < 2000) begin rd32(32'h14, rd); n = n + 1; end
    check(rd[0], "top TEST1: timed out waiting LSR data-ready");
    rd32(32'h00, rd);
    check(rd[7:0] == 8'h41, "top TEST1: RBR must read back 0x41");

    $display("--- TEST7 (through top): decode uart_tx_o for 0x41");
    fork
        begin capture_tx_byte(tx_byte, tx_ok); end
        begin wr32(32'h00, 32'h0000_0041); end
    join
    check(tx_ok, "top TEST7: start/stop framing must be correct");
    check(tx_byte == 8'h41, "top TEST7: uart_tx_o must decode to 0x41");

    if (errors == 0) $display("\n*** TOP SMOKE TB PASS: axi_soc_top integrates correctly ***");
    else             $display("\n*** TOP SMOKE TB FAIL: %0d check(s) failed ***", errors);
    $finish;
end
initial begin #20_000_000; $display("*** TOP SMOKE TB FAIL: global timeout ***"); $finish; end
initial begin
	$fsdbDumpfile("dump.fsdb");
	$fsdbDumpvars("+all");
	$fsdbDumpSVA();
	$fsdbDumpMDA();
end
endmodule
`default_nettype wire
