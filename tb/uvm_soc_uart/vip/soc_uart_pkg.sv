/* =============================================================================
 * Package     : soc_uart_pkg.sv
 * Description : Package compiling all UART VIP and environment components
 * ============================================================================= */

`ifndef SOC_UART_PKG_SV
`define SOC_UART_PKG_SV

package soc_uart_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    `include "uart_seq_item.sv"
    `include "uart_sequencer.sv"
    `include "uart_rx_driver.sv"
    `include "uart_tx_monitor.sv"
    `include "uart_agent.sv"
    `include "soc_uart_scoreboard.sv"
    `include "soc_uart_coverage.sv"
    `include "soc_uart_env.sv"

endpackage

`endif // SOC_UART_PKG_SV
