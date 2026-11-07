/* =============================================================================
 * Package     : soc_env_pkg.sv
 * Description : Package importing all VIP packages and defining soc_top_env
 * ============================================================================= */

`ifndef SOC_ENV_PKG_SV
`define SOC_ENV_PKG_SV

package soc_env_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    import uart_pkg::*;
    import i2c_pkg::*;
    import gpio_pkg::*;
    import pwm_pkg::*;
    import timer_pkg::*;

    `include "soc_scoreboard.sv"
    `include "soc_top_env.sv"
endpackage

`endif // SOC_ENV_PKG_SV
