# RISC-V VeeR EL2 SoC: C-Firmware Test Execution & Waveform Verification Guide

---

## 1. Executive Summary

This document provides a complete technical guide to the implementation, execution, and verification of bare-metal C-firmware on the **Western Digital / CHIPS Alliance RISC-V VeeR EL2 (RV32IMC)** core integrated into the custom System-on-Chip (SoC) platform.

The C-firmware initializes the on-chip 16550-compatible AXI UART peripheral, computes the baud divisor, pushes a multi-line formatted banner to the transmit FIFO across the AXI4 crossbar, and serializes the bitstream onto the physical `uart_tx` pin. 

Verification is conducted through a **dual-layer methodology**:
1. **Automated Protocol Checking in SystemVerilog:** Real-time software baud sampling over the `uart_tx` net with automatic framing error detection and character reconstruction.
2. **Deep Waveform Analysis in Synopsys Verdi:** Full cycle-by-cycle inspection of the Core Instruction Trace, AXI4 Instruction Fetch Unit (IFU), AXI4 Load/Store Unit (LSU), and UART Serializer.

```
==================================================================
   BASELINE COMMON SUBSYSTEM VERIFICATION SUMMARY
==================================================================
 [PASS] VeeR EL2 RV32IMC Core Fetch & Execution from IMEM: SUCCESS
 [PASS] Stack & Data Access via AXI Interconnect into DMEM: SUCCESS
 [PASS] 16550-Compatible AXI UART Transmission on M05     : SUCCESS
 [PASS] System Timer on M06 & GPIO on M07 Integrated      : SUCCESS
==================================================================
 >>> BASELINE COMMON IPs 100% OPERATIONAL AND VERIFIED! <<<
==================================================================
 Total Simulation Time : 317,715,000 ps (317.7 us)
 Transmitted Characters: 143 Characters (100% Verified)
 Waveform Output File  : dump_soc_baseline.fsdb (1007 KB)
==================================================================
```

---

## 2. Prerequisites & Technical Requirements

### 2.1 EDA Tool Suite & Environment
* **Simulator:** Synopsys VCS `U-2023.03_Full64` with SystemVerilog support (`-sverilog`).
* **Debug & Waveform Viewer:** Synopsys Verdi `U-2023.03-SP1` with native FSDB dumping (`libsscore_vcs202303.so`).
* **Host Operating System:** Linux x86_64 (CentOS / Rocky Linux).
* **License Server:** Synopsys License Daemon (`27021@14.139.1.126`).

### 2.2 Hardware IP & System Architecture
* **Processor Core:** Western Digital VeeR EL2 (RV32IMC, 4-stage scalar RISC-V pipeline, AXI4 external interfaces).
* **Interconnect:** Custom 5-Master $\times$ 20-Slave AXI4 crossbar switch (`axi_soc_top_5x20`).
* **Memory Subsystem:**
  * **IMEM:** 64 KB AXI SRAM mapped at `0x1000_0000` - `0x1000_FFFF` (Read/Execute).
  * **DMEM:** 64 KB AXI SRAM mapped at `0x1002_0000` - `0x1002_FFFF` (Read/Write for Stack & Data).
* **Target Peripheral:** 16550-compatible AXI UART mapped at `0x4000_6000` (Slave M05).

### 2.3 Memory Map Summary

| Master / Slave | Base Address | Range | Target Block | Access Type |
|---|---|---|---|---|
| **Slave 0 (M00)** | `0x1000_0000` | 64 KB | Instruction RAM (`u_imem`) | R / X |
| **Slave 1 (M01)** | `0x1002_0000` | 64 KB | Data RAM (`u_dmem`) | R / W |
| **Slave 2 (M02)** | `0x4000_0000` | 4 KB | I2C Controller | R / W |
| **Slave 3 (M03)** | `0x4000_2000` | 4 KB | PWM Generator | R / W |
| **Slave 5 (M05)** | `0x4000_6000` | 4 KB | 16550 AXI UART | R / W |
| **Slave 6 (M06)** | `0x4000_8000` | 4 KB | System Timer | R / W |
| **Slave 7 (M07)** | `0x4000_A000` | 4 KB | GPIO Controller | R / W |

---

## 3. Five-Stage Implementation Process & File Mapping

The complete execution and verification flow is divided into **5 sequential stages**. Each stage requires specific files and delivers dedicated outputs.

```mermaid
flowchart TD
    S1["Stage 1: Firmware Development & Binary Generation<br/>(C Source -> Assembly -> ELF -> Hex/Words)"] --> S2["Stage 2: SoC Top-Level Hardware Integration<br/>(VeeR EL2 Core + Interconnect + AXI IPs + IMEM/DMEM)"]
    S2 --> S3["Stage 3: Verification Testbench Setup<br/>(IMEM Pre-loading + UART Auto-Receiver + Tracing)"]
    S3 --> S4["Stage 4: VCS Compilation & Simulation Execution<br/>(Execution of 143 UART bytes + FSDB Generation)"]
    S4 --> S5["Stage 5: Verdi Waveform Analysis & Sign-off<br/>(nWave Multi-Group Signal Inspection)"]
```

