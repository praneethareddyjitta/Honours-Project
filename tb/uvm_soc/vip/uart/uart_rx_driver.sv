/* =============================================================================
 * File        : uart_rx_driver.sv
 * Description : UVM Driver converting uart_seq_item into pin-level 8-N-1 serial
 *               waveform injected into soc_top.uart_rx via soc_uart_if
 * ============================================================================= */

`ifndef UART_RX_DRIVER_SV
`define UART_RX_DRIVER_SV

class uart_rx_driver extends uvm_driver #(uart_seq_item);
    `uvm_component_utils(uart_rx_driver)

    virtual soc_uart_if vif;

    function new(string name = "uart_rx_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        // Retrieve virtual interface bridge from UVM Config DB
        if (!uvm_config_db#(virtual soc_uart_if)::get(this, "", "uart_vif", vif)) begin
            `uvm_fatal("NOVIF", "uart_rx_driver: Failed to get virtual interface 'uart_vif' from uvm_config_db!")
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        // Initialize line to idle 1
        vif.uart_rx <= 1'b1;

        forever begin
            seq_item_port.get_next_item(req);
            drive_serial_frame(req);
            seq_item_port.item_done();
        end
    endtask

    virtual task drive_serial_frame(uart_seq_item item);
        int bit_clocks;
        bit_clocks = item.baud_div + 1;

        `uvm_info("UART_DRV", $sformatf("Injecting RX Frame: 0x%02X ('%c') [BaudDiv=%0d, BitClocks=%0d]",
                  item.data_byte, item.data_byte, item.baud_div, bit_clocks), UVM_MEDIUM)

        // 1. Start Bit (Logic 0)
        vif.uart_rx <= 1'b0;
        repeat (bit_clocks) @(posedge vif.clk);

        // 2. 8 Data Bits (LSB first)
        for (int i = 0; i < 8; i++) begin
            vif.uart_rx <= item.data_byte[i];
            repeat (bit_clocks) @(posedge vif.clk);
        end

        // 3. Stop Bit (Logic 1)
        vif.uart_rx <= 1'b1;
        repeat (bit_clocks) @(posedge vif.clk);

        // Inter-frame idle delay
        repeat (bit_clocks) @(posedge vif.clk);
    endtask

endclass

`endif // UART_RX_DRIVER_SV
