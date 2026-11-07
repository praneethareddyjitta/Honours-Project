/* =============================================================================
 * File        : gpio_driver.sv
 * Description : UVM Driver for GPIO VIP (drives gpio_in into SoC DUT)
 * ============================================================================= */

`ifndef GPIO_DRIVER_SV
`define GPIO_DRIVER_SV

class gpio_driver extends uvm_driver #(gpio_seq_item);
    `uvm_component_utils(gpio_driver)

    virtual soc_gpio_if vif;

    function new(string name = "gpio_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual soc_gpio_if)::get(this, "", "gpio_vif", vif)) begin
            `uvm_fatal("NOVIF", "gpio_driver: Failed to get virtual interface 'gpio_vif' from uvm_config_db!")
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        gpio_seq_item req;
        vif.gpio_in <= 8'h00;

        forever begin
            seq_item_port.get_next_item(req);
            @(posedge vif.clk);
            vif.gpio_in <= req.gpio_in;
            `uvm_info("GPIO_DRV", $sformatf("Driving gpio_in = 0x%02X", req.gpio_in), UVM_HIGH)
            seq_item_port.item_done();
        end
    endtask
endclass

`endif // GPIO_DRIVER_SV
