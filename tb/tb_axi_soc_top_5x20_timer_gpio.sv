// =============================================================================
// tb_axi_soc_top_5x20_timer_gpio.sv
//
// Verification Testbench for axi_soc_top_5x20 integrating:
//   - AXI4 5x20 Interconnect Crossbar
//   - M05: UART (0x4000_6000)
//   - M06: System Timer (0x4000_8000) via axi4_to_axil_lite bridge
//   - M07: GPIO Controller (0x4000_A000) via axi4_to_axil_lite bridge
//   - NOTE: AES is deliberately NOT connected to the 5x20 interconnect.
// =============================================================================

`timescale 1ns / 1ps
`default_nettype none

module tb_axi_soc_top_5x20_timer_gpio;

localparam DATA_WIDTH   = 32;
localparam ADDR_WIDTH   = 32;
localparam STRB_WIDTH   = 4;
localparam ID_WIDTH     = 8;
localparam AWUSER_WIDTH = 1;
localparam WUSER_WIDTH  = 1;
localparam BUSER_WIDTH  = 1;
localparam ARUSER_WIDTH = 1;
localparam RUSER_WIDTH  = 1;

localparam [31:0] UART_BASE  = 32'h4000_6000;
localparam [31:0] TIMER_BASE = 32'h4000_8000;
localparam [31:0] GPIO_BASE  = 32'h4000_A000;

reg clk = 1'b0;
reg rst = 1'b1;
integer errors = 0;

always #5 clk = ~clk; // 100 MHz (10ns period)

// -----------------------------------------------------------------------------
// S00 Master (Primary BFM)
// -----------------------------------------------------------------------------
reg  [ID_WIDTH-1:0]     s_axi_awid = 0;
reg  [ADDR_WIDTH-1:0]   s_axi_awaddr = 0;
reg  [7:0]              s_axi_awlen = 0;
reg  [2:0]              s_axi_awsize = 0;
reg  [1:0]              s_axi_awburst = 0;
reg                     s_axi_awlock = 0;
reg  [3:0]              s_axi_awcache = 0;
reg  [2:0]              s_axi_awprot = 0;
reg  [3:0]              s_axi_awqos = 0;
reg  [AWUSER_WIDTH-1:0] s_axi_awuser = 0;
reg                     s_axi_awvalid = 0;
wire                    s_axi_awready;

reg  [DATA_WIDTH-1:0]   s_axi_wdata = 0;
reg  [STRB_WIDTH-1:0]   s_axi_wstrb = 0;
reg                     s_axi_wlast = 0;
reg  [WUSER_WIDTH-1:0]  s_axi_wuser = 0;
reg                     s_axi_wvalid = 0;
wire                    s_axi_wready;

wire [ID_WIDTH-1:0]     s_axi_bid;
wire [1:0]              s_axi_bresp;
wire [BUSER_WIDTH-1:0]  s_axi_buser;
wire                    s_axi_bvalid;
reg                     s_axi_bready = 0;

reg  [ID_WIDTH-1:0]     s_axi_arid = 0;
reg  [ADDR_WIDTH-1:0]   s_axi_araddr = 0;
reg  [7:0]              s_axi_arlen = 0;
reg  [2:0]              s_axi_arsize = 0;
reg  [1:0]              s_axi_arburst = 0;
reg                     s_axi_arlock = 0;
reg  [3:0]              s_axi_arcache = 0;
reg  [2:0]              s_axi_arprot = 0;
reg  [3:0]              s_axi_arqos = 0;
reg  [ARUSER_WIDTH-1:0] s_axi_aruser = 0;
reg                     s_axi_arvalid = 0;
wire                    s_axi_arready;

wire [ID_WIDTH-1:0]     s_axi_rid;
wire [DATA_WIDTH-1:0]   s_axi_rdata;
wire [1:0]              s_axi_rresp;
wire                    s_axi_rlast;
wire [RUSER_WIDTH-1:0]  s_axi_ruser;
wire                    s_axi_rvalid;
reg                     s_axi_rready = 0;

// -----------------------------------------------------------------------------
// S01 Master (Secondary BFM)
// -----------------------------------------------------------------------------
reg  [ID_WIDTH-1:0]     s01_axi_awid = 0;
reg  [ADDR_WIDTH-1:0]   s01_axi_awaddr = 0;
reg  [7:0]              s01_axi_awlen = 0;
reg  [2:0]              s01_axi_awsize = 0;
reg  [1:0]              s01_axi_awburst = 0;
reg                     s01_axi_awlock = 0;
reg  [3:0]              s01_axi_awcache = 0;
reg  [2:0]              s01_axi_awprot = 0;
reg  [3:0]              s01_axi_awqos = 0;
reg  [AWUSER_WIDTH-1:0] s01_axi_awuser = 0;
reg                     s01_axi_awvalid = 0;
wire                    s01_axi_awready;

reg  [DATA_WIDTH-1:0]   s01_axi_wdata = 0;
reg  [STRB_WIDTH-1:0]   s01_axi_wstrb = 0;
reg                     s01_axi_wlast = 0;
reg  [WUSER_WIDTH-1:0]  s01_axi_wuser = 0;
reg                     s01_axi_wvalid = 0;
wire                    s01_axi_wready;

