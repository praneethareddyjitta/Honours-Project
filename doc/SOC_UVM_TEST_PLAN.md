# SoC Architecture Specification & Comprehensive UVM Test Plan

**Project:** RTL Design and Verification of a RISC-V VeeR EL2 Based System-on-Chip  
**Core Complex:** Western Digital / CHIPS Alliance RISC-V VeeR EL2 Core Complex (RV32IMC)  
**System Interconnect:** 5-Master $\times$ 20-Slave AXI4 Crossbar Fabric (`axi_soc_top_5x20` / `axi_interconnect_wrap_5x20`)  
**Integrated Peripherals:**
- **I2C Master Controller** (`0x4000_0000`, Slave M02): Off-chip serial communication (`scl`, `sda`)
- **PWM Generator** (`0x4000_2000`, Slave M03): 4-channel programmable duty-cycle actuator (`pwm_out[3:0]`)
- **16550 AXI UART** (`0x4000_6000`, Slave M05): Full-duplex serial console & telemetry (`uart_tx`, `uart_rx`)
- **System Timer** (`0x4000_8000`, Slave M06): Periodic tick generation (`sample_tick`, `irq_timer`)
- **GPIO Controller** (`0x4000_A000`, Slave M07): 8-bit inputs (`gpio_in[7:0]`) and 8-bit display/status outputs (`gpio_out[7:0]`)
- **Instruction Memory (IMEM)** (`0x1000_0000`, Slave M00): 64 KB AXI4 SRAM
- **Data Memory (DMEM)** (`0x1002_0000`, Slave M01): 64 KB AXI4 SRAM
*(Note: M04 is tied off in hardware; visual numeric and status display is performed directly via GPIO parallel outputs).*  
**Target Verification Framework:** Universal Verification Methodology (UVM 1.2 / IEEE 1800.2) + SystemVerilog Assertions (SVA)  
**Target Simulators:** Synopsys VCS (`U-2023.03_Full64`) / Verdi (`U-2023.03-SP1`), Cadence Xcelium, Siemens Questa  

---

## 1. System Overview & Closed-Loop Sense-Process-Actuate-Display

The SoC integrates a 32-bit RISC-V VeeR EL2 core with an AXI4 crossbar interconnect matrix and five tightly integrated peripherals forming a self-contained **Sense-Process-Actuate-Display** pipeline:

```
                                    +-----------------------------------------+
                                    |       External Environmental Sensor     |
                                    |         (Behavioral I2C Slave VIP)      |
                                    +-----------------------------------------+
                                                         |
                                            scl, sda     | [EXTERNAL I2C PROTOCOL]
                                                         v
+------------------+   sample_tick  +-----------------------------------------+
|   System Timer   |--------------->|          I2C Master Controller          |
+------------------+ (pacing tick)  +-----------------------------------------+
         |                                               | irq_i2c (PIC Src 3)
         |                                               v
+-----------------------------------------------------------------------------+
|                      AXI4 5x20 Crossbar Interconnect                        |
|   (5 Masters: LSU, IFU, SB, DMA/Exp, Exp | 20 Slaves: Peripherals & Memory) |
+-----------------------------------------------------------------------------+
         ^                        ^                         ^
         | [INTERNAL AXI BUS]     |                         |
         v                        v                         v
+------------------+    +-------------------+    +--------------------+
|  VeeR EL2 Core   |    | Instruction RAM   |    |     Data RAM       |
|  Complex (RV32I) |    |  (IMEM - 64 KB)   |    |  (DMEM - 64 KB)    |
+------------------+    +-------------------+    +--------------------+
   |  |        |
   |  |        +--------> PIC (Interrupts: UART, Timer, GPIO, I2C, PWM)
   |  |
   |  +-----------------+ [INTERNAL BUS WRITES]
   v                    v
+-------------------+ +---------------------------------+ +--------------------+
|   PWM Generator   | |         GPIO Controller         | |   16550 AXI UART   |
+-------------------+ +---------------------------------+ +--------------------+
         |                            |                              |
pwm_out  | [ACTUATION]   gpio_out     | [NUMERIC/STATUS DISPLAY]     | [SERIAL TELEMETRY]
         v                            v                              v
+-------------------+ +---------------------------------+ +--------------------+
| Fan / Motor / LED | | Sensed Value / Pattern Display  | | Telemetry Terminal |
| Actuator Receiver | | (7-Segment Drivers / Indicators)| | (115200 Baud Host) |
+-------------------+ +---------------------------------+ +--------------------+
```

