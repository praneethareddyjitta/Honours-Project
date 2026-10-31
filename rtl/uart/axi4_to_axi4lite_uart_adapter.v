// -----------------------------------------------------------------------------
// axi4_to_axi4lite_uart_adapter.v            (Verilog-2001, synthesizable)
//
// AXI4 slave (one Mxx port of axi_interconnect_wrap_3x10)
//   -> AXI4-Lite master (axi_uart_top from axi-lite_uart-ipcore)
//
// Every width / behaviour below was taken from the uploaded sources:
//   * Slave side  : axi_interconnect_wrap_3x10.v / axi_interconnect.v
//                   (DATA_WIDTH=32, ADDR_WIDTH=32, ID_WIDTH=8, USER widths=1,
//                    clk + active-HIGH synchronous rst, full AXI4 signal set)
//   * Master side : axi_uart_top.v, axi_uart_defines.vh, axi_uart.vh
//                   (32-bit data, 5-bit address, 12-bit ID, 2-bit resp,
//                    active-LOW async reset, no PROT/LEN/SIZE/LAST signals)
//
// UART / interconnect facts that shaped this design
// --------------------------------------------------
//  U1. The UART only progresses when AWVALID & WVALID are high in the same
//      cycle (wren = awvalid & wvalid).  -> adapter buffers AW and W
//      independently, then presents both together.
//  U2. UART B and R responses are ONE-cycle pulses, asserted in the same
//      cycle as the AW/W (or AR) handshake, and BREADY/RREADY are ignored.
//      -> adapter keeps m_axil_bready / m_axil_rready high while a UART
//         response is outstanding and holds the response in its own register
//         until the AXI4 master asserts BREADY / RREADY.
//  U3. A UART read of any register other than RBR(0)/LSR(5) never completes
//      (read FSM 'default' branch loops forever).  -> adapter never forwards
//      such reads; it answers them itself with UNMAPPED_RESP.
//  U4. The UART ignores WSTRB, decodes only addr[4:2] and treats DIV/LCR as
//      full 32-bit registers.  -> STRICT_WSTRB rejects writes whose strobes
//      would corrupt a register; addr bits above the register block are
//      checked (REGION_ADDR_WIDTH) so the 32-byte map does not alias across
//      the whole interconnect region.
//  I1. The interconnect ends a read only on RLAST=1 and a write only after it
//      has pushed WLAST and received a B.  -> RLAST is always driven, and the
//      adapter always consumes W beats up to WLAST and returns exactly
//      ARLEN+1 R beats for rejected read bursts.
//  I2. The interconnect ignores BID/RID coming from the slave and uses its own
//      stored ID.  The adapter still returns the captured ID.
//
// Reset: 'rst' is active-HIGH synchronous (same as the interconnect).
//        'uart_aresetn' is a registered active-LOW copy for the UART's
//        async active-LOW reset.
// -----------------------------------------------------------------------------
`resetall
//`timescale 1ns / 1ps
`default_nettype none

module axi4_to_axi4lite_uart_adapter #
(
    // ---- AXI4 side: must match the interconnect wrapper instance ----------
    parameter DATA_WIDTH   = 32,   // must be 32 (UART is fixed 32-bit)
    parameter ADDR_WIDTH   = 32,
    parameter STRB_WIDTH   = (DATA_WIDTH/8),
    parameter ID_WIDTH     = 8,
    parameter AWUSER_WIDTH = 1,
    parameter WUSER_WIDTH  = 1,
    parameter BUSER_WIDTH  = 1,
    parameter ARUSER_WIDTH = 1,
    parameter RUSER_WIDTH  = 1,

    // ---- UART side (axi_uart_defines.vh) -----------------------------------
    parameter UART_ADDR_WIDTH = 5,   // _AXI_UART_ADDR_WIDTH_
    parameter UART_ID_WIDTH   = 12,  // _AXI_UART_ID_WIDTH_

    // ---- Address-window policy ---------------------------------------------
    // Size (log2 bytes) of the interconnect region this adapter sits behind,
    // i.e. the MNN_ADDR_WIDTH used for its Mxx port (wrapper default: 24).
    // Offsets inside the region but beyond the 2^UART_ADDR_WIDTH register
    // block get DECERR instead of aliasing.  Set to UART_ADDR_WIDTH (or
    // lower) to disable the check.
    parameter REGION_ADDR_WIDTH = 24,

    // ---- Error policy -------------------------------------------------------
    parameter [1:0] UNMAPPED_RESP = 2'b10, // reads of IER/DIV/LCR/reserved,
                                           // writes to LSR/reserved. 2'b00 =
                                           // silently absorb (reads return 0)
    parameter [1:0] BURST_RESP    = 2'b10, // AxLEN != 0 or illegal AxSIZE
    parameter [1:0] RANGE_RESP    = 2'b11, // offset outside UART block
    parameter [1:0] STRB_RESP     = 2'b10, // STRICT_WSTRB violation
    parameter       STRICT_WSTRB  = 1      // 1: reject writes with strobes
                                           //    that would corrupt the UART
                                           //    (see reg_wstrb_ok below)
)
(
    input  wire                      clk,
    input  wire                      rst,            // active-HIGH, synchronous

    // ------------------------------------------------------------------
    // AXI4 slave  (connect to interconnect mNN_axi_* outputs/inputs)
    // ------------------------------------------------------------------
    input  wire [ID_WIDTH-1:0]       s_axi_awid,
    input  wire [ADDR_WIDTH-1:0]     s_axi_awaddr,
    input  wire [7:0]                s_axi_awlen,
    input  wire [2:0]                s_axi_awsize,
    input  wire [1:0]                s_axi_awburst,
    input  wire                      s_axi_awlock,
    input  wire [3:0]                s_axi_awcache,
    input  wire [2:0]                s_axi_awprot,
    input  wire [3:0]                s_axi_awqos,
    input  wire [3:0]                s_axi_awregion,
    input  wire [AWUSER_WIDTH-1:0]   s_axi_awuser,
    input  wire                      s_axi_awvalid,
    output wire                      s_axi_awready,
    input  wire [DATA_WIDTH-1:0]     s_axi_wdata,
    input  wire [STRB_WIDTH-1:0]     s_axi_wstrb,
    input  wire                      s_axi_wlast,
    input  wire [WUSER_WIDTH-1:0]    s_axi_wuser,
    input  wire                      s_axi_wvalid,
    output wire                      s_axi_wready,
    output wire [ID_WIDTH-1:0]       s_axi_bid,
    output wire [1:0]                s_axi_bresp,
    output wire [BUSER_WIDTH-1:0]    s_axi_buser,
    output wire                      s_axi_bvalid,
    input  wire                      s_axi_bready,
    input  wire [ID_WIDTH-1:0]       s_axi_arid,
    input  wire [ADDR_WIDTH-1:0]     s_axi_araddr,
    input  wire [7:0]                s_axi_arlen,
    input  wire [2:0]                s_axi_arsize,
    input  wire [1:0]                s_axi_arburst,
    input  wire                      s_axi_arlock,
    input  wire [3:0]                s_axi_arcache,
    input  wire [2:0]                s_axi_arprot,
    input  wire [3:0]                s_axi_arqos,
    input  wire [3:0]                s_axi_arregion,
    input  wire [ARUSER_WIDTH-1:0]   s_axi_aruser,
    input  wire                      s_axi_arvalid,
    output wire                      s_axi_arready,
    output wire [ID_WIDTH-1:0]       s_axi_rid,
    output wire [DATA_WIDTH-1:0]     s_axi_rdata,
    output wire [1:0]                s_axi_rresp,
    output wire                      s_axi_rlast,
    output wire [RUSER_WIDTH-1:0]    s_axi_ruser,
    output wire                      s_axi_rvalid,
    input  wire                      s_axi_rready,

    // ------------------------------------------------------------------
    // AXI4-Lite master (connect to axi_uart_top axi_*_i / axi_*_o)
    // ------------------------------------------------------------------
    output wire                      uart_aresetn,   // -> axi_aresetn_i

    output wire [UART_ID_WIDTH-1:0]  m_axil_awid,
    output wire [UART_ADDR_WIDTH-1:0] m_axil_awaddr,
    output wire                      m_axil_awvalid,
    input  wire                      m_axil_awready,
    output wire [DATA_WIDTH-1:0]     m_axil_wdata,
    output wire [STRB_WIDTH-1:0]     m_axil_wstrb,
    output wire                      m_axil_wvalid,
    input  wire                      m_axil_wready,
    input  wire [UART_ID_WIDTH-1:0]  m_axil_bid,     // unused (ID kept internally)
    input  wire [1:0]                m_axil_bresp,
    input  wire                      m_axil_bvalid,
    output wire                      m_axil_bready,
    output wire [UART_ID_WIDTH-1:0]  m_axil_arid,
    output wire [UART_ADDR_WIDTH-1:0] m_axil_araddr,
    output wire                      m_axil_arvalid,
    input  wire                      m_axil_arready,
    input  wire [UART_ID_WIDTH-1:0]  m_axil_rid,     // unused (ID kept internally)
    input  wire [DATA_WIDTH-1:0]     m_axil_rdata,
    input  wire [1:0]                m_axil_rresp,
    input  wire                      m_axil_rvalid,
    output wire                      m_axil_rready
);

// ---------------------------------------------------------------------------
// Static configuration checks (simulation only)
// ---------------------------------------------------------------------------
// synthesis translate_off
initial begin
    if (DATA_WIDTH != 32) begin
        $display("ERROR: %m DATA_WIDTH must be 32 (axi_uart_top is fixed 32-bit)");
        $finish;
    end
    if (ADDR_WIDTH < UART_ADDR_WIDTH) begin
        $display("ERROR: %m ADDR_WIDTH must be >= UART_ADDR_WIDTH");
        $finish;
    end
end
// synthesis translate_on

// ---------------------------------------------------------------------------
// Constants taken from axi_uart.vh (register word index = addr[4:2])
// ---------------------------------------------------------------------------
localparam [2:0] REG_RBR_THR = 3'd0;   // _UART_RBR_ / _UART_THR_
localparam [2:0] REG_IER     = 3'd1;   // _UART_IER_
localparam [2:0] REG_DIV     = 3'd2;   // _UART_BAUD_DIVISOR_
localparam [2:0] REG_LCR     = 3'd3;   // _UART_LCR_
localparam [2:0] REG_LSR     = 3'd5;   // _UART_LSR_

localparam [1:0] RESP_OKAY = 2'b00;

// log2 of bytes per beat supported by the bus (32-bit -> 2)
localparam [2:0] MAX_SIZE = (STRB_WIDTH >= 128) ? 3'd7 :
                            (STRB_WIDTH >=  64) ? 3'd6 :
                            (STRB_WIDTH >=  32) ? 3'd5 :
                            (STRB_WIDTH >=  16) ? 3'd4 :
                            (STRB_WIDTH >=   8) ? 3'd3 :
                            (STRB_WIDTH >=   4) ? 3'd2 :
                            (STRB_WIDTH >=   2) ? 3'd1 : 3'd0;

// Mask of address bits that lie inside the region but outside the UART block
localparam [ADDR_WIDTH-1:0] REGION_MASK =
    (REGION_ADDR_WIDTH > UART_ADDR_WIDTH) ?
        ( ({ADDR_WIDTH{1'b1}} >> (ADDR_WIDTH - REGION_ADDR_WIDTH))
        & ~({ADDR_WIDTH{1'b1}} >> (ADDR_WIDTH - UART_ADDR_WIDTH)) ) :
        {ADDR_WIDTH{1'b0}};

// ID zero-extension / truncation helper width
localparam ID_MAX = (ID_WIDTH > UART_ID_WIDTH) ? ID_WIDTH : UART_ID_WIDTH;

// ---------------------------------------------------------------------------
// Reset for the UART (registered, active-LOW)
// ---------------------------------------------------------------------------
reg uart_aresetn_reg = 1'b0;
always @(posedge clk) uart_aresetn_reg <= ~rst;
assign uart_aresetn = uart_aresetn_reg;

// ---------------------------------------------------------------------------
// Register-map helper functions
// ---------------------------------------------------------------------------
// Which register word indices exist for reads / writes
function reg_rd_ok(input [2:0] idx);
    reg_rd_ok = (idx == REG_RBR_THR) || (idx == REG_LSR);
endfunction

function reg_wr_ok(input [2:0] idx);
    reg_wr_ok = (idx == REG_RBR_THR) || (idx == REG_IER) ||
                (idx == REG_DIV)     || (idx == REG_LCR);
endfunction

// Strobes the UART needs to update a register correctly (U4):
//   THR uses wdata[7:0], IER uses wdata[0], LCR uses bits <=7  -> lane 0
//   DIV is a full 32-bit register                              -> all lanes
function reg_wstrb_ok(input [2:0] idx, input [STRB_WIDTH-1:0] strb);
    begin
        if (idx == REG_DIV)
            reg_wstrb_ok = &strb;
        else
            reg_wstrb_ok = strb[0];
    end
endfunction

// ===========================================================================
//                               WRITE PATH
// ===========================================================================
localparam [1:0] W_IDLE = 2'd0,   // collecting AW and W (independently)
                 W_UART = 2'd1,   // AXI4-Lite write in flight
                 W_RESP = 2'd2;   // holding B towards AXI4 master

reg [1:0] w_state = W_IDLE;

// captured AW
reg                  aw_got  = 1'b0;
reg [ID_WIDTH-1:0]   aw_id   = {ID_WIDTH{1'b0}};
reg [ADDR_WIDTH-1:0] aw_addr = {ADDR_WIDTH{1'b0}};
reg [7:0]            aw_len  = 8'd0;
reg [2:0]            aw_size = 3'd0;
// captured W (first beat)
reg                  w_got       = 1'b0;
reg                  w_last_seen = 1'b0;   // a beat with WLAST accepted
reg                  w_first_last = 1'b0;  // WLAST of first beat
reg [DATA_WIDTH-1:0] w_data = {DATA_WIDTH{1'b0}};
reg [STRB_WIDTH-1:0] w_strb = {STRB_WIDTH{1'b0}};

// UART-side write handshake registers
reg                  uw_awvalid = 1'b0;
reg                  uw_wvalid  = 1'b0;
reg                  uw_bready  = 1'b0;
reg [1:0]            uw_bresp = 2'b00;

// response to AXI4 master
reg                  b_valid = 1'b0;
reg [1:0]            b_resp = 2'b00;

wire [2:0] aw_idx = aw_addr[4:2];

// Accept AW only while collecting and none captured; accept W beats while
// collecting until WLAST has been taken.  After the first beat, extra beats
// are only accepted when they are already known to belong to a burst
// (first beat had WLAST=0), and are discarded.
assign s_axi_awready = (w_state == W_IDLE) && !aw_got;
assign s_axi_wready  = (w_state == W_IDLE) && !w_last_seen;

wire aw_hs = s_axi_awvalid && s_axi_awready;
wire w_hs  = s_axi_wvalid  && s_axi_wready;

// classification of a fully collected write (uses registered values only)
wire w_burst_err  = (aw_len != 8'd0) || (aw_size > MAX_SIZE) || !w_first_last;
wire w_range_err  = |(aw_addr & REGION_MASK);
wire w_unmap_err  = !reg_wr_ok(aw_idx);
wire w_zero_strb  = (w_strb == {STRB_WIDTH{1'b0}});
wire w_strb_err   = (STRICT_WSTRB != 0) && !reg_wstrb_ok(aw_idx, w_strb);

wire uw_aw_hs = uw_awvalid && m_axil_awready;
wire uw_w_hs  = uw_wvalid  && m_axil_wready;
wire uw_b_hs  = uw_bready  && m_axil_bvalid;

wire uw_aw_next = uw_awvalid && !m_axil_awready;
wire uw_w_next  = uw_wvalid  && !m_axil_wready;
wire uw_b_next  = uw_bready  && !m_axil_bvalid;

always @(posedge clk) begin
    if (rst) begin
        w_state      <= W_IDLE;
        aw_got       <= 1'b0;
        w_got        <= 1'b0;
        w_last_seen  <= 1'b0;
        uw_awvalid   <= 1'b0;
        uw_wvalid    <= 1'b0;
        uw_bready    <= 1'b0;
        b_valid      <= 1'b0;
    end else begin
        case (w_state)
        // ------------------------------------------------------------------
        W_IDLE: begin
            if (aw_hs) begin
                aw_got  <= 1'b1;
                aw_id   <= s_axi_awid;
                aw_addr <= s_axi_awaddr;
                aw_len  <= s_axi_awlen;
                aw_size <= s_axi_awsize;
            end
            if (w_hs) begin
                if (!w_got) begin               // first beat: keep it
                    w_got        <= 1'b1;
                    w_data       <= s_axi_wdata;
                    w_strb       <= s_axi_wstrb;
                    w_first_last <= s_axi_wlast;
                end
                if (s_axi_wlast) w_last_seen <= 1'b1;
            end

            // everything received -> decide (registered flags, no bypass)
            if (aw_got && w_got && w_last_seen) begin
                if (w_burst_err) begin
                    b_resp  <= BURST_RESP;   b_valid <= 1'b1; w_state <= W_RESP;
                end else if (w_range_err) begin
                    b_resp  <= RANGE_RESP;   b_valid <= 1'b1; w_state <= W_RESP;
                end else if (w_zero_strb) begin
                    b_resp  <= RESP_OKAY;    b_valid <= 1'b1; w_state <= W_RESP;
                end else if (w_unmap_err) begin
                    b_resp  <= UNMAPPED_RESP; b_valid <= 1'b1; w_state <= W_RESP;
                end else if (w_strb_err) begin
                    b_resp  <= STRB_RESP;    b_valid <= 1'b1; w_state <= W_RESP;
                end else begin
                    uw_awvalid <= 1'b1;
                    uw_wvalid  <= 1'b1;
                    uw_bready  <= 1'b1;      // U2: must be ready before the pulse
                    w_state    <= W_UART;
                end
            end
        end
        // ------------------------------------------------------------------
        W_UART: begin
            // hold VALIDs until READY
            uw_awvalid <= uw_aw_next;
            uw_wvalid  <= uw_w_next;
            uw_bready  <= uw_b_next;
            if (uw_b_hs) uw_bresp <= m_axil_bresp;

            // finished when both handshakes and B are done
            if (!uw_aw_next && !uw_w_next && !uw_b_next) begin
                b_resp  <= uw_b_hs ? m_axil_bresp : uw_bresp;
                b_valid <= 1'b1;
                w_state <= W_RESP;
            end
        end
        // ------------------------------------------------------------------
        W_RESP: begin
            if (s_axi_bready) begin       // B held until BREADY
                b_valid     <= 1'b0;
                aw_got      <= 1'b0;
                w_got       <= 1'b0;
                w_last_seen <= 1'b0;
                w_state     <= W_IDLE;
            end
        end
        default: w_state <= W_IDLE;
        endcase
    end
end

assign s_axi_bid    = aw_id;
assign s_axi_bresp  = b_resp;
assign s_axi_bvalid = b_valid;
assign s_axi_buser  = {BUSER_WIDTH{1'b0}};

// AXI4-Lite write channel outputs
wire [ID_MAX-1:0] aw_id_ext = aw_id;
assign m_axil_awid    = aw_id_ext[UART_ID_WIDTH-1:0];
assign m_axil_awaddr  = aw_addr[UART_ADDR_WIDTH-1:0];
assign m_axil_awvalid = uw_awvalid;
assign m_axil_wdata   = w_data;
assign m_axil_wstrb   = w_strb;
assign m_axil_wvalid  = uw_wvalid;
assign m_axil_bready  = uw_bready;

// ===========================================================================
//                               READ PATH
// ===========================================================================
localparam [1:0] R_IDLE = 2'd0,   // accepting AR
                 R_UART = 2'd1,   // AXI4-Lite read in flight
                 R_RESP = 2'd2,   // holding single R beat
                 R_ERR  = 2'd3;   // returning ARLEN+1 error beats

reg [1:0] r_state = R_IDLE;

reg [ID_WIDTH-1:0]   ar_id = {ID_WIDTH{1'b0}};
reg [ADDR_WIDTH-1:0] ar_addr = {ADDR_WIDTH{1'b0}};
reg [7:0]            ar_cnt = 8'd0;       // remaining beats - 1 (error path)

reg                  ur_arvalid = 1'b0;
reg                  ur_rready  = 1'b0;

reg                  r_valid = 1'b0;
reg                  r_last = 1'b0;
reg [1:0]            r_resp = 2'b00;
reg [DATA_WIDTH-1:0] r_data = {DATA_WIDTH{1'b0}};

assign s_axi_arready = (r_state == R_IDLE);
wire ar_hs = s_axi_arvalid && s_axi_arready;

wire [2:0] ar_idx_in = s_axi_araddr[4:2];
wire r_burst_err = (s_axi_arlen != 8'd0) || (s_axi_arsize > MAX_SIZE);
wire r_range_err = |(s_axi_araddr & REGION_MASK);
wire r_unmap_err = !reg_rd_ok(ar_idx_in);       // U3

wire ur_ar_next = ur_arvalid && !m_axil_arready;
wire ur_r_hs    = ur_rready  &&  m_axil_rvalid;
wire ur_r_next  = ur_rready  && !m_axil_rvalid;

always @(posedge clk) begin
    if (rst) begin
        r_state    <= R_IDLE;
        ur_arvalid <= 1'b0;
        ur_rready  <= 1'b0;
        r_valid    <= 1'b0;
    end else begin
        case (r_state)
        // ------------------------------------------------------------------
        R_IDLE: begin
            if (ar_hs) begin
                ar_id   <= s_axi_arid;
                ar_addr <= s_axi_araddr;
                ar_cnt  <= s_axi_arlen;
                if (r_burst_err || r_range_err || r_unmap_err) begin
                    // reject locally; never touch the UART (U3 / I1)
                    r_resp  <= r_burst_err ? BURST_RESP :
                               r_range_err ? RANGE_RESP : UNMAPPED_RESP;
                    r_data  <= {DATA_WIDTH{1'b0}};
                    r_valid <= 1'b1;
                    r_last  <= (r_burst_err ? (s_axi_arlen == 8'd0) : 1'b1);
                    if (!r_burst_err) ar_cnt <= 8'd0;   // single beat
                    r_state <= R_ERR;
                end else begin
                    ur_arvalid <= 1'b1;
                    ur_rready  <= 1'b1;                 // U2
                    r_state    <= R_UART;
                end
            end
        end
        // ------------------------------------------------------------------
        R_UART: begin
            ur_arvalid <= ur_ar_next;                   // hold until ARREADY
            ur_rready  <= ur_r_next;
            if (ur_r_hs) begin
                r_data <= m_axil_rdata;
                r_resp <= m_axil_rresp;
            end
            if (!ur_ar_next && !ur_r_next) begin
                r_last  <= 1'b1;                        // I1: RLAST mandatory
                r_valid <= 1'b1;
                r_state <= R_RESP;
            end
        end
        // ------------------------------------------------------------------
        R_RESP: begin
            if (s_axi_rready) begin                     // R held until RREADY
                r_valid <= 1'b0;
                r_state <= R_IDLE;
            end
        end
        // ------------------------------------------------------------------
        R_ERR: begin
            if (s_axi_rready) begin
                if (ar_cnt == 8'd0) begin
                    r_valid <= 1'b0;
                    r_state <= R_IDLE;
                end else begin
                    ar_cnt <= ar_cnt - 8'd1;
                    r_last <= (ar_cnt == 8'd1);
                end
            end
        end
        default: r_state <= R_IDLE;
        endcase
    end
end

wire [ID_MAX-1:0] ar_id_ext = ar_id;
assign m_axil_arid    = ar_id_ext[UART_ID_WIDTH-1:0];
assign m_axil_araddr  = ar_addr[UART_ADDR_WIDTH-1:0];
assign m_axil_arvalid = ur_arvalid;
assign m_axil_rready  = ur_rready;

assign s_axi_rid    = ar_id;
assign s_axi_rdata  = r_data;
assign s_axi_rresp  = r_resp;
assign s_axi_rlast  = r_last;
assign s_axi_ruser  = {RUSER_WIDTH{1'b0}};
assign s_axi_rvalid = r_valid;

// ar_addr must be valid while ARVALID to the UART is asserted: it is
// registered on the AR handshake, one cycle before ur_arvalid rises.

endmodule

`resetall
