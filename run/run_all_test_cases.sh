#!/bin/bash
# ==============================================================================
# Script      : run_all_test_cases.sh
# Description : Master Automated Regression Runner for VeeR EL2 SoC
#               Executes all 35 UVM / SystemVerilog Test Cases across 6 Suites
# Simulator   : Synopsys VCS U-2023.03_Full64
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# 1. Setup Synopsys VCS Environment
export VCS_HOME=${VCS_HOME:-/home/student/snps_tools_target/vcs/U-2023.03}
export VERDI_HOME=${VERDI_HOME:-/home/student/snps_tools_target/verdi/U-2023.03-SP1}
export SNPSLMD_LICENSE_FILE=${SNPSLMD_LICENSE_FILE:-27021@14.139.1.126}
export PATH=$VCS_HOME/bin:$VERDI_HOME/bin:$PATH
export LD_LIBRARY_PATH=$VCS_HOME/linux64/lib:$VERDI_HOME/share/PLI/VCS/LINUX64:$LD_LIBRARY_PATH

echo "=================================================================="
echo "          VCS REGRESSION TEST RUNNER - ALL 35 TEST CASES          "
echo "=================================================================="
echo "VCS Version : $($VCS_HOME/bin/vcs -ID 2>&1 | grep -i version || echo 'U-2023.03_Full64')"
echo "Date        : $(date)"
echo "Directory   : $SCRIPT_DIR"
echo "=================================================================="
echo ""

TOTAL_PASSED=0
TOTAL_FAILED=0

run_suite() {
    local suite_num="$1"
    local suite_name="$2"
    local sim_exec="$3"
    local log_file="$4"

    echo ">>> Running Category ${suite_num}: ${suite_name}..."
    if [ ! -x "./${sim_exec}" ]; then
        echo "ERROR: Executable ./${sim_exec} not found or not executable!"
        exit 1
    fi

    ./${sim_exec} -l ${log_file} > /dev/null 2>&1
    local ret_code=$?

    if [ $ret_code -ne 0 ]; then
        echo "[-] Category ${suite_num} FAILED (simulation returned code $ret_code)!"
        TOTAL_FAILED=$((TOTAL_FAILED + 1))
    else
        local pass_line=$(grep -E "ALL .* TESTS PASSED" ${log_file} || true)
        if [ -n "$pass_line" ]; then
            echo "[+] Category ${suite_num} (${suite_name}): PASSED! ($pass_line)"
            TOTAL_PASSED=$((TOTAL_PASSED + 1))
        else
            echo "[-] Category ${suite_num} (${suite_name}): Completed with unverified summary. Check ${log_file}."
            TOTAL_FAILED=$((TOTAL_FAILED + 1))
        fi
    fi
    echo ""
}

# Run all 6 suites
run_suite "1" "Processor Subsystem (VeeR EL2 Core)"    "simv_cat1_cpu"             "sim_cat1_cpu.log"
run_suite "2" "AXI4 Interconnect Matrix (5x20)"         "simv_cat2_axi"             "sim_cat2_axi.log"
run_suite "3" "I2C Master Controller Subsystem"        "simv_cat3_i2c"             "sim_cat3_i2c.log"
run_suite "4" "PWM 4-Channel Generator Subsystem"       "simv_cat4_pwm"             "sim_cat4_pwm.log"
run_suite "5" "System Timer, GPIO & 16550 UART"        "simv_cat5_periph"          "sim_cat5_periph.log"
run_suite "6" "Full Closed-Loop SoC System"            "simv_cat6_soc_closed_loop" "sim_cat6_soc_closed_loop.log"

# Compile Individual Test Case Verification Table
echo "=================================================================================================="
echo "                           INDIVIDUAL TEST CASE VERIFICATION RESULTS                              "
echo "=================================================================================================="
printf "%-18s | %-16s | %-45s | %-8s\n" "Test ID" "Category" "Test Description" "Status"
echo "--------------------------------------------------------------------------------------------------"

