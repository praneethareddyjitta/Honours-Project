/* =============================================================================
 * Package     : pwm_pkg.sv
 * Description : UVM VIP Package for PWM Analyzer
 * ============================================================================= */

`ifndef PWM_PKG_SV
`define PWM_PKG_SV

package pwm_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    `include "pwm_seq_item.sv"
    `include "pwm_monitor.sv"
    `include "pwm_agent.sv"
endpackage

`endif // PWM_PKG_SV
