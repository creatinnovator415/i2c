class i2c_seq_item extends uvm_sequence_item; // Defines the sequence item class, representing a single I2C transaction.
    `uvm_object_utils(i2c_seq_item) // Registers this class with the UVM factory.

    // TODO: Implement and refine I2C specific transaction fields as needed.
    rand bit [6:0] addr; // A 7-bit random variable for the slave address.
    rand bit       rw; // A random variable for the read/write control bit (0 for write, 1 for read).
    rand byte      data[$]; // A queue of random bytes for the data payload.

    // Acknowledge bits
    bit          addr_ack;    // Acknowledge bit for the address phase
    bit          data_ack[$];  // A queue of acknowledge bits for each data byte

    // Constructor for the i2c_seq_item class.
    function new(string name = "i2c_seq_item");
        super.new(name); // Calls the parent class (uvm_sequence_item) constructor.
    endfunction

endclass // End of the class definition.