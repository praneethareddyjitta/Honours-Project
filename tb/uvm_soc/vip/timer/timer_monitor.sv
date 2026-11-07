/* =============================================================================
 * File        : timer_monitor.sv
 * Description : UVM Monitor that sniffs sample_tick and irq_timer from SoC DUT
 * ============================================================================= */

`ifndef TIMER_MONITOR_SV
`define TIMER_MONITOR_SV

class timer_monitor extends uvm_monitor;
    `uvm_component_utils(timer_monitor)

    virtual soc_timer_if vif;
    uvm_analysis_port #(timer_seq_item) ap;

    function new(string name = "timer_monitor", uvm_component parent = null);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual soc_timer_if)::get(this, "", "timer_vif", vif)) begin
            `uvm_fatal("NOVIF", "timer_monitor: Failed to get virtual interface 'timer_vif' from uvm_config_db!")
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        timer_seq_item item;
        int total_ticks;
        int total_irqs;

        total_ticks = 0;
        total_irqs  = 0;

        forever begin
            @(posedge vif.clk);
            if (vif.sample_tick === 1'b1 || vif.irq_timer === 1'b1) begin
                if (vif.sample_tick === 1'b1) total_ticks++;
                if (vif.irq_timer === 1'b1)   total_irqs++;

                vif.mon_tick_count <= total_ticks;
                vif.mon_irq_count  <= total_irqs;

                item = timer_seq_item::type_id::create("timer_item");
                item.tick_count = total_ticks;
                item.irq_count  = total_irqs;
                item.timestamp  = $realtime;

                `uvm_info("TIMER_MON", item.convert2string(), UVM_HIGH)
                ap.write(item);
            end
        end
    endtask
endclass

`endif // TIMER_MONITOR_SV
