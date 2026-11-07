/* =============================================================================
 * Interface   : soc_uart_if.sv
 * Description : SystemVerilog Virtual Interface Bridge connecting Top-Level SoC
 *               physical UART pins (uart_tx, uart_rx, uart_irq) to UVM VIP
 * ============================================================================= */

`ifndef SOC_UART_IF_SV
`define SOC_UART_IF_SV

`timescale 1ns / 1ps

interface soc_uart_if (
    input logic clk,
    input logic rst_n
);

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    // Physical Serial Pins at SoC Boundary
    logic uart_tx;   // Output from SoC DUT -> Sampled by UVM Monitor
    logic uart_rx;   // Input to SoC DUT    <- Driven by UVM Driver
    logic uart_irq;  // Output from SoC DUT -> Observed by UVM Monitor

    // UVM VIP Monitor Internal Signals and Probes for Waveform Inspection
    logic       mon_uart_tx;        // Monitored UART TX signal observed by VIP Monitor
    logic       mon_tx_active;      // Asserted when VIP monitor is actively capturing a frame
    logic       mon_sample_strobe;  // Strobe at exact center of each bit period where monitor samples
    logic [3:0] mon_bit_idx;        // Bit index being sampled (0 to 7)
    logic [7:0] mon_shift_reg;      // Real-time deserializing shift register
    logic [7:0] mon_decoded_byte;   // Final reconstructed byte
    logic       mon_byte_valid;     // 1-cycle byte valid pulse

    assign mon_uart_tx = uart_tx;

    // Default pin states
    initial begin
        uart_rx           = 1'b1; // UART Idle is Active-High
        mon_tx_active     = 1'b0;
        mon_sample_strobe = 1'b0;
        mon_bit_idx       = 4'h0;
        mon_shift_reg     = 8'h00;
        mon_decoded_byte  = 8'h00;
        mon_byte_valid    = 1'b0;
    end

    // Monitor Clocking Block
    clocking cb_mon @(posedge clk);
        default input #1step output #1ns;
        input uart_tx;
        input uart_rx;
        input uart_irq;
    endclocking

    // Driver Clocking Block
    clocking cb_drv @(posedge clk);
        default input #1step output #1ns;
        output uart_rx;
        input  uart_tx;
        input  uart_irq;
    endclocking

    // Modports for clean directional binding
    modport mon_mp (clocking cb_mon);
    modport drv_mp (clocking cb_drv);

    // -------------------------------------------------------------------------
    // SystemVerilog Assertions (SVA) for Protocol Integrity
    // -------------------------------------------------------------------------
    // 1. Reset check: During active reset, serial pins must be stable
    property p_uart_reset_idle;
        @(posedge clk) !rst_n |-> uart_rx == 1'b1;
    endproperty
    a_uart_reset_idle: assert property(p_uart_reset_idle)
        else `uvm_error("SVA_UART", "uart_rx dropped low during reset!")

endinterface

`endif // SOC_UART_IF_SV
