class i2c_env extends uvm_env; // Defines the environment class, inheriting from the UVM base environment.
    `uvm_component_utils(i2c_env) // Registers this class with the UVM factory.

    i2c_agent m_agent; // Declares a handle for the I2C agent.
    i2c_scoreboard m_scoreboard; // Declares a handle for the scoreboard.

    // Constructor for the i2c_env class.
    function new(string name = "i2c_env", uvm_component parent = null);
        super.new(name, parent); // Calls the parent class (uvm_env) constructor.
    endfunction

    // The build_phase is used to construct the environment's sub-components (agent and scoreboard).
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase); // Calls the parent class build_phase.
        m_agent = i2c_agent::type_id::create("m_agent", this); // Creates an instance of the I2C agent.
        m_scoreboard = i2c_scoreboard::type_id::create("m_scoreboard", this); // Creates an instance of the scoreboard.
    endfunction

    // The connect_phase is used to connect the monitor's output to the scoreboard's input.
    virtual function void connect_phase(uvm_phase phase);
        m_agent.m_monitor.item_collected_port.connect(m_scoreboard.item_collected_imp); // Connects the monitor's analysis port to the scoreboard's import.
    endfunction

endclass