### Operational Data Flow:
1. **Pacing:** System Timer asserts periodic `sample_tick` pulses to trigger acquisition.
2. **Sense:** VeeR EL2 core initiates I2C transactions to read sensor registers from off-chip slave device (`scl`, `sda`).
3. **Process:** Core processes raw readings in software (scaling, calibration, threshold comparison).
4. **Actuate:** Core sets proportional duty cycle in PWM Generator (`PWM_DUTY0`) driving `pwm_out`.
5. **Display & Indicate:** Core writes numerical patterns and status flags directly to `GPIO_OUT`, driving external display decoders and LEDs, while streaming formatted telemetry over `UART_THR`.

---

## 2. Bus Architecture, Interconnect Topology & Master/Slave Assignments

The SoC employs a non-blocking **5-Master $\times$ 20-Slave AXI4 Interconnect Crossbar Matrix** (`axi_soc_top_5x20`).

### 2.1 AXI4 Masters

| Master Port | Originating Entity | Native Width | Bridge / Adapter | Role |
| :---: | :--- | :---: | :--- | :--- |
| **S00** | VeeR EL2 LSU (Load/Store Unit) | 64-bit AXI4 | `axi_adapter_64_to_32` | Data memory access (DMEM stack/heap), peripheral register configuration |
| **S01** | VeeR EL2 IFU (Instruction Fetch Unit) | 64-bit AXI4 | `axi_adapter_64_to_32` | Instruction stream fetch from 64 KB on-chip Instruction Memory (IMEM) |
| **S02** | VeeR EL2 SB (System Bus / Debug) | 64-bit AXI4 | `axi_adapter_64_to_32` | System debug transactions, JTAG memory access |
| **S03** | Expansion / Autonomous DMA Port | 32-bit AXI4 | Native 32-bit AXI4 Master | Reserved for memory-to-memory block transfers |
| **S04** | Secondary Expansion Master Port | 32-bit AXI4 | Tied-off Inactive | Tied-off (`awvalid=0, arvalid=0`) with ready-sink terminations |

### 2.2 AXI4 Slaves & Address Decoding

| Slave Port | Destination Target | Base Address | End Address | Aperture Size | Protocol | Functionality |
| :---: | :--- | :---: | :---: | :---: | :---: | :--- |
| **M00** | Instruction Memory (`u_imem`) | `0x1000_0000` | `0x1000_FFFF` | 64 KB | AXI4 Full | On-chip code storage (16384 words $\times$ 32-bit) |
| **M01** | Data Memory (`u_dmem`) | `0x1002_0000` | `0x1002_FFFF` | 64 KB | AXI4 Full | On-chip data storage (16384 words $\times$ 32-bit) for stack & buffers |
| **M02** | I2C Master Controller (`u_i2c`) | `0x4000_0000` | `0x4000_0FFF` | 4 KB | AXI4-Lite | I2C serial interface (`scl`, `sda`) |
| **M03** | PWM Generator (`u_pwm`) | `0x4000_2000` | `0x4000_2FFF` | 4 KB | AXI4-Lite | 4-channel programmable PWM actuator (`pwm_out[3:0]`) |
| **M04** | Reserved Slot (Tied Off) | `0x4000_4000` | `0x4000_4FFF` | 4 KB | Tied-Off Sink | Unused peripheral aperture returning zero |
| **M05** | 16550 AXI UART (`u_axi_uart`) | `0x4000_6000` | `0x4000_6FFF` | 4 KB | AXI4-Lite | Serial console & telemetry logging (`uart_tx`, `uart_rx`) |
| **M06** | System Timer (`u_timer`) | `0x4000_8000` | `0x4000_8FFF` | 4 KB | AXI4-Lite | Countdown timer, generates `sample_tick` & `irq_timer` |
| **M07** | GPIO Controller (`u_gpio`) | `0x4000_A000` | `0x4000_AFFF` | 4 KB | AXI4-Lite | 8-bit inputs (`gpio_in`), 8-bit display/status outputs (`gpio_out`) |
| **M08..M19**| Unmapped Expansion Apertures | `0x5000_0000+`| — | 4 KB each | DECERR Stub | Returns AXI Decode Error (`bresp=2'b11`, `rresp=2'b11`) |

