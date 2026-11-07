/* =============================================================================
 * File        : i2c_agent.sv
 * Description : UVM Agent packaging driver, monitor, and sequencer for I2C VIP
 * ============================================================================= */

`ifndef I2C_AGENT_SV
`define I2C_AGENT_SV

class i2c_agent extends uvm_agent;
    `uvm_component_utils(i2c_agent)

    i2c_slave_driver                 drv;
    i2c_monitor                      mon;
    i2c_sequencer                    sqr;
    uvm_analysis_port #(i2c_seq_item) ap;

    function new(string name = "i2c_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap = new("ap", this);

        mon = i2c_monitor::type_id::create("mon", this);
        if (get_is_active() == UVM_ACTIVE) begin
            drv = i2c_slave_driver::type_id::create("drv", this);
            sqr = i2c_sequencer::type_id::create("sqr", this);
        end
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        mon.ap.connect(ap);
        if (get_is_active() == UVM_ACTIVE) begin
            drv.seq_item_port.connect(sqr.seq_item_export);
        end
    endfunction
endclass

`endif // I2C_AGENT_SV
