/* =============================================================================
 * File        : uart_tx_monitor.sv
 * Description : UVM Monitor that passively sniffs soc_top.uart_tx, aligns to
 *               bit centers, reconstructs 8-N-1 bytes, and broadcasts via ap
 * ============================================================================= */

`ifndef UART_TX_MONITOR_SV
`define UART_TX_MONITOR_SV

class uart_tx_monitor extends uvm_monitor;
    `uvm_component_utils(uart_tx_monitor)

    virtual soc_uart_if vif;
    uvm_analysis_port #(uart_seq_item) ap;
    int baud_div = 16; // Default simulation baud divisor (matching firmware)

    function new(string name = "uart_tx_monitor", uvm_component parent = null);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual soc_uart_if)::get(this, "", "uart_vif", vif)) begin
            `uvm_fatal("NOVIF", "uart_tx_monitor: Failed to get virtual interface 'uart_vif' from uvm_config_db!")
        end
        void'(uvm_config_db#(int)::get(this, "", "baud_div", baud_div));
    endfunction

    virtual task run_phase(uvm_phase phase);
        uart_seq_item item;
        int bit_clocks;

        forever begin
            bit_clocks = baud_div + 1;

            // Ensure monitor probe defaults between frames
            vif.mon_tx_active     <= 1'b0;
            vif.mon_sample_strobe <= 1'b0;

            // 1. Detect Falling Edge of Start Bit (1 -> 0)
            @(negedge vif.uart_tx);
            vif.mon_tx_active <= 1'b1;
            vif.mon_bit_idx   <= 4'h0;
            vif.mon_shift_reg <= 8'h00;

            // 2. Wait Half Bit Period to align to center of Start Bit
            repeat (bit_clocks / 2) @(posedge vif.clk);

            vif.mon_sample_strobe <= 1'b1;
            fork
                begin
                    @(posedge vif.clk);
                    vif.mon_sample_strobe <= 1'b0;
                end
            join_none

            if (vif.uart_tx != 1'b0) begin
                `uvm_warning("UART_MON", "Spurious glitch detected on uart_tx (not a valid start bit)!")
                vif.mon_tx_active <= 1'b0;
                continue;
            end

            // Create new transaction item
            item = uart_seq_item::type_id::create("tx_item");
            item.direction = uart_seq_item::DIRECTION_TX;
            item.baud_div  = baud_div;
            item.timestamp = $time;

            // 3. Sample 8 Data Bits at Center of Each Bit Period
            for (int i = 0; i < 8; i++) begin
                repeat (bit_clocks) @(posedge vif.clk);
                vif.mon_sample_strobe <= 1'b1;
                vif.mon_bit_idx       <= i[3:0];
                item.data_byte[i]      = vif.uart_tx;
                vif.mon_shift_reg[i]  <= vif.uart_tx;
                fork
                    begin
                        @(posedge vif.clk);
                        vif.mon_sample_strobe <= 1'b0;
                    end
                join_none
            end

            // 4. Sample Stop Bit
            repeat (bit_clocks) @(posedge vif.clk);
            vif.mon_sample_strobe <= 1'b1;
            if (vif.uart_tx != 1'b1) begin
                item.framing_err = 1'b1;
                `uvm_error("UART_MON", $sformatf("Framing Error! Expected Stop Bit=1, saw %b", vif.uart_tx))
            end

            `uvm_info("UART_MON", $sformatf("Captured UART TX Byte: 0x%02X ('%c')",
                      item.data_byte, (item.data_byte >= 32 && item.data_byte <= 126) ? item.data_byte : 8'h2E), UVM_LOW)

            // Update interface debug probes for Verdi waveform inspection
            vif.mon_tx_active    <= 1'b0;
            vif.mon_decoded_byte <= item.data_byte;
            vif.mon_byte_valid   <= 1'b1;
            fork
                begin
                    @(posedge vif.clk);
                    vif.mon_sample_strobe <= 1'b0;
                    vif.mon_byte_valid    <= 1'b0;
                end
            join_none

            // Broadcast deserialized item to Scoreboard & Coverage
            ap.write(item);
        end
    endtask

endclass

`endif // UART_TX_MONITOR_SV
