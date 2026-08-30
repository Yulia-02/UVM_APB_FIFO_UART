class full_test extends uvm_test;

    `uvm_component_utils(full_test)

    apb_uart_env m_env;

    function new(string name = "full_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        m_env = apb_uart_env::type_id::create("m_env",this);
    endfunction

    virtual task run_phase(uvm_phase phase);

        apb_write_sequence seq;
        int timeout_count;

        phase.raise_objection(this);

        for(int i=0; i<12; i++)begin
            seq=apb_write_sequence::type_id::create($sformatf("seq_%0d",i));

            seq.data=i[7:0];

            seq.start(m_env.m_agent.m_sequencer);

            if(m_env.m_monitor.vif.full)
                break;
        end

        timeout_count=0;

        while((m_env.m_monitor.vif.full!=1'b1)&&(timeout_count<100))begin
            @(posedge m_env.m_monitor.vif.PCLK);
            timeout_count++;
        end

        if (m_env.m_monitor.vif.full == 1'b1) begin
            `uvm_info("FULL_TEST",$sformatf("PASS: FIFO full asserted after %0d wait cycles",timeout_count),UVM_LOW)
        end else begin
            `uvm_error ("FULL_TEST","FAIL: FIFO full was not asserted before timeout")
        end

        phase.drop_objection(this);

    endtask

endclass