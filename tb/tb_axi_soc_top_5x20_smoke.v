// -----------------------------------------------------------------------------
// tb_axi_soc_top_5x20_smoke.v : comprehensive testbench for axi_soc_top_5x20.
// Exercises and verifies:
//   - UART IP integration with 5x20 interconnect on M05 (base 0x4000_6000)
//   - FORWARD FLOW: AXI Master -> Interconnect -> Adapter -> UART -> uart_tx_o
//   - BACKWARD FLOW: uart_rx_i -> UART -> Adapter -> Interconnect -> AXI Master
//   - INTERRUPT: read_interrupt_o assertion on RX and clearing on RBR read
//   - FULL-DUPLEX: simultaneous forward TX and backward RX without interference
//   - MULTI-MASTER: S00 and S01 masters accessing UART
// -----------------------------------------------------------------------------
`timescale 1ns / 1ps
`default_nettype none

module tb_axi_soc_top_5x20_smoke;

localparam DATA_WIDTH = 32, ADDR_WIDTH = 32, STRB_WIDTH = 4, ID_WIDTH = 8;
localparam AWUSER_WIDTH = 1, WUSER_WIDTH = 1, BUSER_WIDTH = 1, ARUSER_WIDTH = 1, RUSER_WIDTH = 1;
localparam [31:0] UART_BASE = 32'h4000_6000;

reg clk = 1'b0;  reg rst = 1'b1;  integer errors = 0;
always #5 clk = ~clk; // 100 MHz (10ns period)

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

// ---- S01-S04 slave port signals ---------------------------------------------
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

reg  [ID_WIDTH-1:0] s03_axi_awid = 0;
reg  [ADDR_WIDTH-1:0] s03_axi_awaddr = 0;
reg  [7:0] s03_axi_awlen = 0;
reg  [2:0] s03_axi_awsize = 0;
reg  [1:0] s03_axi_awburst = 0;
reg  s03_axi_awlock = 0;
reg  [3:0] s03_axi_awcache = 0;
reg  [2:0] s03_axi_awprot = 0;
reg  [3:0] s03_axi_awqos = 0;
reg  [AWUSER_WIDTH-1:0] s03_axi_awuser = 0;
reg  s03_axi_awvalid = 0;
wire s03_axi_awready;
reg  [DATA_WIDTH-1:0] s03_axi_wdata = 0;
reg  [STRB_WIDTH-1:0] s03_axi_wstrb = 0;
reg  s03_axi_wlast = 0;
reg  [WUSER_WIDTH-1:0] s03_axi_wuser = 0;
reg  s03_axi_wvalid = 0;
wire s03_axi_wready;
wire [ID_WIDTH-1:0] s03_axi_bid;
wire [1:0] s03_axi_bresp;
wire [BUSER_WIDTH-1:0] s03_axi_buser;
wire s03_axi_bvalid;
reg  s03_axi_bready = 0;
reg  [ID_WIDTH-1:0] s03_axi_arid = 0;
reg  [ADDR_WIDTH-1:0] s03_axi_araddr = 0;
reg  [7:0] s03_axi_arlen = 0;
reg  [2:0] s03_axi_arsize = 0;
reg  [1:0] s03_axi_arburst = 0;
reg  s03_axi_arlock = 0;
reg  [3:0] s03_axi_arcache = 0;
reg  [2:0] s03_axi_arprot = 0;
reg  [3:0] s03_axi_arqos = 0;
reg  [ARUSER_WIDTH-1:0] s03_axi_aruser = 0;
reg  s03_axi_arvalid = 0;
wire s03_axi_arready;
wire [ID_WIDTH-1:0] s03_axi_rid;
wire [DATA_WIDTH-1:0] s03_axi_rdata;
wire [1:0] s03_axi_rresp;
wire s03_axi_rlast;
wire [RUSER_WIDTH-1:0] s03_axi_ruser;
wire s03_axi_rvalid;
reg  s03_axi_rready = 0;

reg  [ID_WIDTH-1:0] s04_axi_awid = 0;
reg  [ADDR_WIDTH-1:0] s04_axi_awaddr = 0;
reg  [7:0] s04_axi_awlen = 0;
reg  [2:0] s04_axi_awsize = 0;
reg  [1:0] s04_axi_awburst = 0;
reg  s04_axi_awlock = 0;
reg  [3:0] s04_axi_awcache = 0;
reg  [2:0] s04_axi_awprot = 0;
reg  [3:0] s04_axi_awqos = 0;
reg  [AWUSER_WIDTH-1:0] s04_axi_awuser = 0;
reg  s04_axi_awvalid = 0;
wire s04_axi_awready;
reg  [DATA_WIDTH-1:0] s04_axi_wdata = 0;
reg  [STRB_WIDTH-1:0] s04_axi_wstrb = 0;
reg  s04_axi_wlast = 0;
reg  [WUSER_WIDTH-1:0] s04_axi_wuser = 0;
reg  s04_axi_wvalid = 0;
wire s04_axi_wready;
wire [ID_WIDTH-1:0] s04_axi_bid;
wire [1:0] s04_axi_bresp;
wire [BUSER_WIDTH-1:0] s04_axi_buser;
wire s04_axi_bvalid;
reg  s04_axi_bready = 0;
reg  [ID_WIDTH-1:0] s04_axi_arid = 0;
reg  [ADDR_WIDTH-1:0] s04_axi_araddr = 0;
reg  [7:0] s04_axi_arlen = 0;
reg  [2:0] s04_axi_arsize = 0;
reg  [1:0] s04_axi_arburst = 0;
reg  s04_axi_arlock = 0;
reg  [3:0] s04_axi_arcache = 0;
reg  [2:0] s04_axi_arprot = 0;
reg  [3:0] s04_axi_arqos = 0;
reg  [ARUSER_WIDTH-1:0] s04_axi_aruser = 0;
reg  s04_axi_arvalid = 0;
wire s04_axi_arready;
wire [ID_WIDTH-1:0] s04_axi_rid;
wire [DATA_WIDTH-1:0] s04_axi_rdata;
wire [1:0] s04_axi_rresp;
wire s04_axi_rlast;
wire [RUSER_WIDTH-1:0] s04_axi_ruser;
wire s04_axi_rvalid;
reg  s04_axi_rready = 0;

// ---- M00-M04, M06-M19 master dummy sinks -----------------------------------
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

wire [ID_WIDTH-1:0] m03_axi_awid;
wire [ADDR_WIDTH-1:0] m03_axi_awaddr;
wire [7:0] m03_axi_awlen;
wire [2:0] m03_axi_awsize;
wire [1:0] m03_axi_awburst;
wire m03_axi_awlock;
wire [3:0] m03_axi_awcache;
wire [2:0] m03_axi_awprot;
wire [3:0] m03_axi_awqos;
wire [3:0] m03_axi_awregion;
wire [AWUSER_WIDTH-1:0] m03_axi_awuser;
wire m03_axi_awvalid;
reg  m03_axi_awready;
wire [DATA_WIDTH-1:0] m03_axi_wdata;
wire [STRB_WIDTH-1:0] m03_axi_wstrb;
wire m03_axi_wlast;
wire [WUSER_WIDTH-1:0] m03_axi_wuser;
wire m03_axi_wvalid;
reg  m03_axi_wready;
reg  [ID_WIDTH-1:0] m03_axi_bid;
reg  [1:0] m03_axi_bresp;
reg  [BUSER_WIDTH-1:0] m03_axi_buser;
reg  m03_axi_bvalid;
wire m03_axi_bready;
wire [ID_WIDTH-1:0] m03_axi_arid;
wire [ADDR_WIDTH-1:0] m03_axi_araddr;
wire [7:0] m03_axi_arlen;
wire [2:0] m03_axi_arsize;
wire [1:0] m03_axi_arburst;
wire m03_axi_arlock;
wire [3:0] m03_axi_arcache;
wire [2:0] m03_axi_arprot;
wire [3:0] m03_axi_arqos;
wire [3:0] m03_axi_arregion;
wire [ARUSER_WIDTH-1:0] m03_axi_aruser;
wire m03_axi_arvalid;
reg  m03_axi_arready;
reg  [ID_WIDTH-1:0] m03_axi_rid;
reg  [DATA_WIDTH-1:0] m03_axi_rdata;
reg  [1:0] m03_axi_rresp;
reg  m03_axi_rlast;
reg  [RUSER_WIDTH-1:0] m03_axi_ruser;
reg  m03_axi_rvalid;
wire m03_axi_rready;

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

wire [ID_WIDTH-1:0] m10_axi_awid;
wire [ADDR_WIDTH-1:0] m10_axi_awaddr;
wire [7:0] m10_axi_awlen;
wire [2:0] m10_axi_awsize;
wire [1:0] m10_axi_awburst;
wire m10_axi_awlock;
wire [3:0] m10_axi_awcache;
wire [2:0] m10_axi_awprot;
wire [3:0] m10_axi_awqos;
wire [3:0] m10_axi_awregion;
wire [AWUSER_WIDTH-1:0] m10_axi_awuser;
wire m10_axi_awvalid;
reg  m10_axi_awready;
wire [DATA_WIDTH-1:0] m10_axi_wdata;
wire [STRB_WIDTH-1:0] m10_axi_wstrb;
wire m10_axi_wlast;
wire [WUSER_WIDTH-1:0] m10_axi_wuser;
wire m10_axi_wvalid;
reg  m10_axi_wready;
reg  [ID_WIDTH-1:0] m10_axi_bid;
reg  [1:0] m10_axi_bresp;
reg  [BUSER_WIDTH-1:0] m10_axi_buser;
reg  m10_axi_bvalid;
wire m10_axi_bready;
wire [ID_WIDTH-1:0] m10_axi_arid;
wire [ADDR_WIDTH-1:0] m10_axi_araddr;
wire [7:0] m10_axi_arlen;
wire [2:0] m10_axi_arsize;
wire [1:0] m10_axi_arburst;
wire m10_axi_arlock;
wire [3:0] m10_axi_arcache;
wire [2:0] m10_axi_arprot;
wire [3:0] m10_axi_arqos;
wire [3:0] m10_axi_arregion;
wire [ARUSER_WIDTH-1:0] m10_axi_aruser;
wire m10_axi_arvalid;
reg  m10_axi_arready;
reg  [ID_WIDTH-1:0] m10_axi_rid;
reg  [DATA_WIDTH-1:0] m10_axi_rdata;
reg  [1:0] m10_axi_rresp;
reg  m10_axi_rlast;
reg  [RUSER_WIDTH-1:0] m10_axi_ruser;
reg  m10_axi_rvalid;
wire m10_axi_rready;

