`include "uvm_macros.svh"

import uvm_pkg::*;
import i2c_pkg::*;

class i2c_monitor extends uvm_monitor;
  `uvm_component_utils(i2c_monitor)

  // Virtual interface handle to connect to the I2C bus
  virtual i2c_if vif;

  // Analysis port to broadcast collected transactions
  uvm_analysis_port #(i2c_seq_item) item_collected_port;

  // Configuration object handle
  // i2c_agent_config m_cfg;

  // Constructor
  function new(string name = "i2c_monitor", uvm_component parent = null);
    super.new(name, parent);
    item_collected_port = new("item_collected_port", this);
  endfunction

  // Build phase: get configuration and virtual interface
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual i2c_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", {"Virtual interface must be set for: ", get_full_name(), ".vif"})
  endfunction

  // Run phase: main monitoring logic
  virtual task run_phase(uvm_phase phase);
    `uvm_info(get_type_name(), "I2C monitor run phase starting", UVM_MEDIUM)
    fork
      collect_transactions();
    join
  endtask

  // Task to collect I2C transactions
  protected task collect_transactions();
    i2c_seq_item trans;
    // Declare locals up-front to avoid declaration-after-statement parser errors
    logic stop_or_restart_detected;
    byte current_byte;
    logic ack;

    forever begin
      // Wait for a START condition (SDA goes low while SCL is high)
      do
        @(negedge vif.sda);
      while (vif.scl !== 1'b1);

      `uvm_info(get_type_name(), "START condition detected", UVM_HIGH)

      // Create a new transaction
      trans = i2c_seq_item::type_id::create("trans");

      // 1. Read Address (7 bits)
      for (int i = 6; i >= 0; i--) begin
        @(posedge vif.scl);
        trans.addr[i] = vif.sda;
        @(negedge vif.scl);
      end
      `uvm_info(get_type_name(), $sformatf("Address detected: 0x%0h", trans.addr), UVM_HIGH)

      // 2. Read R/W bit
      @(posedge vif.scl);
      trans.rw = vif.sda;
      @(negedge vif.scl);
      `uvm_info(get_type_name(), $sformatf("R/W bit detected: %b", trans.rw), UVM_HIGH)

      // 3. Check for ACK/NACK from slave (ACK = 0, NACK = 1)
      @(posedge vif.scl);
      trans.addr_ack = vif.sda;
      @(negedge vif.scl);
      `uvm_info(get_type_name(), $sformatf("Addr ACK detected: %b", trans.addr_ack), UVM_HIGH)

      // After address ACK, check for data bytes
      if (trans.addr_ack == 1'b0) begin
        // Loop to capture data bytes until a STOP or REPEATED START
        forever begin
          stop_or_restart_detected = 0;
          // Watch for STOP, REPEATED START, or next byte
          fork
            begin: check_stop
              @(posedge vif.scl); // SCL must go high for STOP/RESTART
              @(posedge vif.sda);
              if (vif.scl == 1'b1) begin
                `uvm_info(get_type_name(), "STOP condition detected", UVM_HIGH)
                stop_or_restart_detected = 1;
              end
            end
            begin: check_restart
              @(posedge vif.scl);
              @(negedge vif.sda);
              if (vif.scl == 1'b1) begin
                `uvm_info(get_type_name(), "REPEATED START detected", UVM_HIGH)
                stop_or_restart_detected = 1;
              end
            end
            begin: check_next_byte
              @(posedge vif.scl);
              // This path proceeds to read the data bit
            end
          join_any
          disable fork;

          if (stop_or_restart_detected) begin
            break; // Exit data gathering loop
          end

          // At this point, we are at the posedge of SCL for the first bit of the new byte.
          current_byte[7] = vif.sda;
          @(negedge vif.scl);

          // Sample remaining 7 data bits
          for (int i = 6; i >= 0; i--) begin
            @(posedge vif.scl);
            current_byte[i] = vif.sda;
            @(negedge vif.scl);
          end
          trans.data.push_back(current_byte);
          `uvm_info(get_type_name(), $sformatf("Data byte detected: 0x%0h", current_byte), UVM_HIGH)

          // Check for ACK/NACK after data byte
          @(posedge vif.scl);
          ack = vif.sda; // ACK==0, NACK==1
          trans.data_ack.push_back(ack);
          `uvm_info(get_type_name(), $sformatf("Data ACK detected: %b", ack), UVM_HIGH)
          @(negedge vif.scl);

          if (ack == 1'b1) begin
            // After a NACK, the master should issue a STOP or REPEATED START.
            `uvm_info(get_type_name(), $sformatf("Data NACK!"), UVM_HIGH)
          end
        end
      end

      // Write the collected transaction to the analysis port
      `uvm_info(get_type_name(), {"Writing transaction to analysis port:\n", trans.sprint()}, UVM_HIGH)
      item_collected_port.write(trans);
    end
  endtask

endclass