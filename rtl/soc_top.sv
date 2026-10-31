/* =============================================================================
 * Module      : soc_top.sv
 * Description : RISC-V VeeR EL2 System-on-Chip Top-Level Integration
 *
 * Integrates the common baseline platform:
 *   1. Western Digital / CHIPS Alliance RISC-V VeeR EL2 Core Complex (RV32IMC)
 *   2. 3x AXI4 64-bit to 32-bit Width Down-Converters (LSU, IFU, SB)
 *   3. AXI4 5-Master x 20-Slave Crossbar Interconnect (axi_soc_top_5x20)
 *   4. Instruction Memory (IMEM, 64 KB at 0x1000_0000)
 *   5. Data Memory (DMEM, 64 KB at 0x1002_0000)
 *   6. Integrated AXI UART Controller (0x4000_6000)
 *   7. Integrated System Timer (0x4000_8000)
 *   8. Integrated GPIO Controller (0x4000_A000)
 *   9. M02 (I2C) and M03 (PWM) reserved ports for application peripheral integration
 * ============================================================================= */

`resetall
`timescale 1ns / 1ps
`default_nettype none

module soc_top
import el2_pkg::*;
#(
    `include "el2_param.vh"
    ,
    parameter DATA_WIDTH   = 32,
    parameter ADDR_WIDTH   = 32,
    parameter STRB_WIDTH   = (DATA_WIDTH / 8),
    parameter ID_WIDTH     = 8,
    parameter AWUSER_WIDTH = 1,
    parameter WUSER_WIDTH  = 1,
    parameter BUSER_WIDTH  = 1,
    parameter ARUSER_WIDTH = 1,
    parameter RUSER_WIDTH  = 1,

    // Base Addresses matching doc/SoC_IP_Registers_Summary.xlsx
    parameter IMEM_BASE_ADDR   = 32'h1000_0000,
    parameter DMEM_BASE_ADDR   = 32'h1002_0000,
    parameter I2C_BASE_ADDR    = 32'h4000_0000,
    parameter PWM_BASE_ADDR    = 32'h4000_2000,
    parameter UART_BASE_ADDR   = 32'h4000_6000,
    parameter TIMER_BASE_ADDR  = 32'h4000_8000,
    parameter GPIO_BASE_ADDR   = 32'h4000_A000
)(
    // System Clock & Reset
    input  wire                 clk,
    input  wire                 rst_n,

    // Core Control & Vectors
    input  wire [31:1]          rst_vec,
    input  wire                 nmi_int,
    input  wire [31:1]          nmi_vec,
    input  wire [31:1]          jtag_id,

    // UART Serial Interface
    input  wire                 uart_rx,
    output wire                 uart_tx,
    output wire                 uart_irq,

    // System Timer
    output wire                 sample_tick,
    output wire                 irq_timer,

    // GPIO Interface
    input  wire [7:0]           gpio_in,
    output wire [7:0]           gpio_out,
    output wire                 irq_gpio,

    // I2C Serial Bus Interface
    inout  wire                 scl,
    inout  wire                 sda,
    output wire                 irq_i2c,

    // PWM Actuator Output
    output wire                 pwm_out
);

    wire rst = ~rst_n;
    wire irq_pwm;

    // -------------------------------------------------------------------------
    // Interrupt Routing to VeeR EL2 Programmable Interrupt Controller (PIC)
    // -------------------------------------------------------------------------
    wire [pt.PIC_TOTAL_INT-1:0] core_extintsrc_req;
    assign core_extintsrc_req[0] = uart_irq;
    assign core_extintsrc_req[1] = irq_timer;
    assign core_extintsrc_req[2] = irq_gpio;
    assign core_extintsrc_req[3] = irq_i2c;
    assign core_extintsrc_req[4] = irq_pwm;
    generate
        if (pt.PIC_TOTAL_INT > 5) begin : gen_pic_tieoffs
            assign core_extintsrc_req[pt.PIC_TOTAL_INT-1:5] = '0;
        end
    endgenerate

    // -------------------------------------------------------------------------
    // 64-bit Core AXI4 Interfaces
    // -------------------------------------------------------------------------
    // LSU 64-bit
    wire                    lsu_axi_awvalid, lsu_axi_awready;
    wire [pt.LSU_BUS_TAG-1:0] lsu_axi_awid;
    wire [31:0]             lsu_axi_awaddr;
    wire [3:0]              lsu_axi_awregion;
    wire [7:0]              lsu_axi_awlen;
    wire [2:0]              lsu_axi_awsize;
    wire [1:0]              lsu_axi_awburst;
    wire                    lsu_axi_awlock;
    wire [3:0]              lsu_axi_awcache;
    wire [2:0]              lsu_axi_awprot;
    wire [3:0]              lsu_axi_awqos;
    wire                    lsu_axi_wvalid, lsu_axi_wready;
    wire [63:0]             lsu_axi_wdata;
    wire [7:0]              lsu_axi_wstrb;
    wire                    lsu_axi_wlast;
    wire                    lsu_axi_bvalid, lsu_axi_bready;
    wire [1:0]              lsu_axi_bresp;
    wire [pt.LSU_BUS_TAG-1:0] lsu_axi_bid;
    wire                    lsu_axi_arvalid, lsu_axi_arready;
    wire [pt.LSU_BUS_TAG-1:0] lsu_axi_arid;
    wire [31:0]             lsu_axi_araddr;
    wire [3:0]              lsu_axi_arregion;
    wire [7:0]              lsu_axi_arlen;
    wire [2:0]              lsu_axi_arsize;
    wire [1:0]              lsu_axi_arburst;
    wire                    lsu_axi_arlock;
    wire [3:0]              lsu_axi_arcache;
    wire [2:0]              lsu_axi_arprot;
    wire [3:0]              lsu_axi_arqos;
    wire                    lsu_axi_rvalid, lsu_axi_rready;
    wire [pt.LSU_BUS_TAG-1:0] lsu_axi_rid;
    wire [63:0]             lsu_axi_rdata;
    wire [1:0]              lsu_axi_rresp;
    wire                    lsu_axi_rlast;

    // IFU 64-bit
    wire                    ifu_axi_awvalid, ifu_axi_awready;
    wire [pt.IFU_BUS_TAG-1:0] ifu_axi_awid;
    wire [31:0]             ifu_axi_awaddr;
    wire [3:0]              ifu_axi_awregion;
    wire [7:0]              ifu_axi_awlen;
    wire [2:0]              ifu_axi_awsize;
    wire [1:0]              ifu_axi_awburst;
    wire                    ifu_axi_awlock;
    wire [3:0]              ifu_axi_awcache;
    wire [2:0]              ifu_axi_awprot;
    wire [3:0]              ifu_axi_awqos;
    wire                    ifu_axi_wvalid, ifu_axi_wready;
    wire [63:0]             ifu_axi_wdata;
    wire [7:0]              ifu_axi_wstrb;
    wire                    ifu_axi_wlast;
    wire                    ifu_axi_bvalid, ifu_axi_bready;
    wire [1:0]              ifu_axi_bresp;
    wire [pt.IFU_BUS_TAG-1:0] ifu_axi_bid;
    wire                    ifu_axi_arvalid, ifu_axi_arready;
    wire [pt.IFU_BUS_TAG-1:0] ifu_axi_arid;
    wire [31:0]             ifu_axi_araddr;
    wire [3:0]              ifu_axi_arregion;
    wire [7:0]              ifu_axi_arlen;
    wire [2:0]              ifu_axi_arsize;
    wire [1:0]              ifu_axi_arburst;
    wire                    ifu_axi_arlock;
    wire [3:0]              ifu_axi_arcache;
    wire [2:0]              ifu_axi_arprot;
    wire [3:0]              ifu_axi_arqos;
    wire                    ifu_axi_rvalid, ifu_axi_rready;
    wire [pt.IFU_BUS_TAG-1:0] ifu_axi_rid;
    wire [63:0]             ifu_axi_rdata;
    wire [1:0]              ifu_axi_rresp;
    wire                    ifu_axi_rlast;

    // SB 64-bit
    wire                    sb_axi_awvalid, sb_axi_awready;
    wire [pt.SB_BUS_TAG-1:0]  sb_axi_awid;
    wire [31:0]             sb_axi_awaddr;
    wire [3:0]              sb_axi_awregion;
    wire [7:0]              sb_axi_awlen;
    wire [2:0]              sb_axi_awsize;
    wire [1:0]              sb_axi_awburst;
    wire                    sb_axi_awlock;
    wire [3:0]              sb_axi_awcache;
    wire [2:0]              sb_axi_awprot;
    wire [3:0]              sb_axi_awqos;
    wire                    sb_axi_wvalid, sb_axi_wready;
    wire [63:0]             sb_axi_wdata;
    wire [7:0]              sb_axi_wstrb;
    wire                    sb_axi_wlast;
    wire                    sb_axi_bvalid, sb_axi_bready;
    wire [1:0]              sb_axi_bresp;
    wire [pt.SB_BUS_TAG-1:0]  sb_axi_bid;
    wire                    sb_axi_arvalid, sb_axi_arready;
    wire [pt.SB_BUS_TAG-1:0]  sb_axi_arid;
    wire [31:0]             sb_axi_araddr;
    wire [3:0]              sb_axi_arregion;
    wire [7:0]              sb_axi_arlen;
    wire [2:0]              sb_axi_arsize;
    wire [1:0]              sb_axi_arburst;
    wire                    sb_axi_arlock;
    wire [3:0]              sb_axi_arcache;
    wire [2:0]              sb_axi_arprot;
    wire [3:0]              sb_axi_arqos;
    wire                    sb_axi_rvalid, sb_axi_rready;
    wire [pt.SB_BUS_TAG-1:0]  sb_axi_rid;
    wire [63:0]             sb_axi_rdata;
    wire [1:0]              sb_axi_rresp;
    wire                    sb_axi_rlast;

    // Trace wires (observability)
    wire [31:0] trace_rv_i_insn_ip, trace_rv_i_address_ip;
    wire        trace_rv_i_valid_ip, trace_rv_i_exception_ip;
    wire [4:0]  trace_rv_i_ecause_ip;
    wire [2:0]  trace_rv_i_interrupt_ip;
    wire [31:0] trace_rv_i_tval_ip;
    wire        o_cpu_halt_ack, o_cpu_halt_status, o_debug_mode_status;

    // =========================================================================
    // 1. RISC-V VeeR EL2 Core Instance
    // =========================================================================
    veer_wrapper u_veer_core (
        .clk                    (clk),
        .rst_l                  (rst_n),
        .dbg_rst_l              (rst_n),
        .rst_vec                (rst_vec),
        .nmi_int                (nmi_int),
        .nmi_vec                (nmi_vec),
        .jtag_id                (jtag_id),

        .timer_int              (1'b0),
        .extintsrc_req          (core_extintsrc_req),

        .lsu_bus_clk_en         (1'b1),
        .ifu_bus_clk_en         (1'b1),
        .dbg_bus_clk_en         (1'b1),
        .dma_bus_clk_en         (1'b1),

        .trace_rv_i_insn_ip     (trace_rv_i_insn_ip),
        .trace_rv_i_address_ip  (trace_rv_i_address_ip),
        .trace_rv_i_valid_ip    (trace_rv_i_valid_ip),
        .trace_rv_i_exception_ip(trace_rv_i_exception_ip),
        .trace_rv_i_ecause_ip   (trace_rv_i_ecause_ip),
        .trace_rv_i_interrupt_ip(trace_rv_i_interrupt_ip),
        .trace_rv_i_tval_ip     (trace_rv_i_tval_ip),

        .mpc_debug_halt_req     (1'b0),
        .mpc_debug_run_req      (1'b0),
        .mpc_reset_run_req      (1'b1),
        .mpc_debug_halt_ack     (),
        .mpc_debug_run_ack      (),
        .debug_brkpt_status     (),
        .i_cpu_halt_req         (1'b0),
        .o_cpu_halt_ack         (o_cpu_halt_ack),
        .o_cpu_halt_status      (o_cpu_halt_status),
        .o_debug_mode_status    (o_debug_mode_status),
        .i_cpu_run_req          (1'b0),
        .o_cpu_run_ack          (),
        .scan_mode              (1'b0),
        .mbist_mode             (1'b0),
        .dmi_core_enable        (1'b0),
        .dmi_uncore_enable      (1'b0),
        .dmi_uncore_en          (),
        .dmi_uncore_wr_en       (),
        .dmi_uncore_addr        (),
        .dmi_uncore_wdata       (),
        .dmi_uncore_rdata       (32'd0),
        .dmi_active             (),

        // LSU AXI
        .lsu_axi_awvalid        (lsu_axi_awvalid),
        .lsu_axi_awready        (lsu_axi_awready),
        .lsu_axi_awid           (lsu_axi_awid),
        .lsu_axi_awaddr         (lsu_axi_awaddr),
        .lsu_axi_awregion       (lsu_axi_awregion),
        .lsu_axi_awlen          (lsu_axi_awlen),
        .lsu_axi_awsize         (lsu_axi_awsize),
        .lsu_axi_awburst        (lsu_axi_awburst),
        .lsu_axi_awlock         (lsu_axi_awlock),
        .lsu_axi_awcache        (lsu_axi_awcache),
        .lsu_axi_awprot         (lsu_axi_awprot),
        .lsu_axi_awqos          (lsu_axi_awqos),
        .lsu_axi_wvalid         (lsu_axi_wvalid),
        .lsu_axi_wready         (lsu_axi_wready),
        .lsu_axi_wdata          (lsu_axi_wdata),
        .lsu_axi_wstrb          (lsu_axi_wstrb),
        .lsu_axi_wlast          (lsu_axi_wlast),
        .lsu_axi_bvalid         (lsu_axi_bvalid),
        .lsu_axi_bready         (lsu_axi_bready),
        .lsu_axi_bresp          (lsu_axi_bresp),
        .lsu_axi_bid            (lsu_axi_bid),
        .lsu_axi_arvalid        (lsu_axi_arvalid),
        .lsu_axi_arready        (lsu_axi_arready),
        .lsu_axi_arid           (lsu_axi_arid),
        .lsu_axi_araddr         (lsu_axi_araddr),
        .lsu_axi_arregion       (lsu_axi_arregion),
        .lsu_axi_arlen          (lsu_axi_arlen),
        .lsu_axi_arsize         (lsu_axi_arsize),
        .lsu_axi_arburst        (lsu_axi_arburst),
        .lsu_axi_arlock         (lsu_axi_arlock),
        .lsu_axi_arcache        (lsu_axi_arcache),
        .lsu_axi_arprot         (lsu_axi_arprot),
        .lsu_axi_arqos          (lsu_axi_arqos),
        .lsu_axi_rvalid         (lsu_axi_rvalid),
        .lsu_axi_rready         (lsu_axi_rready),
        .lsu_axi_rid            (lsu_axi_rid),
        .lsu_axi_rdata          (lsu_axi_rdata),
        .lsu_axi_rresp          (lsu_axi_rresp),
        .lsu_axi_rlast          (lsu_axi_rlast),

        // IFU AXI
        .ifu_axi_awvalid        (ifu_axi_awvalid),
        .ifu_axi_awready        (ifu_axi_awready),
        .ifu_axi_awid           (ifu_axi_awid),
        .ifu_axi_awaddr         (ifu_axi_awaddr),
        .ifu_axi_awregion       (ifu_axi_awregion),
        .ifu_axi_awlen          (ifu_axi_awlen),
        .ifu_axi_awsize         (ifu_axi_awsize),
        .ifu_axi_awburst        (ifu_axi_awburst),
        .ifu_axi_awlock         (ifu_axi_awlock),
        .ifu_axi_awcache        (ifu_axi_awcache),
        .ifu_axi_awprot         (ifu_axi_awprot),
        .ifu_axi_awqos          (ifu_axi_awqos),
        .ifu_axi_wvalid         (ifu_axi_wvalid),
        .ifu_axi_wready         (ifu_axi_wready),
        .ifu_axi_wdata          (ifu_axi_wdata),
        .ifu_axi_wstrb          (ifu_axi_wstrb),
        .ifu_axi_wlast          (ifu_axi_wlast),
        .ifu_axi_bvalid         (ifu_axi_bvalid),
        .ifu_axi_bready         (ifu_axi_bready),
        .ifu_axi_bresp          (ifu_axi_bresp),
        .ifu_axi_bid            (ifu_axi_bid),
        .ifu_axi_arvalid        (ifu_axi_arvalid),
        .ifu_axi_arready        (ifu_axi_arready),
        .ifu_axi_arid           (ifu_axi_arid),
        .ifu_axi_araddr         (ifu_axi_araddr),
        .ifu_axi_arregion       (ifu_axi_arregion),
        .ifu_axi_arlen          (ifu_axi_arlen),
        .ifu_axi_arsize         (ifu_axi_arsize),
        .ifu_axi_arburst        (ifu_axi_arburst),
        .ifu_axi_arlock         (ifu_axi_arlock),
        .ifu_axi_arcache        (ifu_axi_arcache),
        .ifu_axi_arprot         (ifu_axi_arprot),
        .ifu_axi_arqos          (ifu_axi_arqos),
        .ifu_axi_rvalid         (ifu_axi_rvalid),
        .ifu_axi_rready         (ifu_axi_rready),
        .ifu_axi_rid            (ifu_axi_rid),
        .ifu_axi_rdata          (ifu_axi_rdata),
        .ifu_axi_rresp          (ifu_axi_rresp),
        .ifu_axi_rlast          (ifu_axi_rlast),

        // SB AXI
        .sb_axi_awvalid         (sb_axi_awvalid),
        .sb_axi_awready         (sb_axi_awready),
        .sb_axi_awid            (sb_axi_awid),
        .sb_axi_awaddr          (sb_axi_awaddr),
        .sb_axi_awregion        (sb_axi_awregion),
        .sb_axi_awlen           (sb_axi_awlen),
        .sb_axi_awsize          (sb_axi_awsize),
        .sb_axi_awburst         (sb_axi_awburst),
        .sb_axi_awlock          (sb_axi_awlock),
        .sb_axi_awcache         (sb_axi_awcache),
        .sb_axi_awprot          (sb_axi_awprot),
        .sb_axi_awqos           (sb_axi_awqos),
        .sb_axi_wvalid          (sb_axi_wvalid),
        .sb_axi_wready          (sb_axi_wready),
        .sb_axi_wdata           (sb_axi_wdata),
        .sb_axi_wstrb           (sb_axi_wstrb),
        .sb_axi_wlast           (sb_axi_wlast),
        .sb_axi_bvalid          (sb_axi_bvalid),
        .sb_axi_bready          (sb_axi_bready),
        .sb_axi_bresp           (sb_axi_bresp),
        .sb_axi_bid             (sb_axi_bid),
        .sb_axi_arvalid         (sb_axi_arvalid),
        .sb_axi_arready         (sb_axi_arready),
        .sb_axi_arid            (sb_axi_arid),
        .sb_axi_araddr          (sb_axi_araddr),
        .sb_axi_arregion        (sb_axi_arregion),
        .sb_axi_arlen           (sb_axi_arlen),
        .sb_axi_arsize          (sb_axi_arsize),
        .sb_axi_arburst         (sb_axi_arburst),
        .sb_axi_arlock          (sb_axi_arlock),
        .sb_axi_arcache         (sb_axi_arcache),
        .sb_axi_arprot          (sb_axi_arprot),
        .sb_axi_arqos           (sb_axi_arqos),
        .sb_axi_rvalid          (sb_axi_rvalid),
        .sb_axi_rready          (sb_axi_rready),
        .sb_axi_rid             (sb_axi_rid),
        .sb_axi_rdata           (sb_axi_rdata),
        .sb_axi_rresp           (sb_axi_rresp),
        .sb_axi_rlast           (sb_axi_rlast),

        // DMA Slave (Unused)
        .dma_axi_awvalid        (1'b0),
        .dma_axi_awready        (),
        .dma_axi_awid           ('0),
        .dma_axi_awaddr         ('0),
        .dma_axi_awsize         ('0),
        .dma_axi_awprot         ('0),
        .dma_axi_awlen          ('0),
        .dma_axi_awburst        ('0),
        .dma_axi_wvalid         (1'b0),
        .dma_axi_wready         (),
        .dma_axi_wdata          ('0),
        .dma_axi_wstrb          ('0),
        .dma_axi_wlast          (1'b0),
        .dma_axi_bvalid         (),
        .dma_axi_bready         (1'b1),
        .dma_axi_bresp          (),
        .dma_axi_bid            (),
        .dma_axi_arvalid        (1'b0),
        .dma_axi_arready        (),
        .dma_axi_arid           ('0),
        .dma_axi_araddr         ('0),
        .dma_axi_arsize         ('0),
        .dma_axi_arprot         ('0),
        .dma_axi_arlen          ('0),
        .dma_axi_arburst        ('0),
        .dma_axi_rvalid         (),
        .dma_axi_rready         (1'b1),
        .dma_axi_rid            (),
        .dma_axi_rdata          (),
        .dma_axi_rresp          (),
        .dma_axi_rlast          (),

        .soft_int               (1'b0),
        .core_id                ('0),
        .jtag_tck               (1'b0),
        .jtag_tms               (1'b0),
        .jtag_tdi               (1'b0),
        .jtag_trst_n            (1'b1),
        .jtag_tdo               (),
        .jtag_tdoEn             ()
    );

    // -------------------------------------------------------------------------
    // 2. 64-bit to 32-bit AXI Width Down-Converters
    // -------------------------------------------------------------------------
    // S00: LSU (Data access)
    wire [ID_WIDTH-1:0]   s00_axi_awid, s00_axi_bid, s00_axi_arid, s00_axi_rid;
    wire [ADDR_WIDTH-1:0] s00_axi_awaddr, s00_axi_araddr;
    wire [7:0]            s00_axi_awlen, s00_axi_arlen;
    wire [2:0]            s00_axi_awsize, s00_axi_arsize;
    wire [1:0]            s00_axi_awburst, s00_axi_arburst;
    wire                  s00_axi_awlock, s00_axi_arlock;
    wire [3:0]            s00_axi_awcache, s00_axi_arcache;
    wire [2:0]            s00_axi_awprot, s00_axi_arprot;
    wire [3:0]            s00_axi_awqos, s00_axi_arqos;
    wire                  s00_axi_awvalid, s00_axi_awready;
    wire [DATA_WIDTH-1:0] s00_axi_wdata, s00_axi_rdata;
    wire [STRB_WIDTH-1:0] s00_axi_wstrb;
    wire                  s00_axi_wlast, s00_axi_wvalid, s00_axi_wready;
    wire [1:0]            s00_axi_bresp, s00_axi_rresp;
    wire                  s00_axi_bvalid, s00_axi_bready;
    wire                  s00_axi_arvalid, s00_axi_arready;
    wire                  s00_axi_rvalid, s00_axi_rready, s00_axi_rlast;

    axi_adapter_64_to_32 #(
        .ADDR_WIDTH(ADDR_WIDTH), .ID_WIDTH(ID_WIDTH)
    ) u_adapter_lsu (
        .clk(clk), .rst(rst),
        .s_axi_awid(lsu_axi_awid), .s_axi_awaddr(lsu_axi_awaddr), .s_axi_awlen(lsu_axi_awlen),
        .s_axi_awsize(lsu_axi_awsize), .s_axi_awburst(lsu_axi_awburst), .s_axi_awlock(lsu_axi_awlock),
        .s_axi_awcache(lsu_axi_awcache), .s_axi_awprot(lsu_axi_awprot), .s_axi_awqos(lsu_axi_awqos),
        .s_axi_awvalid(lsu_axi_awvalid), .s_axi_awready(lsu_axi_awready),
        .s_axi_wdata(lsu_axi_wdata), .s_axi_wstrb(lsu_axi_wstrb), .s_axi_wlast(lsu_axi_wlast),
        .s_axi_wvalid(lsu_axi_wvalid), .s_axi_wready(lsu_axi_wready),
        .s_axi_bid(lsu_axi_bid), .s_axi_bresp(lsu_axi_bresp), .s_axi_bvalid(lsu_axi_bvalid), .s_axi_bready(lsu_axi_bready),
        .s_axi_arid(lsu_axi_arid), .s_axi_araddr(lsu_axi_araddr), .s_axi_arlen(lsu_axi_arlen),
        .s_axi_arsize(lsu_axi_arsize), .s_axi_arburst(lsu_axi_arburst), .s_axi_arlock(lsu_axi_arlock),
        .s_axi_arcache(lsu_axi_arcache), .s_axi_arprot(lsu_axi_arprot), .s_axi_arqos(lsu_axi_arqos),
        .s_axi_arvalid(lsu_axi_arvalid), .s_axi_arready(lsu_axi_arready),
        .s_axi_rid(lsu_axi_rid), .s_axi_rdata(lsu_axi_rdata), .s_axi_rresp(lsu_axi_rresp),
        .s_axi_rlast(lsu_axi_rlast), .s_axi_rvalid(lsu_axi_rvalid), .s_axi_rready(lsu_axi_rready),

        .m_axi_awid(s00_axi_awid), .m_axi_awaddr(s00_axi_awaddr), .m_axi_awlen(s00_axi_awlen),
        .m_axi_awsize(s00_axi_awsize), .m_axi_awburst(s00_axi_awburst), .m_axi_awlock(s00_axi_awlock),
        .m_axi_awcache(s00_axi_awcache), .m_axi_awprot(s00_axi_awprot), .m_axi_awqos(s00_axi_awqos),
        .m_axi_awregion(), .m_axi_awvalid(s00_axi_awvalid), .m_axi_awready(s00_axi_awready),
        .m_axi_wdata(s00_axi_wdata), .m_axi_wstrb(s00_axi_wstrb), .m_axi_wlast(s00_axi_wlast),
        .m_axi_wvalid(s00_axi_wvalid), .m_axi_wready(s00_axi_wready),
        .m_axi_bid(s00_axi_bid), .m_axi_bresp(s00_axi_bresp), .m_axi_bvalid(s00_axi_bvalid), .m_axi_bready(s00_axi_bready),
        .m_axi_arid(s00_axi_arid), .m_axi_araddr(s00_axi_araddr), .m_axi_arlen(s00_axi_arlen),
        .m_axi_arsize(s00_axi_arsize), .m_axi_arburst(s00_axi_arburst), .m_axi_arlock(s00_axi_arlock),
        .m_axi_arcache(s00_axi_arcache), .m_axi_arprot(s00_axi_arprot), .m_axi_arqos(s00_axi_arqos),
        .m_axi_arregion(), .m_axi_arvalid(s00_axi_arvalid), .m_axi_arready(s00_axi_arready),
        .m_axi_rid(s00_axi_rid), .m_axi_rdata(s00_axi_rdata), .m_axi_rresp(s00_axi_rresp),
        .m_axi_rlast(s00_axi_rlast), .m_axi_rvalid(s00_axi_rvalid), .m_axi_rready(s00_axi_rready)
    );

    // S01: IFU (Instruction fetch)
    wire [ID_WIDTH-1:0]   s01_axi_awid, s01_axi_bid, s01_axi_arid, s01_axi_rid;
    wire [ADDR_WIDTH-1:0] s01_axi_awaddr, s01_axi_araddr;
    wire [7:0]            s01_axi_awlen, s01_axi_arlen;
    wire [2:0]            s01_axi_awsize, s01_axi_arsize;
    wire [1:0]            s01_axi_awburst, s01_axi_arburst;
    wire                  s01_axi_awlock, s01_axi_arlock;
    wire [3:0]            s01_axi_awcache, s01_axi_arcache;
    wire [2:0]            s01_axi_awprot, s01_axi_arprot;
    wire [3:0]            s01_axi_awqos, s01_axi_arqos;
    wire                  s01_axi_awvalid, s01_axi_awready;
    wire [DATA_WIDTH-1:0] s01_axi_wdata, s01_axi_rdata;
    wire [STRB_WIDTH-1:0] s01_axi_wstrb;
    wire                  s01_axi_wlast, s01_axi_wvalid, s01_axi_wready;
    wire [1:0]            s01_axi_bresp, s01_axi_rresp;
    wire                  s01_axi_bvalid, s01_axi_bready;
    wire                  s01_axi_arvalid, s01_axi_arready;
    wire                  s01_axi_rvalid, s01_axi_rready, s01_axi_rlast;

    axi_adapter_64_to_32 #(
        .ADDR_WIDTH(ADDR_WIDTH), .ID_WIDTH(ID_WIDTH)
    ) u_adapter_ifu (
        .clk(clk), .rst(rst),
        .s_axi_awid(ifu_axi_awid), .s_axi_awaddr(ifu_axi_awaddr), .s_axi_awlen(ifu_axi_awlen),
        .s_axi_awsize(ifu_axi_awsize), .s_axi_awburst(ifu_axi_awburst), .s_axi_awlock(ifu_axi_awlock),
        .s_axi_awcache(ifu_axi_awcache), .s_axi_awprot(ifu_axi_awprot), .s_axi_awqos(ifu_axi_awqos),
        .s_axi_awvalid(ifu_axi_awvalid), .s_axi_awready(ifu_axi_awready),
        .s_axi_wdata(ifu_axi_wdata), .s_axi_wstrb(ifu_axi_wstrb), .s_axi_wlast(ifu_axi_wlast),
        .s_axi_wvalid(ifu_axi_wvalid), .s_axi_wready(ifu_axi_wready),
        .s_axi_bid(ifu_axi_bid), .s_axi_bresp(ifu_axi_bresp), .s_axi_bvalid(ifu_axi_bvalid), .s_axi_bready(ifu_axi_bready),
        .s_axi_arid(ifu_axi_arid), .s_axi_araddr(ifu_axi_araddr), .s_axi_arlen(ifu_axi_arlen),
        .s_axi_arsize(ifu_axi_arsize), .s_axi_arburst(ifu_axi_arburst), .s_axi_arlock(ifu_axi_arlock),
        .s_axi_arcache(ifu_axi_arcache), .s_axi_arprot(ifu_axi_arprot), .s_axi_arqos(ifu_axi_arqos),
        .s_axi_arvalid(ifu_axi_arvalid), .s_axi_arready(ifu_axi_arready),
        .s_axi_rid(ifu_axi_rid), .s_axi_rdata(ifu_axi_rdata), .s_axi_rresp(ifu_axi_rresp),
        .s_axi_rlast(ifu_axi_rlast), .s_axi_rvalid(ifu_axi_rvalid), .s_axi_rready(ifu_axi_rready),

        .m_axi_awid(s01_axi_awid), .m_axi_awaddr(s01_axi_awaddr), .m_axi_awlen(s01_axi_awlen),
        .m_axi_awsize(s01_axi_awsize), .m_axi_awburst(s01_axi_awburst), .m_axi_awlock(s01_axi_awlock),
        .m_axi_awcache(s01_axi_awcache), .m_axi_awprot(s01_axi_awprot), .m_axi_awqos(s01_axi_awqos),
        .m_axi_awregion(), .m_axi_awvalid(s01_axi_awvalid), .m_axi_awready(s01_axi_awready),
        .m_axi_wdata(s01_axi_wdata), .m_axi_wstrb(s01_axi_wstrb), .m_axi_wlast(s01_axi_wlast),
        .m_axi_wvalid(s01_axi_wvalid), .m_axi_wready(s01_axi_wready),
        .m_axi_bid(s01_axi_bid), .m_axi_bresp(s01_axi_bresp), .m_axi_bvalid(s01_axi_bvalid), .m_axi_bready(s01_axi_bready),
        .m_axi_arid(s01_axi_arid), .m_axi_araddr(s01_axi_araddr), .m_axi_arlen(s01_axi_arlen),
        .m_axi_arsize(s01_axi_arsize), .m_axi_arburst(s01_axi_arburst), .m_axi_arlock(s01_axi_arlock),
        .m_axi_arcache(s01_axi_arcache), .m_axi_arprot(s01_axi_arprot), .m_axi_arqos(s01_axi_arqos),
        .m_axi_arregion(), .m_axi_arvalid(s01_axi_arvalid), .m_axi_arready(s01_axi_arready),
        .m_axi_rid(s01_axi_rid), .m_axi_rdata(s01_axi_rdata), .m_axi_rresp(s01_axi_rresp),
        .m_axi_rlast(s01_axi_rlast), .m_axi_rvalid(s01_axi_rvalid), .m_axi_rready(s01_axi_rready)
    );

    // S02: SB (System Bus)
    wire [ID_WIDTH-1:0]   s02_axi_awid, s02_axi_bid, s02_axi_arid, s02_axi_rid;
    wire [ADDR_WIDTH-1:0] s02_axi_awaddr, s02_axi_araddr;
    wire [7:0]            s02_axi_awlen, s02_axi_arlen;
    wire [2:0]            s02_axi_awsize, s02_axi_arsize;
    wire [1:0]            s02_axi_awburst, s02_axi_arburst;
    wire                  s02_axi_awlock, s02_axi_arlock;
    wire [3:0]            s02_axi_awcache, s02_axi_arcache;
    wire [2:0]            s02_axi_awprot, s02_axi_arprot;
    wire [3:0]            s02_axi_awqos, s02_axi_arqos;
    wire                  s02_axi_awvalid, s02_axi_awready;
    wire [DATA_WIDTH-1:0] s02_axi_wdata, s02_axi_rdata;
    wire [STRB_WIDTH-1:0] s02_axi_wstrb;
    wire                  s02_axi_wlast, s02_axi_wvalid, s02_axi_wready;
    wire [1:0]            s02_axi_bresp, s02_axi_rresp;
    wire                  s02_axi_bvalid, s02_axi_bready;
    wire                  s02_axi_arvalid, s02_axi_arready;
    wire                  s02_axi_rvalid, s02_axi_rready, s02_axi_rlast;

    axi_adapter_64_to_32 #(
        .ADDR_WIDTH(ADDR_WIDTH), .ID_WIDTH(ID_WIDTH)
    ) u_adapter_sb (
        .clk(clk), .rst(rst),
        .s_axi_awid(sb_axi_awid), .s_axi_awaddr(sb_axi_awaddr), .s_axi_awlen(sb_axi_awlen),
        .s_axi_awsize(sb_axi_awsize), .s_axi_awburst(sb_axi_awburst), .s_axi_awlock(sb_axi_awlock),
        .s_axi_awcache(sb_axi_awcache), .s_axi_awprot(sb_axi_awprot), .s_axi_awqos(sb_axi_awqos),
        .s_axi_awvalid(sb_axi_awvalid), .s_axi_awready(sb_axi_awready),
        .s_axi_wdata(sb_axi_wdata), .s_axi_wstrb(sb_axi_wstrb), .s_axi_wlast(sb_axi_wlast),
        .s_axi_wvalid(sb_axi_wvalid), .s_axi_wready(sb_axi_wready),
        .s_axi_bid(sb_axi_bid), .s_axi_bresp(sb_axi_bresp), .s_axi_bvalid(sb_axi_bvalid), .s_axi_bready(sb_axi_bready),
        .s_axi_arid(sb_axi_arid), .s_axi_araddr(sb_axi_araddr), .s_axi_arlen(sb_axi_arlen),
        .s_axi_arsize(sb_axi_arsize), .s_axi_arburst(sb_axi_arburst), .s_axi_arlock(sb_axi_arlock),
        .s_axi_arcache(sb_axi_arcache), .s_axi_arprot(sb_axi_arprot), .s_axi_arqos(sb_axi_arqos),
        .s_axi_arvalid(sb_axi_arvalid), .s_axi_arready(sb_axi_arready),
        .s_axi_rid(sb_axi_rid), .s_axi_rdata(sb_axi_rdata), .s_axi_rresp(sb_axi_rresp),
        .s_axi_rlast(sb_axi_rlast), .s_axi_rvalid(sb_axi_rvalid), .s_axi_rready(sb_axi_rready),

        .m_axi_awid(s02_axi_awid), .m_axi_awaddr(s02_axi_awaddr), .m_axi_awlen(s02_axi_awlen),
        .m_axi_awsize(s02_axi_awsize), .m_axi_awburst(s02_axi_awburst), .m_axi_awlock(s02_axi_awlock),
        .m_axi_awcache(s02_axi_awcache), .m_axi_awprot(s02_axi_awprot), .m_axi_awqos(s02_axi_awqos),
        .m_axi_awregion(), .m_axi_awvalid(s02_axi_awvalid), .m_axi_awready(s02_axi_awready),
        .m_axi_wdata(s02_axi_wdata), .m_axi_wstrb(s02_axi_wstrb), .m_axi_wlast(s02_axi_wlast),
        .m_axi_wvalid(s02_axi_wvalid), .m_axi_wready(s02_axi_wready),
        .m_axi_bid(s02_axi_bid), .m_axi_bresp(s02_axi_bresp), .m_axi_bvalid(s02_axi_bvalid), .m_axi_bready(s02_axi_bready),
        .m_axi_arid(s02_axi_arid), .m_axi_araddr(s02_axi_araddr), .m_axi_arlen(s02_axi_arlen),
        .m_axi_arsize(s02_axi_arsize), .m_axi_arburst(s02_axi_arburst), .m_axi_arlock(s02_axi_arlock),
        .m_axi_arcache(s02_axi_arcache), .m_axi_arprot(s02_axi_arprot), .m_axi_arqos(s02_axi_arqos),
        .m_axi_arregion(), .m_axi_arvalid(s02_axi_arvalid), .m_axi_arready(s02_axi_arready),
        .m_axi_rid(s02_axi_rid), .m_axi_rdata(s02_axi_rdata), .m_axi_rresp(s02_axi_rresp),
        .m_axi_rlast(s02_axi_rlast), .m_axi_rvalid(s02_axi_rvalid), .m_axi_rready(s02_axi_rready)
    );

    // -------------------------------------------------------------------------
    // 3. Interconnect Master Port Signals for IMEM (M00) & DMEM (M01)
    // -------------------------------------------------------------------------
    // M00 (IMEM)
    wire [ID_WIDTH-1:0]   m00_axi_awid, m00_axi_bid, m00_axi_arid, m00_axi_rid;
    wire [ADDR_WIDTH-1:0] m00_axi_awaddr, m00_axi_araddr;
    wire [7:0]            m00_axi_awlen, m00_axi_arlen;
    wire [2:0]            m00_axi_awsize, m00_axi_arsize;
    wire [1:0]            m00_axi_awburst, m00_axi_arburst;
    wire                  m00_axi_awlock, m00_axi_arlock;
    wire [3:0]            m00_axi_awcache, m00_axi_arcache;
    wire [2:0]            m00_axi_awprot, m00_axi_arprot;
    wire [3:0]            m00_axi_awqos, m00_axi_arqos;
    wire [3:0]            m00_axi_awregion, m00_axi_arregion;
    wire                  m00_axi_awvalid, m00_axi_awready;
    wire [DATA_WIDTH-1:0] m00_axi_wdata, m00_axi_rdata;
    wire [STRB_WIDTH-1:0] m00_axi_wstrb;
    wire                  m00_axi_wlast, m00_axi_wvalid, m00_axi_wready;
    wire [1:0]            m00_axi_bresp, m00_axi_rresp;
    wire                  m00_axi_bvalid, m00_axi_bready;
    wire                  m00_axi_arvalid, m00_axi_arready;
    wire                  m00_axi_rvalid, m00_axi_rready, m00_axi_rlast;

    // M01 (DMEM)
    wire [ID_WIDTH-1:0]   m01_axi_awid, m01_axi_bid, m01_axi_arid, m01_axi_rid;
    wire [ADDR_WIDTH-1:0] m01_axi_awaddr, m01_axi_araddr;
    wire [7:0]            m01_axi_awlen, m01_axi_arlen;
    wire [2:0]            m01_axi_awsize, m01_axi_arsize;
    wire [1:0]            m01_axi_awburst, m01_axi_arburst;
    wire                  m01_axi_awlock, m01_axi_arlock;
    wire [3:0]            m01_axi_awcache, m01_axi_arcache;
    wire [2:0]            m01_axi_awprot, m01_axi_arprot;
    wire [3:0]            m01_axi_awqos, m01_axi_arqos;
    wire [3:0]            m01_axi_awregion, m01_axi_arregion;
    wire                  m01_axi_awvalid, m01_axi_awready;
    wire [DATA_WIDTH-1:0] m01_axi_wdata, m01_axi_rdata;
    wire [STRB_WIDTH-1:0] m01_axi_wstrb;
    wire                  m01_axi_wlast, m01_axi_wvalid, m01_axi_wready;
    wire [1:0]            m01_axi_bresp, m01_axi_rresp;
    wire                  m01_axi_bvalid, m01_axi_bready;
    wire                  m01_axi_arvalid, m01_axi_arready;
    wire                  m01_axi_rvalid, m01_axi_rready, m01_axi_rlast;

    // M02 (I2C) and M03 (PWM) are integrated inside axi_soc_top_5x20
    wire       scl_pad_i, scl_pad_o, scl_padoen_o;
    wire       sda_pad_i, sda_pad_o, sda_padoen_o;
    wire [3:0] pwm_out_4ch;

    assign scl = scl_padoen_o ? 1'bz : scl_pad_o;
    assign sda = sda_padoen_o ? 1'bz : sda_pad_o;
    assign scl_pad_i = scl;
    assign sda_pad_i = sda;
    assign pwm_out = pwm_out_4ch[0];

    // M04 (SSD / reserved) dummy terminations
    wire [ID_WIDTH-1:0]   m04_axi_awid, m04_axi_arid;
    wire [ADDR_WIDTH-1:0] m04_axi_awaddr, m04_axi_araddr;
    wire [7:0]            m04_axi_awlen, m04_axi_arlen;
    wire [2:0]            m04_axi_awsize, m04_axi_arsize;
    wire [1:0]            m04_axi_awburst, m04_axi_arburst;
    wire                  m04_axi_awlock, m04_axi_arlock;
    wire [3:0]            m04_axi_awcache, m04_axi_arcache;
    wire [2:0]            m04_axi_awprot, m04_axi_arprot;
    wire [3:0]            m04_axi_awqos, m04_axi_arqos;
    wire [3:0]            m04_axi_awregion, m04_axi_arregion;
    wire                  m04_axi_awvalid, m04_axi_arvalid, m04_axi_wvalid, m04_axi_wlast;
    wire [DATA_WIDTH-1:0] m04_axi_wdata;
    wire [STRB_WIDTH-1:0] m04_axi_wstrb;

    // Dummy AXI sink macro for unassigned master ports
    `define SINK_TERMINATE(idx) \
        wire [ID_WIDTH-1:0]   m``idx``_axi_awid, m``idx``_axi_arid; \
        wire [ADDR_WIDTH-1:0] m``idx``_axi_awaddr, m``idx``_axi_araddr; \
        wire [7:0]            m``idx``_axi_awlen, m``idx``_axi_arlen; \
        wire [2:0]            m``idx``_axi_awsize, m``idx``_axi_arsize; \
        wire [1:0]            m``idx``_axi_awburst, m``idx``_axi_arburst; \
        wire                  m``idx``_axi_awlock, m``idx``_axi_arlock; \
        wire [3:0]            m``idx``_axi_awcache, m``idx``_axi_arcache; \
        wire [2:0]            m``idx``_axi_awprot, m``idx``_axi_arprot; \
        wire [3:0]            m``idx``_axi_awqos, m``idx``_axi_arqos; \
        wire [3:0]            m``idx``_axi_awregion, m``idx``_axi_arregion; \
        wire                  m``idx``_axi_awvalid, m``idx``_axi_arvalid; \
        wire [DATA_WIDTH-1:0] m``idx``_axi_wdata; \
        wire [STRB_WIDTH-1:0] m``idx``_axi_wstrb; \
        wire                  m``idx``_axi_wvalid, m``idx``_axi_wlast;

    `SINK_TERMINATE(08)
    `SINK_TERMINATE(09)
    `SINK_TERMINATE(10)
    `SINK_TERMINATE(11)
    `SINK_TERMINATE(12)
    `SINK_TERMINATE(13)
    `SINK_TERMINATE(14)
    `SINK_TERMINATE(15)
    `SINK_TERMINATE(16)
    `SINK_TERMINATE(17)
    `SINK_TERMINATE(18)
    `SINK_TERMINATE(19)

    // =========================================================================
    // 4. AXI4 Interconnect + Baseline Peripherals Subsystem (axi_soc_top_5x20)
    //    Contains: Interconnect + M05: UART + M06: Timer + M07: GPIO
    // =========================================================================
    axi_soc_top_5x20 #(
        .DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH), .STRB_WIDTH(STRB_WIDTH),
        .ID_WIDTH(ID_WIDTH),
        .M00_BASE_ADDR(IMEM_BASE_ADDR),
        .M01_BASE_ADDR(DMEM_BASE_ADDR),
        .M02_BASE_ADDR(I2C_BASE_ADDR),
        .M03_BASE_ADDR(PWM_BASE_ADDR),
        .M05_BASE_ADDR(UART_BASE_ADDR),
        .M06_BASE_ADDR(TIMER_BASE_ADDR),
        .M07_BASE_ADDR(GPIO_BASE_ADDR)
    ) u_axi_soc (
        .clk(clk),
        .rst(rst),

        // Slave 00: LSU
        .s00_axi_awid(s00_axi_awid), .s00_axi_awaddr(s00_axi_awaddr), .s00_axi_awlen(s00_axi_awlen),
        .s00_axi_awsize(s00_axi_awsize), .s00_axi_awburst(s00_axi_awburst), .s00_axi_awlock(s00_axi_awlock),
        .s00_axi_awcache(s00_axi_awcache), .s00_axi_awprot(s00_axi_awprot), .s00_axi_awqos(s00_axi_awqos),
        .s00_axi_awuser(1'b0), .s00_axi_awvalid(s00_axi_awvalid), .s00_axi_awready(s00_axi_awready),
        .s00_axi_wdata(s00_axi_wdata), .s00_axi_wstrb(s00_axi_wstrb), .s00_axi_wlast(s00_axi_wlast),
        .s00_axi_wuser(1'b0), .s00_axi_wvalid(s00_axi_wvalid), .s00_axi_wready(s00_axi_wready),
        .s00_axi_bid(s00_axi_bid), .s00_axi_bresp(s00_axi_bresp), .s00_axi_buser(),
        .s00_axi_bvalid(s00_axi_bvalid), .s00_axi_bready(s00_axi_bready),
        .s00_axi_arid(s00_axi_arid), .s00_axi_araddr(s00_axi_araddr), .s00_axi_arlen(s00_axi_arlen),
        .s00_axi_arsize(s00_axi_arsize), .s00_axi_arburst(s00_axi_arburst), .s00_axi_arlock(s00_axi_arlock),
        .s00_axi_arcache(s00_axi_arcache), .s00_axi_arprot(s00_axi_arprot), .s00_axi_arqos(s00_axi_arqos),
        .s00_axi_aruser(1'b0), .s00_axi_arvalid(s00_axi_arvalid), .s00_axi_arready(s00_axi_arready),
        .s00_axi_rid(s00_axi_rid), .s00_axi_rdata(s00_axi_rdata), .s00_axi_rresp(s00_axi_rresp),
        .s00_axi_rlast(s00_axi_rlast), .s00_axi_ruser(), .s00_axi_rvalid(s00_axi_rvalid), .s00_axi_rready(s00_axi_rready),

        // Slave 01: IFU
        .s01_axi_awid(s01_axi_awid), .s01_axi_awaddr(s01_axi_awaddr), .s01_axi_awlen(s01_axi_awlen),
        .s01_axi_awsize(s01_axi_awsize), .s01_axi_awburst(s01_axi_awburst), .s01_axi_awlock(s01_axi_awlock),
        .s01_axi_awcache(s01_axi_awcache), .s01_axi_awprot(s01_axi_awprot), .s01_axi_awqos(s01_axi_awqos),
        .s01_axi_awuser(1'b0), .s01_axi_awvalid(s01_axi_awvalid), .s01_axi_awready(s01_axi_awready),
        .s01_axi_wdata(s01_axi_wdata), .s01_axi_wstrb(s01_axi_wstrb), .s01_axi_wlast(s01_axi_wlast),
        .s01_axi_wuser(1'b0), .s01_axi_wvalid(s01_axi_wvalid), .s01_axi_wready(s01_axi_wready),
        .s01_axi_bid(s01_axi_bid), .s01_axi_bresp(s01_axi_bresp), .s01_axi_buser(),
        .s01_axi_bvalid(s01_axi_bvalid), .s01_axi_bready(s01_axi_bready),
        .s01_axi_arid(s01_axi_arid), .s01_axi_araddr(s01_axi_araddr), .s01_axi_arlen(s01_axi_arlen),
        .s01_axi_arsize(s01_axi_arsize), .s01_axi_arburst(s01_axi_arburst), .s01_axi_arlock(s01_axi_arlock),
        .s01_axi_arcache(s01_axi_arcache), .s01_axi_arprot(s01_axi_arprot), .s01_axi_arqos(s01_axi_arqos),
        .s01_axi_aruser(1'b0), .s01_axi_arvalid(s01_axi_arvalid), .s01_axi_arready(s01_axi_arready),
        .s01_axi_rid(s01_axi_rid), .s01_axi_rdata(s01_axi_rdata), .s01_axi_rresp(s01_axi_rresp),
        .s01_axi_rlast(s01_axi_rlast), .s01_axi_ruser(), .s01_axi_rvalid(s01_axi_rvalid), .s01_axi_rready(s01_axi_rready),

        // Slave 02: SB
        .s02_axi_awid(s02_axi_awid), .s02_axi_awaddr(s02_axi_awaddr), .s02_axi_awlen(s02_axi_awlen),
        .s02_axi_awsize(s02_axi_awsize), .s02_axi_awburst(s02_axi_awburst), .s02_axi_awlock(s02_axi_awlock),
        .s02_axi_awcache(s02_axi_awcache), .s02_axi_awprot(s02_axi_awprot), .s02_axi_awqos(s02_axi_awqos),
        .s02_axi_awuser(1'b0), .s02_axi_awvalid(s02_axi_awvalid), .s02_axi_awready(s02_axi_awready),
        .s02_axi_wdata(s02_axi_wdata), .s02_axi_wstrb(s02_axi_wstrb), .s02_axi_wlast(s02_axi_wlast),
        .s02_axi_wuser(1'b0), .s02_axi_wvalid(s02_axi_wvalid), .s02_axi_wready(s02_axi_wready),
        .s02_axi_bid(s02_axi_bid), .s02_axi_bresp(s02_axi_bresp), .s02_axi_buser(),
        .s02_axi_bvalid(s02_axi_bvalid), .s02_axi_bready(s02_axi_bready),
        .s02_axi_arid(s02_axi_arid), .s02_axi_araddr(s02_axi_araddr), .s02_axi_arlen(s02_axi_arlen),
        .s02_axi_arsize(s02_axi_arsize), .s02_axi_arburst(s02_axi_arburst), .s02_axi_arlock(s02_axi_arlock),
        .s02_axi_arcache(s02_axi_arcache), .s02_axi_arprot(s02_axi_arprot), .s02_axi_arqos(s02_axi_arqos),
        .s02_axi_aruser(1'b0), .s02_axi_arvalid(s02_axi_arvalid), .s02_axi_arready(s02_axi_arready),
        .s02_axi_rid(s02_axi_rid), .s02_axi_rdata(s02_axi_rdata), .s02_axi_rresp(s02_axi_rresp),
        .s02_axi_rlast(s02_axi_rlast), .s02_axi_ruser(), .s02_axi_rvalid(s02_axi_rvalid), .s02_axi_rready(s02_axi_rready),

        // Slaves 03 & 04 (Tied off inactive)
        .s03_axi_awid('0), .s03_axi_awaddr('0), .s03_axi_awlen(8'd0), .s03_axi_awsize(3'd0), .s03_axi_awburst(2'd0),
        .s03_axi_awlock(1'b0), .s03_axi_awcache(4'd0), .s03_axi_awprot(3'd0), .s03_axi_awqos(4'd0),
        .s03_axi_awuser(1'b0), .s03_axi_awvalid(1'b0), .s03_axi_awready(),
        .s03_axi_wdata('0), .s03_axi_wstrb('0), .s03_axi_wlast(1'b0), .s03_axi_wuser(1'b0), .s03_axi_wvalid(1'b0), .s03_axi_wready(),
        .s03_axi_bid(), .s03_axi_bresp(), .s03_axi_buser(), .s03_axi_bvalid(), .s03_axi_bready(1'b0),
        .s03_axi_arid('0), .s03_axi_araddr('0), .s03_axi_arlen(8'd0), .s03_axi_arsize(3'd0), .s03_axi_arburst(2'd0),
        .s03_axi_arlock(1'b0), .s03_axi_arcache(4'd0), .s03_axi_arprot(3'd0), .s03_axi_arqos(4'd0),
        .s03_axi_aruser(1'b0), .s03_axi_arvalid(1'b0), .s03_axi_arready(),
        .s03_axi_rid(), .s03_axi_rdata(), .s03_axi_rresp(), .s03_axi_rlast(), .s03_axi_ruser(), .s03_axi_rvalid(), .s03_axi_rready(1'b0),

        .s04_axi_awid('0), .s04_axi_awaddr('0), .s04_axi_awlen(8'd0), .s04_axi_awsize(3'd0), .s04_axi_awburst(2'd0),
        .s04_axi_awlock(1'b0), .s04_axi_awcache(4'd0), .s04_axi_awprot(3'd0), .s04_axi_awqos(4'd0),
        .s04_axi_awuser(1'b0), .s04_axi_awvalid(1'b0), .s04_axi_awready(),
        .s04_axi_wdata('0), .s04_axi_wstrb('0), .s04_axi_wlast(1'b0), .s04_axi_wuser(1'b0), .s04_axi_wvalid(1'b0), .s04_axi_wready(),
        .s04_axi_bid(), .s04_axi_bresp(), .s04_axi_buser(), .s04_axi_bvalid(), .s04_axi_bready(1'b0),
        .s04_axi_arid('0), .s04_axi_araddr('0), .s04_axi_arlen(8'd0), .s04_axi_arsize(3'd0), .s04_axi_arburst(2'd0),
        .s04_axi_arlock(1'b0), .s04_axi_arcache(4'd0), .s04_axi_arprot(3'd0), .s04_axi_arqos(4'd0),
        .s04_axi_aruser(1'b0), .s04_axi_arvalid(1'b0), .s04_axi_arready(),
        .s04_axi_rid(), .s04_axi_rdata(), .s04_axi_rresp(), .s04_axi_rlast(), .s04_axi_ruser(), .s04_axi_rvalid(), .s04_axi_rready(1'b0),

        // Master 00: IMEM
        .m00_axi_awid(m00_axi_awid), .m00_axi_awaddr(m00_axi_awaddr), .m00_axi_awlen(m00_axi_awlen),
        .m00_axi_awsize(m00_axi_awsize), .m00_axi_awburst(m00_axi_awburst), .m00_axi_awlock(m00_axi_awlock),
        .m00_axi_awcache(m00_axi_awcache), .m00_axi_awprot(m00_axi_awprot), .m00_axi_awqos(m00_axi_awqos),
        .m00_axi_awregion(m00_axi_awregion), .m00_axi_awuser(), .m00_axi_awvalid(m00_axi_awvalid), .m00_axi_awready(m00_axi_awready),
        .m00_axi_wdata(m00_axi_wdata), .m00_axi_wstrb(m00_axi_wstrb), .m00_axi_wlast(m00_axi_wlast),
        .m00_axi_wuser(), .m00_axi_wvalid(m00_axi_wvalid), .m00_axi_wready(m00_axi_wready),
        .m00_axi_bid(m00_axi_bid), .m00_axi_bresp(m00_axi_bresp), .m00_axi_buser(1'b0),
        .m00_axi_bvalid(m00_axi_bvalid), .m00_axi_bready(m00_axi_bready),
        .m00_axi_arid(m00_axi_arid), .m00_axi_araddr(m00_axi_araddr), .m00_axi_arlen(m00_axi_arlen),
        .m00_axi_arsize(m00_axi_arsize), .m00_axi_arburst(m00_axi_arburst), .m00_axi_arlock(m00_axi_arlock),
        .m00_axi_arcache(m00_axi_arcache), .m00_axi_arprot(m00_axi_arprot), .m00_axi_arqos(m00_axi_arqos),
        .m00_axi_arregion(m00_axi_arregion), .m00_axi_aruser(), .m00_axi_arvalid(m00_axi_arvalid), .m00_axi_arready(m00_axi_arready),
        .m00_axi_rid(m00_axi_rid), .m00_axi_rdata(m00_axi_rdata), .m00_axi_rresp(m00_axi_rresp),
        .m00_axi_rlast(m00_axi_rlast), .m00_axi_ruser(1'b0), .m00_axi_rvalid(m00_axi_rvalid), .m00_axi_rready(m00_axi_rready),

        // Master 01: DMEM
        .m01_axi_awid(m01_axi_awid), .m01_axi_awaddr(m01_axi_awaddr), .m01_axi_awlen(m01_axi_awlen),
        .m01_axi_awsize(m01_axi_awsize), .m01_axi_awburst(m01_axi_awburst), .m01_axi_awlock(m01_axi_awlock),
        .m01_axi_awcache(m01_axi_awcache), .m01_axi_awprot(m01_axi_awprot), .m01_axi_awqos(m01_axi_awqos),
        .m01_axi_awregion(m01_axi_awregion), .m01_axi_awuser(), .m01_axi_awvalid(m01_axi_awvalid), .m01_axi_awready(m01_axi_awready),
        .m01_axi_wdata(m01_axi_wdata), .m01_axi_wstrb(m01_axi_wstrb), .m01_axi_wlast(m01_axi_wlast),
        .m01_axi_wuser(), .m01_axi_wvalid(m01_axi_wvalid), .m01_axi_wready(m01_axi_wready),
        .m01_axi_bid(m01_axi_bid), .m01_axi_bresp(m01_axi_bresp), .m01_axi_buser(1'b0),
        .m01_axi_bvalid(m01_axi_bvalid), .m01_axi_bready(m01_axi_bready),
        .m01_axi_arid(m01_axi_arid), .m01_axi_araddr(m01_axi_araddr), .m01_axi_arlen(m01_axi_arlen),
        .m01_axi_arsize(m01_axi_arsize), .m01_axi_arburst(m01_axi_arburst), .m01_axi_arlock(m01_axi_arlock),
        .m01_axi_arcache(m01_axi_arcache), .m01_axi_arprot(m01_axi_arprot), .m01_axi_arqos(m01_axi_arqos),
        .m01_axi_arregion(m01_axi_arregion), .m01_axi_aruser(), .m01_axi_arvalid(m01_axi_arvalid), .m01_axi_arready(m01_axi_arready),
        .m01_axi_rid(m01_axi_rid), .m01_axi_rdata(m01_axi_rdata), .m01_axi_rresp(m01_axi_rresp),
        .m01_axi_rlast(m01_axi_rlast), .m01_axi_ruser(1'b0), .m01_axi_rvalid(m01_axi_rvalid), .m01_axi_rready(m01_axi_rready),

        // Boundary I2C Interface (M02)
        .scl_pad_i(scl_pad_i),
        .scl_pad_o(scl_pad_o),
        .scl_padoen_o(scl_padoen_o),
        .sda_pad_i(sda_pad_i),
        .sda_pad_o(sda_pad_o),
        .sda_padoen_o(sda_padoen_o),
        .irq_i2c(irq_i2c),

        // Boundary PWM Interface (M03)
        .pwm_out(pwm_out_4ch),
        .irq_pwm(irq_pwm),

        // Master 04: SSD (Tied off / unused)
        .m04_axi_awid(m04_axi_awid), .m04_axi_awaddr(m04_axi_awaddr), .m04_axi_awlen(m04_axi_awlen),
        .m04_axi_awsize(m04_axi_awsize), .m04_axi_awburst(m04_axi_awburst), .m04_axi_awlock(m04_axi_awlock),
        .m04_axi_awcache(m04_axi_awcache), .m04_axi_awprot(m04_axi_awprot), .m04_axi_awqos(m04_axi_awqos),
        .m04_axi_awregion(m04_axi_awregion), .m04_axi_awuser(), .m04_axi_awvalid(m04_axi_awvalid), .m04_axi_awready(1'b1),
        .m04_axi_wdata(m04_axi_wdata), .m04_axi_wstrb(m04_axi_wstrb), .m04_axi_wlast(m04_axi_wlast),
        .m04_axi_wuser(), .m04_axi_wvalid(m04_axi_wvalid), .m04_axi_wready(1'b1),
        .m04_axi_bid(m04_axi_awid), .m04_axi_bresp(2'b00), .m04_axi_buser(1'b0),
        .m04_axi_bvalid(m04_axi_wvalid), .m04_axi_bready(),
        .m04_axi_arid(m04_axi_arid), .m04_axi_araddr(m04_axi_araddr), .m04_axi_arlen(m04_axi_arlen),
        .m04_axi_arsize(m04_axi_arsize), .m04_axi_arburst(m04_axi_arburst), .m04_axi_arlock(m04_axi_arlock),
        .m04_axi_arcache(m04_axi_arcache), .m04_axi_arprot(m04_axi_arprot), .m04_axi_arqos(m04_axi_arqos),
        .m04_axi_arregion(m04_axi_arregion), .m04_axi_aruser(), .m04_axi_arvalid(m04_axi_arvalid), .m04_axi_arready(1'b1),
        .m04_axi_rid(m04_axi_arid), .m04_axi_rdata(32'd0), .m04_axi_rresp(2'b00),
        .m04_axi_rlast(1'b1), .m04_axi_ruser(1'b0), .m04_axi_rvalid(m04_axi_arvalid), .m04_axi_rready(),

        // Master 08 - 19: Unassigned peripheral ports
        `define SINK_WIRE(idx) \
            .m``idx``_axi_awid(m``idx``_axi_awid), .m``idx``_axi_awaddr(m``idx``_axi_awaddr), \
            .m``idx``_axi_awlen(m``idx``_axi_awlen), .m``idx``_axi_awsize(m``idx``_axi_awsize), \
            .m``idx``_axi_awburst(m``idx``_axi_awburst), .m``idx``_axi_awlock(m``idx``_axi_awlock), \
            .m``idx``_axi_awcache(m``idx``_axi_awcache), .m``idx``_axi_awprot(m``idx``_axi_awprot), \
            .m``idx``_axi_awqos(m``idx``_axi_awqos), .m``idx``_axi_awregion(m``idx``_axi_awregion), \
            .m``idx``_axi_awuser(), .m``idx``_axi_awvalid(m``idx``_axi_awvalid), .m``idx``_axi_awready(1'b1), \
            .m``idx``_axi_wdata(m``idx``_axi_wdata), .m``idx``_axi_wstrb(m``idx``_axi_wstrb), \
            .m``idx``_axi_wlast(m``idx``_axi_wlast), .m``idx``_axi_wuser(), .m``idx``_axi_wvalid(m``idx``_axi_wvalid), \
            .m``idx``_axi_wready(1'b1), .m``idx``_axi_bid(m``idx``_axi_awid), .m``idx``_axi_bresp(2'b00), \
            .m``idx``_axi_buser(1'b0), .m``idx``_axi_bvalid(m``idx``_axi_wvalid), .m``idx``_axi_bready(), \
            .m``idx``_axi_arid(m``idx``_axi_arid), .m``idx``_axi_araddr(m``idx``_axi_araddr), \
            .m``idx``_axi_arlen(m``idx``_axi_arlen), .m``idx``_axi_arsize(m``idx``_axi_arsize), \
            .m``idx``_axi_arburst(m``idx``_axi_arburst), .m``idx``_axi_arlock(m``idx``_axi_arlock), \
            .m``idx``_axi_arcache(m``idx``_axi_arcache), .m``idx``_axi_arprot(m``idx``_axi_arprot), \
            .m``idx``_axi_arqos(m``idx``_axi_arqos), .m``idx``_axi_arregion(m``idx``_axi_arregion), \
            .m``idx``_axi_aruser(), .m``idx``_axi_arvalid(m``idx``_axi_arvalid), .m``idx``_axi_arready(1'b1), \
            .m``idx``_axi_rid(m``idx``_axi_arid), .m``idx``_axi_rdata(32'd0), .m``idx``_axi_rresp(2'b00), \
            .m``idx``_axi_rlast(1'b1), .m``idx``_axi_ruser(1'b0), .m``idx``_axi_rvalid(m``idx``_axi_arvalid), \
            .m``idx``_axi_rready()

        `SINK_WIRE(08),
        `SINK_WIRE(09),
        `SINK_WIRE(10),
        `SINK_WIRE(11),
        `SINK_WIRE(12),
        `SINK_WIRE(13),
        `SINK_WIRE(14),
        `SINK_WIRE(15),
        `SINK_WIRE(16),
        `SINK_WIRE(17),
        `SINK_WIRE(18),
        `SINK_WIRE(19),

        // Boundary UART Interface (M05)
        .uart_rx_i(uart_rx),
        .uart_tx_o(uart_tx),
        .read_interrupt_o(uart_irq),

        // Boundary Timer Interface (M06)
        .sample_tick(sample_tick),
        .irq_timer(irq_timer),

        // Boundary GPIO Interface (M07)
        .gpio_in(gpio_in),
        .gpio_out(gpio_out),
        .irq_gpio(irq_gpio)
    );

    // =========================================================================
    // 5. Instruction Memory (IMEM, 64 KB at 0x1000_0000 on M00)
    // =========================================================================
    axi_ram #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .STRB_WIDTH(STRB_WIDTH),
        .ID_WIDTH(ID_WIDTH),
        .DEPTH(16384),
        .MEM_ADDR_WIDTH(14)
    ) u_imem (
        .clk(clk),
        .rst_n(rst_n),

        .s_axi_awid(m00_axi_awid),
        .s_axi_awaddr(m00_axi_awaddr),
        .s_axi_awlen(m00_axi_awlen),
        .s_axi_awsize(m00_axi_awsize),
        .s_axi_awburst(m00_axi_awburst),
        .s_axi_awlock(m00_axi_awlock),
        .s_axi_awcache(m00_axi_awcache),
        .s_axi_awprot(m00_axi_awprot),
        .s_axi_awqos(m00_axi_awqos),
        .s_axi_awregion(m00_axi_awregion),
        .s_axi_awvalid(m00_axi_awvalid),
        .s_axi_awready(m00_axi_awready),

        .s_axi_wdata(m00_axi_wdata),
        .s_axi_wstrb(m00_axi_wstrb),
        .s_axi_wlast(m00_axi_wlast),
        .s_axi_wvalid(m00_axi_wvalid),
        .s_axi_wready(m00_axi_wready),

        .s_axi_bid(m00_axi_bid),
        .s_axi_bresp(m00_axi_bresp),
        .s_axi_bvalid(m00_axi_bvalid),
        .s_axi_bready(m00_axi_bready),

        .s_axi_arid(m00_axi_arid),
        .s_axi_araddr(m00_axi_araddr),
        .s_axi_arlen(m00_axi_arlen),
        .s_axi_arsize(m00_axi_arsize),
        .s_axi_arburst(m00_axi_arburst),
        .s_axi_arlock(m00_axi_arlock),
        .s_axi_arcache(m00_axi_arcache),
        .s_axi_arprot(m00_axi_arprot),
        .s_axi_arqos(m00_axi_arqos),
        .s_axi_arregion(m00_axi_arregion),
        .s_axi_arvalid(m00_axi_arvalid),
        .s_axi_arready(m00_axi_arready),

        .s_axi_rid(m00_axi_rid),
        .s_axi_rdata(m00_axi_rdata),
        .s_axi_rresp(m00_axi_rresp),
        .s_axi_rlast(m00_axi_rlast),
        .s_axi_rvalid(m00_axi_rvalid),
        .s_axi_rready(m00_axi_rready)
    );

    // =========================================================================
    // 6. Data Memory (DMEM, 64 KB at 0x1002_0000 on M01)
    // =========================================================================
    axi_ram #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .STRB_WIDTH(STRB_WIDTH),
        .ID_WIDTH(ID_WIDTH),
        .DEPTH(16384),
        .MEM_ADDR_WIDTH(14)
    ) u_dmem (
        .clk(clk),
        .rst_n(rst_n),

        .s_axi_awid(m01_axi_awid),
        .s_axi_awaddr(m01_axi_awaddr),
        .s_axi_awlen(m01_axi_awlen),
        .s_axi_awsize(m01_axi_awsize),
        .s_axi_awburst(m01_axi_awburst),
        .s_axi_awlock(m01_axi_awlock),
        .s_axi_awcache(m01_axi_awcache),
        .s_axi_awprot(m01_axi_awprot),
        .s_axi_awqos(m01_axi_awqos),
        .s_axi_awregion(m01_axi_awregion),
        .s_axi_awvalid(m01_axi_awvalid),
        .s_axi_awready(m01_axi_awready),

        .s_axi_wdata(m01_axi_wdata),
        .s_axi_wstrb(m01_axi_wstrb),
        .s_axi_wlast(m01_axi_wlast),
        .s_axi_wvalid(m01_axi_wvalid),
        .s_axi_wready(m01_axi_wready),

        .s_axi_bid(m01_axi_bid),
        .s_axi_bresp(m01_axi_bresp),
        .s_axi_bvalid(m01_axi_bvalid),
        .s_axi_bready(m01_axi_bready),

        .s_axi_arid(m01_axi_arid),
        .s_axi_araddr(m01_axi_araddr),
        .s_axi_arlen(m01_axi_arlen),
        .s_axi_arsize(m01_axi_arsize),
        .s_axi_arburst(m01_axi_arburst),
        .s_axi_arlock(m01_axi_arlock),
        .s_axi_arcache(m01_axi_arcache),
        .s_axi_arprot(m01_axi_arprot),
        .s_axi_arqos(m01_axi_arqos),
        .s_axi_arregion(m01_axi_arregion),
        .s_axi_arvalid(m01_axi_arvalid),
        .s_axi_arready(m01_axi_arready),

        .s_axi_rid(m01_axi_rid),
        .s_axi_rdata(m01_axi_rdata),
        .s_axi_rresp(m01_axi_rresp),
        .s_axi_rlast(m01_axi_rlast),
        .s_axi_rvalid(m01_axi_rvalid),
        .s_axi_rready(m01_axi_rready)
    );



endmodule

`resetall