wire [ID_WIDTH-1:0] m11_axi_awid;
wire [ADDR_WIDTH-1:0] m11_axi_awaddr;
wire [7:0] m11_axi_awlen;
wire [2:0] m11_axi_awsize;
wire [1:0] m11_axi_awburst;
wire m11_axi_awlock;
wire [3:0] m11_axi_awcache;
wire [2:0] m11_axi_awprot;
wire [3:0] m11_axi_awqos;
wire [3:0] m11_axi_awregion;
wire [AWUSER_WIDTH-1:0] m11_axi_awuser;
wire m11_axi_awvalid;
reg  m11_axi_awready;
wire [DATA_WIDTH-1:0] m11_axi_wdata;
wire [STRB_WIDTH-1:0] m11_axi_wstrb;
wire m11_axi_wlast;
wire [WUSER_WIDTH-1:0] m11_axi_wuser;
wire m11_axi_wvalid;
reg  m11_axi_wready;
reg  [ID_WIDTH-1:0] m11_axi_bid;
reg  [1:0] m11_axi_bresp;
reg  [BUSER_WIDTH-1:0] m11_axi_buser;
reg  m11_axi_bvalid;
wire m11_axi_bready;
wire [ID_WIDTH-1:0] m11_axi_arid;
wire [ADDR_WIDTH-1:0] m11_axi_araddr;
wire [7:0] m11_axi_arlen;
wire [2:0] m11_axi_arsize;
wire [1:0] m11_axi_arburst;
wire m11_axi_arlock;
wire [3:0] m11_axi_arcache;
wire [2:0] m11_axi_arprot;
wire [3:0] m11_axi_arqos;
wire [3:0] m11_axi_arregion;
wire [ARUSER_WIDTH-1:0] m11_axi_aruser;
wire m11_axi_arvalid;
reg  m11_axi_arready;
reg  [ID_WIDTH-1:0] m11_axi_rid;
reg  [DATA_WIDTH-1:0] m11_axi_rdata;
reg  [1:0] m11_axi_rresp;
reg  m11_axi_rlast;
reg  [RUSER_WIDTH-1:0] m11_axi_ruser;
reg  m11_axi_rvalid;
wire m11_axi_rready;

wire [ID_WIDTH-1:0] m12_axi_awid;
wire [ADDR_WIDTH-1:0] m12_axi_awaddr;
wire [7:0] m12_axi_awlen;
wire [2:0] m12_axi_awsize;
wire [1:0] m12_axi_awburst;
wire m12_axi_awlock;
wire [3:0] m12_axi_awcache;
wire [2:0] m12_axi_awprot;
wire [3:0] m12_axi_awqos;
wire [3:0] m12_axi_awregion;
wire [AWUSER_WIDTH-1:0] m12_axi_awuser;
wire m12_axi_awvalid;
reg  m12_axi_awready;
wire [DATA_WIDTH-1:0] m12_axi_wdata;
wire [STRB_WIDTH-1:0] m12_axi_wstrb;
wire m12_axi_wlast;
wire [WUSER_WIDTH-1:0] m12_axi_wuser;
wire m12_axi_wvalid;
reg  m12_axi_wready;
reg  [ID_WIDTH-1:0] m12_axi_bid;
reg  [1:0] m12_axi_bresp;
reg  [BUSER_WIDTH-1:0] m12_axi_buser;
reg  m12_axi_bvalid;
wire m12_axi_bready;
wire [ID_WIDTH-1:0] m12_axi_arid;
wire [ADDR_WIDTH-1:0] m12_axi_araddr;
wire [7:0] m12_axi_arlen;
wire [2:0] m12_axi_arsize;
wire [1:0] m12_axi_arburst;
wire m12_axi_arlock;
wire [3:0] m12_axi_arcache;
wire [2:0] m12_axi_arprot;
wire [3:0] m12_axi_arqos;
wire [3:0] m12_axi_arregion;
wire [ARUSER_WIDTH-1:0] m12_axi_aruser;
wire m12_axi_arvalid;
reg  m12_axi_arready;
reg  [ID_WIDTH-1:0] m12_axi_rid;
reg  [DATA_WIDTH-1:0] m12_axi_rdata;
reg  [1:0] m12_axi_rresp;
reg  m12_axi_rlast;
reg  [RUSER_WIDTH-1:0] m12_axi_ruser;
reg  m12_axi_rvalid;
wire m12_axi_rready;

wire [ID_WIDTH-1:0] m13_axi_awid;
wire [ADDR_WIDTH-1:0] m13_axi_awaddr;
wire [7:0] m13_axi_awlen;
wire [2:0] m13_axi_awsize;
wire [1:0] m13_axi_awburst;
wire m13_axi_awlock;
wire [3:0] m13_axi_awcache;
wire [2:0] m13_axi_awprot;
wire [3:0] m13_axi_awqos;
wire [3:0] m13_axi_awregion;
wire [AWUSER_WIDTH-1:0] m13_axi_awuser;
wire m13_axi_awvalid;
reg  m13_axi_awready;
wire [DATA_WIDTH-1:0] m13_axi_wdata;
wire [STRB_WIDTH-1:0] m13_axi_wstrb;
wire m13_axi_wlast;
wire [WUSER_WIDTH-1:0] m13_axi_wuser;
wire m13_axi_wvalid;
reg  m13_axi_wready;
reg  [ID_WIDTH-1:0] m13_axi_bid;
reg  [1:0] m13_axi_bresp;
reg  [BUSER_WIDTH-1:0] m13_axi_buser;
reg  m13_axi_bvalid;
wire m13_axi_bready;
wire [ID_WIDTH-1:0] m13_axi_arid;
wire [ADDR_WIDTH-1:0] m13_axi_araddr;
wire [7:0] m13_axi_arlen;
wire [2:0] m13_axi_arsize;
wire [1:0] m13_axi_arburst;
wire m13_axi_arlock;
wire [3:0] m13_axi_arcache;
wire [2:0] m13_axi_arprot;
wire [3:0] m13_axi_arqos;
wire [3:0] m13_axi_arregion;
wire [ARUSER_WIDTH-1:0] m13_axi_aruser;
wire m13_axi_arvalid;
reg  m13_axi_arready;
reg  [ID_WIDTH-1:0] m13_axi_rid;
reg  [DATA_WIDTH-1:0] m13_axi_rdata;
reg  [1:0] m13_axi_rresp;
reg  m13_axi_rlast;
reg  [RUSER_WIDTH-1:0] m13_axi_ruser;
reg  m13_axi_rvalid;
wire m13_axi_rready;

wire [ID_WIDTH-1:0] m14_axi_awid;
wire [ADDR_WIDTH-1:0] m14_axi_awaddr;
wire [7:0] m14_axi_awlen;
wire [2:0] m14_axi_awsize;
wire [1:0] m14_axi_awburst;
wire m14_axi_awlock;
wire [3:0] m14_axi_awcache;
wire [2:0] m14_axi_awprot;
wire [3:0] m14_axi_awqos;
wire [3:0] m14_axi_awregion;
wire [AWUSER_WIDTH-1:0] m14_axi_awuser;
wire m14_axi_awvalid;
reg  m14_axi_awready;
wire [DATA_WIDTH-1:0] m14_axi_wdata;
wire [STRB_WIDTH-1:0] m14_axi_wstrb;
wire m14_axi_wlast;
wire [WUSER_WIDTH-1:0] m14_axi_wuser;
wire m14_axi_wvalid;
reg  m14_axi_wready;
reg  [ID_WIDTH-1:0] m14_axi_bid;
reg  [1:0] m14_axi_bresp;
reg  [BUSER_WIDTH-1:0] m14_axi_buser;
reg  m14_axi_bvalid;
wire m14_axi_bready;
wire [ID_WIDTH-1:0] m14_axi_arid;
wire [ADDR_WIDTH-1:0] m14_axi_araddr;
wire [7:0] m14_axi_arlen;
wire [2:0] m14_axi_arsize;
wire [1:0] m14_axi_arburst;
wire m14_axi_arlock;
wire [3:0] m14_axi_arcache;
wire [2:0] m14_axi_arprot;
wire [3:0] m14_axi_arqos;
wire [3:0] m14_axi_arregion;
wire [ARUSER_WIDTH-1:0] m14_axi_aruser;
wire m14_axi_arvalid;
reg  m14_axi_arready;
reg  [ID_WIDTH-1:0] m14_axi_rid;
reg  [DATA_WIDTH-1:0] m14_axi_rdata;
reg  [1:0] m14_axi_rresp;
reg  m14_axi_rlast;
reg  [RUSER_WIDTH-1:0] m14_axi_ruser;
reg  m14_axi_rvalid;
wire m14_axi_rready;

