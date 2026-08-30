class status_read_test extends uvm_test;

    `uvm_component_utils(status_read_test)

    apb_uart_env m_env;

    function new(
        string name = "status_read_test",
        uvm_component parent = null
    );
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        m_env = apb_uart_env::type_id::create(
            "m_env",
            this
        );
    endfunction

    virtual task run_phase(uvm_phase phase);

        apb_read_sequence read_seq;
        apb_write_sequence write_seq;

        phase.raise_objection(this);
        //reset后读取status
        read_seq = apb_read_sequence::type_id::create("read_seq");
        read_seq.start(m_env.m_agent.m_sequencer);

        //write
        write_seq = apb_write_sequence::type_id::create("write_11");
        write_seq.data=8'h11;
        write_seq.start(m_env.m_agent.m_sequencer);

        write_seq = apb_write_sequence::type_id::create("write_22");
        write_seq.data=8'h22;
        write_seq.start(m_env.m_agent.m_sequencer);

        write_seq = apb_write_sequence::type_id::create("write_33");
        write_seq.data=8'h33;
        write_seq.start(m_env.m_agent.m_sequencer);

        //read status again
        read_seq=apb_read_sequence::type_id::create("read_after_write");
        read_seq.start(m_env.m_agent.m_sequencer);

        //wait UART finish
        while(m_env.m_scoreboard.expected_queue.size()!=0)begin
            @(posedge m_env.m_monitor.vif.PCLK);
        end

        @(posedge m_env.m_monitor.vif.PCLK);

        phase.drop_objection(this);

    endtask

endclass