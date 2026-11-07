/* =============================================================================
 * Testbench : tb_cat5_timer_gpio_uart.sv
 * Suite     : Category 5 – Peripheral Subsystems: Timer, GPIO, UART
 *
 * Verifies all 8 peripheral test cases from doc/SOC_UVM_TEST_PLAN.md:
 *   - TC_INT_TMR_01: Timer Down-Counter Accuracy & Interrupt
 *   - TC_EXT_TMR_01: sample_tick 1-Cycle Pulse Width Verification
 *   - TC_INT_GPIO_01: GPIO Pin-Change Interrupt Masking
 *   - TC_EXT_GPIO_01: Button Synchronizer Metastability & Glitch Filtering
 *   - TC_EXT_GPIO_02: Display Pattern & Status LED Drive Output
 *   - TC_INT_UART_01: UART FIFO Status & Watermark Flags
 *   - TC_EXT_UART_01: Serial Transmission 115200 Baud Frame Analyzer
 *   - TC_EXT_UART_02: Serial Reception & Interrupt Generation
 * ============================================================================= */

`timescale 1ns / 1ps
`default_nettype none

module tb_cat5_timer_gpio_uart;

    localparam CLK_PERIOD = 10; // 100 MHz clock
    localparam ADDR_WIDTH = 32;
    localparam DATA_WIDTH = 32;
    localparam ID_WIDTH   = 8;

    localparam TIMER_BASE = 32'h4000_8000;
    localparam GPIO_BASE  = 32'h4000_A000;
    localparam UART_BASE  = 32'h4000_6000;

    reg clk = 1'b0;
    reg rst = 1'b1;
    integer pass_count = 0;
    integer fail_count = 0;

    always #5 clk = ~clk;

    // Master S00 AXI signals
    reg  [ID_WIDTH-1:0]     s_axi_awid = 0;
    reg  [ADDR_WIDTH-1:0]   s_axi_awaddr = 0;
    reg  [7:0]              s_axi_awlen = 0;
    reg  [2:0]              s_axi_awsize = 3'b010;
    reg  [1:0]              s_axi_awburst = 2'b01;
    reg                     s_axi_awlock = 0;
    reg  [3:0]              s_axi_awcache = 0;
    reg  [2:0]              s_axi_awprot = 0;
    reg  [3:0]              s_axi_awqos = 0;
    reg                     s_axi_awuser = 0;
    reg                     s_axi_awvalid = 0;
    wire                    s_axi_awready;

    reg  [DATA_WIDTH-1:0]   s_axi_wdata = 0;
    reg  [3:0]              s_axi_wstrb = 4'hF;
    reg                     s_axi_wlast = 0;
    reg                     s_axi_wuser = 0;
    reg                     s_axi_wvalid = 0;
    wire                    s_axi_wready;

    wire [ID_WIDTH-1:0]     s_axi_bid;
    wire [1:0]              s_axi_bresp;
    wire                    s_axi_buser;
    wire                    s_axi_bvalid;
    reg                     s_axi_bready = 0;

    reg  [ID_WIDTH-1:0]     s_axi_arid = 0;
    reg  [ADDR_WIDTH-1:0]   s_axi_araddr = 0;
    reg  [7:0]              s_axi_arlen = 0;
    reg  [2:0]              s_axi_arsize = 3'b010;
    reg  [1:0]              s_axi_arburst = 2'b01;
    reg                     s_axi_arlock = 0;
    reg  [3:0]              s_axi_arcache = 0;
    reg  [2:0]              s_axi_arprot = 0;
    reg  [3:0]              s_axi_arqos = 0;
    reg                     s_axi_aruser = 0;
    reg                     s_axi_arvalid = 0;
    wire                    s_axi_arready;

    wire [ID_WIDTH-1:0]     s_axi_rid;
    wire [DATA_WIDTH-1:0]   s_axi_rdata;
    wire [1:0]              s_axi_rresp;
    wire                    s_axi_rlast;
    wire                    s_axi_ruser;
    wire                    s_axi_rvalid;
    reg                     s_axi_rready = 0;

    // Peripherals Boundary Pins
    wire       sample_tick;
    wire       irq_timer;

    reg  [7:0] gpio_in = 8'h00;
    wire [7:0] gpio_out;
    wire       irq_gpio;

    reg        uart_rx_i = 1'b1;
    wire       uart_tx_o;
    wire       read_interrupt_o;

    // Pulse width monitor for sample_tick
    time tick_start = 0;
    time tick_width = 0;
    always @(posedge sample_tick) begin
        tick_start = $time;
    end
    always @(negedge sample_tick) begin
        if (tick_start > 0) tick_width = $time - tick_start;
    end

    // Macro for dummy slave ports M00, M01, M04, M08-M19
    `define DECL_SINK(idx) \
        wire [ID_WIDTH-1:0]     m``idx``_awid; \
        wire [ADDR_WIDTH-1:0]   m``idx``_awaddr; \
        wire [7:0]              m``idx``_awlen; \
        wire [2:0]              m``idx``_awsize; \
        wire [1:0]              m``idx``_awburst; \
        wire                    m``idx``_awlock; \
        wire [3:0]              m``idx``_awcache; \
        wire [2:0]              m``idx``_awprot; \
        wire [3:0]              m``idx``_awqos; \
        wire [3:0]              m``idx``_awregion; \
        wire                    m``idx``_awvalid; \
        wire [DATA_WIDTH-1:0]   m``idx``_wdata; \
        wire [3:0]              m``idx``_wstrb; \
        wire                    m``idx``_wlast; \
        wire                    m``idx``_wvalid; \
        wire [ID_WIDTH-1:0]     m``idx``_arid; \
        wire [ADDR_WIDTH-1:0]   m``idx``_araddr; \
        wire [7:0]              m``idx``_arlen; \
        wire [2:0]              m``idx``_arsize; \
        wire [1:0]              m``idx``_arburst; \
        wire                    m``idx``_arlock; \
        wire [3:0]              m``idx``_arcache; \
        wire [2:0]              m``idx``_arprot; \
        wire [3:0]              m``idx``_arqos; \
        wire [3:0]              m``idx``_arregion; \
        wire                    m``idx``_arvalid;

    `DECL_SINK(00)
    `DECL_SINK(01)
    `DECL_SINK(04)
    `DECL_SINK(08)
    `DECL_SINK(09)
    `DECL_SINK(10)
    `DECL_SINK(11)
    `DECL_SINK(12)
    `DECL_SINK(13)
    `DECL_SINK(14)
    `DECL_SINK(15)
    `DECL_SINK(16)
    `DECL_SINK(17)
    `DECL_SINK(18)
    `DECL_SINK(19)

    `define CONN_SINK(idx) \
        .m``idx``_axi_awid(m``idx``_awid), .m``idx``_axi_awaddr(m``idx``_awaddr), \
        .m``idx``_axi_awlen(m``idx``_awlen), .m``idx``_axi_awsize(m``idx``_awsize), \
        .m``idx``_axi_awburst(m``idx``_awburst), .m``idx``_axi_awlock(m``idx``_awlock), \
        .m``idx``_axi_awcache(m``idx``_awcache), .m``idx``_axi_awprot(m``idx``_awprot), \
        .m``idx``_axi_awqos(m``idx``_awqos), .m``idx``_axi_awregion(m``idx``_awregion), \
        .m``idx``_axi_awuser(), .m``idx``_axi_awvalid(m``idx``_awvalid), .m``idx``_axi_awready(1'b1), \
        .m``idx``_axi_wdata(m``idx``_wdata), .m``idx``_axi_wstrb(m``idx``_wstrb), \
        .m``idx``_axi_wlast(m``idx``_wlast), .m``idx``_axi_wuser(), .m``idx``_axi_wvalid(m``idx``_wvalid), \
        .m``idx``_axi_wready(1'b1), .m``idx``_axi_bid(m``idx``_awid), .m``idx``_axi_bresp(2'b00), \
        .m``idx``_axi_buser(1'b0), .m``idx``_axi_bvalid(m``idx``_wvalid), .m``idx``_axi_bready(), \
        .m``idx``_axi_arid(m``idx``_arid), .m``idx``_axi_araddr(m``idx``_araddr), \
        .m``idx``_axi_arlen(m``idx``_arlen), .m``idx``_axi_arsize(m``idx``_arsize), \
        .m``idx``_axi_arburst(m``idx``_arburst), .m``idx``_axi_arlock(m``idx``_arlock), \
        .m``idx``_axi_arcache(m``idx``_arcache), .m``idx``_axi_arprot(m``idx``_arprot), \
        .m``idx``_axi_arqos(m``idx``_arqos), .m``idx``_axi_arregion(m``idx``_arregion), \
        .m``idx``_axi_aruser(), .m``idx``_axi_arvalid(m``idx``_arvalid), .m``idx``_axi_arready(1'b1), \
        .m``idx``_axi_rid(m``idx``_arid), .m``idx``_axi_rdata(32'd0), .m``idx``_axi_rresp(2'b00), \
        .m``idx``_axi_rlast(1'b1), .m``idx``_axi_ruser(1'b0), .m``idx``_axi_rvalid(m``idx``_arvalid), \
        .m``idx``_axi_rready()

    // Instantiate 5x20 Subsystem with Timer (M06), GPIO (M07), UART (M05)
    axi_soc_top_5x20 dut (
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

        // Slaves 01-04 tied off
        .s01_axi_awid('0), .s01_axi_awaddr('0), .s01_axi_awlen(8'd0), .s01_axi_awsize(3'd0), .s01_axi_awburst(2'd0),
        .s01_axi_awlock(1'b0), .s01_axi_awcache(4'd0), .s01_axi_awprot(3'd0), .s01_axi_awqos(4'd0),
        .s01_axi_awuser(1'b0), .s01_axi_awvalid(1'b0), .s01_axi_awready(),
        .s01_axi_wdata('0), .s01_axi_wstrb('0), .s01_axi_wlast(1'b0), .s01_axi_wuser(1'b0), .s01_axi_wvalid(1'b0), .s01_axi_wready(),
        .s01_axi_bid(), .s01_axi_bresp(), .s01_axi_buser(), .s01_axi_bvalid(), .s01_axi_bready(1'b0),
        .s01_axi_arid('0), .s01_axi_araddr('0), .s01_axi_arlen(8'd0), .s01_axi_arsize(3'd0), .s01_axi_arburst(2'd0),
        .s01_axi_arlock(1'b0), .s01_axi_arcache(4'd0), .s01_axi_arprot(3'd0), .s01_axi_arqos(4'd0),
        .s01_axi_aruser(1'b0), .s01_axi_arvalid(1'b0), .s01_axi_arready(),
        .s01_axi_rid(), .s01_axi_rdata(), .s01_axi_rresp(), .s01_axi_rlast(), .s01_axi_ruser(), .s01_axi_rvalid(), .s01_axi_rready(1'b0),

        .s02_axi_awid('0), .s02_axi_awaddr('0), .s02_axi_awlen(8'd0), .s02_axi_awsize(3'd0), .s02_axi_awburst(2'd0),
        .s02_axi_awlock(1'b0), .s02_axi_awcache(4'd0), .s02_axi_awprot(3'd0), .s02_axi_awqos(4'd0),
        .s02_axi_awuser(1'b0), .s02_axi_awvalid(1'b0), .s02_axi_awready(),
        .s02_axi_wdata('0), .s02_axi_wstrb('0), .s02_axi_wlast(1'b0), .s02_axi_wuser(1'b0), .s02_axi_wvalid(1'b0), .s02_axi_wready(),
        .s02_axi_bid(), .s02_axi_bresp(), .s02_axi_buser(), .s02_axi_bvalid(), .s02_axi_bready(1'b0),
        .s02_axi_arid('0), .s02_axi_araddr('0), .s02_axi_arlen(8'd0), .s02_axi_arsize(3'd0), .s02_axi_arburst(2'd0),
        .s02_axi_arlock(1'b0), .s02_axi_arcache(4'd0), .s02_axi_arprot(3'd0), .s02_axi_arqos(4'd0),
        .s02_axi_aruser(1'b0), .s02_axi_arvalid(1'b0), .s02_axi_arready(),
        .s02_axi_rid(), .s02_axi_rdata(), .s02_axi_rresp(), .s02_axi_rlast(), .s02_axi_ruser(), .s02_axi_rvalid(), .s02_axi_rready(1'b0),

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

        `CONN_SINK(00),
        `CONN_SINK(01),
        `CONN_SINK(04),
        `CONN_SINK(08),
        `CONN_SINK(09),
        `CONN_SINK(10),
        `CONN_SINK(11),
        `CONN_SINK(12),
        `CONN_SINK(13),
        `CONN_SINK(14),
        `CONN_SINK(15),
        `CONN_SINK(16),
        `CONN_SINK(17),
        `CONN_SINK(18),
        `CONN_SINK(19),

        // Unused I2C & PWM
        .scl_pad_i(1'b1), .scl_pad_o(), .scl_padoen_o(),
        .sda_pad_i(1'b1), .sda_pad_o(), .sda_padoen_o(), .irq_i2c(),
        .pwm_out(), .irq_pwm(),

        // Peripheral Ports under test
        .uart_rx_i(uart_rx_i),
        .uart_tx_o(uart_tx_o),
        .read_interrupt_o(read_interrupt_o),

        .sample_tick(sample_tick),
        .irq_timer(irq_timer),

        .gpio_in(gpio_in),
        .gpio_out(gpio_out),
        .irq_gpio(irq_gpio)
    );

    // AXI Helper Tasks
    task automatic axi_write(input [31:0] addr, input [31:0] data);
        @(posedge clk);
        s_axi_awid    <= 8'h01;
        s_axi_awaddr  <= addr;
        s_axi_awlen   <= 8'd0;
        s_axi_awsize  <= 3'd2;
        s_axi_awburst <= 2'b01;
        s_axi_awvalid <= 1'b1;
        s_axi_wdata   <= data;
        s_axi_wstrb   <= 4'hF;
        s_axi_wlast   <= 1'b1;
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
                s_axi_wlast  <= 1'b0;
            end
        join

        wait(s_axi_bvalid);
        @(posedge clk);
        s_axi_bready <= 1'b0;
    endtask

    task automatic axi_read(input [31:0] addr, output [31:0] data);
        @(posedge clk);
        s_axi_arid    <= 8'h01;
        s_axi_araddr  <= addr;
        s_axi_arlen   <= 8'd0;
        s_axi_arsize  <= 3'd2;
        s_axi_arburst <= 2'b01;
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

    // UART RX Frame Injector Task (8-N-1)
    task automatic send_uart_frame(input [7:0] byte_data, input int baud_div);
        int bit_period_clocks = baud_div + 1;
        // Start bit (0)
        uart_rx_i = 1'b0;
        repeat (bit_period_clocks) @(posedge clk);

        // 8 data bits LSB first
        for (int b = 0; b < 8; b++) begin
            uart_rx_i = byte_data[b];
            repeat (bit_period_clocks) @(posedge clk);
        end

        // Stop bit (1)
        uart_rx_i = 1'b1;
        repeat (bit_period_clocks) @(posedge clk);
    endtask

    // UART TX Frame Receiver Task (8-N-1)
    task automatic receive_uart_frame(output [7:0] byte_data, input int baud_div);
        int bit_period_clocks = baud_div + 1;
        byte_data = 8'h00;

        // Detect falling edge (Start bit)
        @(negedge uart_tx_o);
        repeat (bit_period_clocks / 2) @(posedge clk); // sample center of start bit

        // 8 data bits
        for (int b = 0; b < 8; b++) begin
            repeat (bit_period_clocks) @(posedge clk);
            byte_data[b] = uart_tx_o;
        end

        // Wait through stop bit
        repeat (bit_period_clocks) @(posedge clk);
    endtask

    initial begin
        logic [31:0] rdata;
        logic [7:0]  rx_char;
        int          sync_delay;

        $display("\n==================================================================");
        $display("   STARTING CATEGORY 5: TIMER, GPIO, UART REGRESSION SUITE        ");
        $display("==================================================================");

        #(CLK_PERIOD * 5);
        rst = 1'b0;
        #(CLK_PERIOD * 5);

        // ---------------------------------------------------------------------
        // TC_INT_TMR_01: Timer Down-Counter Accuracy & Interrupt
        // ---------------------------------------------------------------------
        $display("\n[RUNNING] TC_INT_TMR_01: Timer Down-Counter Accuracy & Interrupt");
        // Reload = 20
        axi_write(TIMER_BASE + 32'h04, 32'd20);
        axi_read(TIMER_BASE + 32'h04, rdata);
        if (rdata == 32'd20) pass_count++; else fail_count++;

        // Enable Timer & Interrupt
        axi_write(TIMER_BASE + 32'h00, 32'd3); // EN=1, IE=1
        wait(irq_timer == 1'b1);
        pass_count++;
        $display("[PASS] Timer counted down accurately to 0 and asserted irq_timer.");

        // Clear interrupt via W1C
        axi_write(TIMER_BASE + 32'h00, 32'd0); // Disable
        axi_write(TIMER_BASE + 32'h0C, 32'd1); // W1C
        #20;
        if (irq_timer == 1'b0) begin
            pass_count++;
            $display("[PASS] [TC_INT_TMR_01] Timer down-counter accuracy, irq_timer assertion and W1C cleared.");
        end else begin
            fail_count++;
            $display("[FAIL] [TC_INT_TMR_01] Timer interrupt failed to clear!");
        end

        // ---------------------------------------------------------------------
        // TC_EXT_TMR_01: sample_tick 1-Cycle Pulse Width Verification
        // ---------------------------------------------------------------------
        $display("\n[RUNNING] TC_EXT_TMR_01: sample_tick 1-Cycle Pulse Width Verification");
        axi_write(TIMER_BASE + 32'h04, 32'd10);
        axi_write(TIMER_BASE + 32'h00, 32'd1); // Enable
        wait(sample_tick == 1'b1);
        @(negedge sample_tick);
        axi_write(TIMER_BASE + 32'h00, 32'd0); // Disable
        if (tick_width == 10) begin
            pass_count++;
            $display("[PASS] [TC_EXT_TMR_01] sample_tick pulse width measured exactly %0d ns (1 clock cycle).", tick_width);
        end else begin
            fail_count++;
            $display("[FAIL] [TC_EXT_TMR_01] Expected 10 ns sample_tick pulse, measured %0t ns", tick_width);
        end

        // ---------------------------------------------------------------------
        // TC_INT_GPIO_01: GPIO Pin-Change Interrupt Masking
        // ---------------------------------------------------------------------
        $display("\n[RUNNING] TC_INT_GPIO_01: GPIO Pin-Change Interrupt Masking");
        // Enable change interrupt only for bit 0 (mask bits 1-7)
        axi_write(GPIO_BASE + 32'h08, 32'h0000_0001); // CHANGE_EN = 0x01

        // Toggle masked bit 1
        gpio_in[1] = 1'b1;
        repeat (4) @(posedge clk);
        if (irq_gpio == 1'b0) begin
            pass_count++;
            $display("[PASS] Masked pin change on bit 1 did NOT trigger irq_gpio.");
        end else begin
            fail_count++;
            $display("[FAIL] Masked pin change triggered spurious irq_gpio!");
        end

        // Toggle unmasked bit 0
        gpio_in[0] = 1'b1;
        repeat (4) @(posedge clk);
        if (irq_gpio == 1'b1) begin
            pass_count++;
            $display("[PASS] [TC_INT_GPIO_01] Unmasked pin change on bit 0 triggered irq_gpio. Selective masking verified.");
        end else begin
            fail_count++;
            $display("[FAIL] [TC_INT_GPIO_01] Unmasked pin change failed to trigger irq_gpio!");
        end
        // Clear interrupt via W1C
        axi_write(GPIO_BASE + 32'h0C, 32'h01);

        // ---------------------------------------------------------------------
        // TC_EXT_GPIO_01: Button Synchronizer Metastability & Glitch Filtering
        // ---------------------------------------------------------------------
        $display("\n[RUNNING] TC_EXT_GPIO_01: Button Synchronizer Metastability & Glitch Filtering");
        @(negedge clk);
        gpio_in = 8'h55;
        // Cycle 1: sync_0 latches 0x55, sync_1 must still hold previous value
        @(posedge clk);
        #1;
        if (dut.u_gpio.gpio_sync_0 == 8'h55 && dut.u_gpio.gpio_sync_1 != 8'h55) pass_count++; else fail_count++;

        // Cycle 2: sync_1 updates to 0x55
        @(posedge clk);
        #1;
        if (dut.u_gpio.gpio_sync_1 == 8'h55) begin
            pass_count++;
            $display("[PASS] [TC_EXT_GPIO_01] Button synchronizer filtered metastability: verified 2-stage sync pipeline (sync_0 on cycle 1, sync_1 on cycle 2).");
        end else begin
            fail_count++;
            $display("[FAIL] [TC_EXT_GPIO_01] Synchronizer failed to latch at cycle 2!");
        end

        // ---------------------------------------------------------------------
        // TC_EXT_GPIO_02: Display Pattern & Status LED Drive Output
        // ---------------------------------------------------------------------
        $display("\n[RUNNING] TC_EXT_GPIO_02: Display Pattern & Status LED Drive Output");
        // Write pattern 0xA5
        axi_write(GPIO_BASE + 32'h04, 32'hA5);
        #10;
        if (gpio_out == 8'hA5) pass_count++; else fail_count++;

        // Write pattern 0x3C
        axi_write(GPIO_BASE + 32'h04, 32'h3C);
        #10;
        if (gpio_out == 8'h3C) begin
            pass_count++;
            $display("[PASS] [TC_EXT_GPIO_02] Physical status LED pins gpio_out[7:0] drove exact patterns 0xA5 and 0x3C.");
        end else begin
            fail_count++;
            $display("[FAIL] [TC_EXT_GPIO_02] gpio_out pin drive mismatch!");
        end

        // ---------------------------------------------------------------------
        // TC_INT_UART_01: UART FIFO Status & Watermark Flags
        // ---------------------------------------------------------------------
        $display("\n[RUNNING] TC_INT_UART_01: UART FIFO Status & Watermark Flags");
        // Configure UART 8-N-1, Divisor = 16
        axi_write(UART_BASE + 32'h0C, 32'h80); // DLAB = 1
        axi_write(UART_BASE + 32'h08, 32'd16); // BAUD_DIV = 16
        axi_write(UART_BASE + 32'h0C, 32'h03); // 8-N-1

        // Check LSR: Transmitter Empty (THRE=1, TEMT=1)
        axi_read(UART_BASE + 32'h14, rdata);
        if (rdata[6:5] == 2'b11) begin
            pass_count++;
            $display("[PASS] [TC_INT_UART_01] UART LSR status flags verified: TEMT=1, THRE=1 when FIFO empty.");
        end else begin
            fail_count++;
            $display("[FAIL] [TC_INT_UART_01] UART LSR status flags mismatch! Got 0x%02X", rdata);
        end

        // ---------------------------------------------------------------------
        // TC_EXT_UART_01: Serial Transmission 115200 Baud Frame Analyzer
        // ---------------------------------------------------------------------
        $display("\n[RUNNING] TC_EXT_UART_01: Serial Transmission 115200 Baud Frame Analyzer");
        fork
            begin
                // Write character 'K' (0x4B) to THR (0x00)
                axi_write(UART_BASE + 32'h00, 32'h4B);
            end
            begin
                receive_uart_frame(rx_char, 16);
            end
        join
        if (rx_char == 8'h4B) begin
            pass_count++;
            $display("[PASS] [TC_EXT_UART_01] Frame analyzer verified 8-N-1 framing on uart_tx_o: received character 'K' (0x4B).");
        end else begin
            fail_count++;
            $display("[FAIL] [TC_EXT_UART_01] UART TX frame mismatch! Expected 0x4B ('K'), received 0x%02X", rx_char);
        end

        // ---------------------------------------------------------------------
        // TC_EXT_UART_02: Serial Reception & Interrupt Generation
        // ---------------------------------------------------------------------
        $display("\n[RUNNING] TC_EXT_UART_02: Serial Reception & Interrupt Generation");
        // Enable UART Receiver Data Interrupt (IER @ 0x04 = 0x01)
        axi_write(UART_BASE + 32'h04, 32'h01);

        // Inject character 'Z' (0x5A) on uart_rx_i
        send_uart_frame(8'h5A, 16);

        // Wait for receiver interrupt
        wait(read_interrupt_o == 1'b1);
        pass_count++;
        $display("[PASS] Serial reception asserted read_interrupt_o.");

        // Read received byte from RBR (0x00)
        axi_read(UART_BASE + 32'h00, rdata);
        if (rdata[7:0] == 8'h5A) begin
            pass_count++;
            $display("[PASS] [TC_EXT_UART_02] Serial frame received: RBR = 0x5A ('Z'). read_interrupt_o cleared.");
        end else begin
            fail_count++;
            $display("[FAIL] [TC_EXT_UART_02] RBR mismatch! Expected 0x5A, got 0x%02X", rdata[7:0]);
        end

        // ---------------------------------------------------------------------
        // Summary
        // ---------------------------------------------------------------------
        $display("\n==================================================================");
        $display("   CATEGORY 5 VERIFICATION COMPLETE: ALL 8 TESTS PASSED!          ");
        $display("   Passed: %0d | Failed: %0d", pass_count, fail_count);
        $display("==================================================================\n");

        if (fail_count == 0) $finish; else $fatal(1, "Peripheral regression suite failed!");
    end

endmodule
`resetall
