/* =============================================================================
 * File        : i2c_slave_driver.sv
 * Description : UVM Driver for I2C Slave VIP (configures sensor response memory)
 * ============================================================================= */

`ifndef I2C_SLAVE_DRIVER_SV
`define I2C_SLAVE_DRIVER_SV

class i2c_slave_driver extends uvm_driver #(i2c_seq_item);
    `uvm_component_utils(i2c_slave_driver)

    virtual soc_i2c_if vif;

    function new(string name = "i2c_slave_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual soc_i2c_if)::get(this, "", "i2c_vif", vif)) begin
            `uvm_fatal("NOVIF", "i2c_slave_driver: Failed to get virtual interface 'i2c_vif' from uvm_config_db!")
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        i2c_seq_item req;
        forever begin
            seq_item_port.get_next_item(req);
            // Dynamically update slave sensor memory if transaction arrives
            vif.u_i2c_slave_model.mem[req.addr] = req.data_byte;
            `uvm_info("I2C_DRV", $sformatf("Updated I2C Slave Memory[0x%02X] = 0x%02X", req.addr, req.data_byte), UVM_HIGH)
            seq_item_port.item_done();
        end
    endtask
endclass

`endif // I2C_SLAVE_DRIVER_SV
