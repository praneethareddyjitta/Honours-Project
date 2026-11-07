#!/bin/bash
# ==============================================================================
# Script      : run_soc_uart_uvm.sh
# Description : Compiles & Runs Full SoC with UVM UART VIP using Synopsys VCS
#               Generates targeted FSDB waveform for Verdi analysis
# ==============================================================================

set -e
cd "$(dirname "$0")"

# Synopsys Environment Setup
export VCS_HOME=/home/student/snps_tools_target/vcs/U-2023.03
export VERDI_HOME=/home/student/snps_tools_target/verdi/U-2023.03-SP1
export SNPSLMD_LICENSE_FILE=27021@14.139.1.126
export PATH=$VCS_HOME/bin:$VERDI_HOME/bin:$PATH
export LD_LIBRARY_PATH=$VCS_HOME/linux64/lib:$VERDI_HOME/share/PLI/VCS/LINUX64:$LD_LIBRARY_PATH

TEST_NAME=${1:-soc_uart_tx_test}

echo "=================================================================="
echo " Compiling Full SoC with UVM UART VIP (Synopsys VCS U-2023.03)..."
echo "=================================================================="

vcs -full64 -sverilog -timescale=1ns/1ps -ntb_opts uvm-1.2 \
    -debug_access+all -kdb +notimingcheck \
    -f filelist_soc_uart_uvm.f \
    -o simv_soc_uart_uvm \
    -l compile_soc_uart_uvm.log

echo ""
echo "=================================================================="
echo " Running UVM Simulation: +UVM_TESTNAME=${TEST_NAME}"
echo "=================================================================="

./simv_soc_uart_uvm +UVM_TESTNAME=${TEST_NAME} -l sim_soc_uart_uvm.log

echo ""
echo "=================================================================="
echo " UVM Simulation Completed Successfully!"
echo " Waveform dumped to: $(pwd)/dump_uart_tx.fsdb"
echo " Signal config file: $(pwd)/uart_transmission_signals.rc"
echo ""
echo " To inspect the UART transmission in Verdi, execute:"
echo "   verdi -ssf dump_uart_tx.fsdb -sswr uart_transmission_signals.rc &"
echo "=================================================================="
