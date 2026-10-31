/* =============================================================================
 * Module      : axi_i2c_top.sv
 * Description : AXI4-Lite I2C Master Controller IP
 *
 * Implements the memory-mapped register interface defined in
 * SoC_IP_Registers_Summary.xlsx:
 *   - 0x00: I2C_CTRL     [0] EN, [1] IE
 *   - 0x04: I2C_PRESCALE [15:0] DIV (SCL freq = fclk / (4 x (DIV + 1)))
 *   - 0x08: I2C_TXR      [7:0] TXDATA
 *   - 0x0C: I2C_RXR      [7:0] RXDATA (Read-only)
 *   - 0x10: I2C_CMD      [0] START, [1] STOP, [2] WR, [3] RD, [4] NACK (Write-only)
 *   - 0x14: I2C_STATUS   [0] BUSY, [1] DONE (W1C), [2] NACK_RX, [3] BUS_BUSY
 *
 * Core Logic:
 *   Wraps OpenCores i2c_master_byte_ctrl / bit_ctrl engines.
 * ============================================================================= */

`resetall
`timescale 1ns / 1ps
`default_nettype none

module axi_i2c_top #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    input  wire                  clk,
    input  wire                  rst_n,

    // -------------------------------------------------------------------------
    // AXI4-Lite Slave Interface
    // -------------------------------------------------------------------------
    input  wire [ADDR_WIDTH-1:0] s_axi_awaddr,
    input  wire                  s_axi_awvalid,
    output reg                   s_axi_awready,

    input  wire [DATA_WIDTH-1:0] s_axi_wdata,
    input  wire [3:0]            s_axi_wstrb,
    input  wire                  s_axi_wvalid,
    output reg                   s_axi_wready,

    output reg  [1:0]            s_axi_bresp,
    output reg                   s_axi_bvalid,
    input  wire                  s_axi_bready,

    input  wire [ADDR_WIDTH-1:0] s_axi_araddr,
    input  wire                  s_axi_arvalid,
    output reg                   s_axi_arready,

    output reg  [DATA_WIDTH-1:0] s_axi_rdata,
    output reg  [1:0]            s_axi_rresp,
    output reg                   s_axi_rvalid,
    input  wire                  s_axi_rready,

    // -------------------------------------------------------------------------
    // External I2C Pins (Tri-state pads)
    // -------------------------------------------------------------------------
    input  wire                  scl_pad_i,
    output wire                  scl_pad_o,
    output wire                  scl_padoen_o,

    input  wire                  sda_pad_i,
    output wire                  sda_pad_o,
    output wire                  sda_padoen_o,

    // Bidirectional convenience signals (optional, can float if using pads)
    inout  wire                  scl,
    inout  wire                  sda,

    // Interrupt Request
    output wire                  irq_i2c
);

    // Bidirectional inout connection (with internal sampling)
    assign scl = scl_padoen_o ? 1'bz : scl_pad_o;
    assign sda = sda_padoen_o ? 1'bz : sda_pad_o;

    wire internal_scl_i = scl_pad_i;
    wire internal_sda_i = sda_pad_i;

    // -------------------------------------------------------------------------
    // Internal Registers
    // -------------------------------------------------------------------------
    reg        ctrl_en;
    reg        ctrl_ie;
    reg [15:0] reg_prescale;
    reg [7:0]  reg_txr;
    reg        cmd_start;
    reg        cmd_stop;
    reg        cmd_wr;
    reg        cmd_rd;
    reg        cmd_nack;

    reg        status_done;
    reg        status_nack_rx;

    wire [7:0] byte_rxr;
    wire       byte_cmd_ack;
    wire       byte_ack_out;
    wire       byte_i2c_busy;
    wire       byte_i2c_al;

    assign irq_i2c = status_done & ctrl_ie;

    // -------------------------------------------------------------------------
    // Byte Controller Instance (OpenCores Core)
    // -------------------------------------------------------------------------
    i2c_master_byte_ctrl byte_controller (
        .clk             (clk),
        .my_addr         (7'h00),
        .rst             (~rst_n),
        .nReset          (rst_n),
        .ena             (ctrl_en),
        .clk_cnt         (reg_prescale),
        .start           (cmd_start),
        .stop            (cmd_stop),
        .read            (cmd_rd),
        .write           (cmd_wr),
        .ack_in          (cmd_nack),
        .din             (reg_txr),
        .cmd_ack         (byte_cmd_ack),
        .ack_out         (byte_ack_out),
        .dout            (byte_rxr),
        .i2c_busy        (byte_i2c_busy),
        .i2c_al          (byte_i2c_al),
        .scl_i           (internal_scl_i),
        .scl_o           (scl_pad_o),
        .scl_oen         (scl_padoen_o),
        .sda_i           (internal_sda_i),
        .sda_o           (sda_pad_o),
        .sda_oen         (sda_padoen_o),
        .sl_cont         (1'b0),
        .slave_en        (1'b0),
        .slave_dat_req   (),
        .slave_dat_avail (),
        .slave_act       (),
        .slave_cmd_ack   ()
    );

    // -------------------------------------------------------------------------
    // AXI4-Lite Write Handshake & Register Updates
    // -------------------------------------------------------------------------
    reg [ADDR_WIDTH-1:0] awaddr_latched;
    reg                  aw_done;
    reg                  w_done;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_awready  <= 1'b0;
            s_axi_wready   <= 1'b0;
            s_axi_bvalid   <= 1'b0;
            s_axi_bresp    <= 2'b00;
            aw_done        <= 1'b0;
            w_done         <= 1'b0;
            awaddr_latched <= {ADDR_WIDTH{1'b0}};

            ctrl_en        <= 1'b0;
            ctrl_ie        <= 1'b0;
            reg_prescale   <= 16'h00FF;
            reg_txr        <= 8'h00;
            cmd_start      <= 1'b0;
            cmd_stop       <= 1'b0;
            cmd_wr         <= 1'b0;
            cmd_rd         <= 1'b0;
            cmd_nack       <= 1'b0;
            status_done    <= 1'b0;
            status_nack_rx <= 1'b0;
        end else begin
            // Automatic command pulse clearing upon core acknowledgment
            if (byte_cmd_ack) begin
                cmd_start      <= 1'b0;
                cmd_stop       <= 1'b0;
                cmd_wr         <= 1'b0;
                cmd_rd         <= 1'b0;
                status_done    <= 1'b1;
                status_nack_rx <= byte_ack_out;
            end

            // Address Write Channel Handshake
            if (s_axi_awvalid && !aw_done) begin
                s_axi_awready  <= 1'b1;
                awaddr_latched <= s_axi_awaddr;
                aw_done        <= 1'b1;
            end else begin
                s_axi_awready  <= 1'b0;
            end

            // Write Data Channel Handshake
            if (s_axi_wvalid && !w_done) begin
                s_axi_wready <= 1'b1;
                w_done       <= 1'b1;
            end else begin
                s_axi_wready <= 1'b0;
            end

            // Register Update when Address and Data are Latched
            if (aw_done && w_done && !s_axi_bvalid) begin
                case (awaddr_latched[4:0])
                    5'h00: begin // I2C_CTRL
                        ctrl_en <= s_axi_wdata[0];
                        ctrl_ie <= s_axi_wdata[1];
                    end
                    5'h04: begin // I2C_PRESCALE
                        reg_prescale <= s_axi_wdata[15:0];
                    end
                    5'h08: begin // I2C_TXR
                        reg_txr <= s_axi_wdata[7:0];
                    end
                    5'h10: begin // I2C_CMD
                        cmd_start   <= s_axi_wdata[0];
                        cmd_stop    <= s_axi_wdata[1];
                        cmd_wr      <= s_axi_wdata[2];
                        cmd_rd      <= s_axi_wdata[3];
                        cmd_nack    <= s_axi_wdata[4];
                        status_done <= 1'b0; // Clear previous done on new command
                    end
                    5'h14: begin // I2C_STATUS (W1C on bit 1)
                        if (s_axi_wdata[1]) status_done <= 1'b0;
                    end
                    default: ;
                endcase
                s_axi_bvalid <= 1'b1;
                s_axi_bresp  <= 2'b00; // OKAY
            end

            if (s_axi_bvalid && s_axi_bready) begin
                s_axi_bvalid <= 1'b0;
                aw_done      <= 1'b0;
                w_done       <= 1'b0;
            end
        end
    end

    // -------------------------------------------------------------------------
    // AXI4-Lite Read Channel
    // -------------------------------------------------------------------------
    wire status_busy     = cmd_wr | cmd_rd | cmd_start | cmd_stop;
    wire status_bus_busy = byte_i2c_busy;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_arready <= 1'b0;
            s_axi_rvalid  <= 1'b0;
            s_axi_rdata   <= {DATA_WIDTH{1'b0}};
            s_axi_rresp   <= 2'b00;
        end else begin
            if (s_axi_arvalid && !s_axi_rvalid) begin
                s_axi_arready <= 1'b1;
                s_axi_rvalid  <= 1'b1;
                s_axi_rresp   <= 2'b00;

                case (s_axi_araddr[4:0])
                    5'h00: s_axi_rdata <= {30'd0, ctrl_ie, ctrl_en};
                    5'h04: s_axi_rdata <= {16'd0, reg_prescale};
                    5'h08: s_axi_rdata <= {24'd0, reg_txr};
                    5'h0C: s_axi_rdata <= {24'd0, byte_rxr};
                    5'h10: s_axi_rdata <= 32'd0; // CMD is write-only
                    5'h14: s_axi_rdata <= {28'd0, status_bus_busy, status_nack_rx, status_done, status_busy};
                    default: s_axi_rdata <= 32'd0;
                endcase
            end else begin
                s_axi_arready <= 1'b0;
            end

            if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid <= 1'b0;
            end
        end
    end

endmodule

`resetall