wire [ID_WIDTH-1:0] m15_axi_awid;
wire [ADDR_WIDTH-1:0] m15_axi_awaddr;
wire [7:0] m15_axi_awlen;
wire [2:0] m15_axi_awsize;
wire [1:0] m15_axi_awburst;
wire m15_axi_awlock;
wire [3:0] m15_axi_awcache;
wire [2:0] m15_axi_awprot;
wire [3:0] m15_axi_awqos;
wire [3:0] m15_axi_awregion;
wire [AWUSER_WIDTH-1:0] m15_axi_awuser;
wire m15_axi_awvalid;
reg  m15_axi_awready;
wire [DATA_WIDTH-1:0] m15_axi_wdata;
wire [STRB_WIDTH-1:0] m15_axi_wstrb;
wire m15_axi_wlast;
wire [WUSER_WIDTH-1:0] m15_axi_wuser;
wire m15_axi_wvalid;
reg  m15_axi_wready;
reg  [ID_WIDTH-1:0] m15_axi_bid;
reg  [1:0] m15_axi_bresp;
reg  [BUSER_WIDTH-1:0] m15_axi_buser;
reg  m15_axi_bvalid;
wire m15_axi_bready;
wire [ID_WIDTH-1:0] m15_axi_arid;
wire [ADDR_WIDTH-1:0] m15_axi_araddr;
wire [7:0] m15_axi_arlen;
wire [2:0] m15_axi_arsize;
wire [1:0] m15_axi_arburst;
wire m15_axi_arlock;
wire [3:0] m15_axi_arcache;
wire [2:0] m15_axi_arprot;
wire [3:0] m15_axi_arqos;
wire [3:0] m15_axi_arregion;
wire [ARUSER_WIDTH-1:0] m15_axi_aruser;
wire m15_axi_arvalid;
reg  m15_axi_arready;
reg  [ID_WIDTH-1:0] m15_axi_rid;
reg  [DATA_WIDTH-1:0] m15_axi_rdata;
reg  [1:0] m15_axi_rresp;
reg  m15_axi_rlast;
reg  [RUSER_WIDTH-1:0] m15_axi_ruser;
reg  m15_axi_rvalid;
wire m15_axi_rready;

wire [ID_WIDTH-1:0] m16_axi_awid;
wire [ADDR_WIDTH-1:0] m16_axi_awaddr;
wire [7:0] m16_axi_awlen;
wire [2:0] m16_axi_awsize;
wire [1:0] m16_axi_awburst;
wire m16_axi_awlock;
wire [3:0] m16_axi_awcache;
wire [2:0] m16_axi_awprot;
wire [3:0] m16_axi_awqos;
wire [3:0] m16_axi_awregion;
wire [AWUSER_WIDTH-1:0] m16_axi_awuser;
wire m16_axi_awvalid;
reg  m16_axi_awready;
wire [DATA_WIDTH-1:0] m16_axi_wdata;
wire [STRB_WIDTH-1:0] m16_axi_wstrb;
wire m16_axi_wlast;
wire [WUSER_WIDTH-1:0] m16_axi_wuser;
wire m16_axi_wvalid;
reg  m16_axi_wready;
reg  [ID_WIDTH-1:0] m16_axi_bid;
reg  [1:0] m16_axi_bresp;
reg  [BUSER_WIDTH-1:0] m16_axi_buser;
reg  m16_axi_bvalid;
wire m16_axi_bready;
wire [ID_WIDTH-1:0] m16_axi_arid;
wire [ADDR_WIDTH-1:0] m16_axi_araddr;
wire [7:0] m16_axi_arlen;
wire [2:0] m16_axi_arsize;
wire [1:0] m16_axi_arburst;
wire m16_axi_arlock;
wire [3:0] m16_axi_arcache;
wire [2:0] m16_axi_arprot;
wire [3:0] m16_axi_arqos;
wire [3:0] m16_axi_arregion;
wire [ARUSER_WIDTH-1:0] m16_axi_aruser;
wire m16_axi_arvalid;
reg  m16_axi_arready;
reg  [ID_WIDTH-1:0] m16_axi_rid;
reg  [DATA_WIDTH-1:0] m16_axi_rdata;
reg  [1:0] m16_axi_rresp;
reg  m16_axi_rlast;
reg  [RUSER_WIDTH-1:0] m16_axi_ruser;
reg  m16_axi_rvalid;
wire m16_axi_rready;

wire [ID_WIDTH-1:0] m17_axi_awid;
wire [ADDR_WIDTH-1:0] m17_axi_awaddr;
wire [7:0] m17_axi_awlen;
wire [2:0] m17_axi_awsize;
wire [1:0] m17_axi_awburst;
wire m17_axi_awlock;
wire [3:0] m17_axi_awcache;
wire [2:0] m17_axi_awprot;
wire [3:0] m17_axi_awqos;
wire [3:0] m17_axi_awregion;
wire [AWUSER_WIDTH-1:0] m17_axi_awuser;
wire m17_axi_awvalid;
reg  m17_axi_awready;
wire [DATA_WIDTH-1:0] m17_axi_wdata;
wire [STRB_WIDTH-1:0] m17_axi_wstrb;
wire m17_axi_wlast;
wire [WUSER_WIDTH-1:0] m17_axi_wuser;
wire m17_axi_wvalid;
reg  m17_axi_wready;
reg  [ID_WIDTH-1:0] m17_axi_bid;
reg  [1:0] m17_axi_bresp;
reg  [BUSER_WIDTH-1:0] m17_axi_buser;
reg  m17_axi_bvalid;
wire m17_axi_bready;
wire [ID_WIDTH-1:0] m17_axi_arid;
wire [ADDR_WIDTH-1:0] m17_axi_araddr;
wire [7:0] m17_axi_arlen;
wire [2:0] m17_axi_arsize;
wire [1:0] m17_axi_arburst;
wire m17_axi_arlock;
wire [3:0] m17_axi_arcache;
wire [2:0] m17_axi_arprot;
wire [3:0] m17_axi_arqos;
wire [3:0] m17_axi_arregion;
wire [ARUSER_WIDTH-1:0] m17_axi_aruser;
wire m17_axi_arvalid;
reg  m17_axi_arready;
reg  [ID_WIDTH-1:0] m17_axi_rid;
reg  [DATA_WIDTH-1:0] m17_axi_rdata;
reg  [1:0] m17_axi_rresp;
reg  m17_axi_rlast;
reg  [RUSER_WIDTH-1:0] m17_axi_ruser;
reg  m17_axi_rvalid;
wire m17_axi_rready;

wire [ID_WIDTH-1:0] m18_axi_awid;
wire [ADDR_WIDTH-1:0] m18_axi_awaddr;
wire [7:0] m18_axi_awlen;
wire [2:0] m18_axi_awsize;
wire [1:0] m18_axi_awburst;
wire m18_axi_awlock;
wire [3:0] m18_axi_awcache;
wire [2:0] m18_axi_awprot;
wire [3:0] m18_axi_awqos;
wire [3:0] m18_axi_awregion;
wire [AWUSER_WIDTH-1:0] m18_axi_awuser;
wire m18_axi_awvalid;
reg  m18_axi_awready;
wire [DATA_WIDTH-1:0] m18_axi_wdata;
wire [STRB_WIDTH-1:0] m18_axi_wstrb;
wire m18_axi_wlast;
wire [WUSER_WIDTH-1:0] m18_axi_wuser;
wire m18_axi_wvalid;
reg  m18_axi_wready;
reg  [ID_WIDTH-1:0] m18_axi_bid;
reg  [1:0] m18_axi_bresp;
reg  [BUSER_WIDTH-1:0] m18_axi_buser;
reg  m18_axi_bvalid;
wire m18_axi_bready;
wire [ID_WIDTH-1:0] m18_axi_arid;
wire [ADDR_WIDTH-1:0] m18_axi_araddr;
wire [7:0] m18_axi_arlen;
wire [2:0] m18_axi_arsize;
wire [1:0] m18_axi_arburst;
wire m18_axi_arlock;
wire [3:0] m18_axi_arcache;
wire [2:0] m18_axi_arprot;
wire [3:0] m18_axi_arqos;
wire [3:0] m18_axi_arregion;
wire [ARUSER_WIDTH-1:0] m18_axi_aruser;
wire m18_axi_arvalid;
reg  m18_axi_arready;
reg  [ID_WIDTH-1:0] m18_axi_rid;
reg  [DATA_WIDTH-1:0] m18_axi_rdata;
reg  [1:0] m18_axi_rresp;
reg  m18_axi_rlast;
reg  [RUSER_WIDTH-1:0] m18_axi_ruser;
reg  m18_axi_rvalid;
wire m18_axi_rready;

