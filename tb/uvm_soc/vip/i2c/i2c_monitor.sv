/* =============================================================================
 * File        : i2c_monitor.sv
 * Description : UVM Monitor that passively sniffs physical SCL & SDA lines,
 *               decodes I2C frames (START, Addr, R/W, ACK, Data, STOP),
 *               updates interface debug probes, and broadcasts via analysis port.
 * ============================================================================= */

`ifndef I2C_MONITOR_SV
`define I2C_MONITOR_SV

class i2c_monitor extends uvm_monitor;
    `uvm_component_utils(i2c_monitor)

    virtual soc_i2c_if vif;
    uvm_analysis_port #(i2c_seq_item) ap;

    function new(string name = "i2c_monitor", uvm_component parent = null);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual soc_i2c_if)::get(this, "", "i2c_vif", vif)) begin
            `uvm_fatal("NOVIF", "i2c_monitor: Failed to get virtual interface 'i2c_vif' from uvm_config_db!")
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        i2c_seq_item item;
        bit [6:0] addr_int;
        bit       rw_int;
        bit [7:0] data_int;
        bit       ack_int;

        forever begin
            // 1. Detect START condition: SDA falling edge while SCL is HIGH
            @(negedge vif.sda);
            if (vif.scl === 1'b1) begin
                vif.mon_start <= 1'b1;
                fork begin @(posedge vif.clk); vif.mon_start <= 1'b0; end join_none

                // 2. Sample 7-bit Slave Address (MSB first)
                addr_int = 7'h00;
                for (int i = 6; i >= 0; i--) begin
                    @(posedge vif.scl);
                    addr_int[i] = vif.sda;
                end

                // 3. Sample R/W Bit
                @(posedge vif.scl);
                rw_int = vif.sda;

                // 4. Sample Address ACK Bit (0 = ACK, 1 = NACK)
                @(posedge vif.scl);
                ack_int = vif.sda;

                vif.mon_addr <= addr_int;
                vif.mon_rw   <= rw_int;
                vif.mon_ack  <= ack_int;

                // 5. Sample 8-bit Data
                data_int = 8'h00;
                for (int i = 7; i >= 0; i--) begin
                    @(posedge vif.scl);
                    data_int[i] = vif.sda;
                end

                // 6. Sample Data ACK Bit
                @(posedge vif.scl);
                ack_int = vif.sda;

                vif.mon_data_byte  <= data_int;
                vif.mon_byte_valid <= 1'b1;
                fork begin @(posedge vif.clk); vif.mon_byte_valid <= 1'b0; end join_none

                // Broadcast transaction item
                item = i2c_seq_item::type_id::create("i2c_mon_item");
                item.addr      = addr_int;
                item.rw        = rw_int;
                item.data_byte = data_int;
                item.ack       = ack_int;
                item.timestamp = $realtime;

                `uvm_info("I2C_MON", item.convert2string(), UVM_LOW)
                ap.write(item);
            end
        end
    endtask
endclass

`endif // I2C_MONITOR_SV
