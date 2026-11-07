/* =============================================================================
 * File        : soc_uart_base_test.sv
 * Description : Base UVM Test instantiating soc_uart_env and setting up VIP
 * ============================================================================= */

`ifndef SOC_UART_BASE_TEST_SV
`define SOC_UART_BASE_TEST_SV

class soc_uart_base_test extends uvm_test;
    `uvm_component_utils(soc_uart_base_test)

    soc_uart_env env;

    function new(string name = "soc_uart_base_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = soc_uart_env::type_id::create("env", this);
    endfunction

    virtual function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);
        uvm_top.print_topology();
    endfunction

endclass

`endif // SOC_UART_BASE_TEST_SV
