import uvm_pkg::*; // Imports the main UVM library package.
`include "uvm_macros.svh" // Includes UVM macros for factory registration, reporting, etc.
import i2c_pkg::*; // Imports the user-defined I2C testbench package.

class i2c_base_test extends uvm_test; // Defines the base test class, inheriting from the UVM base test class.
    `uvm_component_utils(i2c_base_test) // Registers this class with the UVM factory.

    i2c_env m_env; // Declares a handle for the I2C environment component.
    virtual i2c_if vif; // Declares a handle for the virtual interface to connect to the DUT.

    // Constructor for the i2c_base_test class.
    function new(string name = "i2c_base_test", uvm_component parent = null);
        super.new(name, parent); // Calls the parent class (uvm_test) constructor.
    endfunction

    // The build_phase is used to construct components in the testbench hierarchy.
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase); // Calls the parent class build_phase.
        m_env = i2c_env::type_id::create("m_env", this); // Creates an instance of the I2C environment.

        // Get the virtual interface handle from the configuration database.
        if (!uvm_config_db#(virtual i2c_if)::get(this, "", "vif", vif)) 
            begin
                // If the virtual interface is not found, report a fatal error and stop the simulation.
                uvm_report_fatal("NOVIF", "Virtual interface must be set for i2c_base_test");
            end

        // Set the virtual interface handle in the configuration database for the driver and monitor.
        uvm_config_db#(virtual i2c_if)::set(this, "m_env.m_agent.m_driver", "vif", vif);
        uvm_config_db#(virtual i2c_if)::set(this, "m_env.m_agent.m_monitor", "vif", vif);
    endfunction

    // A task to apply a reset sequence to the DUT.
    task reset_dut();
        uvm_report_info("RESET", "Starting DUT reset", UVM_MEDIUM);
        vif.reset_n <= 1'b0; // Drive the active-low reset signal low.
        repeat(5) @(posedge vif.clk); // Wait for 5 clock cycles.
        vif.reset_n <= 1'b1; // De-assert the reset signal.
        uvm_report_info("RESET", "DUT reset complete", UVM_MEDIUM);
    endtask

endclass

// Sequence to scan all I2C addresses (0-127)
class i2c_scan_sequence extends uvm_sequence #(i2c_seq_item);
    `uvm_object_utils(i2c_scan_sequence)

    function new(string name = "i2c_scan_sequence");
        super.new(name);
    endfunction

    virtual task body();
        i2c_seq_item item;
        for (int i = 0; i < 128; i++) begin
            item = i2c_seq_item::type_id::create("item");
            start_item(item);
            item.addr = i;
            item.rw = 0; // Write mode (check for ACK)
            item.data.delete(); // No data payload, just address phase
            finish_item(item);
        end
    endtask
endclass

class simple_test extends i2c_base_test; // Defines a specific test that inherits from i2c_base_test.
    `uvm_component_utils(simple_test) // Registers this class with the UVM factory.

    // Constructor for the simple_test class.
    function new(string name = "simple_test", uvm_component parent = null);
        super.new(name, parent); // Calls the parent class (i2c_base_test) constructor.
    endfunction

    virtual function void build_phase(uvm_phase phase);
        uvm_config_db#(bit)::set(this, "m_env.m_agent.m_driver", "enable_nack_check", 0);
        super.build_phase(phase);
    endfunction

    // The run_phase is where time-consuming simulation activity occurs.
    virtual task run_phase(uvm_phase phase);
        i2c_scan_sequence seq; // Declares a handle for the sequence to be run.
        phase.raise_objection(this); // Prevents the simulation from ending prematurely.

        // 1. Reset the DUT using the task from the base class.
        reset_dut();

        // 2. Create and start the sequence on the agent's sequencer.
        seq = i2c_scan_sequence::type_id::create("seq"); // Creates an instance of the simple_sequence.
        seq.start(m_env.m_agent.m_sequencer); // Starts the sequence, which will generate transactions.

        phase.drop_objection(this); // Signals that this phase is complete, allowing the simulation to end.
    endtask
endclass