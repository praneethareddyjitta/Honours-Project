/* =============================================================================
 * File        : pwm_monitor.sv
 * Description : UVM Monitor that measures pwm_out high cycles, period, and duty
 * ============================================================================= */

`ifndef PWM_MONITOR_SV
`define PWM_MONITOR_SV

class pwm_monitor extends uvm_monitor;
    `uvm_component_utils(pwm_monitor)

    virtual soc_pwm_if vif;
    uvm_analysis_port #(pwm_seq_item) ap;

    function new(string name = "pwm_monitor", uvm_component parent = null);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual soc_pwm_if)::get(this, "", "pwm_vif", vif)) begin
            `uvm_fatal("NOVIF", "pwm_monitor: Failed to get virtual interface 'pwm_vif' from uvm_config_db!")
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        pwm_seq_item item;
        int high_count;
        int period_count;

        forever begin
            high_count = 0;
            period_count = 0;

            // Wait for PWM rising edge
            @(posedge vif.pwm_out);

            // Measure high duration
            while (vif.pwm_out === 1'b1) begin
                @(posedge vif.clk);
                high_count++;
                period_count++;
            end

            // Measure remaining low duration until next rising edge or period end (256 cycles)
            while (vif.pwm_out === 1'b0 && period_count < 256) begin
                @(posedge vif.clk);
                period_count++;
            end

            if (period_count > 0) begin
                vif.mon_period_cycles <= period_count;
                vif.mon_high_cycles   <= high_count;
                vif.mon_duty_percent  <= (high_count * 100) / period_count;
                vif.mon_period_valid  <= 1'b1;
                fork begin @(posedge vif.clk); vif.mon_period_valid <= 1'b0; end join_none

                item = pwm_seq_item::type_id::create("pwm_item");
                item.period_cycles = period_count;
                item.high_cycles   = high_count;
                item.duty_pct      = (high_count * 100) / period_count;
                item.timestamp     = $realtime;

                `uvm_info("PWM_MON", item.convert2string(), UVM_LOW)
                ap.write(item);
            end
        end
    endtask
endclass

`endif // PWM_MONITOR_SV
