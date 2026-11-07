/* =============================================================================
 * Package     : timer_pkg.sv
 * Description : UVM VIP Package for System Timer Verification
 * ============================================================================= */

`ifndef TIMER_PKG_SV
`define TIMER_PKG_SV

package timer_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    `include "timer_seq_item.sv"
    `include "timer_monitor.sv"
    `include "timer_agent.sv"
endpackage

`endif // TIMER_PKG_SV