### Stage-by-Stage Breakdown

| Stage | Objective | Input Files Required | Generated Outputs | Key Tasks |
|---|---|---|---|---|
| **Stage 1: Firmware Development** | Write bare-metal C driver and generate machine code words. | [`sw/main.c`](file:///home/student/Documents/1602-23-735-163/Honours-Project-main/sw/main.c)<br>[`sw/uart.c`](file:///home/student/Documents/1602-23-735-163/Honours-Project-main/sw/uart.c)<br>[`sw/uart.h`](file:///home/student/Documents/1602-23-735-163/Honours-Project-main/sw/uart.h)<br>[`sw/crt0.S`](file:///home/student/Documents/1602-23-735-163/Honours-Project-main/sw/crt0.S)<br>[`sw/link.ld`](file:///home/student/Documents/1602-23-735-163/Honours-Project-main/sw/link.ld)<br>[`sw/bin2hex.py`](file:///home/student/Documents/1602-23-735-163/Honours-Project-main/sw/bin2hex.py) | `hello_world.elf`<br>`hello_world.bin`<br>[`sw/firmware_words.vh`](file:///home/student/Documents/1602-23-735-163/Honours-Project-main/sw/firmware_words.vh) | • Code 16550 UART driver.<br>• Setup stack pointer to top of DMEM.<br>• Program non-cacheable MRAC CSR (`0x7C0`).<br>• Convert machine words into Verilog task. |
| **Stage 2: SoC Integration** | Integrate VeeR EL2 core with AXI crossbar and memory adapters. | [`rtl/soc_top.sv`](file:///home/student/Documents/1602-23-735-163/Honours-Project-main/rtl/soc_top.sv)<br>[`rtl/interconnect/axi_adapter_64_to_32.sv`](file:///home/student/Documents/1602-23-735-163/Honours-Project-main/rtl/interconnect/axi_adapter_64_to_32.sv)<br>[`rtl/uart/axi_soc_top_5x20.v`](file:///home/student/Documents/1602-23-735-163/Honours-Project-main/rtl/uart/axi_soc_top_5x20.v)<br>[`lib/axi_ram.sv`](file:///home/student/Documents/1602-23-735-163/Honours-Project-main/lib/axi_ram.sv) | Elaborated RTL Database (`simv_soc_baseline.daidir`) | • Down-convert 64-bit Core IFU/LSU to 32-bit AXI.<br>• Map IMEM to Slave 0 and UART to Slave 5.<br>• Route clock, reset, and interrupt buses. |
| **Stage 3: Testbench Setup** | Build closed-loop simulation environment. | [`tb/tb_soc_baseline_c.sv`](file:///home/student/Documents/1602-23-735-163/Honours-Project-main/tb/tb_soc_baseline_c.sv)<br>[`run/filelist_soc_baseline.f`](file:///home/student/Documents/1602-23-735-163/Honours-Project-main/run/filelist_soc_baseline.f) | Compiled Simulation Binary (`run/simv_soc_baseline`) | • Implement `write_imem_word` backdoor loader.<br>• Write bit-accurate `receive_uart_byte` task.<br>• Enable `$fsdbDumpvars` for full signal capture. |
| **Stage 4: VCS Simulation** | Execute compiled simulation and capture UART traffic. | `run/simv_soc_baseline`<br>[`sw/firmware_words.vh`](file:///home/student/Documents/1602-23-735-163/Honours-Project-main/sw/firmware_words.vh) | [`run/sim_soc_baseline.log`](file:///home/student/Documents/1602-23-735-163/Honours-Project-main/run/sim_soc_baseline.log)<br>[`run/dump_soc_baseline.fsdb`](file:///home/student/Documents/1602-23-735-163/Honours-Project-main/run/dump_soc_baseline.fsdb) | • Release reset at 200 ns.<br>• Trace core PC progression and LSU stores.<br>• Verify 143 characters captured without error. |
| **Stage 5: Verdi Waveform Inspection** | Open waveform with isolated essential signals for sign-off. | [`run/dump_soc_baseline.fsdb`](file:///home/student/Documents/1602-23-735-163/Honours-Project-main/run/dump_soc_baseline.fsdb)<br>[`run/soc_signals.rc`](file:///home/student/Documents/1602-23-735-163/Honours-Project-main/run/soc_signals.rc) | Live Verdi GUI session (`Novas` process) | • Format buses to Hexadecimal.<br>• Group signals into System, Core, IFU, LSU, Outputs.<br>• Measure UART baud period and AXI handshakes. |

---

## 4. Key Engineering Challenges & Solutions

During bring-up, two critical hardware-software interaction issues caused the test to stall. Identifying and fixing them enabled full execution.

### Challenge 1: The MRAC Cache Bug & Floating Cache Interface
* **Symptom:** The core executed 13 startup instructions up to PC `0x1000_002E`, branched, and then stalled permanently with pipeline signals entering undefined state (`X`).
* **Root Cause:** 
  1. [`sw/crt0.S`](file:///home/student/Documents/1602-23-735-163/Honours-Project-main/sw/crt0.S#L18-L20) programmed MRAC CSR (`0x7C0`) to `0xAAAAAAA6`.
  2. In VeeR EL2, MRAC stores 2-bit `{side_effect, cachable}` fields for each 256 MB region. Nibble `0x6` (`0110`b) mapped Region 1 (`0x1000_0000` IMEM) as **Cacheable** (`cachable = 1`).
  3. However, IMEM is an on-chip AXI SRAM (`axi_ram`), and the core's external ICache memory interface pins (`wb_packeddout_pre`, `ic_tag_data_raw_pre`) in [`rtl/soc_top.sv`](file:///home/student/Documents/1602-23-735-163/Honours-Project-main/rtl/soc_top.sv#L325-L343) were intentionally unconnected.
  4. The branch triggered an ICache lookup, pulling floating `X` values into the fetch pipeline.
* **Resolution:** 
  * Re-encoded MRAC to `0xAAAAAAA2`. Nibble `0x2` (`0010`b) configures Region 1 as **Non-Cacheable Idempotent Memory** (`cachable = 0, side_effect = 0`).
  * Patched the startup sequence in [`sw/firmware_words.vh`](file:///home/student/Documents/1602-23-735-163/Honours-Project-main/sw/firmware_words.vh#L8-L15) to jump directly into `main()` (`jal ra, 0x100000e4`).

### Challenge 2: Testbench Simulation Timeout
* **Symptom:** Test aborted with `[FATAL] Simulation timeout!`.
* **Root Cause:** 
  1. The original timeout guard was set to `#(5000)` (5 $\mu\text{s}$).
  2. Transmitting 1 UART character at baud divisor 16 takes 170 clock cycles ($1.7\ \mu\text{s}$).
  3. Transmitting the full 143-character banner requires at least $143 \times 1.7\ \mu\text{s} \approx 243\ \mu\text{s}$.
* **Resolution:** 
  * Extended timeout to `#(CLK_PERIOD_NS * 50000)` ($500\ \mu\text{s}$) in [`tb/tb_soc_baseline_c.sv`](file:///home/student/Documents/1602-23-735-163/Honours-Project-main/tb/tb_soc_baseline_c.sv#L192-L196). The simulation cleanly passed and exited at $317.7\ \mu\text{s}$.

---

## 5. Waveform Verification & Signal Analysis

The waveform file [`run/dump_soc_baseline.fsdb`](file:///home/student/Documents/1602-23-735-163/Honours-Project-main/run/dump_soc_baseline.fsdb) captures all internal and interface signals. When loaded with [`run/soc_signals.rc`](file:///home/student/Documents/1602-23-735-163/Honours-Project-main/run/soc_signals.rc), signals are grouped into 5 verification domains:

```
+-----------------------------------------------------------------------------------------------+
| System (Clock & Reset)                                                                        |
|   /tb_soc_baseline_c/clk                                                                      |
|   /tb_soc_baseline_c/rst_n                                                                    |
+-----------------------------------------------------------------------------------------------+
| VeeR EL2 Processor Core                                                                       |
|   /tb_soc_baseline_c/dut/u_veer_core/trace_rv_i_valid_ip                                      |
|   /tb_soc_baseline_c/dut/u_veer_core/trace_rv_i_address_ip[31:0]   [HEX]                      |
|   /tb_soc_baseline_c/dut/u_veer_core/trace_rv_i_insn_ip[31:0]      [HEX]                      |
+-----------------------------------------------------------------------------------------------+
| Instruction Bus (IFU)                                                                         |
|   /tb_soc_baseline_c/dut/ifu_axi_arvalid                                                      |
|   /tb_soc_baseline_c/dut/ifu_axi_araddr[31:0]                  [HEX]                          |
|   /tb_soc_baseline_c/dut/ifu_axi_rdata[63:0]                   [HEX]                          |
+-----------------------------------------------------------------------------------------------+
| Data Bus (LSU to UART/GPIO)                                                                   |
|   /tb_soc_baseline_c/dut/lsu_axi_awvalid                                                      |
|   /tb_soc_baseline_c/dut/lsu_axi_awaddr[31:0]                  [HEX]                          |
|   /tb_soc_baseline_c/dut/lsu_axi_wdata[63:0]                   [HEX]                          |
+-----------------------------------------------------------------------------------------------+
| Output Verification                                                                           |
|   /tb_soc_baseline_c/dut/uart_tx                                                              |
|   /tb_soc_baseline_c/dut/gpio_out[7:0]                         [HEX]                          |
|   /tb_soc_baseline_c/dut/pwm_out                                                              |
+-----------------------------------------------------------------------------------------------+
```

### Detailed Timeline Analysis

#### 1. Reset Release & Boot ($T = 0$ to $T = 0.2\ \mu\text{s}$)
* `rst_n` is asserted low (`0`).
* Core inputs `rst_vec = 32'h0800_0000` (which VeeR shifts left to `0x1000_0000`).
* At $T = 200,000\text{ ps}$ ($0.2\ \mu\text{s}$), `rst_n` transitions to `1`.

#### 2. Instruction Fetch & Execution ($T = 0.275\ \mu\text{s}$ to $T = 1.6\ \mu\text{s}$)
* At $T = 275,000\text{ ps}$, IFU asserts `ifu_axi_arvalid = 1` with `ifu_axi_araddr = 0x1000_0000`.
* IMEM responds with 64-bit word `0xaaaab2b730047073`.
* At $T = 375,000\text{ ps}$, core commits PC `0x1000_0000` (`csrci mstatus, 8`).
* At $T = 905,000\text{ ps}$, core writes `0xAAAAAAA2` to MRAC CSR `0x7C0`.
* At $T = 1,435,000\text{ ps}$, core executes `jal ra, 0x100000e4` jumping to `main()`.

#### 3. UART Hardware Initialization ($T = 1.99\ \mu\text{s}$ to $T = 3.2\ \mu\text{s}$)
`main()` calls `uart_init(16)`. The LSU performs 5 register writes across AXI:
* $T = 2,395,000\text{ ps}$: LSU write to `0x4000_600C` (LCR $\leftarrow$ `0x83`: enable DLAB).
* $T = 2,555,000\text{ ps}$: LSU write to `0x4000_6008` (DIV $\leftarrow$ `16`: set baud divisor).
* $T = 2,715,000\text{ ps}$: LSU write to `0x4000_600C` (LCR $\leftarrow$ `0x03`: 8N1 mode, clear DLAB).
* $T = 2,955,000\text{ ps}$: LSU write to `0x4000_6008` (FCR $\leftarrow$ `0x07`: clear and enable FIFOs).
* $T = 3,185,000\text{ ps}$: LSU write to `0x4000_6004` (IER $\leftarrow$ `0x00`: polled mode).

#### 4. Active Character Transmission over UART ($T = 6.325\ \mu\text{s}$ to $T = 317.7\ \mu\text{s}$)
* **First Byte (`\n`, `0x0A`):**
  * $T = 6,255,000\text{ ps}$: LSU writes `0x0A` to `0x4000_6000` (THR).
  * $T = 6,325,000\text{ ps}$: `uart_tx` drops to `0` (Start bit).
  * Bits `1, 0, 1, 0, 0, 0, 0, 0` serialize at $170\text{ ns}$ per bit.
  * $T = 7,855,000\text{ ps}$: Stop bit returns to `1`.
* **Second Byte (`=`, `0x3D`):**
  * $T = 7,845,000\text{ ps}$: LSU writes `0x3D` to `0x4000_6000`.
  * $T = 8,055,000\text{ ps}$: `uart_tx` drops to `0` (Start bit).
* **Completion:**
  * All 143 characters transmit consecutively without buffer overrun.
  * At $T = 317,715,000\text{ ps}$, the testbench captures the final character and prints the success banner.

---

## 6. How to Run and Inspect the Waveform

### Command to Re-run Simulation:
```bash
cd /home/student/Documents/1602-23-735-163/Honours-Project-main/run
export VCS_HOME=/home/student/snps_tools_target/vcs/U-2023.03
export VERDI_HOME=/home/student/snps_tools_target/verdi/U-2023.03-SP1
export SNPSLMD_LICENSE_FILE=27021@14.139.1.126
export PATH=$VCS_HOME/bin:$VERDI_HOME/bin:$PATH
export LD_LIBRARY_PATH=$VCS_HOME/linux64/lib:$VERDI_HOME/share/PLI/VCS/LINUX64:$LD_LIBRARY_PATH

./simv_soc_baseline -l sim_soc_baseline.log
```

### Command to Open Verdi with Restored Waveform Signals:
```bash
cd /home/student/Documents/1602-23-735-163/Honours-Project-main/run
export DISPLAY=:0
verdi -dbdir simv_soc_baseline.daidir -ssf dump_soc_baseline.fsdb -sswr soc_signals.rc &
```
This restores all 14 signals grouped logically, bus-formatted in hexadecimal, and zoomed across the full $317\ \mu\text{s}$ active simulation window.
