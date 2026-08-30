class apb_uart_coverage extends uvm_subscriber #(apb_transaction);
    `uvm_component_utils (apb_uart_coverage)
    apb_transaction tr;

//covergroup
covergroup apb_cg;
  option.per_instance = 1;

    // APB write/read coverage
    cp_write:coverpoint tr.write{
        bins READ={0};
        bins WRITE={1};
    }
    // address coverage
    cp_addr:coverpoint tr.addr{
        bins REG0={32'h0000_0000};
        bins STATUS_REG={32'h0000_0020};
        bins FIFO_DATA={32'h8000_0000};
        bins INVALID={32'h0000_0040};
    }

    // PSLVERR coverage
    cp_slverr: coverpoint tr.slverr{
        bins NO_ERROR = {0};
        bins ERROR = {1};
    }

    cp_depth_cfg : coverpoint tr.wdata[7:0]
    iff (tr.write && tr.addr == 32'h0000_0000)
    {
    bins DEPTH_8   = {8'h01};
    bins DEPTH_16  = {8'h02};
    bins DEPTH_32  = {8'h04};
    bins DEPTH_64  = {8'h08};
    bins DEPTH_128 = {8'h10};
    bins DEPTH_256 = {8'h20};
    }
endgroup

function new(string name="apb_uart_coverage",uvm_component parent=null);
    super.new(name,parent);
    apb_cg=new();
    `uvm_info(

        "COVERAGE_DEBUG",

        "Coverage component and covergroup created",

        UVM_LOW
    )
endfunction

// uvm_subscriber 实现 write
virtual function void write(apb_transaction t);
    tr=t;
     `uvm_info(
        "COVERAGE_DEBUG",
        $sformatf(
            "Sampling: addr=0x%08h write=%0b slverr=%0b",

            tr.addr,

            tr.write,

            tr.slverr
        ),
        UVM_LOW
    )
    apb_cg.sample();
    endfunction
endclass