declare -A TEST_DESCS=(
    ["TC_INT_CPU_01"]="Power-On Reset & Clean Boot"
    ["TC_INT_CPU_02"]="Core Instruction Throughput & Pipeline Efficiency"
    ["TC_INT_CPU_03"]="MRAC Non-Cacheable I/O Enforcement"
    ["TC_INT_CPU_04"]="Branch Mispredict Flush & Recovery"
    ["TC_INT_CPU_05"]="Compressed Instruction (RV32C) Decode"
    ["TC_INT_CPU_06"]="Trap & Exception Handling Architecture"
    ["TC_INT_CPU_07"]="PIC Multi-Source Priority Vectoring"
    ["TC_INT_BUS_01"]="Multi-Master Contention & Round-Robin Arbitration"
    ["TC_INT_BUS_02"]="Unmapped Aperture DECERR Trap Handling"
    ["TC_INT_BUS_03"]="AXI Burst Length Sweeps (INCR 1 to 16 Beats)"
    ["TC_INT_BUS_04"]="Byte-Strobe (wstrb) Sub-Word Masking Integrity"
    ["TC_INT_BUS_05"]="Read-After-Write (RAW) Hazard Avoidance"
    ["TC_INT_I2C_01"]="I2C Register HW Reset & Bit-Bash (RAL)"
    ["TC_INT_I2C_02"]="I2C Command Sequencer & Done Flag Generation"
    ["TC_EXT_I2C_01"]="Bus Timing & SCL Frequency Compliance"
    ["TC_EXT_I2C_02"]="Sensor Slave Register Write & ACK Handshake"
    ["TC_EXT_I2C_03"]="Sensor Data Read & Master ACK/NACK Handshake"
    ["TC_EXT_I2C_04"]="Slave Clock Stretching Resilience"
    ["TC_EXT_I2C_05"]="Slave NACK Detection on Bad Slave Address"
    ["TC_INT_PWM_01"]="PWM Register HW Reset & Bit-Bash (RAL)"
    ["TC_INT_PWM_02"]="Prescaler & Period Rollover Flag & IRQ"
    ["TC_EXT_PWM_01"]="Channel 0 Duty Cycle Sweep (0% to 100%)"
    ["TC_EXT_PWM_02"]="4-Channel Independent Multi-Drive Output"
    ["TC_EXT_PWM_03"]="Output Polarity Inversion Verification"
    ["TC_EXT_PWM_04"]="Channel Gating & Idle State Driving"
    ["TC_INT_TMR_01"]="Timer Down-Counter Accuracy & Interrupt"
    ["TC_EXT_TMR_01"]="sample_tick 1-Cycle Pulse Width (10 ns)"
    ["TC_INT_GPIO_01"]="GPIO Pin-Change Interrupt Masking"
    ["TC_EXT_GPIO_01"]="Button Synchronizer Metastability & Glitch Filtering"
    ["TC_EXT_GPIO_02"]="Display Pattern & Status LED Drive Output"
    ["TC_INT_UART_01"]="UART FIFO Status & Watermark Flags"
    ["TC_EXT_UART_01"]="Serial Transmission 115200 Baud Frame Analyzer"
    ["TC_EXT_UART_02"]="Serial Reception & Interrupt Generation"
    ["TC_SYS_01"]="End-to-End Sense-Process-Actuate-Display Loop"
    ["TC_SYS_02"]="Concurrent Multi-Peripheral Stress Scenario"
    ["TC_SYS_03"]="Over-Temperature Emergency Trip Scenario"
)

