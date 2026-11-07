/* =============================================================================
 * Interface   : soc_timer_if.sv
 * Description : SystemVerilog Virtual Interface Bridge connecting Top-Level SoC
 *               Timer pins (sample_tick, irq_timer) to UVM VIP
 * ============================================================================= */

`ifndef SOC_TIMER_IF_SV
`define SOC_TIMER_IF_SV

`timescale 1ns / 1ps

interface soc_timer_if (
    input logic clk,
    input logic rst_n
);
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    // Physical System Timer Lines at SoC Boundary
    wire sample_tick; // Output from SoC DUT -> Sampled by UVM Timer Monitor
    wire irq_timer;   // Output from SoC DUT -> Observed by UVM Timer Monitor

    // UVM VIP Monitor Probes for Verdi Waveform Inspection
    logic [31:0] mon_tick_count;
    logic        mon_tick_strobe;
    logic [31:0] mon_irq_count;

    assign mon_tick_strobe = sample_tick;

    initial begin
        mon_tick_count  = 32'd0;
        mon_irq_count   = 32'd0;
    end

    // Monitor Clocking Block
    clocking cb_mon @(posedge clk);
        default input #1step output #1ns;
        input sample_tick;
        input irq_timer;
    endclocking

    modport mon_mp (clocking cb_mon);

endinterface

`endif // SOC_TIMER_IF_SV
