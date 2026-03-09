`include "uvm_macros.svh"

import uvm_pkg::*;
import i2c_pkg::*;

class i2c_ref_model extends uvm_component;
    `uvm_component_utils(i2c_ref_model)

    // Analysis import to receive transactions from the monitor
    uvm_analysis_imp #(i2c_seq_item, i2c_ref_model) item_collected_imp;

    // Analysis port to send expected transactions to the scoreboard
    uvm_analysis_port #(i2c_seq_item) expected_item_port;

    // Slave's hardcoded address (matches the DUT in i2c_top.sv)
    const bit [6:0] SLAVE_ADDR = 7'h39;

    function new(string name = "i2c_ref_model", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        item_collected_imp = new("item_collected_imp", this);
        expected_item_port = new("expected_item_port", this);
    endfunction

    // This `write` function is the core logic of the reference model.
    // It gets called when the monitor broadcasts a transaction.
    virtual function void write(i2c_seq_item item);
        i2c_seq_item exp_item;

        // Create a new transaction to hold the expected values
        exp_item = i2c_seq_item::type_id::create("exp_item");

        // 1. Copy the inputs from the actual transaction
        exp_item.addr = item.addr;
        exp_item.rw = item.rw;
        exp_item.data = item.data; // For a write, master provides data

        // 2. Predict the slave's response based on the protocol
        if (item.addr == SLAVE_ADDR) begin
            exp_item.addr_ack = 1'b0; // ACK
            if (item.rw == 0) begin // Write transaction
                foreach (item.data[i]) begin
                    exp_item.data_ack.push_back(1'b0); // Should ACK every data byte
                end
            end
        end else begin
            exp_item.addr_ack = 1'b1; // NACK if address doesn't match
        end

        // 3. Broadcast the complete expected transaction to the scoreboard
        expected_item_port.write(exp_item);
    endfunction

endclass