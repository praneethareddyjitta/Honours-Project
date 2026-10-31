#!/bin/bash
# =============================================================================
# run_soc_top_all_ips.sh
# Compile and simulate the complete 5x20 AXI SoC Top with Synopsys VCS
# Integrated IPs: PWM, I2C, UART, TIMER, GPIO (AES excluded)
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

export VCS_HOME=/home/STUDENT/snps_tools_target/vcs/U-2023.03
export VERDI_HOME=/home/STUDENT/snps_tools_target/verdi/U-2023.03-SP1
export PATH=$VCS_HOME/bin:$VERDI_HOME/bin:$PATH
export SNPSLMD_LICENSE_FILE=27021@14.139.1.126
export LD_LIBRARY_PATH=$VCS_HOME/linux64/lib:$LD_LIBRARY_PATH

echo "=========================================================="
echo " Compiling 5x20 AXI SoC with Synopsys VCS..."
echo "=========================================================="
vcs -full64 -sverilog -timescale=1ns/1ps -f filelist_soc_top_all_ips.f -o simv_soc_top_all_ips

echo "=========================================================="
echo " Running Simulation..."
echo "=========================================================="
./simv_soc_top_all_ips