wire [ID_WIDTH-1:0] m19_axi_awid;
wire [ADDR_WIDTH-1:0] m19_axi_awaddr;
wire [7:0] m19_axi_awlen;
wire [2:0] m19_axi_awsize;
wire [1:0] m19_axi_awburst;
wire m19_axi_awlock;
wire [3:0] m19_axi_awcache;
wire [2:0] m19_axi_awprot;
wire [3:0] m19_axi_awqos;
wire [3:0] m19_axi_awregion;
wire [AWUSER_WIDTH-1:0] m19_axi_awuser;
wire m19_axi_awvalid;
reg  m19_axi_awready;
wire [DATA_WIDTH-1:0] m19_axi_wdata;
wire [STRB_WIDTH-1:0] m19_axi_wstrb;
wire m19_axi_wlast;
wire [WUSER_WIDTH-1:0] m19_axi_wuser;
wire m19_axi_wvalid;
reg  m19_axi_wready;
reg  [ID_WIDTH-1:0] m19_axi_bid;
reg  [1:0] m19_axi_bresp;
reg  [BUSER_WIDTH-1:0] m19_axi_buser;
reg  m19_axi_bvalid;
wire m19_axi_bready;
wire [ID_WIDTH-1:0] m19_axi_arid;
wire [ADDR_WIDTH-1:0] m19_axi_araddr;
wire [7:0] m19_axi_arlen;
wire [2:0] m19_axi_arsize;
wire [1:0] m19_axi_arburst;
wire m19_axi_arlock;
wire [3:0] m19_axi_arcache;
wire [2:0] m19_axi_arprot;
wire [3:0] m19_axi_arqos;
wire [3:0] m19_axi_arregion;
wire [ARUSER_WIDTH-1:0] m19_axi_aruser;
wire m19_axi_arvalid;
reg  m19_axi_arready;
reg  [ID_WIDTH-1:0] m19_axi_rid;
reg  [DATA_WIDTH-1:0] m19_axi_rdata;
reg  [1:0] m19_axi_rresp;
reg  m19_axi_rlast;
reg  [RUSER_WIDTH-1:0] m19_axi_ruser;
reg  m19_axi_rvalid;
wire m19_axi_rready;

// External UART pins
reg  uart_rx_in = 1'b1; // Idle line is HIGH
wire uart_tx_out;
wire uart_irq;

initial begin
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
    m03_axi_awready = 1'b1; m03_axi_wready = 1'b1; m03_axi_arready = 1'b1;
    m03_axi_bvalid  = 1'b0; m03_axi_rvalid = 1'b0; m03_axi_rlast  = 1'b1;
    m03_axi_bid = 0; m03_axi_bresp = 0; m03_axi_buser = 0;
    m03_axi_rid = 0; m03_axi_rdata = 0; m03_axi_rresp = 0; m03_axi_ruser = 0;
    m04_axi_awready = 1'b1; m04_axi_wready = 1'b1; m04_axi_arready = 1'b1;
    m04_axi_bvalid  = 1'b0; m04_axi_rvalid = 1'b0; m04_axi_rlast  = 1'b1;
    m04_axi_bid = 0; m04_axi_bresp = 0; m04_axi_buser = 0;
    m04_axi_rid = 0; m04_axi_rdata = 0; m04_axi_rresp = 0; m04_axi_ruser = 0;
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
    m10_axi_awready = 1'b1; m10_axi_wready = 1'b1; m10_axi_arready = 1'b1;
    m10_axi_bvalid  = 1'b0; m10_axi_rvalid = 1'b0; m10_axi_rlast  = 1'b1;
    m10_axi_bid = 0; m10_axi_bresp = 0; m10_axi_buser = 0;
    m10_axi_rid = 0; m10_axi_rdata = 0; m10_axi_rresp = 0; m10_axi_ruser = 0;
    m11_axi_awready = 1'b1; m11_axi_wready = 1'b1; m11_axi_arready = 1'b1;
    m11_axi_bvalid  = 1'b0; m11_axi_rvalid = 1'b0; m11_axi_rlast  = 1'b1;
    m11_axi_bid = 0; m11_axi_bresp = 0; m11_axi_buser = 0;
    m11_axi_rid = 0; m11_axi_rdata = 0; m11_axi_rresp = 0; m11_axi_ruser = 0;
    m12_axi_awready = 1'b1; m12_axi_wready = 1'b1; m12_axi_arready = 1'b1;
    m12_axi_bvalid  = 1'b0; m12_axi_rvalid = 1'b0; m12_axi_rlast  = 1'b1;
    m12_axi_bid = 0; m12_axi_bresp = 0; m12_axi_buser = 0;
    m12_axi_rid = 0; m12_axi_rdata = 0; m12_axi_rresp = 0; m12_axi_ruser = 0;
    m13_axi_awready = 1'b1; m13_axi_wready = 1'b1; m13_axi_arready = 1'b1;
    m13_axi_bvalid  = 1'b0; m13_axi_rvalid = 1'b0; m13_axi_rlast  = 1'b1;
    m13_axi_bid = 0; m13_axi_bresp = 0; m13_axi_buser = 0;
    m13_axi_rid = 0; m13_axi_rdata = 0; m13_axi_rresp = 0; m13_axi_ruser = 0;
    m14_axi_awready = 1'b1; m14_axi_wready = 1'b1; m14_axi_arready = 1'b1;
    m14_axi_bvalid  = 1'b0; m14_axi_rvalid = 1'b0; m14_axi_rlast  = 1'b1;
    m14_axi_bid = 0; m14_axi_bresp = 0; m14_axi_buser = 0;
    m14_axi_rid = 0; m14_axi_rdata = 0; m14_axi_rresp = 0; m14_axi_ruser = 0;
    m15_axi_awready = 1'b1; m15_axi_wready = 1'b1; m15_axi_arready = 1'b1;
    m15_axi_bvalid  = 1'b0; m15_axi_rvalid = 1'b0; m15_axi_rlast  = 1'b1;
    m15_axi_bid = 0; m15_axi_bresp = 0; m15_axi_buser = 0;
    m15_axi_rid = 0; m15_axi_rdata = 0; m15_axi_rresp = 0; m15_axi_ruser = 0;
    m16_axi_awready = 1'b1; m16_axi_wready = 1'b1; m16_axi_arready = 1'b1;
    m16_axi_bvalid  = 1'b0; m16_axi_rvalid = 1'b0; m16_axi_rlast  = 1'b1;
    m16_axi_bid = 0; m16_axi_bresp = 0; m16_axi_buser = 0;
    m16_axi_rid = 0; m16_axi_rdata = 0; m16_axi_rresp = 0; m16_axi_ruser = 0;
    m17_axi_awready = 1'b1; m17_axi_wready = 1'b1; m17_axi_arready = 1'b1;
    m17_axi_bvalid  = 1'b0; m17_axi_rvalid = 1'b0; m17_axi_rlast  = 1'b1;
    m17_axi_bid = 0; m17_axi_bresp = 0; m17_axi_buser = 0;
    m17_axi_rid = 0; m17_axi_rdata = 0; m17_axi_rresp = 0; m17_axi_ruser = 0;
    m18_axi_awready = 1'b1; m18_axi_wready = 1'b1; m18_axi_arready = 1'b1;
    m18_axi_bvalid  = 1'b0; m18_axi_rvalid = 1'b0; m18_axi_rlast  = 1'b1;
    m18_axi_bid = 0; m18_axi_bresp = 0; m18_axi_buser = 0;
    m18_axi_rid = 0; m18_axi_rdata = 0; m18_axi_rresp = 0; m18_axi_ruser = 0;
    m19_axi_awready = 1'b1; m19_axi_wready = 1'b1; m19_axi_arready = 1'b1;
    m19_axi_bvalid  = 1'b0; m19_axi_rvalid = 1'b0; m19_axi_rlast  = 1'b1;
    m19_axi_bid = 0; m19_axi_bresp = 0; m19_axi_buser = 0;
    m19_axi_rid = 0; m19_axi_rdata = 0; m19_axi_rresp = 0; m19_axi_ruser = 0;
end

