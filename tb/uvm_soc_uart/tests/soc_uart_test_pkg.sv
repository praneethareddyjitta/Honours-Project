/* =============================================================================
 * Package     : soc_uart_test_pkg.sv
 * Description : Package compiling all UVM Tests for SoC UART verification
 * ============================================================================= */

`ifndef SOC_UART_TEST_PKG_SV
`define SOC_UART_TEST_PKG_SV

package soc_uart_test_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"
    import soc_uart_pkg::*;

    `include "soc_uart_base_test.sv"
    `include "soc_uart_tx_test.sv"

endpackage

`endif // SOC_UART_TEST_PKG_SV
