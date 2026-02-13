class i2c_driver extends uvm_driver #(i2c_seq_item); // Defines the driver class, parameterized with the transaction type.
    `uvm_component_utils(i2c_driver) // Registers this class with the UVM factory.

    virtual i2c_if vif; // Declares a handle for the virtual interface to drive the DUT.
    bit enable_nack_check = 1; // Control flag for NACK error reporting (Default: Enabled)

    // Constructor for the i2c_driver class.
    function new(string name = "i2c_driver", uvm_component parent = null);
        super.new(name, parent); // Calls the parent class (uvm_driver) constructor.
    endfunction

    // The build_phase is used to get configuration information, like the virtual interface.
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase); // Calls the parent class build_phase.
        // Get the virtual interface handle from the configuration database.
        if (!uvm_config_db#(virtual i2c_if)::get(this, "", "vif", vif))
            `uvm_fatal("NOVIF", "Virtual interface must be set for driver") // Report fatal error if not found.
        void'(uvm_config_db#(bit)::get(this, "", "enable_nack_check", enable_nack_check));
    endfunction

    //----------------------------------------------------------------
    // I2C Protocol Driving Tasks
    //----------------------------------------------------------------

    // A simple delay task based on the interface clock
    task delay(int cycles = 1);
        repeat(cycles) @(posedge vif.clk);
    endtask

    // Generate the I2C START condition (SDA falling edge while SCL is high)
    task i2c_start;
        vif.sda_out <= 1'b1;
        vif.scl <= 1'b1;
        delay(4);
        vif.sda_out <= 1'b0;
        delay(4);
        vif.scl <= 1'b0;
        delay(4);
    endtask

    // Generate the I2C STOP condition (SDA rising edge while SCL is high)
    task i2c_stop;
        vif.sda_out <= 1'b0;
        vif.scl <= 1'b1;
        delay(4);
        vif.sda_out <= 1'b1;
        delay(4);
    endtask

    // Write a full byte and read the ACK/NACK bit from the slave
    task i2c_write_byte(input byte data_byte, output logic nack);
        // Send 8 data bits, MSB first
        for (int i = 7; i >= 0; i--)
            begin
            vif.sda_out <= data_byte[i];
            delay(2);
            vif.scl <= 1'b1;
            delay(4);
            vif.scl <= 1'b0;
            delay(2);
            end
        // Release SDA and read the ACK/NACK bit
        vif.sda_out <= 1'bz;
        delay(2);
        vif.scl <= 1'b1;
        delay(2);
        nack = vif.sda; // Sample SDA for ACK (0) or NACK (1)
        delay(2);
        vif.scl <= 1'b0;
        delay(2);
    endtask

    // Read a full byte and send an ACK or NACK bit to the slave
    task i2c_read_byte(output byte data_byte, input logic send_nack);
        byte temp_data;
        // Release SDA to allow slave to drive, then read 8 bits
        vif.sda_out <= 1'bz;
        for (int i = 7; i >= 0; i--)
            begin
            delay(2);
            vif.scl <= 1'b1;
            delay(2);
            temp_data[i] = vif.sda; // Sample data bit
            delay(2);
            vif.scl <= 1'b0;
            end
        data_byte = temp_data;

        // Drive ACK (0) or NACK (1) bit
        vif.sda_out <= send_nack;
        delay(2);
        vif.scl <= 1'b1;
        delay(4);
        vif.scl <= 1'b0;
        delay(2);
        vif.sda_out <= 1'bz; // Release SDA
    endtask

    // The run_phase contains the main driver logic.
    virtual task run_phase(uvm_phase phase);
        i2c_seq_item item; // Declares a handle for the transaction item.
        logic nack;
        byte addr_byte;

        // Initialize bus state to idle
        vif.scl <= 1'b1;
        vif.sda_out <= 1'b1;
        delay(5);

        forever
            begin // The driver runs continuously, processing transactions.
            seq_item_port.get_next_item(item); // Blocks until a new transaction is available from the sequencer.

            // 1. Send Start condition
            i2c_start();

            // 2. Send slave address and R/W bit
            addr_byte = {item.addr, item.rw};
            i2c_write_byte(addr_byte, nack);

            // 3. Check for ACK from the slave.
            if (nack)
                begin
                    if (enable_nack_check)
                        `uvm_error("I2C_DRIVER", $sformatf("Address 0x%0h was NACKed by slave.", item.addr))
                    else
                        `uvm_info("I2C_DRIVER", $sformatf("Address 0x%0h NACKed (Scan)", item.addr), UVM_HIGH)
                            i2c_stop(); // If address is NACKed, end the transaction
                end
            else
                begin
                    `uvm_info("I2C_DRIVER", $sformatf("Address 0x%0h ACKed by slave", item.addr), UVM_MEDIUM)
                    // Address was ACKed, proceed with data phase
                    if (item.rw == 0)
                        begin // It's a WRITE transaction
                            // 4. Send each data byte from the item
                            foreach(item.data[i])
                                begin
                                    i2c_write_byte(item.data[i], nack);
                                    // 5. Check for ACK after each byte
                                    if (nack)
                                        begin
                                            `uvm_warning("I2C_DRIVER", $sformatf("Data byte %0d (0x%0h) was NACKed", i, item.data[i]))
                                            break; // Stop sending further data if a byte is NACKed
                                        end
                                end
                            i2c_stop();
                        end
                    else
                        begin // It's a READ transaction
                            // 4. Receive data bytes. The sequence should specify the number of bytes to read
                            // by setting the size of the 'data' array before starting the sequence.
                            if (item.data.size() > 0)
                                begin
                                    byte read_data_byte;
                                    for (int i = 0; i < item.data.size(); i++)
                                        begin
                                        // 5. Send ACK for each byte except the last one. Send NACK for the last byte.
                                        logic send_nack = (i == item.data.size() - 1);
                                        i2c_read_byte(read_data_byte, send_nack);
                                        item.data[i] = read_data_byte; // Store read data back into the sequence item
                                        end
                                    i2c_stop();
                                end
                            else
                                begin
                                    `uvm_warning("I2C_DRIVER", "Read transaction requested, but item.data.size() is 0. No data will be read.")
                                    // 6. Send Stop condition
                                    i2c_stop();
                                end
                        end
                end

            seq_item_port.item_done(); // Unblocks the sequence, indicating the transaction is finished.
            end
    endtask

endclass // End of the class definition.