declare -A TEST_CATS=(
    ["TC_INT_CPU_01"]="Processor"
    ["TC_INT_CPU_02"]="Processor"
    ["TC_INT_CPU_03"]="Processor"
    ["TC_INT_CPU_04"]="Processor"
    ["TC_INT_CPU_05"]="Processor"
    ["TC_INT_CPU_06"]="Processor"
    ["TC_INT_CPU_07"]="Processor"
    ["TC_INT_BUS_01"]="AXI Fabric"
    ["TC_INT_BUS_02"]="AXI Fabric"
    ["TC_INT_BUS_03"]="AXI Fabric"
    ["TC_INT_BUS_04"]="AXI Fabric"
    ["TC_INT_BUS_05"]="AXI Fabric"
    ["TC_INT_I2C_01"]="I2C Master"
    ["TC_INT_I2C_02"]="I2C Master"
    ["TC_EXT_I2C_01"]="I2C Master"
    ["TC_EXT_I2C_02"]="I2C Master"
    ["TC_EXT_I2C_03"]="I2C Master"
    ["TC_EXT_I2C_04"]="I2C Master"
    ["TC_EXT_I2C_05"]="I2C Master"
    ["TC_INT_PWM_01"]="PWM Gen"
    ["TC_INT_PWM_02"]="PWM Gen"
    ["TC_EXT_PWM_01"]="PWM Gen"
    ["TC_EXT_PWM_02"]="PWM Gen"
    ["TC_EXT_PWM_03"]="PWM Gen"
    ["TC_EXT_PWM_04"]="PWM Gen"
    ["TC_INT_TMR_01"]="System Timer"
    ["TC_EXT_TMR_01"]="System Timer"
    ["TC_INT_GPIO_01"]="GPIO Subsystem"
    ["TC_EXT_GPIO_01"]="GPIO Subsystem"
    ["TC_EXT_GPIO_02"]="GPIO Subsystem"
    ["TC_INT_UART_01"]="16550 UART"
    ["TC_EXT_UART_01"]="16550 UART"
    ["TC_EXT_UART_02"]="16550 UART"
    ["TC_SYS_01"]="SoC Closed-Loop"
    ["TC_SYS_02"]="SoC Closed-Loop"
    ["TC_SYS_03"]="SoC Closed-Loop"
)

ALL_TEST_IDS=(
    "TC_INT_CPU_01" "TC_INT_CPU_02" "TC_INT_CPU_03" "TC_INT_CPU_04" "TC_INT_CPU_05" "TC_INT_CPU_06" "TC_INT_CPU_07"
    "TC_INT_BUS_01" "TC_INT_BUS_02" "TC_INT_BUS_03" "TC_INT_BUS_04" "TC_INT_BUS_05"
    "TC_INT_I2C_01" "TC_INT_I2C_02" "TC_EXT_I2C_01" "TC_EXT_I2C_02" "TC_EXT_I2C_03" "TC_EXT_I2C_04" "TC_EXT_I2C_05"
    "TC_INT_PWM_01" "TC_INT_PWM_02" "TC_EXT_PWM_01" "TC_EXT_PWM_02" "TC_EXT_PWM_03" "TC_EXT_PWM_04"
    "TC_INT_TMR_01" "TC_EXT_TMR_01" "TC_INT_GPIO_01" "TC_EXT_GPIO_01" "TC_EXT_GPIO_02"
    "TC_INT_UART_01" "TC_EXT_UART_01" "TC_EXT_UART_02"
    "TC_SYS_01" "TC_SYS_02" "TC_SYS_03"
)

TESTS_PASSED=0
TESTS_FAILED=0

ALL_LOGS="sim_cat1_cpu.log sim_cat2_axi.log sim_cat3_i2c.log sim_cat4_pwm.log sim_cat5_periph.log sim_cat6_soc_closed_loop.log"

for tid in "${ALL_TEST_IDS[@]}"; do
    cat_name="${TEST_CATS[$tid]}"
    desc="${TEST_DESCS[$tid]}"
    if grep -q "\[PASS\] \[${tid}\]" $ALL_LOGS; then
        status="PASS"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        status="FAIL"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    printf "%-18s | %-16s | %-45s | [%-4s]\n" "$tid" "$cat_name" "$desc" "$status"
done

echo "=================================================================================================="
echo "                                   REGRESSION SUMMARY                                             "
echo "=================================================================================================="
echo "Total Test Suites Executed : 6 / 6"
echo "Suites Passed              : $TOTAL_PASSED / 6"
echo "Total Test Cases Evaluated : ${#ALL_TEST_IDS[@]}"
echo "Test Cases Passed          : $TESTS_PASSED / ${#ALL_TEST_IDS[@]}"
echo "Test Cases Failed          : $TESTS_FAILED / ${#ALL_TEST_IDS[@]}"
echo "Overall Pass Rate          : $(( (TESTS_PASSED * 100) / ${#ALL_TEST_IDS[@]} ))%"
echo "=================================================================================================="

if [ $TESTS_FAILED -eq 0 ]; then
    echo "SUCCESS: ALL TEST CASES PASSED WITH 100% REGRESSION CONFIDENCE!"
    exit 0
else
    echo "FAILURE: $TESTS_FAILED TEST CASES FAILED!"
    exit 1
fi
