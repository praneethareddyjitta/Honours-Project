/* =============================================================================
 * File        : uart_sequencer.sv
 * Description : UVM Sequencer for UART verification transactions
 * ============================================================================= */

`ifndef UART_SEQUENCER_SV
`define UART_SEQUENCER_SV

class uart_sequencer extends uvm_sequencer #(uart_seq_item);
    `uvm_component_utils(uart_sequencer)

    function new(string name = "uart_sequencer", uvm_component parent = null);
        super.new(name, parent);
    endfunction
endclass

`endif // UART_SEQUENCER_SV