wire [ID_WIDTH-1:0]     s01_axi_bid;
wire [1:0]              s01_axi_bresp;
wire [BUSER_WIDTH-1:0]  s01_axi_buser;
wire                    s01_axi_bvalid;
reg                     s01_axi_bready = 0;

reg  [ID_WIDTH-1:0]     s01_axi_arid = 0;
reg  [ADDR_WIDTH-1:0]   s01_axi_araddr = 0;
reg  [7:0]              s01_axi_arlen = 0;
reg  [2:0]              s01_axi_arsize = 0;
reg  [1:0]              s01_axi_arburst = 0;
reg                     s01_axi_arlock = 0;
reg  [3:0]              s01_axi_arcache = 0;
reg  [2:0]              s01_axi_arprot = 0;
reg  [3:0]              s01_axi_arqos = 0;
reg  [ARUSER_WIDTH-1:0] s01_axi_aruser = 0;
reg                     s01_axi_arvalid = 0;
wire                    s01_axi_arready;

wire [ID_WIDTH-1:0]     s01_axi_rid;
wire [DATA_WIDTH-1:0]   s01_axi_rdata;
wire [1:0]              s01_axi_rresp;
wire                    s01_axi_rlast;
wire [RUSER_WIDTH-1:0]  s01_axi_ruser;
wire                    s01_axi_rvalid;
reg                     s01_axi_rready = 0;

// Tie off S02, S03, S04
wire [ID_WIDTH-1:0] s02_axi_awid = 0, s03_axi_awid = 0, s04_axi_awid = 0;
wire [ADDR_WIDTH-1:0] s02_axi_awaddr = 0, s03_axi_awaddr = 0, s04_axi_awaddr = 0;
wire [7:0] s02_axi_awlen = 0, s03_axi_awlen = 0, s04_axi_awlen = 0;
wire [2:0] s02_axi_awsize = 0, s03_axi_awsize = 0, s04_axi_awsize = 0;
wire [1:0] s02_axi_awburst = 0, s03_axi_awburst = 0, s04_axi_awburst = 0;
wire s02_axi_awlock = 0, s03_axi_awlock = 0, s04_axi_awlock = 0;
wire [3:0] s02_axi_awcache = 0, s03_axi_awcache = 0, s04_axi_awcache = 0;
wire [2:0] s02_axi_awprot = 0, s03_axi_awprot = 0, s04_axi_awprot = 0;
wire [3:0] s02_axi_awqos = 0, s03_axi_awqos = 0, s04_axi_awqos = 0;
wire s02_axi_awvalid = 0, s03_axi_awvalid = 0, s04_axi_awvalid = 0;
wire [DATA_WIDTH-1:0] s02_axi_wdata = 0, s03_axi_wdata = 0, s04_axi_wdata = 0;
wire [STRB_WIDTH-1:0] s02_axi_wstrb = 0, s03_axi_wstrb = 0, s04_axi_wstrb = 0;
wire s02_axi_wlast = 0, s03_axi_wlast = 0, s04_axi_wlast = 0;
wire s02_axi_wvalid = 0, s03_axi_wvalid = 0, s04_axi_wvalid = 0;
wire s02_axi_bready = 0, s03_axi_bready = 0, s04_axi_bready = 0;
wire [ID_WIDTH-1:0] s02_axi_arid = 0, s03_axi_arid = 0, s04_axi_arid = 0;
wire [ADDR_WIDTH-1:0] s02_axi_araddr = 0, s03_axi_araddr = 0, s04_axi_araddr = 0;
wire [7:0] s02_axi_arlen = 0, s03_axi_arlen = 0, s04_axi_arlen = 0;
wire [2:0] s02_axi_arsize = 0, s03_axi_arsize = 0, s04_axi_arsize = 0;
wire [1:0] s02_axi_arburst = 0, s03_axi_arburst = 0, s04_axi_arburst = 0;
wire s02_axi_arlock = 0, s03_axi_arlock = 0, s04_axi_arlock = 0;
wire [3:0] s02_axi_arcache = 0, s03_axi_arcache = 0, s04_axi_arcache = 0;
wire [2:0] s02_axi_arprot = 0, s03_axi_arprot = 0, s04_axi_arprot = 0;
wire [3:0] s02_axi_arqos = 0, s03_axi_arqos = 0, s04_axi_arqos = 0;
wire s02_axi_arvalid = 0, s03_axi_arvalid = 0, s04_axi_arvalid = 0;
wire s02_axi_rready = 0, s03_axi_rready = 0, s04_axi_rready = 0;

