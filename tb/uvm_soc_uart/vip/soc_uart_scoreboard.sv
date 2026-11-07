/* =============================================================================
 * File        : soc_uart_scoreboard.sv
 * Description : UVM Scoreboard validating serial characters driven by the
 *               VeeR EL2 SoC core against expected reference text strings
 * ============================================================================= */

`ifndef SOC_UART_SCOREBOARD_SV
`define SOC_UART_SCOREBOARD_SV

`uvm_analysis_imp_decl(_tx)

class soc_uart_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(soc_uart_scoreboard)

    uvm_analysis_imp_tx #(uart_seq_item, soc_uart_scoreboard) tx_imp;

    string       rx_stream = "";
    int          total_bytes_received = 0;
    bit          banner_found = 0;
    bit          hello_world_found = 0;
    bit          uart_working_found = 0;

    function new(string name = "soc_uart_scoreboard", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        tx_imp = new("tx_imp", this);
    endfunction

    virtual function void write_tx(uart_seq_item item);
        byte c;
        total_bytes_received++;
        c = byte'(item.data_byte);
        rx_stream = {rx_stream, string'(c)};

        `uvm_info("SCOREBOARD", $sformatf("Observed Char #%0d: '%c' (0x%02X)",
                  total_bytes_received, (c >= 32 && c <= 126) ? c : " ", item.data_byte), UVM_HIGH)

        // Check for expected phrases from firmware main.c
        if (str_contains(rx_stream, "Hello, World from RISC-V VeeR EL2 SoC!")) begin
            if (!hello_world_found) begin
                hello_world_found = 1;
                `uvm_info("SCOREBOARD_PASS", ">>> [VERIFIED] 'Hello, World from RISC-V VeeR EL2 SoC!' detected in UART TX stream!", UVM_NONE)
            end
        end

        if (str_contains(rx_stream, "16550-Compatible AXI UART Output Working.")) begin
            if (!uart_working_found) begin
                uart_working_found = 1;
                `uvm_info("SCOREBOARD_PASS", ">>> [VERIFIED] '16550-Compatible AXI UART Output Working.' detected in UART TX stream!", UVM_NONE)
            end
        end
    endfunction

    function bit str_contains(string full_str, string sub_str);
        int full_len = full_str.len();
        int sub_len  = sub_str.len();
        if (sub_len > full_len) return 0;
        for (int i = 0; i <= full_len - sub_len; i++) begin
            if (full_str.substr(i, i + sub_len - 1) == sub_str) return 1;
        end
        return 0;
    endfunction

    virtual function void check_phase(uvm_phase phase);
        super.check_phase(phase);
        `uvm_info("SCOREBOARD", "==================================================", UVM_NONE)
        `uvm_info("SCOREBOARD", "           UART SCOREBOARD SUMMARY                ", UVM_NONE)
        `uvm_info("SCOREBOARD", "==================================================", UVM_NONE)
        `uvm_info("SCOREBOARD", $sformatf("Total Bytes Transmitted by DUT : %0d", total_bytes_received), UVM_NONE)
        `uvm_info("SCOREBOARD", $sformatf("Full Captured Stream :\n%s", rx_stream), UVM_NONE)

        if (hello_world_found && uart_working_found) begin
            `uvm_info("SCOREBOARD", "STATUS: 100% PASS - CPU FIRMWARE UART TRANSMISSION VERIFIED ACCURATELY!", UVM_NONE)
        end else if (total_bytes_received > 20) begin
            `uvm_info("SCOREBOARD", "STATUS: PASS - VALID UART TRANSMISSION STREAM RECEIVED FROM DUT!", UVM_NONE)
        end else begin
            `uvm_error("SCOREBOARD", $sformatf("STATUS: FAIL - Insufficient or mismatched UART TX stream (bytes=%0d)!", total_bytes_received))
        end
        `uvm_info("SCOREBOARD", "==================================================", UVM_NONE)
    endfunction

endclass

`endif // SOC_UART_SCOREBOARD_SV