`include "axi_bfm.vh"

axi_soc_top_5x20 u_top (
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

    .s03_axi_awid(s03_axi_awid),
    .s03_axi_awaddr(s03_axi_awaddr),
    .s03_axi_awlen(s03_axi_awlen),
    .s03_axi_awsize(s03_axi_awsize),
    .s03_axi_awburst(s03_axi_awburst),
    .s03_axi_awlock(s03_axi_awlock),
    .s03_axi_awcache(s03_axi_awcache),
    .s03_axi_awprot(s03_axi_awprot),
    .s03_axi_awqos(s03_axi_awqos),
    .s03_axi_awuser(s03_axi_awuser),
    .s03_axi_awvalid(s03_axi_awvalid),
    .s03_axi_awready(s03_axi_awready),
    .s03_axi_wdata(s03_axi_wdata),
    .s03_axi_wstrb(s03_axi_wstrb),
    .s03_axi_wlast(s03_axi_wlast),
    .s03_axi_wuser(s03_axi_wuser),
    .s03_axi_wvalid(s03_axi_wvalid),
    .s03_axi_wready(s03_axi_wready),
    .s03_axi_bid(s03_axi_bid),
    .s03_axi_bresp(s03_axi_bresp),
    .s03_axi_buser(s03_axi_buser),
    .s03_axi_bvalid(s03_axi_bvalid),
    .s03_axi_bready(s03_axi_bready),
    .s03_axi_arid(s03_axi_arid),
    .s03_axi_araddr(s03_axi_araddr),
    .s03_axi_arlen(s03_axi_arlen),
    .s03_axi_arsize(s03_axi_arsize),
    .s03_axi_arburst(s03_axi_arburst),
    .s03_axi_arlock(s03_axi_arlock),
    .s03_axi_arcache(s03_axi_arcache),
    .s03_axi_arprot(s03_axi_arprot),
    .s03_axi_arqos(s03_axi_arqos),
    .s03_axi_aruser(s03_axi_aruser),
    .s03_axi_arvalid(s03_axi_arvalid),
    .s03_axi_arready(s03_axi_arready),
    .s03_axi_rid(s03_axi_rid),
    .s03_axi_rdata(s03_axi_rdata),
    .s03_axi_rresp(s03_axi_rresp),
    .s03_axi_rlast(s03_axi_rlast),
    .s03_axi_ruser(s03_axi_ruser),
    .s03_axi_rvalid(s03_axi_rvalid),
    .s03_axi_rready(s03_axi_rready),

    .s04_axi_awid(s04_axi_awid),
    .s04_axi_awaddr(s04_axi_awaddr),
    .s04_axi_awlen(s04_axi_awlen),
    .s04_axi_awsize(s04_axi_awsize),
    .s04_axi_awburst(s04_axi_awburst),
    .s04_axi_awlock(s04_axi_awlock),
    .s04_axi_awcache(s04_axi_awcache),
    .s04_axi_awprot(s04_axi_awprot),
    .s04_axi_awqos(s04_axi_awqos),
    .s04_axi_awuser(s04_axi_awuser),
    .s04_axi_awvalid(s04_axi_awvalid),
    .s04_axi_awready(s04_axi_awready),
    .s04_axi_wdata(s04_axi_wdata),
    .s04_axi_wstrb(s04_axi_wstrb),
    .s04_axi_wlast(s04_axi_wlast),
    .s04_axi_wuser(s04_axi_wuser),
    .s04_axi_wvalid(s04_axi_wvalid),
    .s04_axi_wready(s04_axi_wready),
    .s04_axi_bid(s04_axi_bid),
    .s04_axi_bresp(s04_axi_bresp),
    .s04_axi_buser(s04_axi_buser),
    .s04_axi_bvalid(s04_axi_bvalid),
    .s04_axi_bready(s04_axi_bready),
    .s04_axi_arid(s04_axi_arid),
    .s04_axi_araddr(s04_axi_araddr),
    .s04_axi_arlen(s04_axi_arlen),
    .s04_axi_arsize(s04_axi_arsize),
    .s04_axi_arburst(s04_axi_arburst),
    .s04_axi_arlock(s04_axi_arlock),
    .s04_axi_arcache(s04_axi_arcache),
    .s04_axi_arprot(s04_axi_arprot),
    .s04_axi_arqos(s04_axi_arqos),
    .s04_axi_aruser(s04_axi_aruser),
    .s04_axi_arvalid(s04_axi_arvalid),
    .s04_axi_arready(s04_axi_arready),
    .s04_axi_rid(s04_axi_rid),
    .s04_axi_rdata(s04_axi_rdata),
    .s04_axi_rresp(s04_axi_rresp),
    .s04_axi_rlast(s04_axi_rlast),
    .s04_axi_ruser(s04_axi_ruser),
    .s04_axi_rvalid(s04_axi_rvalid),
    .s04_axi_rready(s04_axi_rready),

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

    .m03_axi_awid(m03_axi_awid),
    .m03_axi_awaddr(m03_axi_awaddr),
    .m03_axi_awlen(m03_axi_awlen),
    .m03_axi_awsize(m03_axi_awsize),
    .m03_axi_awburst(m03_axi_awburst),
    .m03_axi_awlock(m03_axi_awlock),
    .m03_axi_awcache(m03_axi_awcache),
    .m03_axi_awprot(m03_axi_awprot),
    .m03_axi_awqos(m03_axi_awqos),
    .m03_axi_awregion(m03_axi_awregion),
    .m03_axi_awuser(m03_axi_awuser),
    .m03_axi_awvalid(m03_axi_awvalid),
    .m03_axi_awready(m03_axi_awready),
    .m03_axi_wdata(m03_axi_wdata),
    .m03_axi_wstrb(m03_axi_wstrb),
    .m03_axi_wlast(m03_axi_wlast),
    .m03_axi_wuser(m03_axi_wuser),
    .m03_axi_wvalid(m03_axi_wvalid),
    .m03_axi_wready(m03_axi_wready),
    .m03_axi_bid(m03_axi_bid),
    .m03_axi_bresp(m03_axi_bresp),
    .m03_axi_buser(m03_axi_buser),
    .m03_axi_bvalid(m03_axi_bvalid),
    .m03_axi_bready(m03_axi_bready),
    .m03_axi_arid(m03_axi_arid),
    .m03_axi_araddr(m03_axi_araddr),
    .m03_axi_arlen(m03_axi_arlen),
    .m03_axi_arsize(m03_axi_arsize),
    .m03_axi_arburst(m03_axi_arburst),
    .m03_axi_arlock(m03_axi_arlock),
    .m03_axi_arcache(m03_axi_arcache),
    .m03_axi_arprot(m03_axi_arprot),
    .m03_axi_arqos(m03_axi_arqos),
    .m03_axi_arregion(m03_axi_arregion),
    .m03_axi_aruser(m03_axi_aruser),
    .m03_axi_arvalid(m03_axi_arvalid),
    .m03_axi_arready(m03_axi_arready),
    .m03_axi_rid(m03_axi_rid),
    .m03_axi_rdata(m03_axi_rdata),
    .m03_axi_rresp(m03_axi_rresp),
    .m03_axi_rlast(m03_axi_rlast),
    .m03_axi_ruser(m03_axi_ruser),
    .m03_axi_rvalid(m03_axi_rvalid),
    .m03_axi_rready(m03_axi_rready),

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

    .m10_axi_awid(m10_axi_awid),
    .m10_axi_awaddr(m10_axi_awaddr),
    .m10_axi_awlen(m10_axi_awlen),
    .m10_axi_awsize(m10_axi_awsize),
    .m10_axi_awburst(m10_axi_awburst),
    .m10_axi_awlock(m10_axi_awlock),
    .m10_axi_awcache(m10_axi_awcache),
    .m10_axi_awprot(m10_axi_awprot),
    .m10_axi_awqos(m10_axi_awqos),
    .m10_axi_awregion(m10_axi_awregion),
    .m10_axi_awuser(m10_axi_awuser),
    .m10_axi_awvalid(m10_axi_awvalid),
    .m10_axi_awready(m10_axi_awready),
    .m10_axi_wdata(m10_axi_wdata),
    .m10_axi_wstrb(m10_axi_wstrb),
    .m10_axi_wlast(m10_axi_wlast),
    .m10_axi_wuser(m10_axi_wuser),
    .m10_axi_wvalid(m10_axi_wvalid),
    .m10_axi_wready(m10_axi_wready),
    .m10_axi_bid(m10_axi_bid),
    .m10_axi_bresp(m10_axi_bresp),
    .m10_axi_buser(m10_axi_buser),
    .m10_axi_bvalid(m10_axi_bvalid),
    .m10_axi_bready(m10_axi_bready),
    .m10_axi_arid(m10_axi_arid),
    .m10_axi_araddr(m10_axi_araddr),
    .m10_axi_arlen(m10_axi_arlen),
    .m10_axi_arsize(m10_axi_arsize),
    .m10_axi_arburst(m10_axi_arburst),
    .m10_axi_arlock(m10_axi_arlock),
    .m10_axi_arcache(m10_axi_arcache),
    .m10_axi_arprot(m10_axi_arprot),
    .m10_axi_arqos(m10_axi_arqos),
    .m10_axi_arregion(m10_axi_arregion),
    .m10_axi_aruser(m10_axi_aruser),
    .m10_axi_arvalid(m10_axi_arvalid),
    .m10_axi_arready(m10_axi_arready),
    .m10_axi_rid(m10_axi_rid),
    .m10_axi_rdata(m10_axi_rdata),
    .m10_axi_rresp(m10_axi_rresp),
    .m10_axi_rlast(m10_axi_rlast),
    .m10_axi_ruser(m10_axi_ruser),
    .m10_axi_rvalid(m10_axi_rvalid),
    .m10_axi_rready(m10_axi_rready),

    .m11_axi_awid(m11_axi_awid),
    .m11_axi_awaddr(m11_axi_awaddr),
    .m11_axi_awlen(m11_axi_awlen),
    .m11_axi_awsize(m11_axi_awsize),
    .m11_axi_awburst(m11_axi_awburst),
    .m11_axi_awlock(m11_axi_awlock),
    .m11_axi_awcache(m11_axi_awcache),
    .m11_axi_awprot(m11_axi_awprot),
    .m11_axi_awqos(m11_axi_awqos),
    .m11_axi_awregion(m11_axi_awregion),
    .m11_axi_awuser(m11_axi_awuser),
    .m11_axi_awvalid(m11_axi_awvalid),
    .m11_axi_awready(m11_axi_awready),
    .m11_axi_wdata(m11_axi_wdata),
    .m11_axi_wstrb(m11_axi_wstrb),
    .m11_axi_wlast(m11_axi_wlast),
    .m11_axi_wuser(m11_axi_wuser),
    .m11_axi_wvalid(m11_axi_wvalid),
    .m11_axi_wready(m11_axi_wready),
    .m11_axi_bid(m11_axi_bid),
    .m11_axi_bresp(m11_axi_bresp),
    .m11_axi_buser(m11_axi_buser),
    .m11_axi_bvalid(m11_axi_bvalid),
    .m11_axi_bready(m11_axi_bready),
    .m11_axi_arid(m11_axi_arid),
    .m11_axi_araddr(m11_axi_araddr),
    .m11_axi_arlen(m11_axi_arlen),
    .m11_axi_arsize(m11_axi_arsize),
    .m11_axi_arburst(m11_axi_arburst),
    .m11_axi_arlock(m11_axi_arlock),
    .m11_axi_arcache(m11_axi_arcache),
    .m11_axi_arprot(m11_axi_arprot),
    .m11_axi_arqos(m11_axi_arqos),
    .m11_axi_arregion(m11_axi_arregion),
    .m11_axi_aruser(m11_axi_aruser),
    .m11_axi_arvalid(m11_axi_arvalid),
    .m11_axi_arready(m11_axi_arready),
    .m11_axi_rid(m11_axi_rid),
    .m11_axi_rdata(m11_axi_rdata),
    .m11_axi_rresp(m11_axi_rresp),
    .m11_axi_rlast(m11_axi_rlast),
    .m11_axi_ruser(m11_axi_ruser),
    .m11_axi_rvalid(m11_axi_rvalid),
    .m11_axi_rready(m11_axi_rready),

    .m12_axi_awid(m12_axi_awid),
    .m12_axi_awaddr(m12_axi_awaddr),
    .m12_axi_awlen(m12_axi_awlen),
    .m12_axi_awsize(m12_axi_awsize),
    .m12_axi_awburst(m12_axi_awburst),
    .m12_axi_awlock(m12_axi_awlock),
    .m12_axi_awcache(m12_axi_awcache),
    .m12_axi_awprot(m12_axi_awprot),
    .m12_axi_awqos(m12_axi_awqos),
    .m12_axi_awregion(m12_axi_awregion),
    .m12_axi_awuser(m12_axi_awuser),
    .m12_axi_awvalid(m12_axi_awvalid),
    .m12_axi_awready(m12_axi_awready),
    .m12_axi_wdata(m12_axi_wdata),
    .m12_axi_wstrb(m12_axi_wstrb),
    .m12_axi_wlast(m12_axi_wlast),
    .m12_axi_wuser(m12_axi_wuser),
    .m12_axi_wvalid(m12_axi_wvalid),
    .m12_axi_wready(m12_axi_wready),
    .m12_axi_bid(m12_axi_bid),
    .m12_axi_bresp(m12_axi_bresp),
    .m12_axi_buser(m12_axi_buser),
    .m12_axi_bvalid(m12_axi_bvalid),
    .m12_axi_bready(m12_axi_bready),
    .m12_axi_arid(m12_axi_arid),
    .m12_axi_araddr(m12_axi_araddr),
    .m12_axi_arlen(m12_axi_arlen),
    .m12_axi_arsize(m12_axi_arsize),
    .m12_axi_arburst(m12_axi_arburst),
    .m12_axi_arlock(m12_axi_arlock),
    .m12_axi_arcache(m12_axi_arcache),
    .m12_axi_arprot(m12_axi_arprot),
    .m12_axi_arqos(m12_axi_arqos),
    .m12_axi_arregion(m12_axi_arregion),
    .m12_axi_aruser(m12_axi_aruser),
    .m12_axi_arvalid(m12_axi_arvalid),
    .m12_axi_arready(m12_axi_arready),
    .m12_axi_rid(m12_axi_rid),
    .m12_axi_rdata(m12_axi_rdata),
    .m12_axi_rresp(m12_axi_rresp),
    .m12_axi_rlast(m12_axi_rlast),
    .m12_axi_ruser(m12_axi_ruser),
    .m12_axi_rvalid(m12_axi_rvalid),
    .m12_axi_rready(m12_axi_rready),

    .m13_axi_awid(m13_axi_awid),
    .m13_axi_awaddr(m13_axi_awaddr),
    .m13_axi_awlen(m13_axi_awlen),
    .m13_axi_awsize(m13_axi_awsize),
    .m13_axi_awburst(m13_axi_awburst),
    .m13_axi_awlock(m13_axi_awlock),
    .m13_axi_awcache(m13_axi_awcache),
    .m13_axi_awprot(m13_axi_awprot),
    .m13_axi_awqos(m13_axi_awqos),
    .m13_axi_awregion(m13_axi_awregion),
    .m13_axi_awuser(m13_axi_awuser),
    .m13_axi_awvalid(m13_axi_awvalid),
    .m13_axi_awready(m13_axi_awready),
    .m13_axi_wdata(m13_axi_wdata),
    .m13_axi_wstrb(m13_axi_wstrb),
    .m13_axi_wlast(m13_axi_wlast),
    .m13_axi_wuser(m13_axi_wuser),
    .m13_axi_wvalid(m13_axi_wvalid),
    .m13_axi_wready(m13_axi_wready),
    .m13_axi_bid(m13_axi_bid),
    .m13_axi_bresp(m13_axi_bresp),
    .m13_axi_buser(m13_axi_buser),
    .m13_axi_bvalid(m13_axi_bvalid),
    .m13_axi_bready(m13_axi_bready),
    .m13_axi_arid(m13_axi_arid),
    .m13_axi_araddr(m13_axi_araddr),
    .m13_axi_arlen(m13_axi_arlen),
    .m13_axi_arsize(m13_axi_arsize),
    .m13_axi_arburst(m13_axi_arburst),
    .m13_axi_arlock(m13_axi_arlock),
    .m13_axi_arcache(m13_axi_arcache),
    .m13_axi_arprot(m13_axi_arprot),
    .m13_axi_arqos(m13_axi_arqos),
    .m13_axi_arregion(m13_axi_arregion),
    .m13_axi_aruser(m13_axi_aruser),
    .m13_axi_arvalid(m13_axi_arvalid),
    .m13_axi_arready(m13_axi_arready),
    .m13_axi_rid(m13_axi_rid),
    .m13_axi_rdata(m13_axi_rdata),
    .m13_axi_rresp(m13_axi_rresp),
    .m13_axi_rlast(m13_axi_rlast),
    .m13_axi_ruser(m13_axi_ruser),
    .m13_axi_rvalid(m13_axi_rvalid),
    .m13_axi_rready(m13_axi_rready),

    .m14_axi_awid(m14_axi_awid),
    .m14_axi_awaddr(m14_axi_awaddr),
    .m14_axi_awlen(m14_axi_awlen),
    .m14_axi_awsize(m14_axi_awsize),
    .m14_axi_awburst(m14_axi_awburst),
    .m14_axi_awlock(m14_axi_awlock),
    .m14_axi_awcache(m14_axi_awcache),
    .m14_axi_awprot(m14_axi_awprot),
    .m14_axi_awqos(m14_axi_awqos),
    .m14_axi_awregion(m14_axi_awregion),
    .m14_axi_awuser(m14_axi_awuser),
    .m14_axi_awvalid(m14_axi_awvalid),
    .m14_axi_awready(m14_axi_awready),
    .m14_axi_wdata(m14_axi_wdata),
    .m14_axi_wstrb(m14_axi_wstrb),
    .m14_axi_wlast(m14_axi_wlast),
    .m14_axi_wuser(m14_axi_wuser),
    .m14_axi_wvalid(m14_axi_wvalid),
    .m14_axi_wready(m14_axi_wready),
    .m14_axi_bid(m14_axi_bid),
    .m14_axi_bresp(m14_axi_bresp),
    .m14_axi_buser(m14_axi_buser),
    .m14_axi_bvalid(m14_axi_bvalid),
    .m14_axi_bready(m14_axi_bready),
    .m14_axi_arid(m14_axi_arid),
    .m14_axi_araddr(m14_axi_araddr),
    .m14_axi_arlen(m14_axi_arlen),
    .m14_axi_arsize(m14_axi_arsize),
    .m14_axi_arburst(m14_axi_arburst),
    .m14_axi_arlock(m14_axi_arlock),
    .m14_axi_arcache(m14_axi_arcache),
    .m14_axi_arprot(m14_axi_arprot),
    .m14_axi_arqos(m14_axi_arqos),
    .m14_axi_arregion(m14_axi_arregion),
    .m14_axi_aruser(m14_axi_aruser),
    .m14_axi_arvalid(m14_axi_arvalid),
    .m14_axi_arready(m14_axi_arready),
    .m14_axi_rid(m14_axi_rid),
    .m14_axi_rdata(m14_axi_rdata),
    .m14_axi_rresp(m14_axi_rresp),
    .m14_axi_rlast(m14_axi_rlast),
    .m14_axi_ruser(m14_axi_ruser),
    .m14_axi_rvalid(m14_axi_rvalid),
    .m14_axi_rready(m14_axi_rready),

    .m15_axi_awid(m15_axi_awid),
    .m15_axi_awaddr(m15_axi_awaddr),
    .m15_axi_awlen(m15_axi_awlen),
    .m15_axi_awsize(m15_axi_awsize),
    .m15_axi_awburst(m15_axi_awburst),
    .m15_axi_awlock(m15_axi_awlock),
    .m15_axi_awcache(m15_axi_awcache),
    .m15_axi_awprot(m15_axi_awprot),
    .m15_axi_awqos(m15_axi_awqos),
    .m15_axi_awregion(m15_axi_awregion),
    .m15_axi_awuser(m15_axi_awuser),
    .m15_axi_awvalid(m15_axi_awvalid),
    .m15_axi_awready(m15_axi_awready),
    .m15_axi_wdata(m15_axi_wdata),
    .m15_axi_wstrb(m15_axi_wstrb),
    .m15_axi_wlast(m15_axi_wlast),
    .m15_axi_wuser(m15_axi_wuser),
    .m15_axi_wvalid(m15_axi_wvalid),
    .m15_axi_wready(m15_axi_wready),
    .m15_axi_bid(m15_axi_bid),
    .m15_axi_bresp(m15_axi_bresp),
    .m15_axi_buser(m15_axi_buser),
    .m15_axi_bvalid(m15_axi_bvalid),
    .m15_axi_bready(m15_axi_bready),
    .m15_axi_arid(m15_axi_arid),
    .m15_axi_araddr(m15_axi_araddr),
    .m15_axi_arlen(m15_axi_arlen),
    .m15_axi_arsize(m15_axi_arsize),
    .m15_axi_arburst(m15_axi_arburst),
    .m15_axi_arlock(m15_axi_arlock),
    .m15_axi_arcache(m15_axi_arcache),
    .m15_axi_arprot(m15_axi_arprot),
    .m15_axi_arqos(m15_axi_arqos),
    .m15_axi_arregion(m15_axi_arregion),
    .m15_axi_aruser(m15_axi_aruser),
    .m15_axi_arvalid(m15_axi_arvalid),
    .m15_axi_arready(m15_axi_arready),
    .m15_axi_rid(m15_axi_rid),
    .m15_axi_rdata(m15_axi_rdata),
    .m15_axi_rresp(m15_axi_rresp),
    .m15_axi_rlast(m15_axi_rlast),
    .m15_axi_ruser(m15_axi_ruser),
    .m15_axi_rvalid(m15_axi_rvalid),
    .m15_axi_rready(m15_axi_rready),

    .m16_axi_awid(m16_axi_awid),
    .m16_axi_awaddr(m16_axi_awaddr),
    .m16_axi_awlen(m16_axi_awlen),
    .m16_axi_awsize(m16_axi_awsize),
    .m16_axi_awburst(m16_axi_awburst),
    .m16_axi_awlock(m16_axi_awlock),
    .m16_axi_awcache(m16_axi_awcache),
    .m16_axi_awprot(m16_axi_awprot),
    .m16_axi_awqos(m16_axi_awqos),
    .m16_axi_awregion(m16_axi_awregion),
    .m16_axi_awuser(m16_axi_awuser),
    .m16_axi_awvalid(m16_axi_awvalid),
    .m16_axi_awready(m16_axi_awready),
    .m16_axi_wdata(m16_axi_wdata),
    .m16_axi_wstrb(m16_axi_wstrb),
    .m16_axi_wlast(m16_axi_wlast),
    .m16_axi_wuser(m16_axi_wuser),
    .m16_axi_wvalid(m16_axi_wvalid),
    .m16_axi_wready(m16_axi_wready),
    .m16_axi_bid(m16_axi_bid),
    .m16_axi_bresp(m16_axi_bresp),
    .m16_axi_buser(m16_axi_buser),
    .m16_axi_bvalid(m16_axi_bvalid),
    .m16_axi_bready(m16_axi_bready),
    .m16_axi_arid(m16_axi_arid),
    .m16_axi_araddr(m16_axi_araddr),
    .m16_axi_arlen(m16_axi_arlen),
    .m16_axi_arsize(m16_axi_arsize),
    .m16_axi_arburst(m16_axi_arburst),
    .m16_axi_arlock(m16_axi_arlock),
    .m16_axi_arcache(m16_axi_arcache),
    .m16_axi_arprot(m16_axi_arprot),
    .m16_axi_arqos(m16_axi_arqos),
    .m16_axi_arregion(m16_axi_arregion),
    .m16_axi_aruser(m16_axi_aruser),
    .m16_axi_arvalid(m16_axi_arvalid),
    .m16_axi_arready(m16_axi_arready),
    .m16_axi_rid(m16_axi_rid),
    .m16_axi_rdata(m16_axi_rdata),
    .m16_axi_rresp(m16_axi_rresp),
    .m16_axi_rlast(m16_axi_rlast),
    .m16_axi_ruser(m16_axi_ruser),
    .m16_axi_rvalid(m16_axi_rvalid),
    .m16_axi_rready(m16_axi_rready),

    .m17_axi_awid(m17_axi_awid),
    .m17_axi_awaddr(m17_axi_awaddr),
    .m17_axi_awlen(m17_axi_awlen),
    .m17_axi_awsize(m17_axi_awsize),
    .m17_axi_awburst(m17_axi_awburst),
    .m17_axi_awlock(m17_axi_awlock),
    .m17_axi_awcache(m17_axi_awcache),
    .m17_axi_awprot(m17_axi_awprot),
    .m17_axi_awqos(m17_axi_awqos),
    .m17_axi_awregion(m17_axi_awregion),
    .m17_axi_awuser(m17_axi_awuser),
    .m17_axi_awvalid(m17_axi_awvalid),
    .m17_axi_awready(m17_axi_awready),
    .m17_axi_wdata(m17_axi_wdata),
    .m17_axi_wstrb(m17_axi_wstrb),
    .m17_axi_wlast(m17_axi_wlast),
    .m17_axi_wuser(m17_axi_wuser),
    .m17_axi_wvalid(m17_axi_wvalid),
    .m17_axi_wready(m17_axi_wready),
    .m17_axi_bid(m17_axi_bid),
    .m17_axi_bresp(m17_axi_bresp),
    .m17_axi_buser(m17_axi_buser),
    .m17_axi_bvalid(m17_axi_bvalid),
    .m17_axi_bready(m17_axi_bready),
    .m17_axi_arid(m17_axi_arid),
    .m17_axi_araddr(m17_axi_araddr),
    .m17_axi_arlen(m17_axi_arlen),
    .m17_axi_arsize(m17_axi_arsize),
    .m17_axi_arburst(m17_axi_arburst),
    .m17_axi_arlock(m17_axi_arlock),
    .m17_axi_arcache(m17_axi_arcache),
    .m17_axi_arprot(m17_axi_arprot),
    .m17_axi_arqos(m17_axi_arqos),
    .m17_axi_arregion(m17_axi_arregion),
    .m17_axi_aruser(m17_axi_aruser),
    .m17_axi_arvalid(m17_axi_arvalid),
    .m17_axi_arready(m17_axi_arready),
    .m17_axi_rid(m17_axi_rid),
    .m17_axi_rdata(m17_axi_rdata),
    .m17_axi_rresp(m17_axi_rresp),
    .m17_axi_rlast(m17_axi_rlast),
    .m17_axi_ruser(m17_axi_ruser),
    .m17_axi_rvalid(m17_axi_rvalid),
    .m17_axi_rready(m17_axi_rready),

    .m18_axi_awid(m18_axi_awid),
    .m18_axi_awaddr(m18_axi_awaddr),
    .m18_axi_awlen(m18_axi_awlen),
    .m18_axi_awsize(m18_axi_awsize),
    .m18_axi_awburst(m18_axi_awburst),
    .m18_axi_awlock(m18_axi_awlock),
    .m18_axi_awcache(m18_axi_awcache),
    .m18_axi_awprot(m18_axi_awprot),
    .m18_axi_awqos(m18_axi_awqos),
    .m18_axi_awregion(m18_axi_awregion),
    .m18_axi_awuser(m18_axi_awuser),
    .m18_axi_awvalid(m18_axi_awvalid),
    .m18_axi_awready(m18_axi_awready),
    .m18_axi_wdata(m18_axi_wdata),
    .m18_axi_wstrb(m18_axi_wstrb),
    .m18_axi_wlast(m18_axi_wlast),
    .m18_axi_wuser(m18_axi_wuser),
    .m18_axi_wvalid(m18_axi_wvalid),
    .m18_axi_wready(m18_axi_wready),
    .m18_axi_bid(m18_axi_bid),
    .m18_axi_bresp(m18_axi_bresp),
    .m18_axi_buser(m18_axi_buser),
    .m18_axi_bvalid(m18_axi_bvalid),
    .m18_axi_bready(m18_axi_bready),
    .m18_axi_arid(m18_axi_arid),
    .m18_axi_araddr(m18_axi_araddr),
    .m18_axi_arlen(m18_axi_arlen),
    .m18_axi_arsize(m18_axi_arsize),
    .m18_axi_arburst(m18_axi_arburst),
    .m18_axi_arlock(m18_axi_arlock),
    .m18_axi_arcache(m18_axi_arcache),
    .m18_axi_arprot(m18_axi_arprot),
    .m18_axi_arqos(m18_axi_arqos),
    .m18_axi_arregion(m18_axi_arregion),
    .m18_axi_aruser(m18_axi_aruser),
    .m18_axi_arvalid(m18_axi_arvalid),
    .m18_axi_arready(m18_axi_arready),
    .m18_axi_rid(m18_axi_rid),
    .m18_axi_rdata(m18_axi_rdata),
    .m18_axi_rresp(m18_axi_rresp),
    .m18_axi_rlast(m18_axi_rlast),
    .m18_axi_ruser(m18_axi_ruser),
    .m18_axi_rvalid(m18_axi_rvalid),
    .m18_axi_rready(m18_axi_rready),

    .m19_axi_awid(m19_axi_awid),
    .m19_axi_awaddr(m19_axi_awaddr),
    .m19_axi_awlen(m19_axi_awlen),
    .m19_axi_awsize(m19_axi_awsize),
    .m19_axi_awburst(m19_axi_awburst),
    .m19_axi_awlock(m19_axi_awlock),
    .m19_axi_awcache(m19_axi_awcache),
    .m19_axi_awprot(m19_axi_awprot),
    .m19_axi_awqos(m19_axi_awqos),
    .m19_axi_awregion(m19_axi_awregion),
    .m19_axi_awuser(m19_axi_awuser),
    .m19_axi_awvalid(m19_axi_awvalid),
    .m19_axi_awready(m19_axi_awready),
    .m19_axi_wdata(m19_axi_wdata),
    .m19_axi_wstrb(m19_axi_wstrb),
    .m19_axi_wlast(m19_axi_wlast),
    .m19_axi_wuser(m19_axi_wuser),
    .m19_axi_wvalid(m19_axi_wvalid),
    .m19_axi_wready(m19_axi_wready),
    .m19_axi_bid(m19_axi_bid),
    .m19_axi_bresp(m19_axi_bresp),
    .m19_axi_buser(m19_axi_buser),
    .m19_axi_bvalid(m19_axi_bvalid),
    .m19_axi_bready(m19_axi_bready),
    .m19_axi_arid(m19_axi_arid),
    .m19_axi_araddr(m19_axi_araddr),
    .m19_axi_arlen(m19_axi_arlen),
    .m19_axi_arsize(m19_axi_arsize),
    .m19_axi_arburst(m19_axi_arburst),
    .m19_axi_arlock(m19_axi_arlock),
    .m19_axi_arcache(m19_axi_arcache),
    .m19_axi_arprot(m19_axi_arprot),
    .m19_axi_arqos(m19_axi_arqos),
    .m19_axi_arregion(m19_axi_arregion),
    .m19_axi_aruser(m19_axi_aruser),
    .m19_axi_arvalid(m19_axi_arvalid),
    .m19_axi_arready(m19_axi_arready),
    .m19_axi_rid(m19_axi_rid),
    .m19_axi_rdata(m19_axi_rdata),
    .m19_axi_rresp(m19_axi_rresp),
    .m19_axi_rlast(m19_axi_rlast),
    .m19_axi_ruser(m19_axi_ruser),
    .m19_axi_rvalid(m19_axi_rvalid),
    .m19_axi_rready(m19_axi_rready),

    .uart_rx_i(uart_rx_in),
    .uart_tx_o(uart_tx_out),
    .read_interrupt_o(uart_irq)
);

reg [1:0] rsp;  reg [31:0] rd;  reg [7:0] bid;  integer nb;
task wr32(input [31:0] a, input [31:0] d);
    begin axi_write(8'hC1, UART_BASE + a, 0, 3'd2, d, 4'hF, 0, 0, 0, rsp, bid);
          check(rsp == 2'b00, "top 5x20: write expected OKAY"); end
endtask
task rd32(input [31:0] a, output [31:0] d);
    begin axi_read(8'hD2, UART_BASE + a, 0, 3'd2, 0, 0, rsp, d, nb);
          check(rsp == 2'b00 && nb == 1, "top 5x20: read expected OKAY, 1 beat"); end
endtask

integer BIT_PERIOD_NS = 170; // 17 clk cycles * 10ns

// Task: Capture and decode a byte transmitted by UART on uart_tx_out
task capture_tx_byte(output [7:0] byte_out, output frame_ok);
    integer i;
    begin
        @(negedge uart_tx_out);
        #(BIT_PERIOD_NS/2);
        frame_ok = (uart_tx_out == 1'b0); // start bit = 0
        byte_out = 8'h00;
        for (i = 0; i < 8; i = i + 1) begin
            #(BIT_PERIOD_NS);
            byte_out[i] = uart_tx_out;
        end
        #(BIT_PERIOD_NS);
        if (uart_tx_out !== 1'b1) frame_ok = 1'b0; // stop bit = 1
    end
endtask

// Task: Transmit a serial byte into UART on uart_rx_in (backward flow)
task send_rx_byte(input [7:0] byte_in);
    integer i;
    begin
        uart_rx_in = 1'b0; // start bit
        #(BIT_PERIOD_NS);
        for (i = 0; i < 8; i = i + 1) begin
            uart_rx_in = byte_in[i]; // 8 data bits LSB first
            #(BIT_PERIOD_NS);
        end
        uart_rx_in = 1'b1; // stop bit
        #(BIT_PERIOD_NS);
        #(BIT_PERIOD_NS); // inter-byte delay
    end
endtask

// Task: S01 write to UART
task s01_wr32(input [31:0] a, input [31:0] d);
    begin
        @(posedge clk);
        s01_axi_awid    <= 8'h51;
        s01_axi_awaddr  <= UART_BASE + a;
        s01_axi_awlen   <= 8'd0;
        s01_axi_awsize  <= 3'd2;
        s01_axi_awburst <= 2'b01;
        s01_axi_awvalid <= 1'b1;
        s01_axi_wdata   <= d;
        s01_axi_wstrb   <= 4'hF;
        s01_axi_wlast   <= 1'b1;
        s01_axi_wvalid  <= 1'b1;
        s01_axi_bready  <= 1'b1;
        while (!(s01_axi_awvalid && s01_axi_awready)) @(posedge clk);
        @(posedge clk);
        s01_axi_awvalid <= 1'b0;
        while (!(s01_axi_wvalid && s01_axi_wready)) @(posedge clk);
        @(posedge clk);
        s01_axi_wvalid  <= 1'b0;
        while (!s01_axi_bvalid) @(posedge clk);
        @(posedge clk);
        s01_axi_bready  <= 1'b0;
    end
endtask

reg [7:0] tx_byte; reg tx_ok; integer n;

initial begin
    $dumpfile("tb_top_5x20_smoke.vcd"); $dumpvars(0, tb_axi_soc_top_5x20_smoke);
    repeat (5) @(posedge clk); rst <= 1'b0; repeat (10) @(posedge clk);

    $display("===================================================================");
    $display("=== TEST 0: Configure UART via AXI (S00 -> M05 @ 0x4000_6000)   ===");
    $display("===================================================================");
    wr32(32'h0C, 32'h80); // LCR: DLAB = 1
    wr32(32'h08, 32'd16); // BAUD_DIV = 16 (170ns bit period)
    wr32(32'h0C, 32'h00); // LCR: normal mode, 8-bit, 1 stop, no parity
    wr32(32'h04, 32'h01); // IER: enable RX interrupt
    rd32(32'h14, rd);     // Read LSR: flush status and initialize RX path (LSR = 0x60: TEMT+THRE)
    check(rd[6:5] == 2'b11, "TEST 0: Initial LSR must have TEMT and THRE set");
    BIT_PERIOD_NS = 170;

    $display("===================================================================");
    $display("=== TEST 1: FORWARD FLOW (AXI Master Write -> Serial Pin TX)    ===");
    $display("===================================================================");
    $display("--> Master S00 writes 0xA5 to UART THR (0x4000_6000)");
    fork
        begin capture_tx_byte(tx_byte, tx_ok); end
        begin wr32(32'h00, 32'h0000_00A5); end
    join
    check(tx_ok, "TEST 1: uart_tx_out framing must be correct");
    check(tx_byte == 8'hA5, "TEST 1: uart_tx_out decoded byte must match 0xA5");
    $display("    [PASS] Forward flow verified: AXI master -> UART core -> uart_tx_o = 0x%02X", tx_byte);

    $display("===================================================================");
    $display("=== TEST 2: BACKWARD FLOW (Serial Pin RX -> AXI Master Read)    ===");
    $display("===================================================================");
    $display("--> Injecting external serial byte 0x3C into uart_rx_in pin...");
    send_rx_byte(8'h3C);
    repeat (20) @(posedge clk);
    check(uart_irq == 1'b1, "TEST 2: read_interrupt_o must assert when byte received");
    rd = 0; n = 0;
    while (!rd[0] && n < 500) begin rd32(32'h14, rd); n = n + 1; end
    check(rd[0] == 1'b1, "TEST 2: LSR[0] data-ready must be set");
    rd32(32'h00, rd); // Read RBR
    check(rd[7:0] == 8'h3C, "TEST 2: RBR readback must match injected 0x3C");
    repeat (20) @(posedge clk);
    check(uart_irq == 1'b0, "TEST 2: read_interrupt_o must deassert after reading RBR");
    $display("    [PASS] Backward flow verified: uart_rx_i (0x3C) -> IRQ -> AXI Master read RBR = 0x%02X", rd[7:0]);

    $display("===================================================================");
    $display("=== TEST 3: FULL DUPLEX (Simultaneous Forward TX & Backward RX)  ===");
    $display("===================================================================");
    $display("--> Simultaneous: transmitting 0x88 while receiving 0x77...");
    fork
        begin capture_tx_byte(tx_byte, tx_ok); end
        begin wr32(32'h00, 32'h0000_0088); end
        begin send_rx_byte(8'h77); end
    join
    check(tx_ok, "TEST 3: TX framing must be correct during full duplex");
    check(tx_byte == 8'h88, "TEST 3: TX byte must be 0x88 during full duplex");
    rd = 0; n = 0;
    while (!rd[0] && n < 500) begin rd32(32'h14, rd); n = n + 1; end
    check(rd[0] == 1'b1, "TEST 3: RX data-ready must be set during full duplex");
    rd32(32'h00, rd);
    check(rd[7:0] == 8'h77, "TEST 3: RX byte must be 0x77 during full duplex");
    $display("    [PASS] Full duplex verified: TX sent 0x%02X, RX received 0x%02X simultaneously", tx_byte, rd[7:0]);

    $display("===================================================================");
    $display("=== TEST 4: MULTI-MASTER VERIFICATION (S01 Master writes to UART)===");
    $display("===================================================================");
    $display("--> Master S01 writes 0x59 to UART THR via 5x20 interconnect...");
    fork
        begin capture_tx_byte(tx_byte, tx_ok); end
        begin s01_wr32(32'h00, 32'h0000_0059); end
    join
    check(tx_ok, "TEST 4: S01 TX framing must be correct");
    check(tx_byte == 8'h59, "TEST 4: S01 TX byte must be 0x59");
    $display("    [PASS] Multi-master verified: Master S01 successfully drove UART TX = 0x%02X", tx_byte);

    if (errors == 0) begin
        $display("\n*******************************************************************");
        $display("*** ALL TESTS PASSED: FORWARD & BACKWARD FLOWS VERIFIED 100%%  ***");
        $display("*******************************************************************\n");
    end else begin
        $display("\n*** TEST FAILED: %0d error(s) detected ***", errors);
    end
    $finish;
end

initial begin #30_000_000; $display("*** TEST FAILED: global timeout ***"); $finish; end
initial begin
    $fsdbDumpfile("dump_5x20.fsdb");
    $fsdbDumpvars("+all");
    $fsdbDumpSVA();
    $fsdbDumpMDA();
end
endmodule
`default_nettype wire
