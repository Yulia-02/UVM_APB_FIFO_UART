class depth_config_test extends uvm_test;
    `uvm_component_utils(depth_config_test)

    apb_uart_env m_env;

    function new(string name="depth_config_test", uvm_component parent=null);
        super.new(name,parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        m_env=apb_uart_env::type_id::create("m_env",this);
    endfunction

    virtual task run_phase(uvm_phase phase);
        apb_write_sequence write_seq;
        apb_read_sequence read_seq;

        phase.raise_objection(this);

        write_seq=apb_write_sequence::type_id::create("write_depth_8");
        write_seq.target_addr=32'h0000_0000;
        write_seq.data=8'h01;
        write_seq.start(m_env.m_agent.m_sequencer);

        read_seq=apb_read_sequence::type_id::create("read_depth_8");
        read_seq.target_addr=32'h0000_0000;
        read_seq.start(m_env.m_agent.m_sequencer);

        write_seq = apb_write_sequence::type_id::create("write_depth_16");
        write_seq.target_addr = 32'h0000_0000;
        write_seq.data        = 8'h02;
        write_seq.start(m_env.m_agent.m_sequencer);

        read_seq = apb_read_sequence::type_id::create("read_depth_16");
        read_seq.target_addr = 32'h0000_0000;
        read_seq.start(m_env.m_agent.m_sequencer);

        
        write_seq = apb_write_sequence::type_id::create("write_depth_32");
        write_seq.target_addr = 32'h0000_0000;
        write_seq.data        = 8'h04;
        write_seq.start(m_env.m_agent.m_sequencer);

        read_seq = apb_read_sequence::type_id::create("read_depth_32");
        read_seq.target_addr = 32'h0000_0000;
        read_seq.start(m_env.m_agent.m_sequencer);


        write_seq = apb_write_sequence::type_id::create("write_depth_64");
        write_seq.target_addr = 32'h0000_0000;
        write_seq.data        = 8'h08;
        write_seq.start(m_env.m_agent.m_sequencer);

        read_seq = apb_read_sequence::type_id::create("read_depth_64");
        read_seq.target_addr = 32'h0000_0000;
        read_seq.start(m_env.m_agent.m_sequencer);


        write_seq = apb_write_sequence::type_id::create("write_depth_128");
        write_seq.target_addr = 32'h0000_0000;
        write_seq.data        = 8'h10;
        write_seq.start(m_env.m_agent.m_sequencer);

        read_seq = apb_read_sequence::type_id::create("read_depth_128");
        read_seq.target_addr = 32'h0000_0000;
        read_seq.start(m_env.m_agent.m_sequencer);

        
        write_seq = apb_write_sequence::type_id::create("write_depth_256");
        write_seq.target_addr = 32'h0000_0000;
        write_seq.data        = 8'h20;
        write_seq.start(m_env.m_agent.m_sequencer);

        read_seq = apb_read_sequence::type_id::create("read_depth_256");
        read_seq.target_addr = 32'h0000_0000;
        read_seq.start(m_env.m_agent.m_sequencer);

        @(posedge m_env.m_monitor.vif.PCLK);
        phase.drop_objection(this);
    endtask
endclass


