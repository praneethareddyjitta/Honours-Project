/* =============================================================================
 * File        : pwm_seq_item.sv
 * Description : UVM Sequence Item for PWM Verification
 * ============================================================================= */

`ifndef PWM_SEQ_ITEM_SV
`define PWM_SEQ_ITEM_SV

class pwm_seq_item extends uvm_sequence_item;
    bit [31:0] period_cycles;
    bit [31:0] high_cycles;
    bit [7:0]  duty_pct;
    realtime   timestamp;

    `uvm_object_utils_begin(pwm_seq_item)
        `uvm_field_int(period_cycles, UVM_ALL_ON | UVM_DEC)
        `uvm_field_int(high_cycles,   UVM_ALL_ON | UVM_DEC)
        `uvm_field_int(duty_pct,      UVM_ALL_ON | UVM_DEC)
        `uvm_field_real(timestamp,    UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "pwm_seq_item");
        super.new(name);
    endfunction

    virtual function string convert2string();
        return $sformatf("PWM_TXN: Period=%0d High=%0d Duty=%0d%% @ %0t",
                         period_cycles, high_cycles, duty_pct, timestamp);
    endfunction
endclass

`endif // PWM_SEQ_ITEM_SV
