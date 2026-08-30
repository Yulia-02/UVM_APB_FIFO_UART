class multi_write_test extends uvm_test;

    `uvm_component_utils(multi_write_test)

    apb_uart_env m_env;

    function new(string name = "multi_write_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        m_env = apb_uart_env::type_id::create("m_env",this);
    endfunction

    virtual task run_phase(uvm_phase phase);

        apb_write_sequence seq;

        phase.raise_objection(this);

        // Write 0x55
        seq = apb_write_sequence::type_id::create("seq_55");
        seq.data = 8'h55;
        seq.start(m_env.m_agent.m_sequencer);

        // Write 0xA5
        seq = apb_write_sequence::type_id::create("seq_a5");
        seq.data = 8'hA5;
        seq.start(m_env.m_agent.m_sequencer);

        // Write 0x3C
        seq = apb_write_sequence::type_id::create("seq_3c");
        seq.data = 8'h3C;
        seq.start(m_env.m_agent.m_sequencer);

        // 等最后三个 UART byte 都发完
        repeat (3) begin
            @(posedge m_env.m_monitor.vif.uart_tx_done);
        end

        @(posedge m_env.m_monitor.vif.PCLK);

        phase.drop_objection(this);

    endtask

endclass