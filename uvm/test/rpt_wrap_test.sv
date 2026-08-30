class rpt_wrap_test extends uvm_test;
    `uvm_component_utils (rpt_wrap_test)

    apb_uart_env m_env;

    function new(string name="rpt_wrap_test",uvm_component parent=null);
        super.new(name,parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        m_env=apb_uart_env::type_id::create("m_env",this);
    endfunction

    virtual task run_phase(uvm_phase phase);
        apb_write_sequence seq;
        int timeout_count;

        phase.raise_objection(this);

        for(int i=0;i<9;i++)begin
            seq=apb_write_sequence::type_id::create($sformatf("seq_%0d",i));
            seq.data=8'hA0+i[7:0];

            seq.start(m_env.m_agent.m_sequencer);
        end

        timeout_count=0;

        while((m_env.m_scoreboard.expected_queue.size()!=0)&&
            (timeout_count<1000)) begin
        
        @(posedge m_env.m_monitor.vif.PCLK);
        timeout_count++;
            end

        if(m_env.m_scoreboard.expected_queue.size()==0)begin
            `uvm_info("RPT_WRAP_TEST","PASS: All UART data matched after FIFO rpt wrap-around",UVM_LOW);
        end 
        else begin
            `uvm_error("RPT_WRAP_TEST","FAIL: Timeout for FIFO/UART transactions to complete")
        end

        wait(m_env.m_monitor.vif.uart_tx_busy==1'b0);

        repeat(3)
            @(posedge m_env.m_monitor.vif.PCLK);
        
        phase.drop_objection(this);

        endtask
endclass