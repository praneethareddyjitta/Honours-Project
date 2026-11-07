/* =============================================================================
 * Module      : soc_tb_top.sv
 * Description : Master Static UVM Top-Level Testbench for VeeR EL2 SoC
 *               - Statically instantiates full soc_top DUT
 *               - Statically instantiates all 5 interfaces (UART, I2C, GPIO, PWM, Timer)
 *               - Connects all physical DUT peripheral pins to their interfaces
 *               - Registers all 5 virtual interfaces in uvm_config_db
 *               - Dumps targeted FSDB waveform for Verdi analysis
 *               - Launches dynamic UVM Factory test at Time 0 via run_test()
 * ============================================================================= */

`timescale 1ns / 1ps
`default_nettype none

module soc_tb_top;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    import uart_pkg::*;
    import i2c_pkg::*;
    import gpio_pkg::*;
    import pwm_pkg::*;
    import timer_pkg::*;
    import soc_env_pkg::*;
    import soc_test_pkg::*;

    localparam CLK_PERIOD_NS = 10; // 100 MHz clock

    // 1. Clock and Reset Generation
    logic        clk = 0;
    logic        rst_n = 0;
    logic [31:1] rst_vec;
    logic        nmi_int;
    logic [31:1] nmi_vec;
    logic [31:1] jtag_id;

    // 100 MHz Oscillator
    always #(CLK_PERIOD_NS / 2) clk = ~clk;

    // 2. SystemVerilog Interface Bridges Instantiations
    soc_uart_if  uart_vif  (.clk(clk), .rst_n(rst_n));
    soc_i2c_if   i2c_vif   (.clk(clk), .rst_n(rst_n));
    soc_gpio_if  gpio_vif  (.clk(clk), .rst_n(rst_n));
    soc_pwm_if   pwm_vif   (.clk(clk), .rst_n(rst_n));
    soc_timer_if timer_vif (.clk(clk), .rst_n(rst_n));

    // 3. Static Instantiation of Full SoC DUT
    soc_top dut (
        .clk        (clk),
        .rst_n      (rst_n),
        .rst_vec    (rst_vec),
        .nmi_int    (nmi_int),
        .nmi_vec    (nmi_vec),
        .jtag_id    (jtag_id),

        // 1. UART Physical Pins -> soc_uart_if
        .uart_rx    (uart_vif.uart_rx),
        .uart_tx    (uart_vif.uart_tx),
        .uart_irq   (uart_vif.uart_irq),

        // 2. I2C Physical Pins -> soc_i2c_if
        .scl        (i2c_vif.scl),
        .sda        (i2c_vif.sda),
        .irq_i2c    (i2c_vif.irq_i2c),

        // 3. GPIO Physical Pins -> soc_gpio_if
        .gpio_in    (gpio_vif.gpio_in),
        .gpio_out   (gpio_vif.gpio_out),
        .irq_gpio   (gpio_vif.irq_gpio),

        // 4. PWM Physical Pin -> soc_pwm_if
        .pwm_out    (pwm_vif.pwm_out),

        // 5. System Timer Physical Pins -> soc_timer_if
        .sample_tick(timer_vif.sample_tick),
        .irq_timer  (timer_vif.irq_timer)
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

    // 4. Targeted FSDB Waveform Dumping for Verdi
    initial begin
        $fsdbDumpfile("dump_soc_all_vips.fsdb");

        // Clocks and Resets
        $fsdbDumpvars(0, clk);
        $fsdbDumpvars(0, rst_n);

        // UART Interface & Pins
        $fsdbDumpvars(0, uart_vif.uart_tx);
        $fsdbDumpvars(0, uart_vif.uart_rx);
        $fsdbDumpvars(0, uart_vif.uart_irq);
        $fsdbDumpvars(0, uart_vif.mon_uart_tx);
        $fsdbDumpvars(0, uart_vif.mon_sample_strobe);
        $fsdbDumpvars(0, uart_vif.mon_decoded_byte);
        $fsdbDumpvars(0, uart_vif.mon_byte_valid);

        // I2C Interface & Pins
        $fsdbDumpvars(0, i2c_vif.scl);
        $fsdbDumpvars(0, i2c_vif.sda);
        $fsdbDumpvars(0, i2c_vif.irq_i2c);
        $fsdbDumpvars(0, i2c_vif.mon_start);
        $fsdbDumpvars(0, i2c_vif.mon_stop);
        $fsdbDumpvars(0, i2c_vif.mon_addr);
        $fsdbDumpvars(0, i2c_vif.mon_rw);
        $fsdbDumpvars(0, i2c_vif.mon_ack);
        $fsdbDumpvars(0, i2c_vif.mon_data_byte);
        $fsdbDumpvars(0, i2c_vif.mon_byte_valid);

        // GPIO Interface & Pins
        $fsdbDumpvars(0, gpio_vif.gpio_in);
        $fsdbDumpvars(0, gpio_vif.gpio_out);
        $fsdbDumpvars(0, gpio_vif.irq_gpio);
        $fsdbDumpvars(0, gpio_vif.mon_gpio_out);
        $fsdbDumpvars(0, gpio_vif.mon_gpio_change);

        // PWM Interface & Pins
        $fsdbDumpvars(0, pwm_vif.pwm_out);
        $fsdbDumpvars(0, pwm_vif.mon_period_cycles);
        $fsdbDumpvars(0, pwm_vif.mon_high_cycles);
        $fsdbDumpvars(0, pwm_vif.mon_duty_percent);
        $fsdbDumpvars(0, pwm_vif.mon_period_valid);

        // Timer Interface & Pins
        $fsdbDumpvars(0, timer_vif.sample_tick);
        $fsdbDumpvars(0, timer_vif.irq_timer);
        $fsdbDumpvars(0, timer_vif.mon_tick_count);

        $display("[VERDI] Multi-VIP FSDB dumping initialized: dump_soc_all_vips.fsdb");
    end

    // 5. Asynchronous Reset Sequencer
    initial begin
        rst_n = 0;
        #(CLK_PERIOD_NS * 20);
        @(posedge clk);
        rst_n = 1'b1;
        $display("[SOC] VeeR EL2 reset released. Booting C firmware from IMEM (0x1000_0000)...\n");
    end

    // 6. Time 0 Setup and UVM Launch
    initial begin
        nmi_int = 0;
        nmi_vec = 31'h7700_0000;
        jtag_id = 31'h0000_0045;
        rst_vec = (32'h1000_0000 >> 1); // Boot PC = 0x1000_0000 (IMEM Base)

        // Initialize IMEM with NOPs and load compiled C binary at time 0
        for (int i = 0; i < 16384; i++) begin
            write_imem_word(i, 32'h0000_0013);
        end
        load_c_firmware();

        // Register All 5 Virtual Interfaces in UVM Config DB at Time 0
        uvm_config_db#(virtual soc_uart_if)::set(null, "*", "uart_vif", uart_vif);
        uvm_config_db#(virtual soc_i2c_if)::set(null, "*", "i2c_vif", i2c_vif);
        uvm_config_db#(virtual soc_gpio_if)::set(null, "*", "gpio_vif", gpio_vif);
        uvm_config_db#(virtual soc_pwm_if)::set(null, "*", "pwm_vif", pwm_vif);
        uvm_config_db#(virtual soc_timer_if)::set(null, "*", "timer_vif", timer_vif);

        // Launch UVM dynamic Factory tests
        run_test();
    end

endmodule
`resetall