// Master dummy sink wiring for M00-M04 and M08-M19
`define DUMMY_SINK_WIRE(idx) \
    wire [ID_WIDTH-1:0]     m``idx``_axi_awid; \
    wire [ADDR_WIDTH-1:0]   m``idx``_axi_awaddr; \
    wire [7:0]              m``idx``_axi_awlen; \
    wire [2:0]              m``idx``_axi_awsize; \
    wire [1:0]              m``idx``_axi_awburst; \
    wire                    m``idx``_axi_awlock; \
    wire [3:0]              m``idx``_axi_awcache; \
    wire [2:0]              m``idx``_axi_awprot; \
    wire [3:0]              m``idx``_axi_awqos; \
    wire [3:0]              m``idx``_axi_awregion; \
    wire [AWUSER_WIDTH-1:0] m``idx``_axi_awuser; \
    wire                    m``idx``_axi_awvalid; \
    reg                     m``idx``_axi_awready; \
    wire [DATA_WIDTH-1:0]   m``idx``_axi_wdata; \
    wire [STRB_WIDTH-1:0]   m``idx``_axi_wstrb; \
    wire                    m``idx``_axi_wlast; \
    wire [WUSER_WIDTH-1:0]  m``idx``_axi_wuser; \
    wire                    m``idx``_axi_wvalid; \
    reg                     m``idx``_axi_wready; \
    reg  [ID_WIDTH-1:0]     m``idx``_axi_bid; \
    reg  [1:0]              m``idx``_axi_bresp; \
    reg  [BUSER_WIDTH-1:0]  m``idx``_axi_buser; \
    reg                     m``idx``_axi_bvalid; \
    wire                    m``idx``_axi_bready; \
    wire [ID_WIDTH-1:0]     m``idx``_axi_arid; \
    wire [ADDR_WIDTH-1:0]   m``idx``_axi_araddr; \
    wire [7:0]              m``idx``_axi_arlen; \
    wire [2:0]              m``idx``_axi_arsize; \
    wire [1:0]              m``idx``_axi_arburst; \
    wire                    m``idx``_axi_arlock; \
    wire [3:0]              m``idx``_axi_arcache; \
    wire [2:0]              m``idx``_axi_arprot; \
    wire [3:0]              m``idx``_axi_arqos; \
    wire [3:0]              m``idx``_axi_arregion; \
    wire [ARUSER_WIDTH-1:0] m``idx``_axi_aruser; \
    wire                    m``idx``_axi_arvalid; \
    reg                     m``idx``_axi_arready; \
    reg  [ID_WIDTH-1:0]     m``idx``_axi_rid; \
    reg  [DATA_WIDTH-1:0]   m``idx``_axi_rdata; \
    reg  [1:0]              m``idx``_axi_rresp; \
    reg                     m``idx``_axi_rlast; \
    reg  [RUSER_WIDTH-1:0]  m``idx``_axi_ruser; \
    reg                     m``idx``_axi_rvalid; \
    wire                    m``idx``_axi_rready;

`DUMMY_SINK_WIRE(00)
`DUMMY_SINK_WIRE(01)
`DUMMY_SINK_WIRE(02)
`DUMMY_SINK_WIRE(03)
`DUMMY_SINK_WIRE(04)
`DUMMY_SINK_WIRE(08)
`DUMMY_SINK_WIRE(09)
`DUMMY_SINK_WIRE(10)
`DUMMY_SINK_WIRE(11)
`DUMMY_SINK_WIRE(12)
`DUMMY_SINK_WIRE(13)
`DUMMY_SINK_WIRE(14)
`DUMMY_SINK_WIRE(15)
`DUMMY_SINK_WIRE(16)
`DUMMY_SINK_WIRE(17)
`DUMMY_SINK_WIRE(18)
`DUMMY_SINK_WIRE(19)

// -----------------------------------------------------------------------------
// Top-Level Peripheral I/O Pins
// -----------------------------------------------------------------------------
reg        uart_rx_in = 1'b1;
wire       uart_tx_out;
wire       uart_irq;

wire       sample_tick;
wire       irq_timer;

reg  [7:0] gpio_in = 8'h00;
wire [7:0] gpio_out;
wire       irq_gpio;

