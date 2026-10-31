// =============================================================================
// Module      : pwm.sv
// Description : 4-Channel Pulse Width Modulator (PWM) with AXI4-Lite Interface
// Specification: Matching doc/SoC_IP_Registers_Summary.xlsx
//   - Registers (Base: 0x4000_2000, 4KB aperture):
//       0x00: PWM_CTRL     [0] EN, [4:1] CH_EN, [8:5] POL
//       0x04: PWM_PRESCALE [15:0] DIV (tick = DIV + 1 clocks)
//       0x08: PWM_PERIOD   [15:0] PERIOD (counter wraps at PERIOD, reset 0x00FF)
//       0x0C: PWM_DUTY0    [15:0] DUTY (active while COUNT < DUTY)
//       0x10: PWM_DUTY1    [15:0] DUTY
//       0x14: PWM_DUTY2    [15:0] DUTY
//       0x18: PWM_DUTY3    [15:0] DUTY
//       0x1C: PWM_COUNT    [15:0] COUNT (RO)
//       0x20: PWM_STATUS   [0] PERIOD_DONE (W1C)
//   - Outputs:
//       pwm_out [3:0] : 4 PWM channel output pads
//       irq_pwm       : Interrupt asserted on PERIOD_DONE
// =============================================================================

`timescale 1ns / 1ps
`default_nettype none

module pwm #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    input  wire                  clk,
    input  wire                  rst_n,

    // PWM Boundary Pads
    output wire [3:0]            pwm_out,
    output wire                  irq_pwm,

    // AXI4-Lite Slave Interface
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
    input  wire                  s_axi_rready
);

    // -------------------------------------------------------------------------
    // CSR Registers
    // -------------------------------------------------------------------------
    reg        reg_en;
    reg  [3:0] reg_ch_en;
    reg  [3:0] reg_pol;
    reg [15:0] reg_prescale;
    reg [15:0] reg_period;
    reg [15:0] reg_duty0;
    reg [15:0] reg_duty1;
    reg [15:0] reg_duty2;
    reg [15:0] reg_duty3;
    reg [15:0] reg_count;
    reg        reg_period_done;

    assign irq_pwm = reg_period_done;

    // Prescaler logic
    reg [15:0] prescale_cnt;
    wire tick = (prescale_cnt >= reg_prescale);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            prescale_cnt <= 16'd0;
        end else if (reg_en) begin
            if (tick)
                prescale_cnt <= 16'd0;
            else
                prescale_cnt <= prescale_cnt + 1'b1;
        end else begin
            prescale_cnt <= 16'd0;
        end
    end

    // PWM Counter logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_count <= 16'd0;
        end else if (reg_en) begin
            if (tick) begin
                if (reg_count >= reg_period)
                    reg_count <= 16'd0;
                else
                    reg_count <= reg_count + 1'b1;
            end
        end else begin
            reg_count <= 16'd0;
        end
    end

    // Channel outputs
    wire ch0_raw = (reg_count < reg_duty0);
    wire ch1_raw = (reg_count < reg_duty1);
    wire ch2_raw = (reg_count < reg_duty2);
    wire ch3_raw = (reg_count < reg_duty3);

    wire ch0_pol = reg_pol[0] ? ~ch0_raw : ch0_raw;
    wire ch1_pol = reg_pol[1] ? ~ch1_raw : ch1_raw;
    wire ch2_pol = reg_pol[2] ? ~ch2_raw : ch2_raw;
    wire ch3_pol = reg_pol[3] ? ~ch3_raw : ch3_raw;

    assign pwm_out[0] = (reg_en && reg_ch_en[0]) ? ch0_pol : (reg_pol[0] ? 1'b1 : 1'b0);
    assign pwm_out[1] = (reg_en && reg_ch_en[1]) ? ch1_pol : (reg_pol[1] ? 1'b1 : 1'b0);
    assign pwm_out[2] = (reg_en && reg_ch_en[2]) ? ch2_pol : (reg_pol[2] ? 1'b1 : 1'b0);
    assign pwm_out[3] = (reg_en && reg_ch_en[3]) ? ch3_pol : (reg_pol[3] ? 1'b1 : 1'b0);

    // -------------------------------------------------------------------------
    // AXI4-Lite Write Channel
    // -------------------------------------------------------------------------
    reg [ADDR_WIDTH-1:0] awaddr_latched;
    reg                  aw_done;
    reg                  w_done;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_awready   <= 1'b0;
            s_axi_wready    <= 1'b0;
            s_axi_bvalid    <= 1'b0;
            s_axi_bresp     <= 2'b00;
            aw_done         <= 1'b0;
            w_done          <= 1'b0;
            awaddr_latched  <= {ADDR_WIDTH{1'b0}};

            reg_en          <= 1'b0;
            reg_ch_en       <= 4'd0;
            reg_pol         <= 4'd0;
            reg_prescale    <= 16'd0;
            reg_period      <= 16'h00FF; // Default 255
            reg_duty0       <= 16'd0;
            reg_duty1       <= 16'd0;
            reg_duty2       <= 16'd0;
            reg_duty3       <= 16'd0;
            reg_period_done <= 1'b0;
        end else begin
            // Trigger PERIOD_DONE flag
            if (reg_en && tick && (reg_count >= reg_period)) begin
                reg_period_done <= 1'b1;
            end

            // Address Write Channel
            if (s_axi_awvalid && !aw_done) begin
                s_axi_awready  <= 1'b1;
                awaddr_latched <= s_axi_awaddr;
                aw_done        <= 1'b1;
            end else begin
                s_axi_awready  <= 1'b0;
            end

            // Data Write Channel
            if (s_axi_wvalid && !w_done) begin
                s_axi_wready <= 1'b1;
                w_done       <= 1'b1;
            end else begin
                s_axi_wready <= 1'b0;
            end

            // Register updates on write
            if (aw_done && w_done && !s_axi_bvalid) begin
                case (awaddr_latched[5:0])
                    6'h00: begin
                        reg_en    <= s_axi_wdata[0];
                        reg_ch_en <= s_axi_wdata[4:1];
                        reg_pol   <= s_axi_wdata[8:5];
                    end
                    6'h04: reg_prescale <= s_axi_wdata[15:0];
                    6'h08: reg_period   <= s_axi_wdata[15:0];
                    6'h0C: reg_duty0    <= s_axi_wdata[15:0];
                    6'h10: reg_duty1    <= s_axi_wdata[15:0];
                    6'h14: reg_duty2    <= s_axi_wdata[15:0];
                    6'h18: reg_duty3    <= s_axi_wdata[15:0];
                    6'h20: begin
                        // W1C for PERIOD_DONE
                        if (s_axi_wdata[0]) reg_period_done <= 1'b0;
                    end
                    default: ;
                endcase
                s_axi_bvalid <= 1'b1;
                s_axi_bresp  <= 2'b00;
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
                case (s_axi_araddr[5:0])
                    6'h00: s_axi_rdata <= {23'd0, reg_pol, reg_ch_en, reg_en};
                    6'h04: s_axi_rdata <= {16'd0, reg_prescale};
                    6'h08: s_axi_rdata <= {16'd0, reg_period};
                    6'h0C: s_axi_rdata <= {16'd0, reg_duty0};
                    6'h10: s_axi_rdata <= {16'd0, reg_duty1};
                    6'h14: s_axi_rdata <= {16'd0, reg_duty2};
                    6'h18: s_axi_rdata <= {16'd0, reg_duty3};
                    6'h1C: s_axi_rdata <= {16'd0, reg_count};
                    6'h20: s_axi_rdata <= {31'd0, reg_period_done};
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
