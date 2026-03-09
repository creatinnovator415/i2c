class i2c_seq_item extends uvm_sequence_item; // Defines the sequence item class, representing a single I2C transaction.
    // Register with factory and enable field automation macros for print, copy, compare, etc.
    `uvm_object_utils_begin(i2c_seq_item)

    // TODO: Implement and refine I2C specific transaction fields as needed.
    rand bit [6:0] addr; // A 7-bit random variable for the slave address.
    rand bit       rw; // A random variable for the read/write control bit (0 for write, 1 for read).
    rand byte      data[$]; // A queue of random bytes for the data payload.
        `uvm_field_int(addr, UVM_DEFAULT)
        `uvm_field_int(rw, UVM_DEFAULT)
        `uvm_field_queue_int(data, UVM_DEFAULT)

    // Acknowledge bits
    bit          addr_ack;    // Acknowledge bit for the address phase
    bit          data_ack[$];  // A queue of acknowledge bits for each data byte
        `uvm_field_int(addr_ack, UVM_DEFAULT)
        `uvm_field_queue_int(data_ack, UVM_DEFAULT)

    `uvm_object_utils_end

    // Constraints to ensure valid I2C transactions
    constraint addr_c { addr != 0; } // Avoid general call address if not supported
    constraint data_size_c { data.size() inside {[1:32]}; } // Limit payload size

    // Constructor for the i2c_seq_item class.
    function new(string name = "i2c_seq_item");
        super.new(name); // Calls the parent class (uvm_sequence_item) constructor.
    endfunction

endclass // End of the class definition.