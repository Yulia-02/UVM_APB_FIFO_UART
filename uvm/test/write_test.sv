class write_test extends uvm_test;
    `uvm_component_utils(write_test)

    apb_uart_env m_env;

    function new(string name="write_test",uvm_component parent=null);
        super.new(name,parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        m_env=apb_uart_env::type_id::create("m_env",this);
    endfunction

    virtual task run_phase(uvm_phase phase);
        apb_write_sequence seq;
        phase.raise_objection(this);//创建并启动apb_write_sequence

        seq=apb_write_sequence::type_id::create("seq",this);
        seq.start(m_env.m_agent.m_sequencer);

        wait(m_env.m_monitor.vif.uart_tx_done==1'b1);

        @(posedge m_env.m_monitor.vif.PCLK);

        phase.drop_objection(this);
    endtask

endclass
