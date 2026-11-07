/* =============================================================================
 * File        : soc_uart_tx_test.sv
 * Description : UVM Test verifying VeeR EL2 CPU boot and UART transmission stream
 * ============================================================================= */

`ifndef SOC_UART_TX_TEST_SV
`define SOC_UART_TX_TEST_SV

class soc_uart_tx_test extends soc_uart_base_test;
    `uvm_component_utils(soc_uart_tx_test)

    function new(string name = "soc_uart_tx_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        `uvm_info("UART_TX_TEST", "==================================================", UVM_NONE)
        `uvm_info("UART_TX_TEST", "   STARTING UVM SOC UART TRANSMISSION TEST        ", UVM_NONE)
        `uvm_info("UART_TX_TEST", "==================================================", UVM_NONE)
        `uvm_info("UART_TX_TEST", "VeeR EL2 core active from IMEM (0x1000_0000). Sniffing uart_tx pin...", UVM_NONE)

        // Wait until scoreboard captures the full firmware banner or timeout
        fork : wait_banner
            begin
                wait (env.sb.hello_world_found && env.sb.uart_working_found);
                #10000ns; // allow remaining trailing characters to finish
            end
            begin
                #5000000ns; // 5 ms timeout guard
                `uvm_warning("UART_TX_TEST", "Simulation timeout reached before full banner detected.")
            end
        join_any
        disable wait_banner;

        `uvm_info("UART_TX_TEST", "Finishing UART TX Test Phase...", UVM_NONE)
        phase.drop_objection(this);
    endtask

endclass

`endif // SOC_UART_TX_TEST_SV