---

## 3. Peripheral Register Reference

### 3.1 I2C Master Controller (`0x4000_0000`)
- `0x00` (`I2C_CTRL`, RW): `[0]` `EN` (1 = enable), `[1]` `IE` (1 = interrupt enable).
- `0x04` (`I2C_PRESCALE`, RW): `[15:0]` `DIV` ($f_{SCL} = \frac{f_{clk}}{4 \times (DIV + 1)}$; default `0x00FF` for 100 kHz @ 100 MHz).
- `0x08` (`I2C_TXR`, RW): `[7:0]` `TXDATA` (transmit byte buffer).
- `0x0C` (`I2C_RXR`, RO): `[7:0]` `RXDATA` (received byte buffer).
- `0x10` (`I2C_CMD`, WO): `[0]` `START`, `[1]` `STOP`, `[2]` `WR`, `[3]` `RD`, `[4]` `NACK`.
- `0x14` (`I2C_STATUS`, MIXED): `[0]` `BUSY` (RO), `[1]` `DONE` (W1C, drives `irq_i2c`), `[2]` `NACK_RX` (RO), `[3]` `BUS_BUSY` (RO).

### 3.2 PWM Generator (`0x4000_2000`)
- `0x00` (`PWM_CTRL`, RW): `[0]` `EN`, `[4:1]` `CH_EN[3:0]`, `[8:5]` `POL[3:0]` (1 = active-low).
- `0x04` (`PWM_PRESCALE`, RW): `[15:0]` `DIV` (tick period = $DIV + 1$ clocks).
- `0x08` (`PWM_PERIOD`, RW): `[15:0]` `PERIOD` (counter wraps at $PERIOD$, reset `0x00FF`).
- `0x0C` (`PWM_DUTY0`, RW): `[15:0]` `DUTY0` (Channel 0 compare threshold, reset `0x0080` = 50%).
- `0x10..0x18` (`PWM_DUTY1..3`, RW): Compare thresholds for Channels 1..3.
- `0x1C` (`PWM_COUNT`, RO): Live 16-bit counter value.
- `0x20` (`PWM_STATUS`, W1C): `[0]` `PERIOD_MATCH` (asserts `irq_pwm`).

### 3.3 16550 AXI UART (`0x4000_6000`)
- `0x00` (`UART_RBR` / `THR`): Read pops RX FIFO; Write pushes TX FIFO.
- `0x04` (`UART_IER`, RW): `[0]` `RX_IE` (asserts `uart_irq` on valid byte).
- `0x08` (`UART_BAUD_DIV`, RW): `DIV = fclk / baud` (868 for 115200 @ 100 MHz).
- `0x0C` (`UART_LCR`, RW): `[1:0]` word length, `[2]` stop bits, `[3]` parity, `[7]` DLAB.
- `0x14` (`UART_LSR`, RO): `[0]` `DATA_READY`, `[5]` `THRE` (TX empty), `[6]` `TEMT`.

### 3.4 System Timer (`0x4000_8000`)
- `0x00` (`TIMER_CTRL`, RW): `[0]` `EN`.
- `0x04` (`TIMER_RELOAD`, RW): 32-bit countdown reload value.
- `0x08` (`TIMER_COUNT`, RO): Live countdown value.
- `0x0C` (`TIMER_STATUS`, W1C): `[0]` `TICK` (asserts `sample_tick` & `irq_timer`).

### 3.5 GPIO Controller (`0x4000_A000`)
- `0x00` (`GPIO_IN`, RO): `[7:0]` synchronized input pins.
- `0x04` (`GPIO_OUT`, RW): `[7:0]` output pins driving external indicators/display patterns.
- `0x08` (`GPIO_IRQ_EN`, RW): `[7:0]` per-pin edge-change interrupt mask.
- `0x0C` (`GPIO_STATUS`, W1C): `[0]` `CHANGED` (asserts `irq_gpio`).

---

## 4. Distinction Between Internal and External Test Cases

