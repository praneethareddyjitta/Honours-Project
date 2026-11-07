/* =============================================================================
 * Package     : soc_test_pkg.sv
 * Description : Package importing environment and defining all SoC tests
 * ============================================================================= */

`ifndef SOC_TEST_PKG_SV
`define SOC_TEST_PKG_SV

package soc_test_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    import uart_pkg::*;
    import i2c_pkg::*;
    import gpio_pkg::*;
    import pwm_pkg::*;
    import timer_pkg::*;
    import soc_env_pkg::*;

    `include "soc_base_test.sv"
    `include "soc_all_vips_test.sv"
endpackage

`endif // SOC_TEST_PKG_SV
