/* =============================================================================
 * Interface   : soc_pwm_if.sv
 * Description : SystemVerilog Virtual Interface Bridge connecting Top-Level SoC
 *               PWM output pin (pwm_out) to UVM VIP
 * ============================================================================= */

`ifndef SOC_PWM_IF_SV
`define SOC_PWM_IF_SV

`timescale 1ns / 1ps

interface soc_pwm_if (
    input logic clk,
    input logic rst_n
);
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    // Physical PWM Line at SoC Boundary
    wire pwm_out; // Output from SoC DUT -> Sampled by UVM PWM Monitor

    // UVM VIP Monitor Probes for Verdi Waveform Inspection
    logic [31:0] mon_period_cycles;
    logic [31:0] mon_high_cycles;
    logic [7:0]  mon_duty_percent;
    logic        mon_period_valid;

    initial begin
        mon_period_cycles = 32'd0;
        mon_high_cycles   = 32'd0;
        mon_duty_percent  = 8'd0;
        mon_period_valid  = 1'b0;
    end

    // Monitor Clocking Block
    clocking cb_mon @(posedge clk);
        default input #1step output #1ns;
        input pwm_out;
    endclocking

    modport mon_mp (clocking cb_mon);

endinterface

`endif // SOC_PWM_IF_SV
