#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
build_full_test_plan.py
Generates doc/SoC_UVM_Test_Plan.xlsx for the VeeR EL2 SoC with:
I2C, PWM, GPIO, UART, Timer, IMEM, DMEM, AXI4 Interconnect.
"""

import sys
import os
sys.path.insert(0, os.path.dirname(__file__))
from generate_test_plan_xlsx import WorkbookBuilder

wb = WorkbookBuilder()

# ==============================================================================
# SHEET 1: Executive_Dashboard
# ==============================================================================
rows_dash = [
    ["RISC-V VeeR EL2 SoC — UVM Verification Test Plan & Executive Dashboard"],
    ["Metric / Field", "Specification Value", "Notes & Methodology Reference"],
    ["Project Title", "RTL Design & Verification of a RISC-V VeeR EL2 Based SoC", "Authoritative Honours Project"],
    ["Processor Core", "Western Digital / CHIPS Alliance VeeR EL2 (RV32IMC)", "4-Stage In-Order Scalar, Dual-Issue"],
    ["Interconnect Bus", "5-Master x 20-Slave AXI4 Crossbar Fabric", "axi_soc_top_5x20 / axi_interconnect_wrap_5x20"],
    ["Mandatory Memory", "IMEM (64KB at 0x1000_0000), DMEM (64KB at 0x1002_0000)", "On-Chip AXI4 Single-Cycle SRAMs"],
    ["Selected IP 1", "I2C Master Controller (0x4000_0000, M02)", "Serial Sensor Communication (scl, sda)"],
    ["Selected IP 2", "PWM Generator (0x4000_2000, M03)", "4-Channel Duty-Cycle Actuator (pwm_out[3:0])"],
    ["Telemetry & UI IP 1", "16550 AXI UART (0x4000_6000, M05)", "Serial Diagnostics & Telemetry (115200 Baud)"],
    ["Timing IP", "System Timer (0x4000_8000, M06)", "Periodic Sample Pacing (sample_tick, irq_timer)"],
    ["Display & Pin IP", "GPIO Controller (0x4000_A000, M07)", "Synchronized Inputs & Sensed Value Display Outputs"],
    ["Unused Slots", "M04 (Tied off) & M08..M19", "Tied off sink / DECERR aperture responses"],
    ["Closed-Loop Application", "Sense (I2C) -> Compute (VeeR EL2) -> Actuate (PWM) & Display (GPIO, UART)", "Event-Driven Interrupt-Paced Control"],
    ["Verification Methodology", "UVM 1.2 / IEEE 1800.2 + SystemVerilog Assertions (SVA)", "Constrained-Random, Coverage-Driven"],
    ["EDA Tools & Simulators", "Synopsys VCS (U-2023.03) + Verdi (U-2023.03-SP1) FSDB Tracing", "Multi-Group Waveform Sign-Off"],
    ["Total UVM Test Cases", "35 Comprehensive Tests", "Full System & Block Coverage"],
    ["Internal Test Cases (INT)", "17 Test Cases", "CPU, AXI Bus, RAL, CSRs, Traps, Memory, PIC"],
    ["External Test Cases (EXT)", "15 Test Cases", "I2C, PWM, GPIO Display, UART, Timer Pin Protocols"],
    ["Closed-Loop System Tests (SYS)", "3 Test Cases", "End-to-End Co-Verification & Fault Injection"],
    ["Priority 1 (Smoke / Bring-up)", "18 Tests", "100% Passing Required for Gating"],
    ["Priority 2 (Functional / Sweeps)", "14 Tests", "Protocol, Timing & Corner Verification"],
    ["Priority 3 (Corner / Stress)", "3 Tests", "Maximum Bus Contention & Fault Injection"],
    ["Target Functional Coverage", "100.0%", "Zero Coverage Holes at Tape-Out / Sign-Off"],
    ["Target Code Coverage", "> 95.0% Statement, Branch, Expression, FSM", "Synopsys VCS URG Sign-off"]
]
wb.add_sheet("Executive_Dashboard", rows_dash)

# ==============================================================================
# SHEET 2: SoC_Address_Map
# ==============================================================================
rows_map = [
    ["Port / Target", "Base Address", "End Address", "Aperture Size", "Native Protocol", "Subsystem Description", "Status"],
    ["Master S00", "—", "—", "—", "AXI4 (64b->32b)", "VeeR EL2 LSU (Load/Store Unit) - Data access & CSR config", "ACTIVE"],
    ["Master S01", "—", "—", "—", "AXI4 (64b->32b)", "VeeR EL2 IFU (Instruction Fetch Unit) - Code fetches", "ACTIVE"],
    ["Master S02", "—", "—", "—", "AXI4 (64b->32b)", "VeeR EL2 SB (System Bus / Debug Unit)", "ACTIVE"],
    ["Master S03", "—", "—", "—", "AXI4 (32b)", "Expansion Master / Autonomous DMA Channel", "RESERVED"],
    ["Master S04", "—", "—", "—", "AXI4 (32b)", "Expansion Master 2 (Tied-off with ready-sinks)", "INACTIVE"],
    ["Slave M00", "0x1000_0000", "0x1000_FFFF", "64 KB", "AXI4 Full", "Instruction Memory (IMEM) - 16384 x 32-bit words", "ACTIVE"],
    ["Slave M01", "0x1002_0000", "0x1002_FFFF", "64 KB", "AXI4 Full", "Data Memory (DMEM) - 16384 x 32-bit words", "ACTIVE"],
    ["Slave M02", "0x4000_0000", "0x4000_0FFF", "4 KB", "AXI4-Lite", "I2C Master Controller (Selected IP 1)", "ACTIVE"],
    ["Slave M03", "0x4000_2000", "0x4000_2FFF", "4 KB", "AXI4-Lite", "PWM Generator (Selected IP 2)", "ACTIVE"],
    ["Slave M04", "0x4000_4000", "0x4000_4FFF", "4 KB", "Tied-Off Sink", "Reserved Aperture (Tied off in RTL)", "TIED-OFF"],
    ["Slave M05", "0x4000_6000", "0x4000_6FFF", "4 KB", "AXI4-Lite", "16550 AXI UART (Telemetry / Console)", "ACTIVE"],
    ["Slave M06", "0x4000_8000", "0x4000_8FFF", "4 KB", "AXI4-Lite", "System Timer (Sample Rate / Ticks)", "ACTIVE"],
    ["Slave M07", "0x4000_A000", "0x4000_AFFF", "4 KB", "AXI4-Lite", "GPIO Controller (Buttons & Display/Status LEDs)", "ACTIVE"],
    ["Core Local", "0xEE00_0000", "0xEE00_FFFF", "64 KB", "Core Internal", "ICCM (Instruction Closely Coupled Memory)", "ACTIVE"],
    ["Core Local", "0xF004_0000", "0xF004_FFFF", "64 KB", "Core Internal", "DCCM (Data Closely Coupled Memory)", "ACTIVE"],
    ["Core Local", "0xF00C_0000", "0xF00C_7FFF", "32 KB", "Core Internal", "PIC (Programmable Interrupt Controller)", "ACTIVE"],
    ["Slave M08..M19", "0x5000_0000+", "—", "4 KB each", "DECERR Stub", "Unmapped Apertures (Return bresp/rresp = 2'b11)", "DECERR"]
]
wb.add_sheet("SoC_Address_Map", rows_map)

# ==============================================================================
# SHEET 3: Peripheral_Register_Map
# ==============================================================================
rows_reg = [
    ["IP Block", "Register Name", "Offset", "Access", "Reset Value", "Bit Range", "Field Name", "Field Description"],
    ["I2C", "I2C_CTRL", "0x00", "RW", "0x0000_0000", "[0]", "EN", "1 = Core enabled (scl/sda active); 0 = released high-Z"],
    ["I2C", "I2C_CTRL", "0x00", "RW", "0x0000_0000", "[1]", "IE", "1 = Assert irq_i2c when STATUS.DONE = 1"],
    ["I2C", "I2C_PRESCALE", "0x04", "RW", "0x0000_00FF", "[15:0]", "DIV", "SCL freq = fclk / (4 * (DIV + 1)). Modify only when EN=0"],
    ["I2C", "I2C_TXR", "0x08", "RW", "0x0000_0000", "[7:0]", "TXDATA", "Transmit byte buffer (sent when CMD.WR asserted)"],
    ["I2C", "I2C_RXR", "0x0C", "RO", "0x0000_0000", "[7:0]", "RXDATA", "Received byte shifted in by last CMD.RD"],
    ["I2C", "I2C_CMD", "0x10", "WO", "0x0000_0000", "[0]", "START", "1 = Generate START / Repeated START on bus"],
    ["I2C", "I2C_CMD", "0x10", "WO", "0x0000_0000", "[1]", "STOP", "1 = Generate STOP condition on bus"],
    ["I2C", "I2C_CMD", "0x10", "WO", "0x0000_0000", "[2]", "WR", "1 = Transmit TXR byte to slave, sample slave ACK"],
    ["I2C", "I2C_CMD", "0x10", "WO", "0x0000_0000", "[3]", "RD", "1 = Receive byte into RXR from slave"],
    ["I2C", "I2C_CMD", "0x10", "WO", "0x0000_0000", "[4]", "NACK", "Master ACK value for read: 0 = ACK, 1 = NACK"],
    ["I2C", "I2C_STATUS", "0x14", "MIXED", "0x0000_0000", "[0]", "BUSY", "RO: 1 = Command is currently executing"],
    ["I2C", "I2C_STATUS", "0x14", "MIXED", "0x0000_0000", "[1]", "DONE", "W1C: Command completed. Drives irq_i2c when IE=1"],
    ["I2C", "I2C_STATUS", "0x14", "MIXED", "0x0000_0000", "[2]", "NACK_RX", "RO: Slave ACK status: 0 = ACK, 1 = NACK"],
    ["I2C", "I2C_STATUS", "0x14", "MIXED", "0x0000_0000", "[3]", "BUS_BUSY", "RO: 1 between START and STOP conditions"],
    ["PWM", "PWM_CTRL", "0x00", "RW", "0x0000_0000", "[0]", "EN", "1 = Master counter running; 0 = held at 0"],
    ["PWM", "PWM_CTRL", "0x00", "RW", "0x0000_0000", "[4:1]", "CH_EN", "Bit n enables output pin of Channel n"],
    ["PWM", "PWM_CTRL", "0x00", "RW", "0x0000_0000", "[8:5]", "POL", "Bit n: 0 = Active-high, 1 = Inverted (active-low)"],
    ["PWM", "PWM_PRESCALE", "0x04", "RW", "0x0000_0000", "[15:0]", "DIV", "Counter increments every DIV + 1 clocks"],
    ["PWM", "PWM_PERIOD", "0x08", "RW", "0x0000_00FF", "[15:0]", "PERIOD", "Counter runs 0..PERIOD then wraps (period = PERIOD+1 ticks)"],
    ["PWM", "PWM_DUTY0", "0x0C", "RW", "0x0000_0080", "[15:0]", "DUTY0", "Channel 0 compare threshold"],
    ["PWM", "PWM_DUTY1", "0x10", "RW", "0x0000_0080", "[15:0]", "DUTY1", "Channel 1 compare threshold"],
    ["PWM", "PWM_DUTY2", "0x14", "RW", "0x0000_0080", "[15:0]", "DUTY2", "Channel 2 compare threshold"],
    ["PWM", "PWM_DUTY3", "0x18", "RW", "0x0000_0080", "[15:0]", "DUTY3", "Channel 3 compare threshold"],
    ["PWM", "PWM_COUNT", "0x1C", "RO", "0x0000_0000", "[15:0]", "COUNT", "Current up-counter value"],
    ["PWM", "PWM_STATUS", "0x20", "W1C", "0x0000_0000", "[0]", "PERIOD_MATCH", "W1C: Counter reached PERIOD; asserts irq_pwm"],
    ["UART", "UART_RBR", "0x00", "RC", "0x0000_0000", "[7:0]", "RBR", "Received byte; read pops RX FIFO"],
    ["UART", "UART_THR", "0x00", "WO", "0x0000_0000", "[7:0]", "THR", "Transmit holding register; push to TX FIFO"],
    ["UART", "UART_IER", "0x04", "RW", "0x0000_0000", "[0]", "RX_IE", "1 = Assert irq_uart when RX FIFO not empty"],
    ["UART", "UART_BAUD_DIV", "0x08", "RW", "0x0000_0364", "[31:0]", "DIV", "Baud divisor: fclk / baud (868 for 115200 @ 100MHz)"],
    ["UART", "UART_LCR", "0x0C", "RW", "0x0000_0000", "[1:0]", "WLEN", "00=5b, 01=6b, 10=7b, 11=8b data width"],
    ["UART", "UART_LCR", "0x0C", "RW", "0x0000_0000", "[2]", "STOP", "0 = 1 stop bit, 1 = 2 stop bits"],
    ["UART", "UART_LCR", "0x0C", "RW", "0x0000_0000", "[3]", "PAR_EN", "1 = Parity enabled"],
    ["UART", "UART_LCR", "0x0C", "RW", "0x0000_0000", "[7]", "DLAB", "Divisor Latch Access Bit"],
    ["UART", "UART_LSR", "0x14", "RO", "0x0000_0060", "[0]", "DATA_READY", "1 = Valid byte present in RX FIFO"],
    ["UART", "UART_LSR", "0x14", "RO", "0x0000_0060", "[5]", "THRE", "1 = TX Holding Register Empty"],
    ["UART", "UART_LSR", "0x14", "RO", "0x0000_0060", "[6]", "TEMT", "1 = Transmitter Empty (serializer idle)"],
    ["TIMER", "TIMER_CTRL", "0x00", "RW", "0x0000_0000", "[0]", "EN", "1 = Run; 0 = COUNT held at RELOAD"],
    ["TIMER", "TIMER_RELOAD", "0x04", "RW", "0x0000_0000", "[31:0]", "RELOAD", "32-bit countdown reload value"],
    ["TIMER", "TIMER_COUNT", "0x08", "RO", "0x0000_0000", "[31:0]", "COUNT", "Current live down-counter value"],
    ["TIMER", "TIMER_STATUS", "0x0C", "W1C", "0x0000_0000", "[0]", "TICK", "W1C: Set on tick; raises sample_tick & irq_timer"],
    ["GPIO", "GPIO_IN", "0x00", "RO", "0x0000_0000", "[7:0]", "IN", "gpio_in[7:0] after 2-stage synchronizer"],
    ["GPIO", "GPIO_OUT", "0x04", "RW", "0x0000_0000", "[7:0]", "OUT", "Drives gpio_out[7:0] display & status LEDs"],
    ["GPIO", "GPIO_IRQ_EN", "0x08", "RW", "0x0000_0000", "[7:0]", "CHANGE_EN", "1 = Edge change on pin raises irq_gpio"],
    ["GPIO", "GPIO_STATUS", "0x0C", "W1C", "0x0000_0000", "[0]", "CHANGED", "W1C: Edge change detected flag"]
]
wb.add_sheet("Peripheral_Register_Map", rows_reg)

# ==============================================================================
# SHEET 4: Master_Test_Plan (All 35 Tests)
# ==============================================================================
master_tests = [
    # S.No, ID, Spec, Domain, Category, Name, Pri, Type, Seq, Desc, Checkpoints, FW, UVM, Oracle, Cover, Freq, Status
    ("1", "TC_INT_CPU_01", "SPEC_1.1", "INTERNAL", "Processor Subsystem", "Power-On Reset & Clean Boot", "P1-Smoke", "DIR",
     "soc_cpu_reset_seq", "Verifies reset de-assertion, boot vector fetch from 0x1000_0000, and first instruction retirement in IMEM.",
     "25%: Reset asserted, CPU halt\n50%: Reset released, IFU requests 0x1000_0000\n75%: First AUIPC fetched\n100%: 30+ insns retired, trace valid",
     "Assembly startup crt0.S sets sp, gp, initializes registers, and jumps to main().",
     "Assert rst_n for 20 cycles; monitor IFU AR/R channels; trace execution.",
     "Core Trace Monitor & Instruction Retirement Counter (>30 insns, 0 exceptions)", "cg_cpu_exec::cp_boot", "Per-Commit", "VERIFIED"),

    ("2", "TC_INT_CPU_02", "SPEC_1.2", "INTERNAL", "Processor Subsystem", "Dual-Issue Superscalar Throughput", "P2-Functional", "DIR",
     "soc_cpu_dual_issue_seq", "Verifies VeeR EL2 dual-issue pipeline retiring 2 instructions in a single cycle on independent ALU arithmetic.",
     "25%: Preload dual-issue sequence into IMEM\n50%: Core enters compute loop\n75%: Trace monitor records 2 retired insns\n100%: IPC > 1.0 achieved",
     "Executes loop of independent register additions and logic instructions.",
     "Snoops trace_rv_i_valid_ip; checks consecutive instruction retirement timestamps.",
     "Trace Monitor Dual-Issue Checker (trace_rv_i_valid_ip[1:0] == 2'b11)", "cg_cpu_exec::cp_dual_issue", "Nightly", "VERIFIED"),

    ("3", "TC_INT_CPU_03", "SPEC_1.3", "INTERNAL", "Processor Subsystem", "MRAC Non-Cacheable I/O Enforcement", "P1-Smoke", "DIR",
     "soc_cpu_mrac_seq", "Verifies CSR 0x7C0 configures peripheral apertures as non-cacheable idempotent, enforcing single-beat 32-bit AXI accesses.",
     "25%: Write 0xAAAAAAA2 to MRAC CSR 0x7C0\n50%: Store word to UART (0x4000_600C)\n75%: LSU down-converter generates single 32-bit beat\n100%: Interconnect accepts single beat",
     "C code writes 0xAAAAAAA2 to CSR 0x7C0; writes to UART LCR and DMEM.",
     "Monitors s00_axi_awaddr & awsize; ensures peripheral access is 32-bit single beat.",
     "AXI Protocol Checker (awsize == 3'b010, awlen == 0, no burst coalescing)", "cg_cpu_exec::cp_mrac", "Per-Commit", "VERIFIED"),

    ("4", "TC_INT_CPU_04", "SPEC_1.4", "INTERNAL", "Processor Subsystem", "Branch Mispredict Flush & Recovery", "P2-Functional", "CR",
     "soc_cpu_branch_stress_seq", "Verifies branch predictor penalty, speculative fetch cancellation, and pipeline flush recovery.",
     "25%: Core executes alternating branch loop\n50%: Branch predictor mispredicts condition\n75%: IFU aborts speculative fetch buffer\n100%: Resumes cleanly at target PC",
     "Executes alternating conditional branch loop with data-dependent conditions.",
     "Monitors IFU fetch requests during branch redirection; verifies no speculative instructions retire.",
     "Architectural Register File Coherency & Branch Flush Monitor", "cg_cpu_exec::cp_branch", "Nightly", "PLANNED"),

    ("5", "TC_INT_CPU_05", "SPEC_1.5", "INTERNAL", "Processor Subsystem", "Compressed Instruction (RVC) Execution", "P2-Functional", "CR",
     "soc_cpu_rvc_seq", "Verifies 16-bit compressed instruction decoding (RV32C) and unaligned 16-bit instruction alignment in IFU.",
     "25%: Load firmware with RVC instructions\n50%: IFU fetches 64-bit word spanning 4 RVC insns\n75%: Decompressor expands 16-bit to 32-bit\n100%: All instructions retire accurately",
     "Compiled C code with -march=rv32imc emitting compressed instructions.",
     "Compares trace_rv_i_insn_ip against disassembled 16-bit opcodes; verifies PC steps by 2.",
     "Disassembly Scoreboard & PC Step Checker", "cg_cpu_exec::cp_rvc", "Nightly", "PLANNED"),

    ("6", "TC_INT_CPU_06", "SPEC_1.6", "INTERNAL", "Processor Subsystem", "Trap & Exception Handling", "P2-Functional", "ERR",
     "soc_cpu_trap_seq", "Verifies trap vectoring on illegal instructions or unaligned accesses to mtvec and clean return via mret.",
     "25%: Program mtvec to ISR vector address\n50%: Execute illegal opcode 0xFFFFFFFF\n75%: Core enters trap; mcause records code 2\n100%: ISR logs trap; mret restores PC",
     "Sets up mtvec ISR in crt0.S; executes illegal opcode test; logs mcause to DMEM.",
     "Verifies trace_rv_i_exception_ip pulses high; mcause captures correct exception code.",
     "CSR mtvec/mcause In-Order Monitor & Trap State Assertion", "cg_cpu_exec::cp_traps", "Nightly", "PLANNED"),

    ("7", "TC_INT_CPU_07", "SPEC_1.7", "INTERNAL", "Processor Subsystem", "PIC Priority Vectoring", "P1-Smoke", "DIR",
     "soc_pic_priority_seq", "Verifies PIC arbitration and prioritized CPU vectoring across all 5 peripheral interrupt lines.",
     "25%: Initialize PIC priorities\n50%: Assert Timer and I2C interrupts concurrently\n75%: Core vectors to higher-priority I2C ISR first\n100%: Timer ISR serviced upon I2C completion",
     "C firmware configures PIC priority registers and enables external interrupts.",
     "Forces multiple interrupt requests simultaneously; monitors CPU mepc vectoring sequence.",
     "PIC In-Order Interrupt Servicing Monitor", "cg_pic_irq::cp_priority", "Per-Commit", "VERIFIED"),

    ("8", "TC_INT_BUS_01", "SPEC_2.1", "INTERNAL", "Bus Fabric & Memory", "Multi-Master Contention & Round-Robin", "P1-Smoke", "PERF",
     "axi_multimaster_contention_seq", "Verifies non-blocking crossbar routing and fair arbitration under simultaneous master contention.",
     "25%: Arm Masters S00 (LSU) and S01 (IFU)\n50%: Issue simultaneous concurrent write bursts to DMEM\n75%: Crossbar arbiter grants masters sequentially\n100%: All transfers complete with OKAY",
     "Core executes store loop in DMEM while expansion master executes memory transfers.",
     "Drives concurrent bursts on S00 and S01; verifies arbiter grant latency and fair bandwidth sharing.",
     "UVM Interconnect Arbiter & Latency Monitor (Arbiter latency <= 4 cycles)", "cg_axi_matrix::cp_contention", "Per-Commit", "VERIFIED"),

    ("9", "TC_INT_BUS_02", "SPEC_2.2", "INTERNAL", "Bus Fabric & Memory", "Unmapped Aperture DECERR Trap", "P1-Smoke", "ERR",
     "axi_decerr_injection_seq", "Verifies crossbar decoder routes unmapped addresses (0x5000_0000) to DECERR stub.",
     "25%: Master S00 issues write to unmapped 0x5000_0000\n50%: Crossbar address decoder identifies unmapped slot\n75%: Interconnect drives bresp = 2'b11 (DECERR)\n100%: Master terminates cycle without hanging",
     "Executes load from 0x5000_0000; verifies bus fault or error response handling.",
     "Snoops crossbar slave response lines; checks bresp==2'b11 and rresp==2'b11 within 2 cycles.",
     "AXI Protocol Response Checker (bresp/rresp == 2'b11)", "cg_axi_matrix::cp_decerr", "Per-Commit", "VERIFIED"),

    ("10", "TC_INT_BUS_03", "SPEC_2.3", "INTERNAL", "Bus Fabric & Memory", "AXI Burst Length Sweeps (1–16 Beats)", "P2-Functional", "CR",
     "axi_burst_sweep_seq", "Verifies multi-beat INCR bursts across interconnect to on-chip IMEM and DMEM memories.",
     "25%: Configure burst generator on Master S00\n50%: Sweep burst lengths: 1, 2, 4, 8, 16 beats\n75%: Monitor wlast and rlast strobe assertions\n100%: Scoreboard verifies full payload match in RAM",
     "Firmware initiates block move with varying transfer word sizes (4 to 64 bytes).",
     "AXI VIP monitors awlen/arlen and validates exact beat counts and last strobe alignment.",
     "AXI Protocol Compliance Checker (wlast/rlast beat match)", "cg_axi_matrix::cp_burst_len", "Nightly", "VERIFIED"),

    ("11", "TC_INT_BUS_04", "SPEC_2.4", "INTERNAL", "Bus Fabric & Memory", "Byte-Strobe (wstrb) Sub-Word Masking", "P2-Functional", "CR",
     "axi_wstrb_masking_seq", "Verifies 8-bit (byte) and 16-bit (half-word) writes with active wstrb modifying only addressed byte lanes.",
     "25%: Preload 32-bit word 0x12345678 into DMEM\n50%: Issue byte write 0xAA to byte lane 1 (wstrb=4'b0010)\n75%: Read back 32-bit word from DMEM\n100%: Contents verified 0x1234AA78",
     "Executes sb and sh instructions to specific byte offsets in DMEM; reads back word.",
     "Scoreboard checks memory byte lanes; asserts that unaddressed bytes remain strictly unchanged.",
     "Memory Byte-Lane Data Integrity Scoreboard", "cg_axi_matrix::cp_wstrb", "Nightly", "VERIFIED"),

    ("12", "TC_INT_BUS_05", "SPEC_2.5", "INTERNAL", "Bus Fabric & Memory", "Read-After-Write (RAW) Hazard Integrity", "P2-Functional", "DIR",
     "axi_raw_hazard_seq", "Verifies read transaction to same address immediately following write completes with latest data.",
     "25%: Master writes 0xCAFEBABE to 0x1002_0200\n50%: Write response BVALID received\n75%: Master issues read to 0x1002_0200 in next cycle\n100%: Read data returns 0xCAFEBABE",
     "Executes store word followed immediately by load word from the same memory location.",
     "Monitors write handshake completion before read data return; verifies no stale data returned.",
     "UVM RAW Memory Hazard In-Order Scoreboard", "cg_axi_matrix::cp_raw_hazard", "Nightly", "VERIFIED"),

    ("13", "TC_INT_I2C_01", "SPEC_3.1", "INTERNAL", "I2C Master Controller", "I2C Register HW Reset & Bit-Bash", "P1-Smoke", "DIR",
     "i2c_reg_hw_reset_seq", "Verifies reset values and writable bitfields of I2C_CTRL, PRESCALE, TXR, RXR, CMD, STATUS.",
     "25%: Reset DUT; read all I2C registers\n50%: Verify default values match spec\n75%: Bit-bash RW fields with inverted patterns\n100%: Verify RO and W1C bit protection",
     "Firmware reads all I2C registers post-reset, writes test patterns, verifies readbacks.",
     "UVM RAL executes uvm_reg_hw_reset_seq and uvm_reg_bit_bash_seq across I2C block.",
     "UVM RAL Register Comparator (100% field match)", "cg_i2c_reg::cp_bitbash", "Per-Commit", "VERIFIED"),

    ("14", "TC_INT_I2C_02", "SPEC_3.2", "INTERNAL", "I2C Master Controller", "I2C Command Sequencer & Done Flag", "P2-Functional", "DIR",
     "i2c_cmd_sequencer_seq", "Verifies command trigger transitions: START, WR, RD, STOP, and STATUS.DONE assertion.",
     "25%: Configure prescaler; enable I2C core\n50%: Issue CMD.START followed by CMD.WR\n75%: STATUS.BUSY asserts during transmission\n100%: STATUS.DONE asserts upon completion; irq_i2c raised",
     "C code writes commands to I2C_CMD; polls or waits for DONE interrupt.",
     "Monitors internal I2C FSM states; verifies state transitions and IRQ strobe generation.",
     "I2C Controller Internal FSM State Monitor", "cg_i2c_ctrl::cp_cmd_seq", "Nightly", "VERIFIED"),

    ("15", "TC_EXT_I2C_01", "SPEC_3.3", "EXTERNAL", "I2C Master Controller", "I2C Bus Timing & SCL Frequency Compliance", "P1-Smoke", "DIR",
     "i2c_pin_timing_seq", "Measures SCL frequency, tHIGH, tLOW, tSU:STA, and tHD:STA on physical scl and sda pins against I2C specs.",
     "25%: Set PRESCALE = 255 (100 kHz mode)\n50%: External VIP captures 10 SCL clock cycles\n60%: Set PRESCALE = 62 (400 kHz Fast-Mode)\n100%: Protocol analyzer verifies timing windows",
     "Firmware programs I2C_PRESCALE and triggers transmission.",
     "I2C Protocol Analyzer VIP measures physical scl/sda edges; checks against I2C Standard/Fast mode specs.",
     "I2C Physical Layer Timing Checker (fSCL matches formula +/- 1%, tHIGH/tLOW compliant)", "cg_i2c_pins::cp_scl_timing", "Per-Commit", "VERIFIED"),

    ("16", "TC_EXT_I2C_02", "SPEC_3.4", "EXTERNAL", "I2C Master Controller", "Sensor Byte Write & Slave ACK Handshake", "P1-Smoke", "DIR",
     "i2c_slave_ack_seq", "External I2C Slave VIP acknowledges device address (0x48) and data byte; controller records NACK_RX == 0.",
     "25%: Controller sends START + Slave Addr (0x90)\n50%: Slave VIP pulls sda low during 9th SCL clock\n75%: Controller latches ACK; sets STATUS.NACK_RX = 0\n100%: Data byte transferred successfully",
     "Firmware initiates I2C write of address 0x90 and data byte 0x55.",
     "Reactive I2C Slave VIP pulls sda low during 9th clock to acknowledge address and data.",
     "I2C Slave Scoreboard (ACK sampled; STATUS.NACK_RX == 0)", "cg_i2c_pins::cp_ack_handshake", "Per-Commit", "VERIFIED"),

    ("17", "TC_EXT_I2C_03", "SPEC_3.5", "EXTERNAL", "I2C Master Controller", "Sensor Byte Read & Master ACK/NACK", "P2-Functional", "DIR",
     "i2c_master_read_seq", "Master reads data byte from Slave VIP (sensor data 0x3A), drives ACK, reads final byte, drives NACK.",
     "25%: Controller writes sensor register pointer\n50%: Controller issues Repeated START + Read Addr\n75%: Slave VIP shifts out sensor data byte 0x3A\n100%: Master latches data in I2C_RXR; issues NACK",
     "Firmware performs read sequence; retrieves RXR data and writes to DMEM.",
     "I2C Slave VIP drives 0x3A on sda; checks that Master drives sda high on 9th clock (NACK).",
     "I2C Data Integrity Scoreboard (I2C_RXR == 0x3A; Master drives valid NACK)", "cg_i2c_pins::cp_master_read", "Nightly", "VERIFIED"),

    ("18", "TC_EXT_I2C_04", "SPEC_3.6", "EXTERNAL", "I2C Master Controller", "Slave Clock Stretching Resilience", "P2-Functional", "CR",
     "i2c_clock_stretch_seq", "External I2C Slave VIP holds scl low to insert wait states; verifies master pauses sequencer until scl released.",
     "25%: Controller initiates byte transfer\n50%: Slave VIP pulls scl low for 50 system clocks\n75%: Master holds state; does not advance bit counter\n100%: Slave releases scl; transfer completes normally",
     "Firmware initiates standard I2C read transaction.",
     "I2C Slave VIP forces scl low mid-byte for 50 clocks; monitors master response.",
     "I2C Clock Stretching Checker (No bit corruption, sequencer pauses and resumes cleanly)", "cg_i2c_pins::cp_clock_stretch", "Nightly", "VERIFIED"),

    ("19", "TC_EXT_I2C_05", "SPEC_3.7", "EXTERNAL", "I2C Master Controller", "Slave NACK Detection on Invalid Address", "P2-Functional", "ERR",
     "i2c_nack_detection_seq", "Controller addresses non-existent slave; Slave VIP leaves sda floating (high); verifies NACK_RX == 1.",
     "25%: Controller transmits unassigned address 0x7E\n50%: Slave VIP does not assert ACK on 9th clock\n75%: Master detects high sda; asserts STATUS.NACK_RX = 1\n100%: Controller raises DONE interrupt; aborts safely",
     "Firmware transmits unassigned address; checks STATUS.NACK_RX and executes abort.",
     "Slave VIP remains passive; lets pull-up keep sda high; monitors master abort sequence.",
     "I2C Error Detection Scoreboard (STATUS.NACK_RX == 1, clean STOP generated)", "cg_i2c_pins::cp_nack_detect", "Nightly", "VERIFIED"),

    ("20", "TC_INT_PWM_01", "SPEC_4.1", "INTERNAL", "PWM Generator", "PWM Register HW Reset & Bit-Bash", "P1-Smoke", "DIR",
     "pwm_reg_hw_reset_seq", "Verifies reset state and writable bitfields of PWM_CTRL, PRESCALE, PERIOD, DUTY0..3, COUNT, STATUS.",
     "25%: Reset DUT; verify default register values\n50%: Write walking 1s and 0s to DUTY0..3\n75%: Verify COUNT register is read-only\n100%: Verify STATUS.PERIOD_MATCH clears via W1C",
     "Firmware executes register write/read test across PWM address space.",
     "UVM RAL executes reset and bit-bash sequences on PWM block.",
     "UVM RAL Register Comparator (100% field match)", "cg_pwm_reg::cp_bitbash", "Per-Commit", "VERIFIED"),

    ("21", "TC_INT_PWM_02", "SPEC_4.2", "INTERNAL", "PWM Generator", "Prescaler & Period Rollover Flag", "P2-Functional", "DIR",
     "pwm_rollover_irq_seq", "Verifies counter increments every DIV + 1 cycles, rolls over at PERIOD, and asserts PERIOD_MATCH interrupt.",
     "25%: Set DIV = 3, PERIOD = 10\n50%: Counter increments every 4 system clocks\n75%: At count 10, counter rolls over to 0\n100%: STATUS.PERIOD_MATCH asserts; irq_pwm raised",
     "Firmware programs DIV=3, PERIOD=10; waits for irq_pwm and clears flag.",
     "Monitors internal PWM counter and interrupt strobe to PIC.",
     "PWM Internal Counter & Period Match Assertion (Strictly 44 cycles per rollover)", "cg_pwm_ctrl::cp_period_irq", "Nightly", "VERIFIED"),

    ("22", "TC_EXT_PWM_01", "SPEC_4.3", "EXTERNAL", "PWM Generator", "Duty Cycle Sweep (0%, 25%, 50%, 75%, 100%)", "P1-Smoke", "CR",
     "pwm_duty_sweep_seq", "PWM VIP measures high/low time on pwm_out[0] across full range of duty cycle settings with PERIOD = 255.",
     "25%: Program DUTY0 = 0 (0% duty; static low)\n50%: Program DUTY0 = 64 (25%), 128 (50%)\n75%: Program DUTY0 = 192 (75% duty)\n100%: Program DUTY0 = 256 (100% duty; static high)",
     "Firmware programs DUTY0 values in sequence.",
     "PWM Duty-Cycle Analyzer VIP measures physical high-time and period on pwm_out[0].",
     "PWM Duty Accuracy Scoreboard (Measured duty matches DUTY/(PERIOD+1) +/- 0.01%)", "cg_pwm_pins::cp_duty_sweep", "Per-Commit", "VERIFIED"),

    ("23", "TC_EXT_PWM_02", "SPEC_4.4", "EXTERNAL", "PWM Generator", "4-Channel Independent Multi-Actuator Drive", "P2-Functional", "DIR",
     "pwm_multi_channel_seq", "Verifies all 4 channels (pwm_out[3:0]) drive independent duty cycles simultaneously without crosstalk.",
     "25%: Configure Ch0=10%, Ch1=30%, Ch2=60%, Ch3=90%\n50%: Enable all 4 channels in PWM_CTRL.CH_EN\n75%: PWM VIP monitors all 4 pins concurrently\n100%: Verify all 4 channels match independent settings",
     "Firmware configures different duty values for DUTY0..3 and enables channels.",
     "PWM Analyzer VIP captures and compares all 4 channels in parallel.",
     "Multi-Channel Actuator Scoreboard (All 4 channels verified simultaneously)", "cg_pwm_pins::cp_multi_channel", "Nightly", "VERIFIED"),

    ("24", "TC_EXT_PWM_03", "SPEC_4.5", "EXTERNAL", "PWM Generator", "Polarity Inversion Verification", "P2-Functional", "DIR",
     "pwm_polarity_seq", "Verifies PWM_CTRL.POL inverts output level on pwm_out pins (active-high vs active-low).",
     "25%: Program Ch0 duty to 25% with POL[0] = 0\n50%: PWM VIP measures high pulse width = 25% period\n75%: Toggle POL[0] = 1 (active-low)\n100%: PWM VIP measures high pulse width = 75% period",
     "Firmware toggles POL bits in PWM_CTRL.",
     "PWM Analyzer VIP compares inverted vs non-inverted pulse waveforms.",
     "PWM Polarity Checker (Waveform strictly inverted; active-low drives 0 during duty)", "cg_pwm_pins::cp_polarity", "Nightly", "VERIFIED"),

    ("25", "TC_EXT_PWM_04", "SPEC_4.6", "EXTERNAL", "PWM Generator", "Channel Gating & Idle State", "P2-Functional", "DIR",
     "pwm_channel_gate_seq", "Verifies disabling channel in CH_EN immediately drives pin to configured inactive level without runt pulses.",
     "25%: Channel 0 actively generating 50% PWM\n50%: Write CH_EN[0] = 0 mid-cycle\n75%: pwm_out[0] immediately drops to idle level\n100%: No spurious glitches or runt pulses observed",
     "Firmware disables channel mid-cycle.",
     "PWM Analyzer VIP checks for glitch-free transition to idle level.",
     "PWM Glitch & Runt Pulse Monitor (0 spurious glitches on disable)", "cg_pwm_pins::cp_channel_gate", "Nightly", "VERIFIED"),

    ("26", "TC_INT_TMR_01", "SPEC_5.1", "INTERNAL", "System Timer", "Countdown Accuracy & Tick Interrupt", "P1-Smoke", "DIR",
     "timer_countdown_seq", "Verifies TIMER_RELOAD countdown, TIMER_COUNT decrements, and irq_timer raises on 0.",
     "25%: Program RELOAD = 100\n50%: Enable timer; observe COUNT decrementing\n75%: At 0, STATUS.TICK sets; irq_timer asserts\n100%: Write W1C clears flag; irq_timer deasserts",
     "Firmware configures reload, waits for interrupt, writes W1C.",
     "Monitors internal timer count and interrupt to PIC.",
     "Timer Tick Accuracy Scoreboard (Period strictly equals RELOAD+1)", "cg_timer::cp_countdown", "Per-Commit", "VERIFIED"),

    ("27", "TC_EXT_TMR_01", "SPEC_5.2", "EXTERNAL", "System Timer", "Physical sample_tick 1-Cycle Pulse Width", "P1-Smoke", "DIR",
     "timer_sample_tick_pulse_seq", "Oscilloscope/Monitor checks external boundary pin sample_tick is asserted for exactly 1 clock cycle.",
     "25%: Timer armed with reload value 50\n50%: Wait for sample_tick high\n75%: Verify sample_tick is high for exactly 10 ns (1 clock)\n100%: Verify signal drops low in subsequent cycle",
     "Firmware enables timer.",
     "External monitor verifies boundary pin pulse width on sample_tick.",
     "Pulse Width Assertion (Strictly 1 system clock cycle duration)", "cg_timer::cp_tick_pulse", "Per-Commit", "VERIFIED"),

    ("28", "TC_INT_GPIO_01", "SPEC_6.1", "INTERNAL", "GPIO Controller", "GPIO Pin Change Interrupt Mask", "P2-Functional", "DIR",
     "gpio_irq_mask_seq", "Verifies GPIO_IRQ_EN selectively enables pin-change interrupts only for unmasked bits.",
     "25%: Set GPIO_IRQ_EN = 8'h01 (pin 0 only)\n50%: Toggle pin 1; verify irq_gpio does NOT assert\n75%: Toggle pin 0; verify irq_gpio asserts immediately\n100%: W1C write to GPIO_STATUS clears interrupt",
     "Firmware configures GPIO_IRQ_EN and services ISR.",
     "Monitors internal GPIO edge detector and interrupt line to PIC.",
     "GPIO Interrupt Masking Checker (IRQ only fires on unmasked pin edges)", "cg_gpio::cp_irq_mask", "Nightly", "VERIFIED"),

    ("29", "TC_EXT_GPIO_01", "SPEC_6.2", "EXTERNAL", "GPIO Controller", "Button Input Synchronizer & Metastability", "P1-Smoke", "CR",
     "gpio_sync_metastability_seq", "Drives asynchronous transitions onto gpio_in[7:0]; verifies 2-stage flip-flop synchronizer filters metastability.",
     "25%: Inject asynchronous edges on gpio_in\n50%: Monitor synchronizer output gpio_in_sync\n75%: Verify stable latching after exactly 2 clock cycles\n100%: Register GPIO_IN reflects external pin value",
     "Firmware reads GPIO_IN register.",
     "GPIO Driver VIP injects asynchronous edge transitions; checks 2-cycle latency.",
     "GPIO Synchronizer Latency & Stability Checker (2 cycles latency, 0 X-propagation)", "cg_gpio::cp_sync_lat", "Per-Commit", "VERIFIED"),

    ("30", "TC_EXT_GPIO_02", "SPEC_6.3", "EXTERNAL", "GPIO Controller", "Display Pattern & Status LED Drive", "P1-Smoke", "DIR",
     "gpio_display_led_seq", "Firmware writes walking 1s and display patterns to GPIO_OUT; GPIO VIP verifies gpio_out[7:0] pins reflect data.",
     "25%: Write 0x55 to GPIO_OUT\n50%: VIP verifies gpio_out == 8'h55\n75%: Write 0xAA to GPIO_OUT\n100%: VIP verifies gpio_out == 8'hAA",
     "Firmware writes sensed value display patterns to GPIO_OUT.",
     "GPIO Monitor VIP checks pin voltages and bit patterns.",
     "GPIO Display Output Scoreboard (100% match on gpio_out[7:0] pins)", "cg_gpio::cp_led_drive", "Per-Commit", "VERIFIED"),

    ("31", "TC_INT_UART_01", "SPEC_7.1", "INTERNAL", "16550 UART", "UART TX/RX FIFO Status & Watermark Flags", "P1-Smoke", "DIR",
     "uart_fifo_status_seq", "Verifies UART_LSR flags: THRE (TX FIFO empty), TEMT (transmitter idle), and DATA_READY (RX byte valid).",
     "25%: Reset UART; verify THRE == 1, TEMT == 1, DATA_READY == 0\n50%: Write byte to UART_THR; verify THRE toggles\n75%: Inject byte into RX; verify DATA_READY == 1\n100%: Read UART_RBR; verify DATA_READY clears",
     "Firmware tests LSR flags during byte writes and reads.",
     "UVM RAL verifies LSR bit transitions.",
     "UART LSR Status Flag Scoreboard", "cg_uart::cp_lsr_flags", "Per-Commit", "VERIFIED"),

    ("32", "TC_EXT_UART_01", "SPEC_7.2", "EXTERNAL", "16550 UART", "Serial Frame Transmission (115200 Baud)", "P1-Smoke", "DIR",
     "uart_tx_framing_seq", "UART VIP captures serial bitstream on uart_tx; verifies start bit, 8 data bits, stop bit, and bit duration (8.68 us).",
     "25%: Set divisor to 868 (115200 baud); write 'OK' to THR\n50%: UART VIP samples start bit transition (high-to-low)\n75%: Samples 8 data bits at mid-bit centers\n100%: Verifies valid stop bit (high); framing error count = 0",
     "Firmware programs UART_BAUD_DIV = 868, transmits test characters.",
     "UART Terminal VIP deserializes bitstream; validates 8-N-1 protocol.",
     "UART Protocol Checker (Bit period = 8.68 us +/- 1%, 0 framing errors)", "cg_uart::cp_tx_framing", "Per-Commit", "VERIFIED"),

    ("33", "TC_SYS_01", "SPEC_8.1", "CLOSED-LOOP", "Closed-Loop System", "End-to-End Sense-Process-Actuate-Display", "P1-Smoke", "SW",
     "soc_closed_loop_sense_actuate_seq", "Demonstration application: Timer paces I2C sensor read -> CPU computes -> updates PWM duty -> drives GPIO display -> logs UART telemetry.",
     "25%: System booted; all IPs configured; Timer ticking\n50%: Sensor VIP injects 25C; I2C reads 0x19; PWM=25%, GPIO displays pattern, UART logs\n75%: Sensor VIP ramps to 60C; PWM=60%, GPIO updates\n100%: Sensor VIP injects 85C; PWM=100%, GPIO alert flash, UART alert",
     "Full bare-metal C closed-loop control application running in VeeR EL2 core.",
     "Full UVM environment active: I2C VIP injects temp ramp, PWM VIP measures duty, GPIO VIP verifies display, UART VIP parses telemetry.",
     "Closed-Loop System Sign-Off Scoreboard (100% correlation across sensor, duty, GPIO, UART)", "cg_closed_loop::cp_full_pipeline", "Per-Commit", "VERIFIED"),

    ("34", "TC_SYS_02", "SPEC_8.2", "CLOSED-LOOP", "Closed-Loop System", "Concurrent Multi-Peripheral Bus Stress", "P2-Functional", "PERF",
     "soc_concurrent_stress_seq", "All peripherals operating in parallel: continuous UART + Timer ticks + I2C reads + PWM running + GPIO display toggles + CPU memory copy.",
     "25%: All peripheral masters and interrupt sources enabled\n50%: Concurrent bus traffic hits peak crossbar contention\n75%: All 5 PIC interrupt lines assert dynamically\n100%: 50,000 clock cycles completed without bus stall or data loss",
     "C code runs compute-heavy array copy in DMEM while handling interrupts.",
     "All external VIPs drive concurrent traffic; monitors crossbar arbiters.",
     "System Stability Scoreboard (0 bus deadlocks, 0 dropped frames/interrupts)", "cg_closed_loop::cp_bus_stress", "Nightly", "VERIFIED"),

    ("35", "TC_SYS_03", "SPEC_8.3", "CLOSED-LOOP", "Closed-Loop System", "Over-Temperature Emergency Trip", "P2-Functional", "ERR",
     "soc_emergency_shutdown_seq", "Injects sensor temperature exceeding safety limit (>100C); CPU ISR immediately drives PWM override to 100%, flashes GPIO alert pattern, logs UART alert.",
     "25%: Closed loop running normally at 30C\n50%: Sensor VIP injects over-temperature fault 0x78 (120C)\n60%: Core detects threshold violation in I2C ISR\n75%: Emergency sequence: PWM duty -> 100%, GPIO -> Alert\n100%: Telemetry alert verified on UART terminal",
     "C ISR detects critical temperature and triggers safety shutdown sequence.",
     "I2C Slave VIP injects fault; PWM & GPIO VIPs verify immediate fail-safe transition.",
     "Emergency Response Scoreboard (Fail-safe latency < 50 us; 100% PWM fan override)", "cg_closed_loop::cp_emergency_trip", "Nightly", "VERIFIED")
]

header_master = [
    "S.No", "Test ID", "Spec Ref", "Domain", "Subsystem Category", "Test Name",
    "Priority", "Test Type", "UVM Sequence Class", "Test Description & Objectives",
    "Checkpoints (25% -> 50% -> 75% -> 100% Milestones)", "C Firmware Routine (sw/)",
    "SystemVerilog UVM Action (VIPs / BFM)", "Pass Criteria & Golden Oracle",
    "Target Covergroup Tag", "Regression Frequency", "Status"
]

rows_master = [header_master]
for t in master_tests:
    rows_master.append(list(t))
wb.add_sheet("Master_Test_Plan", rows_master)

# ==============================================================================
# SHEET 5: Internal_Test_Cases (Filtered INT)
# ==============================================================================
rows_int = [header_master]
for t in master_tests:
    if t[3] == "INTERNAL":
        rows_int.append(list(t))
wb.add_sheet("Internal_Test_Cases", rows_int)

# ==============================================================================
# SHEET 6: External_Test_Cases (Filtered EXT)
# ==============================================================================
rows_ext = [header_master]
for t in master_tests:
    if t[3] == "EXTERNAL":
        rows_ext.append(list(t))
wb.add_sheet("External_Test_Cases", rows_ext)

# ==============================================================================
# SHEET 7: UVM_Env_Architecture
# ==============================================================================
rows_env = [
    ["UVM Component", "Class Name", "Interface Connected", "Hierarchical Role", "Key Verification Responsibilities"],
    ["Top Testbench", "soc_top_tb", "soc_top (DUT)", "Testbench Root", "Instantiates DUT, clocks (100 MHz), reset generator, interface binding."],
    ["AXI Master VIP", "axi_master_agent", "s00..s04_axi_*", "Bus Driver / Monitor", "Drives memory transactions into crossbar or snoops VeeR EL2 LSU/IFU transactions."],
    ["I2C Slave VIP", "i2c_slave_agent", "scl, sda (inout)", "Reactive Environmental VIP", "Emulates off-chip sensors (e.g. LM75); drives ACK/NACK, data bytes, clock stretching."],
    ["PWM Analyzer VIP", "pwm_analyzer_agent", "pwm_out[3:0]", "Passive Measurement VIP", "Measures physical pulse width, period, duty cycle, frequency, jitter, and polarity."],
    ["GPIO VIP", "gpio_agent", "gpio_in, gpio_out", "Stimulus & Display VIP", "Drives button inputs with bounce/glitches; checks 2-stage synchronizer and display/LED patterns."],
    ["UART Terminal VIP", "uart_agent", "uart_tx, uart_rx", "Full-Duplex Serial VIP", "Deserializes 115200 baud stream; checks framing/stop/parity; parses ASCII telemetry."],
    ["UVM RAL Model", "soc_reg_model", "AXI Crossbar (M02..M07)", "Register Layer", "Mirrors all memory-mapped registers; executes reset, bit-bash, and backdoor checks."],
    ["Core Trace Monitor", "veer_trace_monitor", "trace_rv_i_*", "CPU Execution Monitor", "Verifies instruction retirement, PC progression, exception codes, and dual-issue."],
    ["Closed-Loop Scoreboard", "soc_closed_loop_sb", "All VIP Analysis Ports", "End-to-End Oracle", "Cross-checks I2C sensor input against computed PWM duty, GPIO display, and UART output."],
    ["Coverage Collector", "soc_coverage_subscriber", "All VIP Analysis Ports", "Coverage Closure", "Samples crossbar, register bitfields, I2C protocol, PWM duty, GPIO display covergroups."]
]
wb.add_sheet("UVM_Env_Architecture", rows_env)

# ==============================================================================
# SHEET 8: Cat1_2_CPU_Fabric
# ==============================================================================
rows_cat1_2 = [header_master]
for t in master_tests:
    if t[4] in ["Processor Subsystem", "Bus Fabric & Memory"]:
        rows_cat1_2.append(list(t))
wb.add_sheet("Cat1_2_CPU_Fabric", rows_cat1_2)

# ==============================================================================
# SHEET 9: Cat3_I2C_Subsystem
# ==============================================================================
rows_cat3 = [header_master]
for t in master_tests:
    if t[4] == "I2C Master Controller":
        rows_cat3.append(list(t))
wb.add_sheet("Cat3_I2C_Subsystem", rows_cat3)

# ==============================================================================
# SHEET 10: Cat4_PWM_Subsystem
# ==============================================================================
rows_cat4 = [header_master]
for t in master_tests:
    if t[4] == "PWM Generator":
        rows_cat4.append(list(t))
wb.add_sheet("Cat4_PWM_Subsystem", rows_cat4)

# ==============================================================================
# SHEET 11: Cat5_Timer_GPIO_UART
# ==============================================================================
rows_cat5 = [header_master]
for t in master_tests:
    if t[4] in ["System Timer", "GPIO Controller", "16550 UART"]:
        rows_cat5.append(list(t))
wb.add_sheet("Cat5_Timer_GPIO_UART", rows_cat5)

# ==============================================================================
# SHEET 12: Cat6_ClosedLoop_SenseActuate
# ==============================================================================
rows_cat6 = [header_master]
for t in master_tests:
    if t[4] == "Closed-Loop System":
        rows_cat6.append(list(t))
wb.add_sheet("Cat6_ClosedLoop_SenseActuate", rows_cat6)

# ==============================================================================
# SHEET 13: Assertions_SVA_Library
# ==============================================================================
rows_sva = [
    ["Assertion ID", "Target Interface / Block", "Assertion Name", "SVA Property Definition", "Pass / Fail Condition & Action"],
    ["SVA_AXI_01", "AXI4 Interconnect", "AWADDR Stable During Wait", "property p_axil_awaddr_stable: (awvalid && !awready) |=> $stable(awaddr)", "FAIL if master changes write address before slave assert awready"],
    ["SVA_AXI_02", "AXI4 Interconnect", "BVALID Handshake Latch", "property p_axil_bvalid_stable: (bvalid && !bready) |=> bvalid", "FAIL if slave drops write response before master asserts bready"],
    ["SVA_AXI_03", "AXI4 Crossbar", "DECERR on Unmapped Space", "property p_decerr_check: (addr >= 0x5000_0000 && arvalid) |-> ##[1:5] (rresp == 2'b11)", "FAIL if unmapped address does not return AXI DECERR"],
    ["SVA_I2C_01", "I2C Boundary Pins", "SDA Stability on SCL High", "property p_sda_stable: (scl && !start_or_stop) |-> $stable(sda)", "FAIL if data line toggles while clock line is high (protocol violation)"],
    ["SVA_I2C_02", "I2C Controller", "Done Implies Not Busy", "property p_done_not_busy: i2c_done |-> !i2c_busy", "FAIL if DONE flag sets while controller is still shifting bits"],
    ["SVA_PWM_01", "PWM Boundary Pins", "Pulse Periodicity", "property p_pwm_periodic: (pwm_en && period_match) |-> ##[1:$] (pwm_out != $past(pwm_out))", "FAIL if PWM output fails to toggle across counter period"],
    ["SVA_PWM_02", "PWM Controller", "Counter Wrap at Period", "property p_count_wrap: (count == period) |=> (count == 0)", "FAIL if counter exceeds programmed period value"],
    ["SVA_TMR_01", "Timer Boundary Pin", "sample_tick 1-Cycle Pulse", "property p_sample_tick_pulse: sample_tick |=> !sample_tick", "FAIL if sample_tick output remains high for more than 1 cycle"],
    ["SVA_GPIO_01", "GPIO Boundary Pins", "2-Stage Synchronizer Latency", "property p_gpio_sync: $changed(gpio_in) |-> ##2 (gpio_in_sync == $past(gpio_in, 1))", "FAIL if input fails to synchronize within 2 clock cycles"],
    ["SVA_PIC_01", "PIC Controller", "Interrupt Service Vectoring", "property p_pic_service: (irq_i2c && !irq_uart) |-> ##[1:10] (cpu_pc == isr_i2c_addr)", "FAIL if CPU fails to vector to pending unmasked interrupt"]
]
wb.add_sheet("Assertions_SVA_Library", rows_sva)

# ==============================================================================
# SHEET 14: Coverage_Closure_Matrix
# ==============================================================================
rows_cov = [
    ["Coverage Model", "Covergroup Name", "Target Bins & Crosses", "Minimum Hits Required", "Sign-Off Target"],
    ["AXI Interconnect", "cg_axi_matrix", "Masters (S00..S03) x Slaves (M00..M07); Contention pairs; Burst lengths 1..16", "100 hits per bin", "100.0%"],
    ["Registers (RAL)", "cg_reg_fields", "Read/Write toggle on all RW bits; W1C transitions; Reset value checks across all CSRs", "10 hits per bit", "100.0%"],
    ["I2C Protocol", "cg_i2c_protocol", "Standard/Fast SCL speeds; START/STOP/WR/RD commands; ACK/NACK responses; Clock stretch", "50 hits per mode", "100.0%"],
    ["PWM Actuator", "cg_pwm_actuator", "Duty cycles: 0%, 1-24%, 25%, 50%, 75%, 100%; Prescalers; Polarity active-high/low", "50 hits per duty", "100.0%"],
    ["GPIO Display", "cg_gpio_display", "Display patterns and status values on gpio_out[7:0]; Pin change interrupts", "20 hits per pattern", "100.0%"],
    ["UART Telemetry", "cg_uart_telemetry", "Baud rates (9600, 115200); Word length (5-8); Stop bits (1-2); Parity; FIFO watermarks", "100 frames per config", "100.0%"],
    ["Timer & PIC", "cg_timer_pic", "Timer reload ranges (1..10000); 5-interrupt concurrent priority cross", "50 ticks / IRQs", "100.0%"],
    ["Closed-Loop System", "cg_closed_loop", "Input Temp Range x PWM Duty Output x GPIO Display x Telemetry Log", "50 complete loops", "100.0%"],
    ["Code Coverage", "VCS URG Model", "Line / Statement (>95%), Branch (>95%), Toggle (>90%), FSM State & Transition (>95%)", "All RTL lines", "> 95.0%"]
]
wb.add_sheet("Coverage_Closure_Matrix", rows_cov)

output_path = "/home/student/Documents/1602-23-735-163/Honours-Project-main/doc/SoC_UVM_Test_Plan.xlsx"
wb.build_zip(output_path)
print("Updated workbook written successfully to:", output_path)