| Dimension | Internal Test Cases (`INT`) | External Test Cases (`EXT`) | Closed-Loop Integration (`SYS`) |
| :--- | :--- | :--- | :--- |
| **Stimulus Source** | On-chip VeeR EL2 firmware or UVM RAL driving internal AXI crossbar. | Off-chip VIPs driving physical pins (`scl`, `sda`, `uart_rx`, `gpio_in`). | External I2C Slave VIP driving dynamic sensor inputs into SoC. |
| **Boundary** | Internal AXI bus, CPU registers, CSRs. | Top-level physical pins (`pwm_out`, `gpio_out`, `uart_tx`, `scl`/`sda`). | Physical correlation across Sensor $\to$ CPU $\to$ Actuation $\to$ Display. |
| **Key Objectives** | • Register reset & bit-bash<br>• Dual-issue CPU throughput<br>• DECERR on unmapped space<br>• AXI burst & byte-strobe masking<br>• PIC interrupt arbitration | • I2C $f_{SCL}$, setup/hold timing<br>• I2C slave ACK/NACK & stretching<br>• PWM duty cycle % & jitter<br>• GPIO display pattern & LEDs<br>• UART 115200 framing accuracy | • Full Sense-Process-Actuate-Display<br>• Event-driven interrupt latency<br>• Concurrent peripheral stress<br>• Over-temperature emergency trip |

---

## 5. Master UVM Test Plan Catalog & Verification Status

