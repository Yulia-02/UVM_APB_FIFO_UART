class apb_read_sequence extends uvm_sequence #(apb_transaction);

    `uvm_object_utils(apb_read_sequence)

    bit [31:0] target_addr = 32'h0000_0020;

    function new(string name="apb_read_sequence");
        super.new(name);
    endfunction

    task body();

    req=apb_transaction::type_id::create("req");

    start_item(req);

    req.strb=4'b000;
    req.prot=3'b000;
    req.write=1'b0;//read操作
    //req.addr=32'h0000_0020;//地址在status_reg
    req.addr = target_addr;

    finish_item(req);
    endtask


endclass
        