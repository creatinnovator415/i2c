class i2c_agent extends uvm_agent; // Defines the agent class, inheriting from the UVM base agent.
    `uvm_component_utils(i2c_agent) // Registers this class with the UVM factory.

    i2c_driver m_driver; // Declares a handle for the driver component.
    i2c_monitor m_monitor; // Declares a handle for the monitor component.
    uvm_sequencer #(i2c_seq_item) m_sequencer; // Declares a handle for the sequencer, parameterized with the transaction type.

    // Constructor for the i2c_agent class.
    function new(string name = "i2c_agent", uvm_component parent = null);
        super.new(name, parent); // Calls the parent class (uvm_agent) constructor.
    endfunction

    // The build_phase is used to construct the agent's sub-components.
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase); // Calls the parent class build_phase.
        m_driver = i2c_driver::type_id::create("m_driver", this); // Creates an instance of the driver.
        m_monitor = i2c_monitor::type_id::create("m_monitor", this); // Creates an instance of the monitor.
        m_sequencer = uvm_sequencer#(i2c_seq_item)::type_id::create("m_sequencer", this); // Creates an instance of the sequencer.
    endfunction

    // The connect_phase is used to connect TLM ports between components.
    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase); // Calls the parent class connect_phase.
        m_driver.seq_item_port.connect(m_sequencer.seq_item_export); // Connects the driver's port to the sequencer's export.
    endfunction

endclass // End of the class definition.