/* =============================================================================
 * File        : timer_agent.sv
 * Description : UVM Agent for System Timer VIP (Passive Monitor)
 * ============================================================================= */

`ifndef TIMER_AGENT_SV
`define TIMER_AGENT_SV

class timer_agent extends uvm_agent;
    `uvm_component_utils(timer_agent)

    timer_monitor                      mon;
    uvm_analysis_port #(timer_seq_item) ap;

    function new(string name = "timer_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap = new("ap", this);
        mon = timer_monitor::type_id::create("mon", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        mon.ap.connect(ap);
    endfunction
endclass

`endif // TIMER_AGENT_SV
