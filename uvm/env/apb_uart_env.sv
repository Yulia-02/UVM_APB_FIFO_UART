class apb_uart_env extends uvm_env;
    
    `uvm_component_utils(apb_uart_env)

    //handle
    apb_agent m_agent;
    uart_monitor m_monitor;
    apb_uart_scoreboard m_scoreboard;
    apb_uart_coverage m_coverage;

    //constructor
    function new(string name="apb_uart_env", uvm_component parent=null);
        super.new(name,parent);
    endfunction

    //build phase
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        m_agent=apb_agent::type_id::create("m_agent",this);
        m_monitor=uart_monitor::type_id::create("m_monitor",this);
        m_scoreboard=apb_uart_scoreboard::type_id::create("m_scoreboard",this);
        m_coverage=apb_uart_coverage::type_id::create("m_coverage",this);
    endfunction

    //connect phase
    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        //uart monitor -> scoreboard
        m_monitor.ap.connect(m_scoreboard.uart_imp);
        //apb monitor -> scoreboard
        m_agent.m_monitor.ap.connect(m_scoreboard.apb_imp);
        //apb monitor -> coverage
        m_agent.m_monitor.ap.connect(m_coverage.analysis_export);//uvm_subscriber 自带 analysis_export
    endfunction
        


endclass