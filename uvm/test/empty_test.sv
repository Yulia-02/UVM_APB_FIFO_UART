class empty_test extends uvm_test;

    `uvm_component_utils(empty_test)

    apb_uart_env m_env;


    // Constructor
    function new(
        string name = "empty_test",
        uvm_component parent = null
    );
        super.new(name, parent);
    endfunction


    // Build phase
    virtual function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        m_env = apb_uart_env::type_id::create(
            "m_env",
            this
        );

    endfunction

    // Run phase
    virtual task run_phase(uvm_phase phase);

        apb_write_sequence seq;

        int empty_timeout;
        int scoreboard_timeout;

        phase.raise_objection(this);

        // Write several bytes into FIFO
        seq = apb_write_sequence::type_id::create("seq_11");
        seq.data = 8'h11;
        seq.start(m_env.m_agent.m_sequencer);

        seq = apb_write_sequence::type_id::create("seq_22");
        seq.data = 8'h22;
        seq.start(m_env.m_agent.m_sequencer);

        seq = apb_write_sequence::type_id::create("seq_33");
        seq.data = 8'h33;
        seq.start(m_env.m_agent.m_sequencer);

        // Wait until FIFO becomes empty
        empty_timeout = 0;

        while (
            (m_env.m_monitor.vif.empty != 1'b1) &&
            (empty_timeout < 500)
        ) begin
            @(posedge m_env.m_monitor.vif.PCLK);
            empty_timeout++;
        end

        if (m_env.m_monitor.vif.empty == 1'b1) begin
            `uvm_info("EMPTY_TEST",$sformatf("FIFO empty asserted after %0d wait cycles",empty_timeout),UVM_LOW)
        end
        else begin
            `uvm_error("EMPTY_TEST","FIFO did not become empty before timeout")
        end

        // Wait until all expected UART bytes have actually been received and compared by the scoreboard
        scoreboard_timeout = 0;

        while (
            (m_env.m_scoreboard.expected_queue.size() != 0) &&
            (scoreboard_timeout < 500)
        ) begin
            @(posedge m_env.m_monitor.vif.PCLK);
            scoreboard_timeout++;
        end

        if (
            m_env.m_scoreboard.expected_queue.size() == 0
        ) begin
            `uvm_info("EMPTY_TEST",$sformatf("PASS: FIFO empty and all UART data matched after %0d additional cycles",scoreboard_timeout),UVM_LOW)
        end
        else begin
            `uvm_error("EMPTY_TEST",$sformatf("FAIL: %0d expected UART byte(s) still unmatched",m_env.m_scoreboard.expected_queue.size()))
        end

        @(posedge m_env.m_monitor.vif.PCLK);
        phase.drop_objection(this);

    endtask

endclass