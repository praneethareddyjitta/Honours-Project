/* =============================================================================
 * Module      : soc_tb_top.sv
 * Description : Static UVM Top-Level Testbench for VeeR EL2 System-on-Chip
 *               - Statically instantiates full soc_top DUT
 *               - Statically instantiates soc_uart_if interface bridge
 *               - Dumps targeted FSDB waveform with necessary transmission signals
 *               - Registers virtual interface in uvm_config_db
 *               - Calls run_test() to launch UVM dynamic factory tests
 * ============================================================================= */

`timescale 1ns / 1ps
`default_nettype none

module soc_tb_top;
    import uvm_pkg::*;
    `include "uvm_macros.svh"
    import soc_uart_pkg::*;
    import soc_uart_test_pkg::*;

    localparam CLK_PERIOD_NS = 10; // 100 MHz clock

    // 1. Clocks and Control Signals
    logic        clk = 0;
    logic        rst_n = 0;
    logic [31:1] rst_vec;
    logic        nmi_int;
    logic [31:1] nmi_vec;
    logic [31:1] jtag_id;

    // Passive Peripheral Pins
    wire         sample_tick;
    wire         irq_timer;
    logic [7:0]  gpio_in;
    wire  [7:0]  gpio_out;
    wire         irq_gpio;
    wire         scl;
    wire         sda;
    wire         irq_i2c;
    wire         pwm_out;

    pullup(scl);
    pullup(sda);

    // 100 MHz Oscillator
    always #(CLK_PERIOD_NS / 2) clk = ~clk;

    // 2. SystemVerilog Interface Bridge Instantiation
    soc_uart_if uart_vif (
        .clk   (clk),
        .rst_n (rst_n)
    );

    // 3. Static Instantiation of Full SoC DUT
    soc_top dut (
        .clk        (clk),
        .rst_n      (rst_n),
        .rst_vec    (rst_vec),
        .nmi_int    (nmi_int),
        .nmi_vec    (nmi_vec),
        .jtag_id    (jtag_id),

        // UART Physical Pins wired to Interface Bridge
        .uart_rx    (uart_vif.uart_rx),
        .uart_tx    (uart_vif.uart_tx),
        .uart_irq   (uart_vif.uart_irq),

        // Passive Peripherals
        .sample_tick(sample_tick),
        .irq_timer  (irq_timer),
        .gpio_in    (gpio_in),
        .gpio_out   (gpio_out),
        .irq_gpio   (irq_gpio),
        .scl        (scl),
        .sda        (sda),
        .irq_i2c    (irq_i2c),
        .pwm_out    (pwm_out)
    );

    // Helper task to write words into IMEM
    task automatic write_imem_word(input int index, input logic [31:0] data);
        dut.u_imem.mem_0[index] = data[7:0];
        dut.u_imem.mem_1[index] = data[15:8];
        dut.u_imem.mem_2[index] = data[23:16];
        dut.u_imem.mem_3[index] = data[31:24];
    endtask

    // Precompiled C firmware loader
    `include "../sw/firmware_words.vh"

    // -------------------------------------------------------------------------
    // 4. Targeted FSDB Waveform Dumping for Verdi
    //    Dumps ONLY the necessary signals to verify UART transmission
    // -------------------------------------------------------------------------
    initial begin
        $fsdbDumpfile("dump_uart_tx.fsdb");

        // Group 1: System Clocks & Resets
        $fsdbDumpvars(0, clk);
        $fsdbDumpvars(0, rst_n);

        // Group 2: DUT UART Physical Pins
        $fsdbDumpvars(0, dut.uart_tx);
        $fsdbDumpvars(0, dut.uart_rx);
        $fsdbDumpvars(0, dut.uart_irq);

        // Group 3: UART Serial Interface (soc_uart_if)
        $fsdbDumpvars(0, uart_vif.uart_tx);
        $fsdbDumpvars(0, uart_vif.uart_rx);
        $fsdbDumpvars(0, uart_vif.uart_irq);

        // Group 4: UVM VIP Monitor Probes & Monitored TX Signals
        $fsdbDumpvars(0, uart_vif.mon_uart_tx);
        $fsdbDumpvars(0, uart_vif.mon_tx_active);
        $fsdbDumpvars(0, uart_vif.mon_sample_strobe);
        $fsdbDumpvars(0, uart_vif.mon_bit_idx);
        $fsdbDumpvars(0, uart_vif.mon_shift_reg);
        $fsdbDumpvars(0, uart_vif.mon_byte_valid);
        $fsdbDumpvars(0, uart_vif.mon_decoded_byte);

        // Group 5: UART Core Internal TX FIFO
        $fsdbDumpvars(0, dut.u_axi_soc.u_axi_uart.tx_fifo_push_int);
        $fsdbDumpvars(0, dut.u_axi_soc.u_axi_uart.pull_controller_tx_fifo);
        $fsdbDumpvars(0, dut.u_axi_soc.u_axi_uart.tx_fifo_data_in_int);
        $fsdbDumpvars(0, dut.u_axi_soc.u_axi_uart.data_tx_fifo_controller);
        $fsdbDumpvars(0, dut.u_axi_soc.u_axi_uart.tx_fifo_full_int);
        $fsdbDumpvars(0, dut.u_axi_soc.u_axi_uart.available_write_space_int);
        $fsdbDumpvars(0, dut.u_axi_soc.u_axi_uart.uart_lsr_reg_int);

        // Group 6: UART Core Internal Transmitter Engine
        $fsdbDumpvars(0, dut.u_axi_soc.u_axi_uart.uart_controller_inst.uart_transmitter_inst.state);
        $fsdbDumpvars(0, dut.u_axi_soc.u_axi_uart.uart_controller_inst.uart_transmitter_inst.busy);
        $fsdbDumpvars(0, dut.u_axi_soc.u_axi_uart.uart_controller_inst.uart_transmitter_inst.tx_ready);
        $fsdbDumpvars(0, dut.u_axi_soc.u_axi_uart.uart_controller_inst.uart_transmitter_inst.tx_data_int);
        $fsdbDumpvars(0, dut.u_axi_soc.u_axi_uart.uart_controller_inst.uart_transmitter_inst.bitcount_int);

        // Group 7: Processor LSU & AXI-Lite Writes
        $fsdbDumpvars(0, dut.lsu_axi_awaddr);
        $fsdbDumpvars(0, dut.lsu_axi_wdata);
        $fsdbDumpvars(0, dut.lsu_axi_wvalid);
        $fsdbDumpvars(0, dut.u_axi_soc.u_axi_uart.axi_awaddr_i);
        $fsdbDumpvars(0, dut.u_axi_soc.u_axi_uart.axi_wdata_i);
        $fsdbDumpvars(0, dut.u_axi_soc.u_axi_uart.axi_wvalid_i);
        $fsdbDumpvars(0, dut.u_axi_soc.u_axi_uart.axi_wready_o);

        $display("[VERDI] Targeted FSDB dumping initialized: dump_uart_tx.fsdb");
    end

    // -------------------------------------------------------------------------
    // 5. Testbench Initialization & UVM Trigger
    // -------------------------------------------------------------------------
    // Asynchronous Reset Sequencer (runs concurrently during simulation)
    initial begin
        rst_n = 0;
        #(CLK_PERIOD_NS * 20);
        @(posedge clk);
        rst_n = 1'b1;
        $display("[SOC] VeeR EL2 reset released. Booting C firmware from IMEM (0x1000_0000)...\n");
    end

    // Time 0 Setup and UVM Launch
    initial begin
        nmi_int = 0;
        nmi_vec = 31'h7700_0000;
        jtag_id = 31'h0000_0045;
        gpio_in = 8'h00;
        rst_vec = (32'h1000_0000 >> 1); // Boot PC = 0x1000_0000 (IMEM Base)

        // Initialize IMEM with NOPs and load compiled C binary at time 0
        for (int i = 0; i < 16384; i++) begin
            write_imem_word(i, 32'h0000_0013);
        end
        load_c_firmware();

        // Set virtual interface in UVM Config DB at time 0
        uvm_config_db#(virtual soc_uart_if)::set(null, "*", "uart_vif", uart_vif);

        // Run UVM Test at time 0 (Required by UVM methodology)
        run_test();
    end

endmodule
`resetall
