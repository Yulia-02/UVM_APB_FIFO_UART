class invalid_addr_test extends uvm_test;
    `uvm_component_utils(invalid_addr_test)

    apb_uart_env m_env;

    function new (string name="invalid_addr_test", uvm_component parent);
        super.new(name,parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase); 
        m_env = apb_uart_env::type_id::create("m_env",this);
    endfunction

    virtual task run_phase(uvm_phase phase);
        apb_write_sequence seq;
        
        phase.raise_objection(this);

        seq = apb_write_sequence::type_id::create("invalid_seq");

        seq.target_addr = 32'h0000_0040;
        seq.data = 8'hAA;

        seq.start(m_env.m_agent.m_sequencer);

        /*
        @(posedge m_env.m_monitor.vif.PCLK);
        if(m_env.m_monitor.vif.PSLVERR == 1'b1)begin
            `uvm_info("INVALID_ADDR_TEST","PASS:PSLVERR asserted for invalid address",UVM_LOW)
        end
        else begin
            `uvm_error("INVALID_ADDR_TEST","FAIL:PSLVERR was not asserted for invalid address")
        end
        */

        //非法transaction不应该进入expected queue
        if(m_env.m_scoreboard.expected_queue.size()==0) begin
            `uvm_info("INVALID_ADDR_TEST", "PASS: Invalid write did not enter FIFO/UART expected path", UVM_LOW)
        end
        else begin
            `uvm_error("INVALID_ADDR_TEST", "FAIL:Invalid write incorrectly entered expected queue")
        end

        repeat(10)
            @(posedge m_env.m_monitor.vif.PCLK);

        if (m_env.m_monitor.vif.uart_tx_busy==1'b0) begin
            `uvm_info("INVALID_ADDR_TEST","PASSED: No unexpected UART transmission",UVM_LOW)
        end
        else begin
            `uvm_error("INVALID_ADDR_TEST","FAIL: UART unexpectedly started after invalid APB access")
        end

        phase.drop_objection(this);
    endtask

endclass