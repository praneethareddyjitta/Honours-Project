#!/bin/sh
# Usage: ./run_sim.sh <UART_IP_DIR> <DIR_WITH_INTERCONNECT_FILES>
#   UART_IP_DIR : the unzipped axi-lite_uart-ipcore-develop folder
#   IC_DIR      : folder with axi_interconnect_wrap_3x10.v axi_interconnect.v arbiter.v priority_encoder.v
# Needs Icarus Verilog (iverilog/vvp) >= 11.
UART=${1:?usage: run_sim.sh <UART_IP_DIR> <IC_DIR>}
IC=${2:?usage: run_sim.sh <UART_IP_DIR> <IC_DIR>}
set -e
echo "=== direct: BFM -> adapter -> real UART ==="
iverilog -g2005-sv -o sim_direct.vvp -I "$UART/src/include" -I . \
   ../axi4_to_axi4lite_uart_adapter.v tb_axi4_to_axi4lite_uart_adapter.v "$UART"/src/rtl/*.v
vvp sim_direct.vvp | grep -E "^---|PASS|FAIL|CHECK"
echo "=== integration: BFM -> interconnect M03 -> adapter -> real UART ==="
iverilog -g2005-sv -o sim_soc.vvp -I "$UART/src/include" -I . \
   ../axi4_to_axi4lite_uart_adapter.v tb_soc_interconnect_uart.v "$UART"/src/rtl/*.v \
   "$IC"/axi_interconnect_wrap_3x10.v "$IC"/axi_interconnect.v "$IC"/arbiter.v "$IC"/priority_encoder.v
vvp sim_soc.vvp | grep -E "Addressing| 3 \(|^---|PASS|FAIL|CHECK"
