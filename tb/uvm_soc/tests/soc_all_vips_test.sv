/* =============================================================================
 * File        : soc_all_vips_test.sv
 * Description : Master UVM Test running Full SoC with all 5 VIPs concurrently
 * ============================================================================= */

`ifndef SOC_ALL_VIPS_TEST_SV
`define SOC_ALL_VIPS_TEST_SV

class soc_all_vips_test extends soc_base_test;
    `uvm_component_utils(soc_all_vips_test)

    function new(string name = "soc_all_vips_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        phase.raise_objection(this, "Starting Master Multi-VIP Full SoC Test");
        `uvm_info("ALL_VIPS_TEST", "Executing Full SoC Test with UART, I2C, GPIO, PWM, and Timer VIPs Active...", UVM_LOW)

        // Allow VeeR EL2 core to boot and run all peripheral interactions
        #400us;

        `uvm_info("ALL_VIPS_TEST", "Completing Master Multi-VIP Full SoC Test Phase.", UVM_LOW)
        phase.drop_objection(this, "Master Multi-VIP Full SoC Test Completed");
    endtask
endclass

`endif // SOC_ALL_VIPS_TEST_SV
