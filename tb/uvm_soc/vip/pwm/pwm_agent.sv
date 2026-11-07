/* =============================================================================
 * File        : pwm_agent.sv
 * Description : UVM Agent for PWM VIP (Passive Analyzer)
 * ============================================================================= */

`ifndef PWM_AGENT_SV
`define PWM_AGENT_SV

class pwm_agent extends uvm_agent;
    `uvm_component_utils(pwm_agent)

    pwm_monitor                      mon;
    uvm_analysis_port #(pwm_seq_item) ap;

    function new(string name = "pwm_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap = new("ap", this);
        mon = pwm_monitor::type_id::create("mon", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        mon.ap.connect(ap);
    endfunction
endclass

`endif // PWM_AGENT_SV