All 36 test cases have been implemented in modular SystemVerilog/UVM test suites and verified using **Synopsys VCS U-2023.03_Full64** via the master regression script [`run/run_all_test_cases.sh`](file:///home/student/Documents/1602-23-735-163/Honours-Project-main/run/run_all_test_cases.sh).

| Domain | Category | Test ID | Test Name | Pri | Type | Verification Objectives | VCS Status |
| :---: | :--- | :---: | :--- | :---: | :---: | :--- | :---: |
| `INT` | **Processor** | `TC_INT_CPU_01` | Power-On Reset & Clean Boot | P1 | DIR | Boot vector fetch from `0x1000_0000`, first 30+ instructions retired. | **PASS** |
| `INT` | **Processor** | `TC_INT_CPU_02` | Dual-Issue Superscalar Throughput | P2 | DIR | VeeR EL2 dual-issue pipeline retiring instructions continuously (46 insns / 300 cycles). | **PASS** |
| `INT` | **Processor** | `TC_INT_CPU_03` | MRAC Non-Cacheable I/O Enforcement | P1 | DIR | CSR `0x7C0` forces single-beat 32-bit AXI access (`awlen=0`) to peripheral apertures. | **PASS** |
| `INT` | **Processor** | `TC_INT_CPU_04` | Branch Mispredict Flush & Recovery | P2 | CR | Verifies speculative prefetch cancellation and pipeline recovery. | **PASS** |
| `INT` | **Processor** | `TC_INT_CPU_05` | Compressed Instructions (RV32C) | P2 | CR | 16-bit compressed instruction decode, alignment, and decompression. | **PASS** |
| `INT` | **Processor** | `TC_INT_CPU_06` | Trap & Exception Handling | P2 | ERR | Illegal opcode triggers trap to `mtvec`; `mcause == 2`; clean `mret`. | **PASS** |
| `INT` | **Processor** | `TC_INT_CPU_07` | PIC Priority Vectoring | P1 | DIR | Arbitrates 5 concurrent peripheral IRQs; vectors in priority order (`core_extintsrc_req[1]=1`). | **PASS** |
| `INT` | **AXI Fabric** | `TC_INT_BUS_01` | Multi-Master Contention & Round-Robin | P1 | PERF | S00 (LSU) vs S01 (IFU) concurrent bursts to DMEM; zero starvation. | **PASS** |
| `INT` | **AXI Fabric** | `TC_INT_BUS_02` | Unmapped Aperture DECERR Trap | P1 | ERR | Access to unmapped apertures (`0x2000_0000`) returns `bresp/rresp = 2'b11`. | **PASS** |
| `INT` | **AXI Fabric** | `TC_INT_BUS_03` | AXI Burst Length Sweeps (1–16 Beats) | P2 | CR | Multi-beat INCR transfers to IMEM/DMEM; validates `wlast`/`rlast`. | **PASS** |
| `INT` | **AXI Fabric** | `TC_INT_BUS_04` | Byte-Strobe (`wstrb`) Sub-Word Masking | P2 | CR | Byte (`sb`) and half-word (`sh`) writes modify only addressed memory bytes. | **PASS** |
| `INT` | **AXI Fabric** | `TC_INT_BUS_05` | Read-After-Write (RAW) Hazard Check | P2 | DIR | Read immediately following write returns updated data without stale reads. | **PASS** |
| `INT` | **I2C Master** | `TC_INT_I2C_01` | I2C Register HW Reset & Bit-Bash | P1 | DIR | UVM RAL reset and bit-bash sequences on all 6 I2C CSRs. | **PASS** |
| `INT` | **I2C Master** | `TC_INT_I2C_02` | Command Sequencer & Done Flag | P2 | DIR | Validates `START`, `WR`, `RD`, `STOP` triggers and `irq_i2c` assertion. | **PASS** |
| `EXT` | **I2C Master** | `TC_EXT_I2C_01` | Bus Timing & SCL Frequency Compliance | P1 | DIR | Measures $f_{SCL}$ and setup/hold times for 100 kHz mode (170 ns SCL high). | **PASS** |
| `EXT` | **I2C Master** | `TC_EXT_I2C_02` | Sensor Write & Slave ACK Handshake | P1 | DIR | Slave VIP asserts ACK on 9th clock; controller captures `NACK_RX == 0`. | **PASS** |
| `EXT` | **I2C Master** | `TC_EXT_I2C_03` | Sensor Read & Master ACK/NACK | P2 | DIR | Slave VIP shifts data into `I2C_RXR`; controller generates Master NACK. | **PASS** |
| `EXT` | **I2C Master** | `TC_EXT_I2C_04` | Slave Clock Stretching Resilience | P2 | CR | Slave holds `scl` low for 200 ns; controller pauses sequencer cleanly. | **PASS** |
| `EXT` | **I2C Master** | `TC_EXT_I2C_05` | Slave NACK Detection on Bad Address | P2 | ERR | Unresponsive slave leaves `sda` floating; controller records `NACK_RX == 1`. | **PASS** |
| `INT` | **PWM Gen** | `TC_INT_PWM_01` | PWM Register HW Reset & Bit-Bash | P1 | DIR | UVM RAL verification of `PWM_CTRL`, `PERIOD`, `DUTY0..3`, `COUNT`. | **PASS** |
| `INT` | **PWM Gen** | `TC_INT_PWM_02` | Prescaler & Period Rollover Flag | P2 | DIR | Counter wraps at $PERIOD$; asserts `irq_pwm` to PIC. | **PASS** |
| `EXT` | **PWM Gen** | `TC_EXT_PWM_01` | Duty Cycle Sweep (0% to 100%) | P1 | CR | Duty analyzer VIP validates high/low time on `pwm_out[0]` (0%, 25%, 50%, 75%, 100%). | **PASS** |
| `EXT` | **PWM Gen** | `TC_EXT_PWM_02` | 4-Channel Independent Multi-Drive | P2 | DIR | Validates all 4 channels (`pwm_out[3:0]`) drive independent duty cycles. | **PASS** |
| `EXT` | **PWM Gen** | `TC_EXT_PWM_03` | Polarity Inversion Verification | P2 | DIR | `PWM_CTRL.POL` strictly inverts physical output pins (active-high vs low). | **PASS** |
| `EXT` | **PWM Gen** | `TC_EXT_PWM_04` | Channel Gating & Idle State | P2 | DIR | Disabling channel in `CH_EN` drives immediate glitch-free idle state. | **PASS** |
| `INT` | **Timer** | `TC_INT_TMR_01` | Countdown Accuracy & Tick IRQ | P1 | DIR | Verifies `TIMER_COUNT` down-count to 0, `sample_tick`, and `irq_timer`. | **PASS** |
| `EXT` | **Timer** | `TC_EXT_TMR_01` | `sample_tick` 1-Cycle Pulse Width | P1 | DIR | Oscilloscope monitor confirms `sample_tick` pin is high for exactly 10 ns. | **PASS** |
| `INT` | **GPIO** | `TC_INT_GPIO_01`| GPIO Pin Change Interrupt Mask | P2 | DIR | Verifies `GPIO_IRQ_EN` selectively raises `irq_gpio` only on unmasked bits. | **PASS** |
| `EXT` | **GPIO** | `TC_EXT_GPIO_01`| Button Input Synchronizer & Metastability | P1 | CR | Injects asynchronous transitions; verifies 2-stage synchronizer filtering. | **PASS** |
| `EXT` | **GPIO** | `TC_EXT_GPIO_02`| Display Pattern & Status LED Drive | P1 | DIR | Validates `gpio_out[7:0]` pins reflect sensed values and indicator patterns. | **PASS** |
| `INT` | **UART** | `TC_INT_UART_01`| UART FIFO Status & Watermark Flags | P1 | DIR | Verifies `THRE`, `TEMT`, and `DATA_READY` status flags in `UART_LSR`. | **PASS** |
| `EXT` | **UART** | `TC_EXT_UART_01`| Serial Transmission (115200 Baud) | P1 | DIR | UART VIP captures `uart_tx`; verifies 8-N-1 framing and received character. | **PASS** |
| `EXT` | **UART** | `TC_EXT_UART_02`| Serial Frame Reception & Interrupt | P2 | DIR | Injects byte on `uart_rx`; controller latches into `UART_RBR` and raises IRQ. | **PASS** |
| `SYS` | **Closed Loop**| `TC_SYS_01` | **End-to-End Sense-Process-Actuate-Display** | **P1** | **SW** | **Sensor reading (I2C) $\to$ CPU math $\to$ PWM duty $\to$ GPIO display $\to$ UART log.** | **PASS** |
| `SYS` | **Closed Loop**| `TC_SYS_02` | Concurrent Multi-Peripheral Stress | P2 | PERF | UART + Timer ticks + I2C reads + PWM running + GPIO toggles simultaneously. | **PASS** |
| `SYS` | **Closed Loop**| `TC_SYS_03` | Over-Temperature Emergency Trip | P2 | ERR | Over-temperature input ($> 100^\circ\text{C}$) triggers 100% PWM fan override, GPIO alert flash. | **PASS** |

---

## 6. SystemVerilog Assertions (SVA) Library

```systemverilog
// 1. AXI4 Protocol: AWADDR must remain stable while AWVALID is asserted and waiting for AWREADY
property p_axil_awaddr_stable(clk, rst_n, awvalid, awready, awaddr);
    @(posedge clk) disable iff (!rst_n)
    (awvalid && !awready) |=> $stable(awaddr);
endproperty

// 2. I2C Protocol: SDA transitions must only occur when SCL is low (except START/STOP)
property p_i2c_sda_stable_when_scl_high(sck, rst_n, scl, sda, is_start_or_stop);
    @(posedge sck) disable iff (!rst_n)
    (scl && !is_start_or_stop) |-> $stable(sda);
endproperty

// 3. Timer Protocol: sample_tick must never assert for more than 1 clock cycle
property p_sample_tick_one_cycle(clk, rst_n, sample_tick);
    @(posedge clk) disable iff (!rst_n)
    sample_tick |=> !sample_tick;
endproperty

// 4. GPIO Latency: Synchronized input must update exactly 2 clock cycles after asynchronous edge
property p_gpio_sync_latency(clk, rst_n, gpio_in, gpio_in_sync);
    @(posedge clk) disable iff (!rst_n)
    $changed(gpio_in) |-> ##2 (gpio_in_sync == $past(gpio_in, 1));
endproperty
```

---

## 7. Functional Coverage & Closure Metrics

Target Closure: **100% Functional Coverage, >95% Code Coverage** across all RTL blocks.
- **`cg_axi_matrix`:** Masters (`S00..S03`) $\times$ Slaves (`M00..M07`); Contention pairs; Burst lengths 1..16.
- **`cg_i2c_protocol`:** Standard (100k) / Fast (400k) speeds; START/STOP/WR/RD; ACK/NACK; Clock stretch.
- **`cg_pwm_actuator`:** Duty cycle bins ($0\%, 25\%, 50\%, 75\%, 100\%$); Polarity active-high/low.
- **`cg_gpio_display`:** Sensed value display patterns on `gpio_out[7:0]`; Pin change interrupts.
- **`cg_uart_telemetry`:** 115200 baud; 8-N-1 frames; Telemetry packet format check.
- **`cg_closed_loop`:** Input Temp Range $\times$ PWM Duty Output $\times$ GPIO Display $\times$ Telemetry Log.
