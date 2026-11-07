/* =============================================================================
 * Package     : uart_pkg.sv
 * Description : UVM VIP Package for UART Transmit & Receive
 * ============================================================================= */

`ifndef UART_PKG_SV
`define UART_PKG_SV

package uart_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    `include "uart_seq_item.sv"
    `include "uart_sequencer.sv"
    `include "uart_rx_driver.sv"
    `include "uart_tx_monitor.sv"
    `include "uart_agent.sv"
endpackage

`endif // UART_PKG_SV
