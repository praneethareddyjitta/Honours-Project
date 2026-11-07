/* =============================================================================
 * File        : gpio_monitor.sv
 * Description : UVM Monitor that sniffs gpio_out and irq_gpio from SoC DUT
 * ============================================================================= */

`ifndef GPIO_MONITOR_SV
`define GPIO_MONITOR_SV

class gpio_monitor extends uvm_monitor;
    `uvm_component_utils(gpio_monitor)

    virtual soc_gpio_if vif;
    uvm_analysis_port #(gpio_seq_item) ap;

    function new(string name = "gpio_monitor", uvm_component parent = null);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual soc_gpio_if)::get(this, "", "gpio_vif", vif)) begin
            `uvm_fatal("NOVIF", "gpio_monitor: Failed to get virtual interface 'gpio_vif' from uvm_config_db!")
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        gpio_seq_item item;
        logic [7:0] prev_out;
        logic       prev_irq;

        prev_out = vif.gpio_out;
        prev_irq = vif.irq_gpio;

        forever begin
            @(posedge vif.clk);
            if (vif.gpio_out !== prev_out || vif.irq_gpio !== prev_irq) begin
                prev_out = vif.gpio_out;
                prev_irq = vif.irq_gpio;

                vif.mon_gpio_change <= 1'b1;
                fork begin @(posedge vif.clk); vif.mon_gpio_change <= 1'b0; end join_none

                item = gpio_seq_item::type_id::create("gpio_item");
                item.gpio_in   = vif.gpio_in;
                item.gpio_out  = vif.gpio_out;
                item.irq_gpio  = vif.irq_gpio;
                item.timestamp = $realtime;

                `uvm_info("GPIO_MON", item.convert2string(), UVM_LOW)
                ap.write(item);
            end
        end
    endtask
endclass

`endif // GPIO_MONITOR_SV
