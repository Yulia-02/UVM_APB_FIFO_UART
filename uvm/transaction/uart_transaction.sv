class uart_transaction extends uvm_sequence_item;

//data
bit [7:0] data; //output

//register
`uvm_object_utils_begin(uart_transaction)
   `uvm_field_int(data, UVM_HEX)
`uvm_object_utils_end

//new
function new(string name="uart_transaction");
    super.new(name);
endfunction

endclass

