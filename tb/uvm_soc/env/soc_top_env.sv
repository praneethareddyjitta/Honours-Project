/* =============================================================================
 * File        : soc_top_env.sv
 * Description : Top-Level UVM Environment instantiating all 5 peripheral VIP
 *               agents (UART, I2C, GPIO, PWM, Timer) and connecting them to Scoreboard
 * ============================================================================= */

`ifndef SOC_TOP_ENV_SV
`define SOC_TOP_ENV_SV

class soc_top_env extends uvm_env;
    `uvm_component_utils(soc_top_env)

    // VIP Agents
    uart_agent  uart_ag;
    i2c_agent   i2c_ag;
    gpio_agent  gpio_ag;
    pwm_agent   pwm_ag;
    timer_agent timer_ag;

    // Central Scoreboard
    soc_scoreboard sb;

    function new(string name = "soc_top_env", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        uart_ag  = uart_agent::type_id::create("uart_ag", this);
        i2c_ag   = i2c_agent::type_id::create("i2c_ag", this);
        gpio_ag  = gpio_agent::type_id::create("gpio_ag", this);
        pwm_ag   = pwm_agent::type_id::create("pwm_ag", this);
        timer_ag = timer_agent::type_id::create("timer_ag", this);

        sb = soc_scoreboard::type_id::create("sb", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        // Connect VIP Analysis Ports to Scoreboard FIFOs
        uart_ag.ap.connect(sb.uart_fifo.analysis_export);
        i2c_ag.ap.connect(sb.i2c_fifo.analysis_export);
        gpio_ag.ap.connect(sb.gpio_fifo.analysis_export);
        pwm_ag.ap.connect(sb.pwm_fifo.analysis_export);
        timer_ag.ap.connect(sb.timer_fifo.analysis_export);
    endfunction
endclass

`endif // SOC_TOP_ENV_SV