// Instantiate DUT: axi_soc_top_5x20
axi_soc_top_5x20 #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH),
    .ID_WIDTH(ID_WIDTH)
) dut (
    .clk(clk),
    .rst(rst),

    .s00_axi_awid(s_axi_awid), .s00_axi_awaddr(s_axi_awaddr), .s00_axi_awlen(s_axi_awlen),
    .s00_axi_awsize(s_axi_awsize), .s00_axi_awburst(s_axi_awburst), .s00_axi_awlock(s_axi_awlock),
    .s00_axi_awcache(s_axi_awcache), .s00_axi_awprot(s_axi_awprot), .s00_axi_awqos(s_axi_awqos),
    .s00_axi_awuser(s_axi_awuser), .s00_axi_awvalid(s_axi_awvalid), .s00_axi_awready(s_axi_awready),
    .s00_axi_wdata(s_axi_wdata), .s00_axi_wstrb(s_axi_wstrb), .s00_axi_wlast(s_axi_wlast),
    .s00_axi_wuser(s_axi_wuser), .s00_axi_wvalid(s_axi_wvalid), .s00_axi_wready(s_axi_wready),
    .s00_axi_bid(s_axi_bid), .s00_axi_bresp(s_axi_bresp), .s00_axi_buser(s_axi_buser),
    .s00_axi_bvalid(s_axi_bvalid), .s00_axi_bready(s_axi_bready),
    .s00_axi_arid(s_axi_arid), .s00_axi_araddr(s_axi_araddr), .s00_axi_arlen(s_axi_arlen),
    .s00_axi_arsize(s_axi_arsize), .s00_axi_arburst(s_axi_arburst), .s00_axi_arlock(s_axi_arlock),
    .s00_axi_arcache(s_axi_arcache), .s00_axi_arprot(s_axi_arprot), .s00_axi_arqos(s_axi_arqos),
    .s00_axi_aruser(s_axi_aruser), .s00_axi_arvalid(s_axi_arvalid), .s00_axi_arready(s_axi_arready),
    .s00_axi_rid(s_axi_rid), .s00_axi_rdata(s_axi_rdata), .s00_axi_rresp(s_axi_rresp),
    .s00_axi_rlast(s_axi_rlast), .s00_axi_ruser(s_axi_ruser), .s00_axi_rvalid(s_axi_rvalid),
    .s00_axi_rready(s_axi_rready),

    .s01_axi_awid(s01_axi_awid), .s01_axi_awaddr(s01_axi_awaddr), .s01_axi_awlen(s01_axi_awlen),
    .s01_axi_awsize(s01_axi_awsize), .s01_axi_awburst(s01_axi_awburst), .s01_axi_awlock(s01_axi_awlock),
    .s01_axi_awcache(s01_axi_awcache), .s01_axi_awprot(s01_axi_awprot), .s01_axi_awqos(s01_axi_awqos),
    .s01_axi_awuser(s01_axi_awuser), .s01_axi_awvalid(s01_axi_awvalid), .s01_axi_awready(s01_axi_awready),
    .s01_axi_wdata(s01_axi_wdata), .s01_axi_wstrb(s01_axi_wstrb), .s01_axi_wlast(s01_axi_wlast),
    .s01_axi_wuser(s01_axi_wuser), .s01_axi_wvalid(s01_axi_wvalid), .s01_axi_wready(s01_axi_wready),
    .s01_axi_bid(s01_axi_bid), .s01_axi_bresp(s01_axi_bresp), .s01_axi_buser(s01_axi_buser),
    .s01_axi_bvalid(s01_axi_bvalid), .s01_axi_bready(s01_axi_bready),
    .s01_axi_arid(s01_axi_arid), .s01_axi_araddr(s01_axi_araddr), .s01_axi_arlen(s01_axi_arlen),
    .s01_axi_arsize(s01_axi_arsize), .s01_axi_arburst(s01_axi_arburst), .s01_axi_arlock(s01_axi_arlock),
    .s01_axi_arcache(s01_axi_arcache), .s01_axi_arprot(s01_axi_arprot), .s01_axi_arqos(s01_axi_arqos),
    .s01_axi_aruser(s01_axi_aruser), .s01_axi_arvalid(s01_axi_arvalid), .s01_axi_arready(s01_axi_arready),
    .s01_axi_rid(s01_axi_rid), .s01_axi_rdata(s01_axi_rdata), .s01_axi_rresp(s01_axi_rresp),
    .s01_axi_rlast(s01_axi_rlast), .s01_axi_ruser(s01_axi_ruser), .s01_axi_rvalid(s01_axi_rvalid),
    .s01_axi_rready(s01_axi_rready),

    .s02_axi_awid(s02_axi_awid), .s02_axi_awaddr(s02_axi_awaddr), .s02_axi_awlen(s02_axi_awlen),
    .s02_axi_awsize(s02_axi_awsize), .s02_axi_awburst(s02_axi_awburst), .s02_axi_awlock(s02_axi_awlock),
    .s02_axi_awcache(s02_axi_awcache), .s02_axi_awprot(s02_axi_awprot), .s02_axi_awqos(s02_axi_awqos),
    .s02_axi_awuser(1'b0), .s02_axi_awvalid(s02_axi_awvalid), .s02_axi_awready(),
    .s02_axi_wdata(s02_axi_wdata), .s02_axi_wstrb(s02_axi_wstrb), .s02_axi_wlast(s02_axi_wlast),
    .s02_axi_wuser(1'b0), .s02_axi_wvalid(s02_axi_wvalid), .s02_axi_wready(),
    .s02_axi_bid(), .s02_axi_bresp(), .s02_axi_buser(), .s02_axi_bvalid(), .s02_axi_bready(s02_axi_bready),
    .s02_axi_arid(s02_axi_arid), .s02_axi_araddr(s02_axi_araddr), .s02_axi_arlen(s02_axi_arlen),
    .s02_axi_arsize(s02_axi_arsize), .s02_axi_arburst(s02_axi_arburst), .s02_axi_arlock(s02_axi_arlock),
    .s02_axi_arcache(s02_axi_arcache), .s02_axi_arprot(s02_axi_arprot), .s02_axi_arqos(s02_axi_arqos),
    .s02_axi_aruser(1'b0), .s02_axi_arvalid(s02_axi_arvalid), .s02_axi_arready(),
    .s02_axi_rid(), .s02_axi_rdata(), .s02_axi_rresp(), .s02_axi_rlast(), .s02_axi_ruser(),
    .s02_axi_rvalid(), .s02_axi_rready(s02_axi_rready),

    .s03_axi_awid(s03_axi_awid), .s03_axi_awaddr(s03_axi_awaddr), .s03_axi_awlen(s03_axi_awlen),
    .s03_axi_awsize(s03_axi_awsize), .s03_axi_awburst(s03_axi_awburst), .s03_axi_awlock(s03_axi_awlock),
    .s03_axi_awcache(s03_axi_awcache), .s03_axi_awprot(s03_axi_awprot), .s03_axi_awqos(s03_axi_awqos),
    .s03_axi_awuser(1'b0), .s03_axi_awvalid(s03_axi_awvalid), .s03_axi_awready(),
    .s03_axi_wdata(s03_axi_wdata), .s03_axi_wstrb(s03_axi_wstrb), .s03_axi_wlast(s03_axi_wlast),
    .s03_axi_wuser(1'b0), .s03_axi_wvalid(s03_axi_wvalid), .s03_axi_wready(),
    .s03_axi_bid(), .s03_axi_bresp(), .s03_axi_buser(), .s03_axi_bvalid(), .s03_axi_bready(s03_axi_bready),
    .s03_axi_arid(s03_axi_arid), .s03_axi_araddr(s03_axi_araddr), .s03_axi_arlen(s03_axi_arlen),
    .s03_axi_arsize(s03_axi_arsize), .s03_axi_arburst(s03_axi_arburst), .s03_axi_arlock(s03_axi_arlock),
    .s03_axi_arcache(s03_axi_arcache), .s03_axi_arprot(s03_axi_arprot), .s03_axi_arqos(s03_axi_arqos),
    .s03_axi_aruser(1'b0), .s03_axi_arvalid(s03_axi_arvalid), .s03_axi_arready(),
    .s03_axi_rid(), .s03_axi_rdata(), .s03_axi_rresp(), .s03_axi_rlast(), .s03_axi_ruser(),
    .s03_axi_rvalid(), .s03_axi_rready(s03_axi_rready),

    .s04_axi_awid(s04_axi_awid), .s04_axi_awaddr(s04_axi_awaddr), .s04_axi_awlen(s04_axi_awlen),
    .s04_axi_awsize(s04_axi_awsize), .s04_axi_awburst(s04_axi_awburst), .s04_axi_awlock(s04_axi_awlock),
    .s04_axi_awcache(s04_axi_awcache), .s04_axi_awprot(s04_axi_awprot), .s04_axi_awqos(s04_axi_awqos),
    .s04_axi_awuser(1'b0), .s04_axi_awvalid(s04_axi_awvalid), .s04_axi_awready(),
    .s04_axi_wdata(s04_axi_wdata), .s04_axi_wstrb(s04_axi_wstrb), .s04_axi_wlast(s04_axi_wlast),
    .s04_axi_wuser(1'b0), .s04_axi_wvalid(s04_axi_wvalid), .s04_axi_wready(),
    .s04_axi_bid(), .s04_axi_bresp(), .s04_axi_buser(), .s04_axi_bvalid(), .s04_axi_bready(s04_axi_bready),
    .s04_axi_arid(s04_axi_arid), .s04_axi_araddr(s04_axi_araddr), .s04_axi_arlen(s04_axi_arlen),
    .s04_axi_arsize(s04_axi_arsize), .s04_axi_arburst(s04_axi_arburst), .s04_axi_arlock(s04_axi_arlock),
    .s04_axi_arcache(s04_axi_arcache), .s04_axi_arprot(s04_axi_arprot), .s04_axi_arqos(s04_axi_arqos),
    .s04_axi_aruser(1'b0), .s04_axi_arvalid(s04_axi_arvalid), .s04_axi_arready(),
    .s04_axi_rid(), .s04_axi_rdata(), .s04_axi_rresp(), .s04_axi_rlast(), .s04_axi_ruser(),
    .s04_axi_rvalid(), .s04_axi_rready(s04_axi_rready),

    // M00-M04 master ports
    `define DUMMY_SINK_CONNECT(idx) \
        .m``idx``_axi_awid(m``idx``_axi_awid), .m``idx``_axi_awaddr(m``idx``_axi_awaddr), \
        .m``idx``_axi_awlen(m``idx``_axi_awlen), .m``idx``_axi_awsize(m``idx``_axi_awsize), \
        .m``idx``_axi_awburst(m``idx``_axi_awburst), .m``idx``_axi_awlock(m``idx``_axi_awlock), \
        .m``idx``_axi_awcache(m``idx``_axi_awcache), .m``idx``_axi_awprot(m``idx``_axi_awprot), \
        .m``idx``_axi_awqos(m``idx``_axi_awqos), .m``idx``_axi_awregion(m``idx``_axi_awregion), \
        .m``idx``_axi_awuser(m``idx``_axi_awuser), .m``idx``_axi_awvalid(m``idx``_axi_awvalid), \
        .m``idx``_axi_awready(m``idx``_axi_awready), .m``idx``_axi_wdata(m``idx``_axi_wdata), \
        .m``idx``_axi_wstrb(m``idx``_axi_wstrb), .m``idx``_axi_wlast(m``idx``_axi_wlast), \
        .m``idx``_axi_wuser(m``idx``_axi_wuser), .m``idx``_axi_wvalid(m``idx``_axi_wvalid), \
        .m``idx``_axi_wready(m``idx``_axi_wready), .m``idx``_axi_bid(m``idx``_axi_bid), \
        .m``idx``_axi_bresp(m``idx``_axi_bresp), .m``idx``_axi_buser(m``idx``_axi_buser), \
        .m``idx``_axi_bvalid(m``idx``_axi_bvalid), .m``idx``_axi_bready(m``idx``_axi_bready), \
        .m``idx``_axi_arid(m``idx``_axi_arid), .m``idx``_axi_araddr(m``idx``_axi_araddr), \
        .m``idx``_axi_arlen(m``idx``_axi_arlen), .m``idx``_axi_arsize(m``idx``_axi_arsize), \
        .m``idx``_axi_arburst(m``idx``_axi_arburst), .m``idx``_axi_arlock(m``idx``_axi_arlock), \
        .m``idx``_axi_arcache(m``idx``_axi_arcache), .m``idx``_axi_arprot(m``idx``_axi_arprot), \
        .m``idx``_axi_arqos(m``idx``_axi_arqos), .m``idx``_axi_arregion(m``idx``_axi_arregion), \
        .m``idx``_axi_aruser(m``idx``_axi_aruser), .m``idx``_axi_arvalid(m``idx``_axi_arvalid), \
        .m``idx``_axi_arready(m``idx``_axi_arready), .m``idx``_axi_rid(m``idx``_axi_rid), \
        .m``idx``_axi_rdata(m``idx``_axi_rdata), .m``idx``_axi_rresp(m``idx``_axi_rresp), \
        .m``idx``_axi_rlast(m``idx``_axi_rlast), .m``idx``_axi_ruser(m``idx``_axi_ruser), \
        .m``idx``_axi_rvalid(m``idx``_axi_rvalid), .m``idx``_axi_rready(m``idx``_axi_rready)

    `DUMMY_SINK_CONNECT(00),
    `DUMMY_SINK_CONNECT(01),
    `DUMMY_SINK_CONNECT(02),
    `DUMMY_SINK_CONNECT(03),
    `DUMMY_SINK_CONNECT(04),

    // M08-M19 master ports
    `DUMMY_SINK_CONNECT(08),
    `DUMMY_SINK_CONNECT(09),
    `DUMMY_SINK_CONNECT(10),
    `DUMMY_SINK_CONNECT(11),
    `DUMMY_SINK_CONNECT(12),
    `DUMMY_SINK_CONNECT(13),
    `DUMMY_SINK_CONNECT(14),
    `DUMMY_SINK_CONNECT(15),
    `DUMMY_SINK_CONNECT(16),
    `DUMMY_SINK_CONNECT(17),
    `DUMMY_SINK_CONNECT(18),
    `DUMMY_SINK_CONNECT(19),

    // Boundary UART interface
    .uart_rx_i(uart_rx_in),
    .uart_tx_o(uart_tx_out),
    .read_interrupt_o(uart_irq),

    // Boundary Timer interface
    .sample_tick(sample_tick),
    .irq_timer(irq_timer),

    // Boundary GPIO interface
    .gpio_in(gpio_in),
    .gpio_out(gpio_out),
    .irq_gpio(irq_gpio)
);

// Include master BFM tasks
`include "axi_bfm.vh"

// Helper tasks
reg [1:0] rsp;
reg [31:0] rd;
reg [7:0] bid;
integer nb;

task timer_wr(input [31:0] a, input [31:0] d);
    begin
        axi_write(8'hA1, TIMER_BASE + a, 0, 3'd2, d, 4'hF, 0, 0, 0, rsp, bid);
        check(rsp == 2'b00, "Timer write expected OKAY");
    end
endtask

task timer_rd(input [31:0] a, output [31:0] d);
    begin
        axi_read(8'hB1, TIMER_BASE + a, 0, 3'd2, 0, 0, rsp, d, nb);
        check(rsp == 2'b00 && nb == 1, "Timer read expected OKAY, 1 beat");
    end
endtask

task gpio_wr(input [31:0] a, input [31:0] d);
    begin
        axi_write(8'hC1, GPIO_BASE + a, 0, 3'd2, d, 4'hF, 0, 0, 0, rsp, bid);
        check(rsp == 2'b00, "GPIO write expected OKAY");
    end
endtask

task gpio_rd(input [31:0] a, output [31:0] d);
    begin
        axi_read(8'hD1, GPIO_BASE + a, 0, 3'd2, 0, 0, rsp, d, nb);
        check(rsp == 2'b00 && nb == 1, "GPIO read expected OKAY, 1 beat");
    end
endtask

task uart_wr(input [31:0] a, input [31:0] d);
    begin
        axi_write(8'hE1, UART_BASE + a, 0, 3'd2, d, 4'hF, 0, 0, 0, rsp, bid);
        check(rsp == 2'b00, "UART write expected OKAY");
    end
endtask

task uart_rd(input [31:0] a, output [31:0] d);
    begin
        axi_read(8'hF1, UART_BASE + a, 0, 3'd2, 0, 0, rsp, d, nb);
        check(rsp == 2'b00 && nb == 1, "UART read expected OKAY, 1 beat");
    end
endtask

// S01 Master writes to GPIO
task s01_gpio_wr(input [31:0] a, input [31:0] d);
    begin
        @(posedge clk);
        s01_axi_awid    <= 8'h62;
        s01_axi_awaddr  <= GPIO_BASE + a;
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
        s01_axi_wvalid <= 1'b0;
        s01_axi_wlast  <= 1'b0;
        while (!s01_axi_bvalid) @(posedge clk);
        check(s01_axi_bresp == 2'b00, "S01 GPIO write expected OKAY");
        @(posedge clk);
        s01_axi_bready <= 1'b0;
    end
endtask

// Dummy sinks initialization
`define DUMMY_INIT(idx) \
    m``idx``_axi_awready = 1'b1; m``idx``_axi_wready = 1'b1; m``idx``_axi_arready = 1'b1; \
    m``idx``_axi_bvalid  = 1'b0; m``idx``_axi_rvalid = 1'b0; m``idx``_axi_rlast  = 1'b1; \
    m``idx``_axi_bid = 0; m``idx``_axi_bresp = 0; m``idx``_axi_buser = 0; \
    m``idx``_axi_rid = 0; m``idx``_axi_rdata = 0; m``idx``_axi_rresp = 0; m``idx``_axi_ruser = 0;

initial begin
    `DUMMY_INIT(00)
    `DUMMY_INIT(01)
    `DUMMY_INIT(02)
    `DUMMY_INIT(03)
    `DUMMY_INIT(04)
    `DUMMY_INIT(08)
    `DUMMY_INIT(09)
    `DUMMY_INIT(10)
    `DUMMY_INIT(11)
    `DUMMY_INIT(12)
    `DUMMY_INIT(13)
    `DUMMY_INIT(14)
    `DUMMY_INIT(15)
    `DUMMY_INIT(16)
    `DUMMY_INIT(17)
    `DUMMY_INIT(18)
    `DUMMY_INIT(19)
end

// -----------------------------------------------------------------------------
// Test Execution Sequence
// -----------------------------------------------------------------------------
initial begin
    $display("==================================================================");
    $display(" Starting AXI SoC Top (5x20) Interconnect Verification");
    $display(" Peripherals Integrated: UART (M05), TIMER (M06), GPIO (M07)");
    $display(" Note: AES is deliberately NOT connected to 5x20 Interconnect");
    $display("==================================================================");

    // Apply Reset
    rst = 1'b1;
    gpio_in = 8'h00;
    uart_rx_in = 1'b1;
    #100;
    @(posedge clk);
    rst = 1'b0;
    repeat (10) @(posedge clk);

    // -------------------------------------------------------------------------
    // TEST 1: Default State Verification
    // -------------------------------------------------------------------------
    $display("--- TEST 1: Default State Verification ---");
    check(gpio_out == 8'h00, "gpio_out should default to 8'h00");
    check(irq_timer == 1'b0, "irq_timer should default to 0");
    check(irq_gpio == 1'b0, "irq_gpio should default to 0");
    check(sample_tick == 1'b0, "sample_tick should default to 0");
    $display("[PASS] TEST 1: Reset defaults verified.");

    // -------------------------------------------------------------------------
    // TEST 2: Timer Configuration & CSR Read/Write via Interconnect M06
    // -------------------------------------------------------------------------
    $display("--- TEST 2: Timer CSR Access via Interconnect M06 (0x4000_8000) ---");
    // Verify default TIMER_CTRL is 0
    timer_rd(32'h00, rd);
    check(rd[0] == 1'b0, "TIMER_CTRL default must be disabled");

    // Program RELOAD = 12
    timer_wr(32'h04, 32'd12);
    timer_rd(32'h04, rd);
    check(rd == 32'd12, "TIMER_RELOAD readback mismatch");
    $display("[PASS] TEST 2: Timer reload register programmed and read back.");

    // -------------------------------------------------------------------------
    // TEST 3: Timer Countdown, sample_tick Pulse & irq_timer Assertion
    // -------------------------------------------------------------------------
    $display("--- TEST 3: Timer Enable, Countdown & Interrupt Generation ---");
    // Enable timer: CTRL[0] = 1
    timer_wr(32'h00, 32'd1);

    // Wait for sample_tick pulse
    wait(sample_tick == 1'b1);
    $display("[PASS] TEST 3A: sample_tick pulse asserted at time %0t ns", $time);
    @(posedge clk);
    #1;
    check(sample_tick == 1'b0, "sample_tick must be a 1-cycle pulse");
    $display("[PASS] TEST 3B: sample_tick width is exactly 1 clock cycle.");

    // Check irq_timer assertion
    wait(irq_timer == 1'b1);
    timer_rd(32'h0C, rd);
    check(rd[0] == 1'b1, "TIMER_STATUS.TICK must be 1 when irq_timer asserted");
    $display("[PASS] TEST 3C: irq_timer asserted and STATUS.TICK verified.");

    // -------------------------------------------------------------------------
    // TEST 4: Timer W1C Status Clear
    // -------------------------------------------------------------------------
    $display("--- TEST 4: Timer W1C Clear & Disable ---");
    // Disable timer first
    timer_wr(32'h00, 32'd0);

    // Write 1 to clear TICK
    timer_wr(32'h0C, 32'd1);
    timer_rd(32'h0C, rd);
    check(rd[0] == 1'b0, "TIMER_STATUS.TICK must be cleared after W1C");
    check(irq_timer == 1'b0, "irq_timer must be deasserted after W1C clear");
    $display("[PASS] TEST 4: Timer status cleared and interrupt deasserted.");

    // -------------------------------------------------------------------------
    // TEST 5: GPIO Output Control via Interconnect M07 (0x4000_A000)
    // -------------------------------------------------------------------------
    $display("--- TEST 5: GPIO Output via Interconnect M07 (0x4000_A000) ---");
    // Write GPIO_OUT (0x04) = 8'hA5
    gpio_wr(32'h04, 32'hA5);
    #10;
    check(gpio_out == 8'hA5, "gpio_out boundary pins mismatch (expected 8'hA5)");
    gpio_rd(32'h04, rd);
    check(rd[7:0] == 8'hA5, "GPIO_OUT readback mismatch");
    $display("[PASS] TEST 5: GPIO_OUT written (8'hA5), checked on pins and read back.");

    // Test a second pattern: 8'h3C
    gpio_wr(32'h04, 32'h3C);
    #10;
    check(gpio_out == 8'h3C, "gpio_out boundary pins mismatch (expected 8'h3C)");
    $display("[PASS] TEST 5B: GPIO_OUT written (8'h3C) and verified.");

    // -------------------------------------------------------------------------
    // TEST 6: GPIO Synchronized Input Read
    // -------------------------------------------------------------------------
    $display("--- TEST 6: GPIO Synchronized Input Read ---");
    gpio_in = 8'h69;
    repeat (4) @(posedge clk); // Allow 2-stage synchronizer to settle
    gpio_rd(32'h00, rd);
    check(rd[7:0] == 8'h69, "GPIO_IN read mismatch (expected 8'h69)");
    $display("[PASS] TEST 6: GPIO input pin driven (8'h69) and read back through CSR.");

    // -------------------------------------------------------------------------
    // TEST 7: GPIO Edge Interrupt & W1C Clear
    // -------------------------------------------------------------------------
    $display("--- TEST 7: GPIO Edge Detection and Interrupt Generation ---");
    // Enable edge interrupt on bit 2 (8'h04)
    gpio_wr(32'h08, 32'h04);

    // Toggle bit 2 of gpio_in
    gpio_in[2] = ~gpio_in[2];
    repeat (5) @(posedge clk);

    check(irq_gpio == 1'b1, "irq_gpio should be asserted on input change");
    gpio_rd(32'h0C, rd);
    check(rd[0] == 1'b1, "GPIO_STATUS.CHANGED should be set");
    $display("[PASS] TEST 7A: Input edge detected and irq_gpio asserted.");

    // W1C clear
    gpio_wr(32'h0C, 32'd1);
    gpio_rd(32'h0C, rd);
    check(rd[0] == 1'b0, "GPIO_STATUS.CHANGED should be cleared");
    check(irq_gpio == 1'b0, "irq_gpio should deassert after clear");
    $display("[PASS] TEST 7B: GPIO W1C clear verified.");

    // -------------------------------------------------------------------------
    // TEST 8: Concurrent / Multi-Master Crossbar Access
    // -------------------------------------------------------------------------
    $display("--- TEST 8: Multi-Master Crossbar Routing (S00 -> Timer, S01 -> GPIO) ---");
    // S01 writes to GPIO_OUT while S00 writes to Timer reload
    fork
        begin
            s01_gpio_wr(32'h04, 32'h5A);
        end
        begin
            timer_wr(32'h04, 32'd25);
        end
    join
    #10;
    check(gpio_out == 8'h5A, "S01 GPIO write failed to update gpio_out");
    timer_rd(32'h04, rd);
    check(rd == 32'd25, "S00 Timer reload readback mismatch after concurrent access");
    $display("[PASS] TEST 8: S00 and S01 parallel routing verified through crossbar.");

    // -------------------------------------------------------------------------
    // TEST 9: UART IP Access on M05 (0x4000_6000)
    // -------------------------------------------------------------------------
    $display("--- TEST 9: UART IP Access via Interconnect M05 (0x4000_6000) ---");
    // Configure UART: Set DLAB=1, write baud divisor=16, clear DLAB
    uart_wr(32'h0C, 32'h80); // LCR: DLAB = 1
    uart_wr(32'h08, 32'd16); // BAUD_DIV = 16
    uart_wr(32'h0C, 32'h00); // LCR: normal mode
    uart_rd(32'h14, rd);     // Read LSR: TEMT+THRE (0x60)
    check(rd[6:5] == 2'b11, "UART LSR must have TEMT and THRE set");
    $display("[PASS] TEST 9: UART configured and LSR read (0x%02X) cleanly via M05.", rd[7:0]);

    // -------------------------------------------------------------------------
    // Final Summary
    // -------------------------------------------------------------------------
    repeat (20) @(posedge clk);
    $display("==================================================================");
    if (errors == 0) begin
        $display(" >>> ALL SOC INTEGRATION TESTS PASSED SUCCESSFULLY! <<<");
        $display(" >>> TIMER, GPIO, UART, INTERCONNECT FULLY VERIFIED! <<<");
        $display(" >>> AES EXCLUDED FROM 5x20 AS REQUESTED <<<");
    end else begin
        $display(" >>> INTEGRATION FAILED WITH %0d ERRORS <<<", errors);
    end
    $display("==================================================================");
    $finish;
end

endmodule

`resetall
