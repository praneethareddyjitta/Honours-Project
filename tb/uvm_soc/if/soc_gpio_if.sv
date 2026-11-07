/* =============================================================================
 * Interface   : soc_gpio_if.sv
 * Description : SystemVerilog Virtual Interface Bridge connecting Top-Level SoC
 *               GPIO pins (gpio_in, gpio_out, irq_gpio) to UVM VIP
 * ============================================================================= */

`ifndef SOC_GPIO_IF_SV
`define SOC_GPIO_IF_SV

`timescale 1ns / 1ps

interface soc_gpio_if (
    input logic clk,
    input logic rst_n
);
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    // Physical GPIO Lines at SoC Boundary
    logic [7:0] gpio_in;   // Input to SoC DUT   <- Driven by UVM GPIO Driver
    logic [7:0] gpio_out;  // Output from SoC DUT -> Sampled by UVM GPIO Monitor
    logic       irq_gpio;  // Output from SoC DUT -> Observed by UVM GPIO Monitor

    // UVM VIP Monitor Probes for Verdi Waveform Inspection
    logic [7:0] mon_gpio_out;
    logic       mon_gpio_change;

    assign mon_gpio_out = gpio_out;

    initial begin
        gpio_in         = 8'h00;
        mon_gpio_change = 1'b0;
    end

    // Monitor Clocking Block
    clocking cb_mon @(posedge clk);
        default input #1step output #1ns;
        input gpio_in;
        input gpio_out;
        input irq_gpio;
    endclocking

    // Driver Clocking Block
    clocking cb_drv @(posedge clk);
        default input #1step output #1ns;
        output gpio_in;
        input  gpio_out;
        input  irq_gpio;
    endclocking

    modport mon_mp (clocking cb_mon);
    modport drv_mp (clocking cb_drv);

endinterface

`endif // SOC_GPIO_IF_SV
