#!/bin/bash
set -e

# Synopsys Tool Environment Setup
export VCS_HOME=${VCS_HOME:-/home/STUDENT/snps_tools_target/vcs/U-2023.03}
export VERDI_HOME=${VERDI_HOME:-/home/STUDENT/snps_tools_target/verdi/U-2023.03-SP1}
export SNPSLMD_LICENSE_FILE=${SNPSLMD_LICENSE_FILE:-27021@14.139.1.126}
export PATH=$VCS_HOME/bin:$VERDI_HOME/bin:$PATH
export LD_LIBRARY_PATH=$VCS_HOME/linux64/lib:$VERDI_HOME/share/PLI/VCS/LINUX64:$LD_LIBRARY_PATH

echo "=========================================================="
echo " Compiling Closed-Loop VeeR EL2 SoC with Synopsys VCS..."
echo "=========================================================="
cd $(dirname "$0")

vcs -full64 -sverilog -timescale=1ns/1ps -debug_access+all -kdb \
    -f filelist_soc_closed_loop.f \
    -o simv_soc_closed_loop \
    -l compile_soc_closed_loop.log

echo "=========================================================="
echo " Running Closed-Loop SoC Simulation..."
echo " (I2C Sense -> VeeR CPU -> PWM Actuate -> GPIO Display) "
echo "=========================================================="
./simv_soc_closed_loop -l sim_soc_closed_loop.log

echo "=========================================================="
echo " Closed-Loop Simulation Finished Successfully."
echo "=========================================================="
