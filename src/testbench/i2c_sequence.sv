import uvm_pkg::*; // Imports the main UVM library package.
class i2c_sequence extends uvm_sequence #(i2c_seq_item); // Defines a sequence class, parameterized with the transaction type.
    `uvm_object_utils(i2c_sequence) // Registers this sequence (which is a uvm_object) with the UVM factory.
    
    // Constructor for the i2c_sequence class.
    function new(string name = "i2c_sequence");
        super.new(name); // Calls the parent class (uvm_sequence) constructor.
    endfunction
    
    // The 'body' task contains the main logic of the sequence.
    task body();
        i2c_seq_item item; // Declares a handle for the transaction item.
        item = i2c_seq_item::type_id::create("item"); // Creates a new transaction object using the factory.

        // TODO: Implement I2C specific sequence logic to define the stimulus.
        // 1. Randomize the item with specific constraints if needed.
        //    Example: assert(item.randomize() with { addr == 'h24; data.size() == 4; });
        // 2. You can create a series of transactions (e.g., a write followed by a read).
        // 3. The example below sends one basic randomized transaction.
        
        // First, randomize the item to define its properties.
        assert(item.randomize()); // Randomizes the transaction item's properties.
        start_item(item); // Sends the transaction to the driver and waits for it to be accepted.
        finish_item(item); // Waits for the driver to signal completion and updates the item with any response data.

    endtask
endclass // End of the class definition.
