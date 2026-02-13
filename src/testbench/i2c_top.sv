import uvm_pkg::*;
`include "uvm_macros.svh"
import i2c_pkg::*; // Imports the user-defined I2C testbench package.
`timescale 1ns/1ps // Sets the simulation time unit and precision.

module i2c_top; // Defines the top-level module for the simulation.
    logic clk = 0; // Declares the main clock signal, initialized to 0.
    always #5 clk = ~clk; // Generates a clock with a 10ns period (5ns high, 5ns low).

    i2c_if tb_if(clk); // Instantiates the I2C interface, connecting the clock.

    // TODO: Instantiate the correct I2C DUT (master or slave) and connect the ports.
    // The example below instantiates both a master and a slave.
    // You may need to adjust this based on your specific design.
    // i2c_master master_inst ( // Instantiates the I2C Master DUT.
    //     .clk(clk), // Connects the DUT clock.
    //     .reset_n(tb_if.reset_n), // Connects the DUT reset.
    //     .scl(tb_if.scl), // Connects the I2C clock line.
    //     .sda(tb_if.sda) // Connects the I2C data line.
    //     // Add other master ports if any
    // );

    i2c_slave slave_inst ( // Instantiates the I2C Slave model/DUT.
        .clk(clk), // Connects the slave clock.
        .reset(~tb_if.reset_n), // Connects the slave reset.
        .SCL(tb_if.scl), // Connects the I2C clock line.
        .SDA(tb_if.sda), // Connects the I2C data line.
        .MY_ADDR(7'h39),
        .data_received_flag(),
        .rw_captured()
        // Add other slave ports if any
    );

    initial 
        begin // An initial block that executes once at the beginning of the simulation.
            // Places the virtual interface handle into the UVM configuration database for other components to access.
            uvm_config_db#(virtual i2c_if)::set(null, "*", "vif", tb_if);
            // Starts the UVM simulation by running the specified test ('i2c_base_test').
            run_test("simple_test");
        end

endmodule // End of the top-level module.