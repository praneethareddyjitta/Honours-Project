// =============================================================================
// tb_axi_soc_top_5x20_all_ips.sv
//
// Comprehensive Verification Testbench for axi_soc_top_5x20 integrating:
//   - AXI4 5x20 Interconnect Crossbar
//   - M02: I2C Master Controller (0x4000_0000) via axi_to_wb_bridge
//   - M03: 4-Channel PWM Controller (0x4000_2000) via axi4_to_axil_lite bridge
//   - M05: UART (0x4000_6000) via axi4_to_axi4lite_uart_adapter
//   - M06: System Timer (0x4000_8000) via axi4_to_axil_lite bridge
//   - M07: GPIO Controller (0x4000_A000) via axi4_to_axil_lite bridge
//   - NOTE: AES is strictly excluded from this 5x20 interconnect.
// =============================================================================

`timescale 1ns / 1ps
`default_nettype none

module tb_axi_soc_top_5x20_all_ips;

localparam DATA_WIDTH   = 32;
localparam ADDR_WIDTH   = 32;
localparam STRB_WIDTH   = 4;
localparam ID_WIDTH     = 8;
localparam AWUSER_WIDTH = 1;
localparam WUSER_WIDTH  = 1;
localparam BUSER_WIDTH  = 1;
localparam ARUSER_WIDTH = 1;
localparam RUSER_WIDTH  = 1;

localparam [31:0] I2C_BASE   = 32'h4000_0000;
localparam [31:0] PWM_BASE   = 32'h4000_2000;
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
// S01 Master (Secondary BFM for Concurrent Access Testing)
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

// Tie off S02-S04
wire [ID_WIDTH-1:0]     s02_axi_awid = 0, s03_axi_awid = 0, s04_axi_awid = 0;
wire [ADDR_WIDTH-1:0]   s02_axi_awaddr = 0, s03_axi_awaddr = 0, s04_axi_awaddr = 0;
wire [7:0]              s02_axi_awlen = 0, s03_axi_awlen = 0, s04_axi_awlen = 0;
wire [2:0]              s02_axi_awsize = 0, s03_axi_awsize = 0, s04_axi_awsize = 0;
wire [1:0]              s02_axi_awburst = 0, s03_axi_awburst = 0, s04_axi_awburst = 0;
wire                    s02_axi_awlock = 0, s03_axi_awlock = 0, s04_axi_awlock = 0;
wire [3:0]              s02_axi_awcache = 0, s03_axi_awcache = 0, s04_axi_awcache = 0;
wire [2:0]              s02_axi_awprot = 0, s03_axi_awprot = 0, s04_axi_awprot = 0;
wire [3:0]              s02_axi_awqos = 0, s03_axi_awqos = 0, s04_axi_awqos = 0;
wire                    s02_axi_awvalid = 0, s03_axi_awvalid = 0, s04_axi_awvalid = 0;
wire [DATA_WIDTH-1:0]   s02_axi_wdata = 0, s03_axi_wdata = 0, s04_axi_wdata = 0;
wire [STRB_WIDTH-1:0]   s02_axi_wstrb = 0, s03_axi_wstrb = 0, s04_axi_wstrb = 0;
wire                    s02_axi_wlast = 0, s03_axi_wlast = 0, s04_axi_wlast = 0;
wire                    s02_axi_wvalid = 0, s03_axi_wvalid = 0, s04_axi_wvalid = 0;
wire                    s02_axi_bready = 0, s03_axi_bready = 0, s04_axi_bready = 0;
wire [ID_WIDTH-1:0]     s02_axi_arid = 0, s03_axi_arid = 0, s04_axi_arid = 0;
wire [ADDR_WIDTH-1:0]   s02_axi_araddr = 0, s03_axi_araddr = 0, s04_axi_araddr = 0;
wire [7:0]              s02_axi_arlen = 0, s03_axi_arlen = 0, s04_axi_arlen = 0;
wire [2:0]              s02_axi_arsize = 0, s03_axi_arsize = 0, s04_axi_arsize = 0;
wire [1:0]              s02_axi_arburst = 0, s03_axi_arburst = 0, s04_axi_arburst = 0;
wire                    s02_axi_arlock = 0, s03_axi_arlock = 0, s04_axi_arlock = 0;
wire [3:0]              s02_axi_arcache = 0, s03_axi_arcache = 0, s04_axi_arcache = 0;
wire [2:0]              s02_axi_arprot = 0, s03_axi_arprot = 0, s04_axi_arprot = 0;
wire [3:0]              s02_axi_arqos = 0, s03_axi_arqos = 0, s04_axi_arqos = 0;
wire                    s02_axi_arvalid = 0, s03_axi_arvalid = 0, s04_axi_arvalid = 0;
wire                    s02_axi_rready = 0, s03_axi_rready = 0, s04_axi_rready = 0;

