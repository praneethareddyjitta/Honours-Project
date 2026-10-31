/* =============================================================================
 * Module      : tb_pwm.sv
 * Description : Verification Testbench for 4-Channel AXI4-Lite PWM Controller IP
 *               Matching doc/SoC_IP_Registers_Summary.xlsx
 * ============================================================================= */

`timescale 1ns / 1ps
`default_nettype none

module tb_pwm;

    localparam CLK_PERIOD = 10; // 100 MHz clock
    localparam ADDR_WIDTH = 32;
    localparam DATA_WIDTH = 32;

    // Registers
    localparam REG_CTRL     = 32'h00;
    localparam REG_PRESCALE = 32'h04;
    localparam REG_PERIOD   = 32'h08;
    localparam REG_DUTY0    = 32'h0C;
    localparam REG_DUTY1    = 32'h10;
    localparam REG_DUTY2    = 32'h14;
    localparam REG_DUTY3    = 32'h18;
    localparam REG_COUNT    = 32'h1C;
    localparam REG_STATUS   = 32'h20;

    logic                   clk;
    logic                   rst_n;

    // DUT I/O
    wire [3:0]              pwm_out;
    wire                    irq_pwm;

    // AXI-Lite signals
    logic [ADDR_WIDTH-1:0]  s_axi_awaddr;
    logic                   s_axi_awvalid;
    wire                    s_axi_awready;

    logic [DATA_WIDTH-1:0]  s_axi_wdata;
    logic [3:0]             s_axi_wstrb;
    logic                   s_axi_wvalid;
    wire                    s_axi_wready;

    wire [1:0]              s_axi_bresp;
    wire                    s_axi_bvalid;
    logic                   s_axi_bready;

    logic [ADDR_WIDTH-1:0]  s_axi_araddr;
    logic                   s_axi_arvalid;
    wire                    s_axi_arready;

    wire [DATA_WIDTH-1:0]   s_axi_rdata;
    wire [1:0]              s_axi_rresp;
    wire                    s_axi_rvalid;
    logic                   s_axi_rready;

    // DUT instantiation
    pwm #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) dut (
        .clk          (clk),
        .rst_n        (rst_n),
        .pwm_out      (pwm_out),
        .irq_pwm      (irq_pwm),
        .s_axi_awaddr (s_axi_awaddr),
        .s_axi_awvalid(s_axi_awvalid),
        .s_axi_awready(s_axi_awready),
        .s_axi_wdata  (s_axi_wdata),
        .s_axi_wstrb  (s_axi_wstrb),
        .s_axi_wvalid (s_axi_wvalid),
        .s_axi_wready (s_axi_wready),
        .s_axi_bresp  (s_axi_bresp),
        .s_axi_bvalid (s_axi_bvalid),
        .s_axi_bready (s_axi_bready),
        .s_axi_araddr (s_axi_araddr),
        .s_axi_arvalid(s_axi_arvalid),
        .s_axi_arready(s_axi_arready),
        .s_axi_rdata  (s_axi_rdata),
        .s_axi_rresp  (s_axi_rresp),
        .s_axi_rvalid (s_axi_rvalid),
        .s_axi_rready (s_axi_rready)
    );

    // Clock generator
    always #(CLK_PERIOD / 2) clk = ~clk;

    // AXI Write Task
    task axi_write(input [ADDR_WIDTH-1:0] addr, input [DATA_WIDTH-1:0] data);
        @(posedge clk);
        s_axi_awaddr  <= addr;
        s_axi_awvalid <= 1'b1;
        s_axi_wdata   <= data;
        s_axi_wstrb   <= 4'hF;
        s_axi_wvalid  <= 1'b1;
        s_axi_bready  <= 1'b1;

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
            end
        join

        wait(s_axi_bvalid);
        @(posedge clk);
        s_axi_bready <= 1'b0;
    endtask

    // AXI Read Task
    task axi_read(input [ADDR_WIDTH-1:0] addr, output [DATA_WIDTH-1:0] data);
        @(posedge clk);
        s_axi_araddr  <= addr;
        s_axi_arvalid <= 1'b1;
        s_axi_rready  <= 1'b1;

        wait(s_axi_arready);
        @(posedge clk);
        s_axi_arvalid <= 1'b0;

        wait(s_axi_rvalid);
        data = s_axi_rdata;
        @(posedge clk);
        s_axi_rready <= 1'b0;
    endtask

    // Measure high clocks over a given cycle period for channel 'ch'
    task measure_high_cycles(input int ch, input int total_cycles, output int high_count);
        high_count = 0;
        repeat (total_cycles) begin
            @(posedge clk);
            if (pwm_out[ch]) high_count++;
        end
    endtask

    // Main Test Sequence
    initial begin
        logic [DATA_WIDTH-1:0] rdata;
        int high_clocks;

        $display("\n==========================================================");
        $display("   STARTING 4-CHANNEL PWM CONTROLLER VERIFICATION         ");
        $display("==========================================================");

        clk           = 0;
        rst_n         = 0;
        s_axi_awaddr  = 0;
        s_axi_awvalid = 0;
        s_axi_wdata   = 0;
        s_axi_wstrb   = 0;
        s_axi_wvalid  = 0;
        s_axi_bready  = 0;
        s_axi_araddr  = 0;
        s_axi_arvalid = 0;
        s_axi_rready  = 0;

        // Reset
        #(CLK_PERIOD * 5);
        rst_n = 1;
        #(CLK_PERIOD * 5);

        // Test 1: Check Default Reset Register Values
        axi_read(REG_CTRL, rdata);
        if (rdata != 32'h0) $fatal(1, "[FAIL] REG_CTRL expected 0, got %h", rdata);
        axi_read(REG_PERIOD, rdata);
        if (rdata[15:0] != 16'h00FF) $fatal(1, "[FAIL] REG_PERIOD expected 0x00FF, got %h", rdata);
        if (pwm_out != 4'b0000) $fatal(1, "[FAIL] Default pwm_out expected 0000, got %b", pwm_out);
        $display("[PASS] Test 1: Reset defaults verified (CTRL=0, PERIOD=0xFF, PWM_OUT=0000).");

        // Test 2: Channel 0 Duty Cycle Generation (25%, 50%, 75%)
        // Set PERIOD = 255 (256 cycles)
        axi_write(REG_PERIOD, 32'd255);
        axi_write(REG_PRESCALE, 32'd0); // 1 tick per clock

        // 25% duty -> DUTY0 = 64
        axi_write(REG_DUTY0, 32'd64);
        // Enable PWM and CH0: EN=1, CH0_EN=1 -> bit 0=1, bit 1=1 -> 0x03
        axi_write(REG_CTRL, 32'h03);

        measure_high_cycles(0, 256, high_clocks);
        if (high_clocks != 64) $fatal(1, "[FAIL] CH0 25%% duty expected 64 high cycles, got %0d", high_clocks);
        $display("[PASS] Test 2A: CH0 25%% duty cycle verified (64/256 high cycles).");

        // 50% duty -> DUTY0 = 128
        axi_write(REG_DUTY0, 32'd128);
        measure_high_cycles(0, 256, high_clocks);
        if (high_clocks != 128) $fatal(1, "[FAIL] CH0 50%% duty expected 128 high cycles, got %0d", high_clocks);
        $display("[PASS] Test 2B: CH0 50%% duty cycle verified (128/256 high cycles).");

        // 75% duty -> DUTY0 = 192
        axi_write(REG_DUTY0, 32'd192);
        measure_high_cycles(0, 256, high_clocks);
        if (high_clocks != 192) $fatal(1, "[FAIL] CH0 75%% duty expected 192 high cycles, got %0d", high_clocks);
        $display("[PASS] Test 2C: CH0 75%% duty cycle verified (192/256 high cycles).");

        // Test 3: Polarity Inversion on CH0
        // CTRL: EN=1, CH0_EN=1, POL0=1 -> bit 0=1, bit 1=1, bit 5=1 -> 0x23
        axi_write(REG_CTRL, 32'h23);
        measure_high_cycles(0, 256, high_clocks);
        // Inverted 75% high should now be 25% high (64 high cycles)
        if (high_clocks != 64) $fatal(1, "[FAIL] Inverted 75%% duty expected 64 high cycles, got %0d", high_clocks);
        $display("[PASS] Test 3: Polarity inversion verified (inverted 75%% = 64 high cycles).");

        // Test 4: Multi-Channel Operation (CH0=25%, CH1=50%, CH2=75%, CH3=100%)
        axi_write(REG_DUTY0, 32'd64);
        axi_write(REG_DUTY1, 32'd128);
        axi_write(REG_DUTY2, 32'd192);
        axi_write(REG_DUTY3, 32'd256);
        // CTRL: EN=1, CH[3:0]_EN=4'b1111 (bits 4:1), POL=4'b0000 -> 0x001F
        axi_write(REG_CTRL, 32'h1F);

        fork
            measure_high_cycles(0, 256, high_clocks);
        join
        if (high_clocks != 64) $fatal(1, "[FAIL] Multi-channel CH0 expected 64, got %0d", high_clocks);

        fork
            measure_high_cycles(1, 256, high_clocks);
        join
        if (high_clocks != 128) $fatal(1, "[FAIL] Multi-channel CH1 expected 128, got %0d", high_clocks);

        fork
            measure_high_cycles(2, 256, high_clocks);
        join
        if (high_clocks != 192) $fatal(1, "[FAIL] Multi-channel CH2 expected 192, got %0d", high_clocks);

        fork
            measure_high_cycles(3, 256, high_clocks);
        join
        if (high_clocks != 256) $fatal(1, "[FAIL] Multi-channel CH3 expected 256, got %0d", high_clocks);
        $display("[PASS] Test 4: Multi-channel independent duties verified (CH0:25%%, CH1:50%%, CH2:75%%, CH3:100%%).");

        // Test 5: Interrupt on PERIOD_DONE and W1C
        // Wait for irq_pwm to assert
        wait(irq_pwm == 1'b1);
        axi_read(REG_STATUS, rdata);
        if (rdata[0] != 1'b1) $fatal(1, "[FAIL] Expected STATUS[0] PERIOD_DONE=1");
        $display("[PASS] Test 5A: PERIOD_DONE status and irq_pwm asserted.");

        // Clear interrupt with W1C (write 1 to bit 0)
        axi_write(REG_STATUS, 32'h01);
        #1;
        if (irq_pwm != 1'b0) $fatal(1, "[FAIL] Expected irq_pwm to clear after W1C");
        axi_read(REG_STATUS, rdata);
        if (rdata[0] != 1'b0) $fatal(1, "[FAIL] Expected STATUS[0] cleared to 0");
        $display("[PASS] Test 5B: PERIOD_DONE cleared via W1C.");

        $display("\n==========================================================");
        $display("   ALL 4-CHANNEL PWM TESTS PASSED SUCCESSFULLY!          ");
        $display("==========================================================\n");
        $finish;
    end

endmodule

`resetall
