/* =============================================================================
 * Interface   : soc_i2c_if.sv
 * Description : SystemVerilog Virtual Interface Bridge connecting Top-Level SoC
 *               physical I2C pins (scl, sda, irq_i2c) to UVM VIP
 * ============================================================================= */

`ifndef SOC_I2C_IF_SV
`define SOC_I2C_IF_SV

`timescale 1ns / 1ps

interface soc_i2c_if (
    input logic clk,
    input logic rst_n
);
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    // Physical I2C Open-Drain Bus Lines
    wire scl;
    wire sda;
    logic irq_i2c;

    // Standard I2C Pullups
    pullup(scl);
    pullup(sda);

    // Physical I2C Sensor Slave Model (Address 0x10)
    // Responds to I2C Master read/write requests from VeeR EL2 C firmware
    i2c_slave_model #(
        .I2C_ADR(7'b001_0000)
    ) u_i2c_slave_model (
        .scl (scl),
        .sda (sda)
    );

    // UVM VIP Monitor Probes for Verdi Waveform Inspection
    logic       mon_scl;
    logic       mon_sda;
    logic       mon_start;
    logic       mon_stop;
    logic [6:0] mon_addr;
    logic       mon_rw;          // 0 = Write, 1 = Read
    logic       mon_ack;         // 0 = ACK, 1 = NACK
    logic [7:0] mon_data_byte;
    logic       mon_byte_valid;

    assign mon_scl = scl;
    assign mon_sda = sda;

    initial begin
        mon_start      = 1'b0;
        mon_stop       = 1'b0;
        mon_addr       = 7'h00;
        mon_rw         = 1'b0;
        mon_ack        = 1'b0;
        mon_data_byte  = 8'h00;
        mon_byte_valid = 1'b0;
        // Preload slave sensor memory at offset 0x02 with calibrated value 0x80 (50% scale)
        u_i2c_slave_model.mem[2] = 8'h80;
    end

    // Clocking block for passive protocol monitoring
    clocking cb_mon @(posedge clk);
        default input #1step output #1ns;
        input scl;
        input sda;
        input irq_i2c;
    endclocking

    modport mon_mp (clocking cb_mon);

endinterface

`endif // SOC_I2C_IF_SV