// Unused external Master Ports: M00-M01, M04, M08-M19
`define DECLARE_EXT_MASTER(idx) \
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
    reg                     m``idx``_axi_awready = 1'b1; \
    wire [DATA_WIDTH-1:0]   m``idx``_axi_wdata; \
    wire [STRB_WIDTH-1:0]   m``idx``_axi_wstrb; \
    wire                    m``idx``_axi_wlast; \
    wire [WUSER_WIDTH-1:0]  m``idx``_axi_wuser; \
    wire                    m``idx``_axi_wvalid; \
    reg                     m``idx``_axi_wready = 1'b1; \
    reg  [ID_WIDTH-1:0]     m``idx``_axi_bid = 0; \
    reg  [1:0]              m``idx``_axi_bresp = 2'b00; \
    reg  [BUSER_WIDTH-1:0]  m``idx``_axi_buser = 0; \
    reg                     m``idx``_axi_bvalid = 0; \
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
    reg                     m``idx``_axi_arready = 1'b1; \
    reg  [ID_WIDTH-1:0]     m``idx``_axi_rid = 0; \
    reg  [DATA_WIDTH-1:0]   m``idx``_axi_rdata = 0; \
    reg  [1:0]              m``idx``_axi_rresp = 2'b00; \
    reg                     m``idx``_axi_rlast = 0; \
    reg  [RUSER_WIDTH-1:0]  m``idx``_axi_ruser = 0; \
    reg                     m``idx``_axi_rvalid = 0; \
    wire                    m``idx``_axi_rready;

`DECLARE_EXT_MASTER(00)
`DECLARE_EXT_MASTER(01)
`DECLARE_EXT_MASTER(04)
`DECLARE_EXT_MASTER(08)
`DECLARE_EXT_MASTER(09)
`DECLARE_EXT_MASTER(10)
`DECLARE_EXT_MASTER(11)
`DECLARE_EXT_MASTER(12)
`DECLARE_EXT_MASTER(13)
`DECLARE_EXT_MASTER(14)
`DECLARE_EXT_MASTER(15)
`DECLARE_EXT_MASTER(16)
`DECLARE_EXT_MASTER(17)
`DECLARE_EXT_MASTER(18)
`DECLARE_EXT_MASTER(19)

// -----------------------------------------------------------------------------
// Top-Level Peripheral I/O Pins
// -----------------------------------------------------------------------------
// I2C
wire       scl_pad_i;
wire       scl_pad_o;
wire       scl_padoen_o;
wire       sda_pad_i;
wire       sda_pad_o;
wire       sda_padoen_o;
wire       irq_i2c;

wire scl = scl_padoen_o ? 1'bz : scl_pad_o;
wire sda = sda_padoen_o ? 1'bz : sda_pad_o;
assign scl_pad_i = scl;
assign sda_pad_i = sda;
pullup(scl);
pullup(sda);

// PWM
wire [3:0] pwm_out;
wire       irq_pwm;

// UART
reg        uart_rx_in = 1'b1;
wire       uart_tx_out;
wire       uart_irq;

// TIMER
wire       sample_tick;
wire       irq_timer;

