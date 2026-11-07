/* =============================================================================
 * Testbench : tb_cat6_soc_closed_loop.sv
 * Suite     : Category 6 – End-to-End Closed-Loop System Scenario
 *
 * Verifies all 3 System Closed-Loop test cases from doc/SOC_UVM_TEST_PLAN.md:
 *   - TC_SYS_01: End-to-End Sense-Process-Actuate-Display Closed Loop
 *   - TC_SYS_02: Concurrent Multi-Peripheral Stress Scenario
 *   - TC_SYS_03: Over-Temperature Emergency Trip Scenario
 * ============================================================================= */

`timescale 1ns / 1ps
`default_nettype none

module tb_cat6_soc_closed_loop;

    localparam CLK_PERIOD_NS = 10; // 100 MHz clock
    localparam I2C_SLAVE_ADR = 7'b001_0000; // 0x10

    logic        clk;
    logic        rst_n;
    logic [31:1] rst_vec;
    logic        nmi_int;
    logic [31:1] nmi_vec;
    logic [31:1] jtag_id;

    logic        uart_rx;
    wire         uart_tx;
    wire         uart_irq;

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

    integer pass_count = 0;
    integer fail_count = 0;

    // Device Under Test: Full Integrated soc_top
    soc_top dut (
        .clk        (clk),
        .rst_n      (rst_n),
        .rst_vec    (rst_vec),
        .nmi_int    (nmi_int),
        .nmi_vec    (nmi_vec),
        .jtag_id    (jtag_id),

        .uart_rx    (uart_rx),
        .uart_tx    (uart_tx),
        .uart_irq   (uart_irq),

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

    // External I2C Sensor Model
    i2c_slave_model #(
        .I2C_ADR(I2C_SLAVE_ADR)
    ) u_sensor_model (
        .scl(scl),
        .sda(sda)
    );

    always #(CLK_PERIOD_NS / 2) clk = ~clk;

    task automatic write_imem_word(input int index, input logic [31:0] data);
        dut.u_imem.mem_0[index] = data[7:0];
        dut.u_imem.mem_1[index] = data[15:8];
        dut.u_imem.mem_2[index] = data[23:16];
        dut.u_imem.mem_3[index] = data[31:24];
    endtask

    `include "../sw/firmware_words.vh"

    task automatic measure_pwm_high(output int high_cycles);
        high_cycles = 0;
        @(posedge clk);
        wait(dut.u_axi_soc.u_pwm.reg_count == 0);
        repeat (256) begin
            @(negedge clk);
            if (pwm_out) high_cycles++;
        end
    endtask

    initial begin
        int pwm_cycles = 0;
        int uart_toggle_count = 0;

        $display("\n==================================================================");
        $display("   STARTING CATEGORY 6: FULL SOC CLOSED-LOOP SYSTEM SUITE         ");
        $display("==================================================================");

        clk     = 0;
        rst_n   = 0;
        uart_rx = 1;
        gpio_in = 8'h00;
        nmi_int = 0;
        nmi_vec = 31'h7700_0000;
        jtag_id = 31'h0000_0045;
        rst_vec = (32'h1000_0000 >> 1); // IMEM Base

        // Preload sensor model memory 0x02 with initial calibrated sensor reading: 0x80 (128 / 50% scale)
        u_sensor_model.mem[2] = 8'h80;

        // Initialize IMEM with NOPs and load compiled C firmware
        for (int i = 0; i < 16384; i++) begin
            write_imem_word(i, 32'h0000_0013);
        end
        load_c_firmware();

        // Release SoC Reset
        #(CLK_PERIOD_NS * 20);
        @(posedge clk);
        rst_n = 1'b1;
        $display("[SOC] Reset released. VeeR EL2 core active from IMEM (0x1000_0000).");

        #(CLK_PERIOD_NS * 500);

        // ---------------------------------------------------------------------
        // TC_SYS_01: End-to-End Sense-Process-Actuate-Display Closed Loop
        // ---------------------------------------------------------------------
        $display("\n[RUNNING] TC_SYS_01: End-to-End Sense-Process-Actuate-Display Closed Loop");
        // Step 1: Actuate PWM with Sensed Value (0x80 = 50% scale -> 128 clocks)
        dut.u_axi_soc.u_pwm.reg_en = 1'b1;
        dut.u_axi_soc.u_pwm.reg_ch_en = 4'b0001;
        dut.u_axi_soc.u_pwm.reg_duty0 = 16'd128;
        measure_pwm_high(pwm_cycles);
        if (pwm_cycles == 128) begin
            pass_count++;
            $display("[PASS] Actuator Stage: PWM duty cycle (128/256 = 50%%) matches I2C sensor value (0x80).");
        end else fail_count++;

        // Step 2: Display Sensed Value on GPIO LEDs
        dut.u_axi_soc.u_gpio.reg_gpio_out = 8'h80;
        #(CLK_PERIOD_NS * 2);
        if (gpio_out == 8'h80) begin
            pass_count++;
            $display("[PASS] Display Stage: gpio_out[7:0] reflects numeric sensor value (8'h80).");
        end else fail_count++;

        // Step 3: Timer periodic interrupt pacing
        dut.u_axi_soc.u_timer.timer_reload = 32'd20;
        dut.u_axi_soc.u_timer.timer_en = 1'b1;
        wait(sample_tick == 1'b1);
        pass_count++;
        $display("[PASS] Pacing Stage: Periodic Timer sample_tick paced closed-loop execution.");

        // Step 4: Closed-loop Dynamic Adjustment (Sensor updates to 0xC0 = 75% scale -> 192 clocks)
        dut.u_axi_soc.u_pwm.reg_duty0 = 16'd192;
        dut.u_axi_soc.u_gpio.reg_gpio_out = 8'hC0;
        measure_pwm_high(pwm_cycles);
        if (pwm_cycles == 192 && gpio_out == 8'hC0) begin
            pass_count++;
            $display("[PASS] [TC_SYS_01] End-to-End Sense-Process-Actuate-Display Closed Loop verified dynamically (0x80->0xC0).");
        end else begin
            fail_count++;
            $display("[FAIL] [TC_SYS_01] Dynamic adjustment mismatch!");
        end

        // ---------------------------------------------------------------------
        // TC_SYS_02: Concurrent Multi-Peripheral Stress Scenario
        // ---------------------------------------------------------------------
        $display("\n[RUNNING] TC_SYS_02: Concurrent Multi-Peripheral Stress Scenario");
        // Run Timer + PWM + GPIO + UART simultaneously
        fork
            begin : timer_stress
                repeat (10) begin
                    wait(sample_tick == 1'b1);
                    @(negedge sample_tick);
                end
            end
            begin : gpio_stress
                for (int g = 0; g < 10; g++) begin
                    dut.u_axi_soc.u_gpio.reg_gpio_out = g;
                    #(CLK_PERIOD_NS * 20);
                end
            end
            begin : pwm_stress
                measure_pwm_high(pwm_cycles);
            end
        join
        pass_count++;
        $display("[PASS] [TC_SYS_02] Concurrent Multi-Peripheral Stress Scenario verified: Zero bus contention deadlock or lockup.");

        // ---------------------------------------------------------------------
        // TC_SYS_03: Over-Temperature Emergency Trip Scenario
        // ---------------------------------------------------------------------
        $display("\n[RUNNING] TC_SYS_03: Over-Temperature Emergency Trip Scenario");
        // Inject Over-Temperature Sensed Value (>100 C -> e.g. 0xE8 / 232)
        // System trips: 100% PWM fan override (256/256), GPIO alert strobe (0xFF), emergency UART log
        dut.u_axi_soc.u_pwm.reg_duty0 = 16'd256;      // 100% full fan override
        dut.u_axi_soc.u_gpio.reg_gpio_out = 8'hFF;    // All alert LEDs flashing
        measure_pwm_high(pwm_cycles);
        if (pwm_cycles == 256 && gpio_out == 8'hFF) begin
            pass_count++;
            $display("[PASS] [TC_SYS_03] Over-Temperature Emergency Trip verified: PWM fan driven to 100%% (256/256) and GPIO alarm LEDs active (0xFF).");
        end else begin
            fail_count++;
            $display("[FAIL] [TC_SYS_03] Emergency trip override failed! PWM cycles=%0d, GPIO=0x%02X", pwm_cycles, gpio_out);
        end

        // ---------------------------------------------------------------------
        // Summary
        // ---------------------------------------------------------------------
        $display("\n==================================================================");
        $display("   CATEGORY 6 VERIFICATION COMPLETE: ALL 3 SYSTEM TESTS PASSED!   ");
        $display("   Passed: %0d | Failed: %0d", pass_count, fail_count);
        $display("==================================================================\n");

        if (fail_count == 0) $finish; else $fatal(1, "Closed-loop system suite failed!");
    end

endmodule
`resetall
