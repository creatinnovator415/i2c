`include "uvm_macros.svh" // Includes UVM macros for factory registration, reporting, etc.

import uvm_pkg::*;
import i2c_pkg::*;

class i2c_scoreboard extends uvm_scoreboard; // Defines the scoreboard class, inheriting from the UVM base scoreboard.
    `uvm_component_utils(i2c_scoreboard) // Registers this class with the UVM factory.

    // Analysis import to receive actual transactions from the monitor.
    uvm_analysis_imp #(i2c_seq_item, i2c_scoreboard) item_collected_imp;

    // Analysis export and FIFO for expected transactions
    uvm_analysis_export #(i2c_seq_item) expected_analysis_export;
    uvm_tlm_analysis_fifo #(i2c_seq_item) expected_fifo;

    // Constructor for the i2c_scoreboard class.
    function new(string name = "i2c_scoreboard", uvm_component parent = null);
        super.new(name, parent); // Calls the parent class (uvm_scoreboard) constructor.
    endfunction

    // Build phase to create the analysis import component.
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase); // Calls the parent class build_phase.
        item_collected_imp = new("item_collected_imp", this); // Creates an instance of the analysis import.
        expected_analysis_export = new("expected_analysis_export", this);
        expected_fifo = new("expected_fifo", this);
    endfunction

    // Connect phase to connect the export to the FIFO.
    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        expected_analysis_export.connect(expected_fifo.analysis_export);
    endfunction

    // The `write` method is automatically called via the item_collected_imp.
    // This is where the checking logic resides.
    virtual function void write(i2c_seq_item item);
        i2c_seq_item exp_item;

        // Try to get the expected transaction from the FIFO
        if (!expected_fifo.try_get(exp_item)) 
            begin
                `uvm_warning("SCOREBOARD", "Received transaction from Monitor but Expected FIFO is empty. Skipping comparison.")
                return;
            end

        // Use the uvm_object::compare() method for a comprehensive comparison.
        // This requires the field macros to be implemented in i2c_seq_item.
        `uvm_info("SCOREBOARD", "Comparing transactions...", UVM_HIGH)
        if (!exp_item.compare(item)) begin
            `uvm_error("SCOREBOARD", "Transaction MISMATCH!")
            `uvm_info("SCOREBOARD", {"\nExpected:\n", exp_item.sprint(), 
                                     "\nActual:\n",   item.sprint()}, UVM_NONE)
        end else begin
            `uvm_info("SCOREBOARD", "Transaction MATCH!", UVM_HIGH)
        end
    endfunction
endclass // End of the class definition.