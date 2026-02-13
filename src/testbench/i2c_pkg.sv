`timescale 1ns/1ps // Sets the simulation time unit and precision.
package i2c_pkg; // Defines a package named 'i2c_pkg'.
    import uvm_pkg::*; // Imports the UVM library, making its contents available inside this package.
    `include "uvm_macros.svh" // Includes the file containing UVM macros.
    `include "i2c_seq_item.sv" // Includes the transaction item definition.
    `include "i2c_driver.sv" // Includes the driver class definition.
    `include "i2c_monitor.sv" // Includes the monitor class definition.
    `include "i2c_agent.sv" // Includes the agent class definition.
    `include "i2c_scoreboard.sv" // Includes the scoreboard class definition.
    `include "i2c_env.sv" // Includes the environment class definition.
    `include "i2c_sequence.sv" // Includes the sequence class definition.
    `include "i2c_base_test.sv" // Includes the test class definitions.
endpackage // End of the package definition.
