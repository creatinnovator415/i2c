class i2c_seq_item extends uvm_sequence_item;

rand bit [6:0] addr;
rand bit rw;
rand int data[$];
bit addr_ack;
bit data_ack[$];

`uvm_object_utils_begin(i2c_seq_item)

`uvm_field_int(addr, UVM_DEFAULT)
`uvm_field_int(rw, UVM_DEFAULT)
// `uvm_field_queue_int(data, UVM_DEFAULT)
`uvm_field_int(addr_ack, UVM_DEFAULT)
// `uvm_field_queue_int(data_ack, UVM_DEFAULT)

`uvm_object_utils_end

constraint addr_c { addr != 0; }

constraint data_size_c { data.size() inside {[1:32]}; }

function new(string name = "i2c_seq_item");

    super.new(name);

endfunction

endclass