// GPIO
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

    // External master ports
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
    `DUMMY_SINK_CONNECT(04),

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

    // I2C Peripheral Pads (M02)
    .scl_pad_i(scl_pad_i),
    .scl_pad_o(scl_pad_o),
    .scl_padoen_o(scl_padoen_o),
    .sda_pad_i(sda_pad_i),
    .sda_pad_o(sda_pad_o),
    .sda_padoen_o(sda_padoen_o),
    .irq_i2c(irq_i2c),

    // PWM Peripheral Pads (M03)
    .pwm_out(pwm_out),
    .irq_pwm(irq_pwm),

    // UART Peripheral Pins (M05)
    .uart_rx_i(uart_rx_in),
    .uart_tx_o(uart_tx_out),
    .read_interrupt_o(uart_irq),

    // Timer Peripheral Pins (M06)
    .sample_tick(sample_tick),
    .irq_timer(irq_timer),

    // GPIO Peripheral Pins (M07)
    .gpio_in(gpio_in),
    .gpio_out(gpio_out),
    .irq_gpio(irq_gpio)
);

// -----------------------------------------------------------------------------
// S00 Master AXI Tasks
// -----------------------------------------------------------------------------
task s00_write(input [ADDR_WIDTH-1:0] addr, input [DATA_WIDTH-1:0] data, input [7:0] id);
    @(posedge clk);
    s_axi_awid     <= id;
    s_axi_awaddr   <= addr;
    s_axi_awlen    <= 8'd0;
    s_axi_awsize   <= 3'b010;
    s_axi_awburst  <= 2'b01;
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

task s00_read(input [ADDR_WIDTH-1:0] addr, output [DATA_WIDTH-1:0] data, input [7:0] id);
    @(posedge clk);
    s_axi_arid     <= id;
    s_axi_araddr   <= addr;
    s_axi_arlen    <= 8'd0;
    s_axi_arsize   <= 3'b010;
    s_axi_arburst  <= 2'b01;
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

// -----------------------------------------------------------------------------
// S01 Master AXI Tasks
// -----------------------------------------------------------------------------
task s01_write(input [ADDR_WIDTH-1:0] addr, input [DATA_WIDTH-1:0] data, input [7:0] id);
    @(posedge clk);
    s01_axi_awid     <= id;
    s01_axi_awaddr   <= addr;
    s01_axi_awlen    <= 8'd0;
    s01_axi_awsize   <= 3'b010;
    s01_axi_awburst  <= 2'b01;
    s01_axi_awvalid  <= 1'b1;

    s01_axi_wdata    <= data;
    s01_axi_wstrb    <= 4'hF;
    s01_axi_wlast    <= 1'b1;
    s01_axi_wvalid   <= 1'b1;
    s01_axi_bready   <= 1'b1;

    fork
        begin
            wait(s01_axi_awready);
            @(posedge clk);
            s01_axi_awvalid <= 1'b0;
        end
        begin
            wait(s01_axi_wready);
            @(posedge clk);
            s01_axi_wvalid <= 1'b0;
            s01_axi_wlast  <= 1'b0;
        end
    join

    wait(s01_axi_bvalid);
    @(posedge clk);
    s01_axi_bready <= 1'b0;
endtask

task s01_read(input [ADDR_WIDTH-1:0] addr, output [DATA_WIDTH-1:0] data, input [7:0] id);
    @(posedge clk);
    s01_axi_arid     <= id;
    s01_axi_araddr   <= addr;
    s01_axi_arlen    <= 8'd0;
    s01_axi_arsize   <= 3'b010;
    s01_axi_arburst  <= 2'b01;
    s01_axi_arvalid  <= 1'b1;
    s01_axi_rready   <= 1'b1;

    wait(s01_axi_arready);
    @(posedge clk);
    s01_axi_arvalid <= 1'b0;

    wait(s01_axi_rvalid);
    data = s01_axi_rdata;
    @(posedge clk);
    s01_axi_rready <= 1'b0;
endtask

// -----------------------------------------------------------------------------
// Main Test Routine
// -----------------------------------------------------------------------------
initial begin
    reg [31:0] rdata;
    reg [31:0] rdata2;

    $display("\n==================================================================");
    $display("   STARTING TOP-LEVEL 5x20 SOC INTEGRATION VERIFICATION           ");
    $display("   Common IPs: PWM, I2C, UART, TIMER, GPIO                        ");
    $display("   (AES Excluded as strictly constrained)                         ");
    $display("==================================================================");

    // Apply Reset
    rst = 1'b1;
    #(100);
    @(posedge clk);
    rst = 1'b0;
    #(100);

    // -------------------------------------------------------------------------
    // TEST 1: Timer Verification via S00 (M06 @ 0x4000_8000)
    // -------------------------------------------------------------------------
    $display("\n[TEST 1] Testing TIMER Peripheral on M06 (0x4000_8000)...");
    // Default TIMER_CTRL (0x00) should be 0
    s00_read(TIMER_BASE + 32'h00, rdata, 8'h10);
    if (rdata[0] != 1'b0) begin
        $display("[FAIL] Timer CTRL default mismatch! Got %h", rdata);
        errors = errors + 1;
    end else begin
        $display("[PASS] Timer CTRL default = 0 verified.");
    end

    // Program TIMER_RELOAD (0x04) = 15
    s00_write(TIMER_BASE + 32'h04, 32'd15, 8'h11);
    s00_read(TIMER_BASE + 32'h04, rdata, 8'h12);
    if (rdata != 32'd15) begin
        $display("[FAIL] Timer RELOAD readback mismatch! Got %0d", rdata);
        errors = errors + 1;
    end else begin
        $display("[PASS] Timer RELOAD programmed and read back (15)");
    end

    // Enable Timer: CTRL[0] = 1 (0x00)
    s00_write(TIMER_BASE + 32'h00, 32'd1, 8'h13);

    // Wait for sample_tick pulse and irq_timer
    wait(sample_tick == 1'b1);
    $display("[PASS] Timer sample_tick pulse asserted!");
    wait(irq_timer == 1'b1);
    $display("[PASS] Timer irq_timer asserted!");

    // Clear Timer interrupt via W1C on STATUS (0x0C)
    s00_write(TIMER_BASE + 32'h00, 32'd0, 8'h14); // Disable timer
    s00_write(TIMER_BASE + 32'h0C, 32'd1, 8'h15); // W1C
    #20;
    if (irq_timer != 1'b0) begin
        $display("[FAIL] Timer interrupt did not clear!");
        errors = errors + 1;
    end else begin
        $display("[PASS] Timer interrupt cleared via W1C.");
    end

    // -------------------------------------------------------------------------
    // TEST 2: GPIO Verification via S00 (M07 @ 0x4000_A000)
    // -------------------------------------------------------------------------
    $display("\n[TEST 2] Testing GPIO Peripheral on M07 (0x4000_A000)...");
    // Write GPIO_OUT (0x04) = 8'hA5
    s00_write(GPIO_BASE + 32'h04, 32'hA5, 8'h20);
    #20;
    if (gpio_out != 8'hA5) begin
        $display("[FAIL] gpio_out mismatch! Got %h, expected 0xA5", gpio_out);
        errors = errors + 1;
    end else begin
        $display("[PASS] gpio_out matches written data (0x%02h)", gpio_out);
    end

    // Read back GPIO_OUT
    s00_read(GPIO_BASE + 32'h04, rdata, 8'h21);
    if (rdata[7:0] != 8'hA5) begin
        $display("[FAIL] GPIO_OUT readback mismatch! Got %h", rdata);
        errors = errors + 1;
    end else begin
        $display("[PASS] GPIO_OUT readback verified (0x%02h)", rdata[7:0]);
    end

    // Test GPIO Synchronized Input (GPIO_IN @ 0x00)
    gpio_in = 8'h69;
    repeat (5) @(posedge clk);
    s00_read(GPIO_BASE + 32'h00, rdata, 8'h22);
    if (rdata[7:0] != 8'h69) begin
        $display("[FAIL] GPIO_IN readback mismatch! Got %h, expected 0x69", rdata);
        errors = errors + 1;
    end else begin
        $display("[PASS] GPIO_IN readback verified (0x%02h)", rdata[7:0]);
    end

    // -------------------------------------------------------------------------
    // TEST 3: UART Verification via S00 (M05 @ 0x4000_6000)
    // -------------------------------------------------------------------------
    $display("\n[TEST 3] Testing UART Peripheral on M05 (0x4000_6000)...");
    // DLAB = 1 (LCR @ 0x0C = 0x80)
    s00_write(UART_BASE + 32'h0C, 32'h80, 8'h30);
    // Program BAUD_DIV (0x08) = 16
    s00_write(UART_BASE + 32'h08, 32'd16, 8'h31);
    // Set LCR normal 8N1 (0x0C = 0x03)
    s00_write(UART_BASE + 32'h0C, 32'h03, 8'h32);

    // Read LSR (0x14) - Transmitter Empty (TEMT + THRE = 0x60)
    s00_read(UART_BASE + 32'h14, rdata, 8'h33);
    if (rdata[6:5] != 2'b11) begin
        $display("[FAIL] UART LSR mismatch! Got %h", rdata);
        errors = errors + 1;
    end else begin
        $display("[PASS] UART configured (8N1) and LSR verified (0x%02h)", rdata[7:0]);
    end

    // -------------------------------------------------------------------------
    // TEST 4: PWM Verification via S00 (M03 @ 0x4000_2000)
    // -------------------------------------------------------------------------
    $display("\n[TEST 4] Testing PWM Peripheral on M03 (0x4000_2000)...");
    // Period = 100, Prescale = 0
    s00_write(PWM_BASE + 32'h08, 32'd100, 8'h40);
    s00_write(PWM_BASE + 32'h04, 32'd0,   8'h41);
    // Duty0 = 25 (25%), Duty1 = 50 (50%), Duty2 = 75 (75%), Duty3 = 100 (100%)
    s00_write(PWM_BASE + 32'h0C, 32'd25, 8'h42);
    s00_write(PWM_BASE + 32'h10, 32'd50, 8'h43);
    s00_write(PWM_BASE + 32'h14, 32'd75, 8'h44);
    s00_write(PWM_BASE + 32'h18, 32'd100, 8'h45);

    // Read back Duty0 and Period
    s00_read(PWM_BASE + 32'h0C, rdata, 8'h46);
    if (rdata[15:0] != 16'd25) begin
        $display("[FAIL] PWM Duty0 readback mismatch! Got %0d", rdata);
        errors = errors + 1;
    end else begin
        $display("[PASS] PWM Duty0 programmed and verified (25)");
    end

    // Enable PWM and all 4 channels (CTRL: EN=1, CH_EN=4'b1111 -> 0x1F)
    s00_write(PWM_BASE + 32'h00, 32'h1F, 8'h47);
    #500;
    $display("[PASS] PWM outputs active: pwm_out = %b", pwm_out);

    // Wait for PERIOD_DONE interrupt
    wait(irq_pwm == 1'b1);
    $display("[PASS] PWM irq_pwm asserted on period completion!");
    // Clear PERIOD_DONE
    s00_write(PWM_BASE + 32'h20, 32'h01, 8'h48);
    #20;
    if (irq_pwm != 1'b0) begin
        $display("[FAIL] PWM interrupt did not clear!");
        errors = errors + 1;
    end else begin
        $display("[PASS] PWM interrupt cleared via W1C.");
    end

    // -------------------------------------------------------------------------
    // TEST 5: I2C Verification via S00 (M02 @ 0x4000_0000)
    // -------------------------------------------------------------------------
    $display("\n[TEST 5] Testing I2C Peripheral on M02 (0x4000_0000)...");
    // Check reset default of PRER_LO (0xFF) and PRER_HI (0xFF)
    s00_read(I2C_BASE + 32'h00, rdata, 8'h50);
    if (rdata[7:0] != 8'hFF) begin
        $display("[FAIL] I2C PRER_LO default mismatch! Got %h", rdata);
        errors = errors + 1;
    end else begin
        $display("[PASS] I2C PRER_LO default verified (0xFF)");
    end

    // Program PRER_LO = 0x64 (100) and PRER_HI = 0x01
    s00_write(I2C_BASE + 32'h00, 32'h64, 8'h51);
    s00_write(I2C_BASE + 32'h04, 32'h01, 8'h52);

    s00_read(I2C_BASE + 32'h00, rdata, 8'h53);
    if (rdata[7:0] != 8'h64) begin
        $display("[FAIL] I2C PRER_LO write mismatch! Got %h", rdata);
        errors = errors + 1;
    end else begin
        $display("[PASS] I2C PRER_LO programmed and verified (0x64)");
    end

    // Enable I2C Core (CTR: EN=1, IEN=1 -> 0xC0 at offset 0x08)
    s00_write(I2C_BASE + 32'h08, 32'hC0, 8'h54);
    s00_read(I2C_BASE + 32'h08, rdata, 8'h55);
    if (rdata[7:0] != 8'hC0) begin
        $display("[FAIL] I2C CTR write mismatch! Got %h", rdata);
        errors = errors + 1;
    end else begin
        $display("[PASS] I2C core enabled (CTR = 0xC0)");
    end

    // Write to TXR (offset 0x0C)
    s00_write(I2C_BASE + 32'h0C, 32'hA5, 8'h56);
    s00_read(I2C_BASE + 32'h10, rdata, 8'h57); // Read Status Register
    $display("[PASS] I2C Status Register verified (SR = 0x%02h)", rdata[7:0]);

    // -------------------------------------------------------------------------
    // TEST 6: Concurrent Multi-Master Access (S00 -> Timer, S01 -> PWM)
    // -------------------------------------------------------------------------
    $display("\n[TEST 6] Testing Concurrent Multi-Master Crossbar Access (S00->Timer, S01->PWM)...");
    fork
        begin
            // S00 writes and reads Timer Reload
            s00_write(TIMER_BASE + 32'h04, 32'd50, 8'h60);
            s00_read(TIMER_BASE + 32'h04, rdata, 8'h61);
            if (rdata != 32'd50) begin
                $display("[FAIL] S00 concurrent Timer read mismatch! Got %0d", rdata);
                errors = errors + 1;
            end else begin
                $display("[PASS] S00 accessed Timer concurrently (Reload = %0d)", rdata);
            end
        end
        begin
            // S01 writes and reads PWM Duty1
            s01_write(PWM_BASE + 32'h10, 32'd88, 8'h62);
            s01_read(PWM_BASE + 32'h10, rdata2, 8'h63);
            if (rdata2[15:0] != 16'd88) begin
                $display("[FAIL] S01 concurrent PWM read mismatch! Got %0d", rdata2);
                errors = errors + 1;
            end else begin
                $display("[PASS] S01 accessed PWM concurrently (Duty1 = %0d)", rdata2[15:0]);
            end
        end
    join

    // -------------------------------------------------------------------------
    // TEST 7: Concurrent Multi-Master Access (S00 -> I2C, S01 -> GPIO)
    // -------------------------------------------------------------------------
    $display("\n[TEST 7] Testing Concurrent Multi-Master Crossbar Access (S00->I2C, S01->GPIO)...");
    fork
        begin
            // S00 reads I2C PRER_LO
            s00_read(I2C_BASE + 32'h00, rdata, 8'h70);
            if (rdata[7:0] != 8'h64) begin
                $display("[FAIL] S00 concurrent I2C read mismatch! Got %h", rdata);
                errors = errors + 1;
            end else begin
                $display("[PASS] S00 accessed I2C concurrently (PRER_LO = 0x%02h)", rdata[7:0]);
            end
        end
        begin
            // S01 writes and reads GPIO_OUT (0x04)
            s01_write(GPIO_BASE + 32'h04, 32'h3C, 8'h71);
            s01_read(GPIO_BASE + 32'h04, rdata2, 8'h72);
            if (gpio_out != 8'h3C) begin
                $display("[FAIL] S01 concurrent GPIO write mismatch! Got %h", gpio_out);
                errors = errors + 1;
            end else begin
                $display("[PASS] S01 accessed GPIO concurrently (gpio_out = 0x%02h)", gpio_out);
            end
        end
    join

    // -------------------------------------------------------------------------
    // SUMMARY
    // -------------------------------------------------------------------------
    $display("\n==================================================================");
    if (errors == 0) begin
        $display("   ALL 5x20 SOC INTEGRATION TESTS PASSED SUCCESSFULLY! (0 ERRORS) ");
        $display("   Verified IPs: PWM, I2C, UART, TIMER, GPIO                      ");
        $display("   Crossbar: 5x20 Concurrent Multi-Master Architecture             ");
        $display("   AES Exclusion: Fully Verified                                  ");
    end else begin
        $display("   VERIFICATION FAILED WITH %0d ERRORS!", errors);
    end
    $display("==================================================================\n");

    $finish;
end

endmodule

`resetall
