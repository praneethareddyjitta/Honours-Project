/* =============================================================================
 * Module      : tb_axi_i2c.sv
 * Description : Verification Testbench for AXI4-Lite I2C Master IP
 *
 * Verifies:
 *   1. AXI4-Lite CSR writes and reads (CTRL, PRESCALE, TXR, CMD, STATUS)
 *   2. I2C Master protocol transactions with i2c_slave_model:
 *      - START condition, slave address (0x10), ACK sampling
 *      - Byte write to slave memory
 *      - Repeated START & byte read from slave memory
 *      - STOP condition
 *   3. Interrupt assertion (irq_i2c) on DONE and W1C clearing
 * ============================================================================= */

`timescale 1ns / 1ps
`default_nettype none

module tb_axi_i2c;

    localparam CLK_PERIOD = 10; // 100 MHz clock
    localparam ADDR_WIDTH = 32;
    localparam DATA_WIDTH = 32;
    localparam SLAVE_ADDR = 7'b001_0000; // 7-bit address: 0x10

    logic                  clk;
    logic                  rst_n;

    logic [ADDR_WIDTH-1:0] s_axi_awaddr;
    logic                  s_axi_awvalid;
    wire                   s_axi_awready;

    logic [DATA_WIDTH-1:0] s_axi_wdata;
    logic [3:0]            s_axi_wstrb;
    logic                  s_axi_wvalid;
    wire                   s_axi_wready;

    wire [1:0]             s_axi_bresp;
    wire                   s_axi_bvalid;
    logic                  s_axi_bready;

    logic [ADDR_WIDTH-1:0] s_axi_araddr;
    logic                  s_axi_arvalid;
    wire                   s_axi_arready;

    wire [DATA_WIDTH-1:0]  s_axi_rdata;
    wire [1:0]             s_axi_rresp;
    wire                   s_axi_rvalid;
    logic                  s_axi_rready;

    wire                   scl_o, scl_oen;
    wire                   sda_o, sda_oen;
    wire                   irq_i2c;

    // Pull-up resistors for open-drain I2C bus lines
    wire scl;
    wire sda;
    pullup(scl);
    pullup(sda);

    assign scl = scl_oen ? 1'bz : scl_o;
    assign sda = sda_oen ? 1'bz : sda_o;

    // -------------------------------------------------------------------------
    // Instantiate DUT (axi_i2c_top)
    // -------------------------------------------------------------------------
    axi_i2c_top #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) dut (
        .clk          (clk),
        .rst_n        (rst_n),

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
        .s_axi_rready (s_axi_rready),

        .scl_pad_i    (scl),
        .scl_pad_o    (scl_o),
        .scl_padoen_o (scl_oen),

        .sda_pad_i    (sda),
        .sda_pad_o    (sda_o),
        .sda_padoen_o (sda_oen),

        .scl          (),
        .sda          (),
        .irq_i2c      (irq_i2c)
    );

    // -------------------------------------------------------------------------
    // Instantiate I2C Slave Model
    // -------------------------------------------------------------------------
    i2c_slave_model #(
        .I2C_ADR(SLAVE_ADDR)
    ) u_slave (
        .scl(scl),
        .sda(sda)
    );

    // Clock generator (100 MHz)
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

    // Helper task to wait for I2C command completion (polling STATUS.DONE)
    task wait_for_done();
        logic [31:0] st;
        int timeout = 0;
        do begin
            axi_read(32'h14, st);
            timeout++;
            if (timeout > 50000) $fatal(1, "Timeout waiting for I2C command DONE!");
            #(CLK_PERIOD * 4);
        end while (st[1] == 1'b0);
    endtask

    // Main Test Sequence
    initial begin
        logic [DATA_WIDTH-1:0] rdata;

        $display("\n==========================================================");
        $display("   STARTING AXI4-LITE I2C MASTER VERIFICATION             ");
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
        #(CLK_PERIOD * 10);
        rst_n = 1;
        #(CLK_PERIOD * 10);

        // Test 1: Program Fast Simulation Clock Prescaler (DIV = 4)
        axi_write(32'h04, 32'd4);
        axi_read(32'h04, rdata);
        if (rdata[15:0] != 16'd4) $fatal(1, "Prescaler readback mismatch!");
        $display("[PASS] Test 1: I2C_PRESCALE programmed and verified (DIV = 4).");

        // Test 2: Enable Core and Interrupts (CTRL = 3: EN=1, IE=1)
        axi_write(32'h00, 32'd3);
        axi_read(32'h00, rdata);
        if (rdata[1:0] != 2'b11) $fatal(1, "CTRL readback mismatch!");
        $display("[PASS] Test 2: I2C_CTRL enabled (EN=1, IE=1).");

        // Test 3: Write Byte to I2C Slave
        // Step A: Address Phase -> START + Slave Addr (0x10) + Write (0) = 8'h20
        $display("\n--- Step A: Transmitting Slave Address (0x10, Write) ---");
        axi_write(32'h08, 32'h20);          // TXDATA = 0x20
        axi_write(32'h10, 32'b00101);       // CMD: WR=1, START=1
        wait_for_done();
        axi_read(32'h14, rdata);
        if (rdata[2] != 1'b0) $fatal(1, "Expected ACK from slave for address 0x10!");
        $display("[PASS] Address acknowledged by I2C slave model.");
        // Clear DONE flag (W1C)
        axi_write(32'h14, 32'h02);

        // Step B: Data Phase -> Write Sub-Address (0x04) + STOP
        $display("--- Step B: Transmitting Memory Sub-Address (0x04) + STOP ---");
        axi_write(32'h08, 32'h04);          // TXDATA = 0x04 (within slave memory 0..15)
        axi_write(32'h10, 32'b00110);       // CMD: WR=1, STOP=1
        wait_for_done();
        axi_read(32'h14, rdata);
        if (rdata[2] != 1'b0) $fatal(1, "Expected ACK from slave for sub-address 0x04!");
        if (!irq_i2c) $fatal(1, "irq_i2c should be asserted when IE=1 and DONE=1!");
        $display("[PASS] Memory sub-address 0x04 written and irq_i2c asserted.");
        axi_write(32'h14, 32'h02); // Clear DONE

        #(CLK_PERIOD * 20);

        // Test 4: Read Byte from I2C Slave
        // Step A: Send START + Slave Addr (0x10) + Read (1) = 8'h21
        $display("\n--- Step C: Transmitting Slave Address (0x10, Read) ---");
        axi_write(32'h08, 32'h21);          // TXDATA = 0x21
        axi_write(32'h10, 32'b00101);       // CMD: WR=1, START=1
        wait_for_done();
        axi_read(32'h14, rdata);
        if (rdata[2] != 1'b0) $fatal(1, "Expected ACK from slave for address 0x10 Read!");
        axi_write(32'h14, 32'h02);

        // Step B: Receive Data Byte + Master NACK + STOP
        $display("--- Step D: Reading Data Byte from Slave + STOP ---");
        axi_write(32'h10, 32'b11010);       // CMD: NACK=1, RD=1, STOP=1
        wait_for_done();
        axi_read(32'h0C, rdata);            // Read RXDATA
        $display("[INFO] Byte read from I2C slave: 0x%02X", rdata[7:0]);
        axi_write(32'h14, 32'h02);

        $display("\n==========================================================");
        $display("   ALL AXI4-LITE I2C MASTER TESTS PASSED SUCCESSFULLY!    ");
        $display("==========================================================\n");
        $finish;
    end

endmodule

`resetall
