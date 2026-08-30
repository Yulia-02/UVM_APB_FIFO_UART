class baud_div_zero_test extends uvm_test;
    `uvm_component_utils(baud_div_zero_test)

    apb_uart_env m_env;

    function new(string name="baud_div_zero_test", uvm_component parent=null);
        super.new(name,parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        m_env = apb_uart_env::type_id::create("m_env",this);
    endfunction

    virtual task run_phase(uvm_phase phase);
        apb_write_sequence seq;
        int timeout_count;

        phase.raise_objection(this);

        //set uart baud divider to zero
        m_env.m_monitor.vif.uart_baud_div=16'd0;
        `uvm_info("BAUD_DIY_ZERO_TEST","Set uart_baud_div=0",UVM_LOW)

        //write one byte into FIFO
        seq=apb_write_sequence::type_id::create("seq",this);
        seq.data=8'hA5;
        seq.start(m_env.m_agent.m_sequencer);

        //wait until scoreboard receiver UART data
        timeout_count=0;

        while((m_env.m_scoreboard.expected_queue.size()!=0)&&(timeout_count<100))begin
            @(posedge m_env.m_monitor.vif.PCLK);
            timeout_count++;
        end

        //check result
        if(m_env.m_scoreboard.expected_queue.size()==0)begin
            `uvm_info("BAUD_DIV_ZERO_TEST","PASS:UART transmission completed with baud_div=0",UVM_LOW)
        end
        else begin
            `uvm_error("BAUD_DIV_ZERO_TEST","FAIL:UART transmission did not complete with baud_div=0")
        end

        wait(m_env.m_monitor.vif.uart_tx_busy==1'b0);

        repeat(3)
            @(posedge m_env.m_monitor.vif.PCLK);

        phase.drop_objection(this);
    endtask

endclass
