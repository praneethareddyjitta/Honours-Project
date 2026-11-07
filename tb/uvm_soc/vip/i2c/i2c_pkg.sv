/* =============================================================================
 * Package     : i2c_pkg.sv
 * Description : UVM VIP Package for I2C Master/Slave Verification
 * ============================================================================= */

`ifndef I2C_PKG_SV
`define I2C_PKG_SV

package i2c_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    `include "i2c_seq_item.sv"
    `include "i2c_sequencer.sv"
    `include "i2c_slave_driver.sv"
    `include "i2c_monitor.sv"
    `include "i2c_agent.sv"
endpackage

`endif // I2C_PKG_SV
