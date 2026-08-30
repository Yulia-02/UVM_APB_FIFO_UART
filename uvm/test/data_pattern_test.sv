class data_pattern_test extends uvm_test;

    `uvm_component_utils(data_pattern_test)

    apb_uart_env m_env;

    function new(
        string name = "data_pattern_test",
        uvm_component parent = null
    );
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        m_env = apb_uart_env::type_id::create("m_env", this);
    endfunction


    virtual task run_phase(uvm_phase phase);

        apb_write_sequence seq;

        phase.raise_objection(this);

        // 0x00
        seq = apb_write_sequence::type_id::create("seq_00");
        seq.data = 8'h00;
        seq.start(m_env.m_agent.m_sequencer);

        // 0xFF
        seq = apb_write_sequence::type_id::create("seq_ff");
        seq.data = 8'hFF;
        seq.start(m_env.m_agent.m_sequencer);

        // 0xAA
        seq = apb_write_sequence::type_id::create("seq_aa");
        seq.data = 8'hAA;
        seq.start(m_env.m_agent.m_sequencer);

        // 0x55
        seq = apb_write_sequence::type_id::create("seq_55");
        seq.data = 8'h55;
        seq.start(m_env.m_agent.m_sequencer);

        // 0x01
        seq = apb_write_sequence::type_id::create("seq_01");
        seq.data = 8'h01;
        seq.start(m_env.m_agent.m_sequencer);

        // 0x80
        seq = apb_write_sequence::type_id::create("seq_80");
        seq.data = 8'h80;
        seq.start(m_env.m_agent.m_sequencer);


        // 等待4个UART byte全部发送完成
        repeat (6) begin
            @(posedge m_env.m_monitor.vif.uart_tx_done);
        end

        // 给monitor / scoreboard一个clock完成最后处理
        @(posedge m_env.m_monitor.vif.PCLK);

        phase.drop_objection(this);

    endtask

endclass