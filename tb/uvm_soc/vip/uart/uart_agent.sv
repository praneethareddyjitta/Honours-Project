/* =============================================================================
 * File        : uart_agent.sv
 * Description : UVM Agent packaging driver, monitor, and sequencer for UART VIP
 * ============================================================================= */

`ifndef UART_AGENT_SV
`define UART_AGENT_SV

class uart_agent extends uvm_agent;
    `uvm_component_utils(uart_agent)

    uart_rx_driver                  drv;
    uart_tx_monitor                 mon;
    uart_sequencer                  sqr;
    uvm_analysis_port #(uart_seq_item) ap;

    function new(string name = "uart_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap = new("ap", this);

        // Monitor is always created (passive sampling)
        mon = uart_tx_monitor::type_id::create("mon", this);

        // Driver and sequencer created only if active
        if (get_is_active() == UVM_ACTIVE) begin
            drv = uart_rx_driver::type_id::create("drv", this);
            sqr = uart_sequencer::type_id::create("sqr", this);
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

`endif // UART_AGENT_SV
