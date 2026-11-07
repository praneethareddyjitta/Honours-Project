/* =============================================================================
 * File        : timer_seq_item.sv
 * Description : UVM Sequence Item for System Timer Verification
 * ============================================================================= */

`ifndef TIMER_SEQ_ITEM_SV
`define TIMER_SEQ_ITEM_SV

class timer_seq_item extends uvm_sequence_item;
    bit [31:0] tick_count;
    bit [31:0] irq_count;
    realtime   timestamp;

    `uvm_object_utils_begin(timer_seq_item)
        `uvm_field_int(tick_count, UVM_ALL_ON | UVM_DEC)
        `uvm_field_int(irq_count,  UVM_ALL_ON | UVM_DEC)
        `uvm_field_real(timestamp, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "timer_seq_item");
        super.new(name);
    endfunction

    virtual function string convert2string();
        return $sformatf("TIMER_TXN: TickCount=%0d IRQCount=%0d @ %0t",
                         tick_count, irq_count, timestamp);
    endfunction
endclass

`endif // TIMER_SEQ_ITEM_SV
