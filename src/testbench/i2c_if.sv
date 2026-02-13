`timescale 1ns/1ps // Sets the simulation time unit to 1ns and precision to 1ps.

interface i2c_if(input logic clk); // Defines an interface named 'i2c_if' which takes 'clk' as an input port.
    logic reset_n; // Active-low reset signal.
    // TODO: Implement I2C specific logic for signal interactions if needed.
    logic scl; // The serial clock for the I2C bus.
    wire sda; // The bidirectional serial data line for the I2C bus.

    logic sda_out = 1'bz; // Internal signal for driving sda
    assign sda = sda_out; // Continuous assignment to the wire
    assign (pull1, pull0) sda = 1'b1; // Pull-up resistor for I2C open-drain behavior

    // Modport for the master driver, defining signal directions from the master's perspective.
    modport master (
        output scl, // The master drives the clock.
        inout sda, // The data line is bidirectional.
        input clk, // The system clock.
        input reset_n // The active-low reset.
    );

    // Modport for the monitor, defining signal directions from the monitor's perspective.
    modport monitor (
        input scl, // The monitor observes the clock.
        input sda, // The monitor observes the data line.
        input clk, // The system clock.
        input reset_n // The active-low reset.
    );

endinterface // End of the interface definition.