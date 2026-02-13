// -----------------------------------------------------------
// File Name: i2c_slave.sv
// Module Name: i2c_slave
// Function: Implement basic I2C Slave operations (Address recognition, Send ACK)
// -----------------------------------------------------------

module i2c_slave (
    // System Inputs
	input logic clk,     // System Clock
	input logic reset,   // Reset signal (Active High)

	// I2C Physical I/O (Connected to I2C Bus)
	input logic SCL, // I2C Clock Line
	inout logic SDA, // I2C Data Line

	// Configuration Parameters
	input logic [6:0] MY_ADDR, // 7-bit Address of this Slave device

	// Output Status
	output logic data_received_flag, // Flag: Address recognized
	output logic rw_captured        // Captured R/W bit
	);

	// ------------------- I/O Processing & Internal Signals -------------------
	// Slave only needs to handle SDA open-drain output (for sending ACK)
	// Master drives SCL, Slave only reads
	logic SCL_in;
	logic SDA_out; // Slave output SDA signal (1=Release, 0=Pull Low)
	logic SDA_in;  // Actual read bus SDA signal

	// Slave reads SCL/SDA
	assign SCL_in = SCL;
	assign SDA_in = SDA;

	// Slave's SDA Open-Drain Output: Only pull low when SDA_out=0
	// Otherwise, Slave releases SDA (High-Z 1'bz), letting Master or pull-up resistor control
	assign SDA = SDA_out ? 1'bz : 1'b0;

	// ------------------- State Machine Definition -------------------
	typedef enum {
			IDLE,              // Idle, waiting for START
			CHECK_START,       // Detected START condition
			RCV_ADDR,          // Receive 7-bit address and R/W bit
			SEND_ACK,          // Send ACK (Pull SDA Low)
			DATA_TRANSFER,     // Enter data transfer phase (Not implemented)
			WAIT_STOP          // Wait for STOP condition
			} i2c_slave_state_t;

	i2c_slave_state_t state, next_state;

	reg [3:0] bit_cnt;         // Bit counter (0 to 7)
	logic [3:0] next_bit_cnt;
	logic next_data_received_flag;
	reg [7:0] rcv_byte;        // Buffer for received 8 bits (Address + R/W)
	reg sda_sync;              // Synchronized SDA input (Debounce)
	reg sda_meta_edge;         // Detect SDA edge (For START/STOP detection)
	reg sda_meta_value;        // Delayed SDA value

	reg scl_meta_value, scl_sync;
	logic scl_rising, scl_falling;

	// ------------------- 2. Input Synchronization & Edge Detection -------------------
	// I2C signals may come from external, need synchronization to system clock clk
	always @(posedge clk)
		begin
			sda_meta_value <= SDA_in;
			sda_sync       <= sda_meta_value;

			scl_meta_value <= SCL_in;
			scl_sync       <= scl_meta_value;

			// Detect SDA edge (Used for finding START/STOP)
			if (SCL_in == 1'b1)
				begin
					sda_meta_edge <= sda_sync ^ sda_meta_value;
				end
			else
				begin
					sda_meta_edge <= 1'b0;
				end
		end

	assign scl_rising  = (scl_meta_value == 1'b1 && scl_sync == 1'b0);
	assign scl_falling = (scl_meta_value == 1'b0 && scl_sync == 1'b1);

  // ------------------- 3. State Machine Logic -------------------

  // State Register Update (Sequential Logic)
	always @(posedge clk)
	begin
		if (reset)
			begin
				state <= IDLE;
				bit_cnt <= 0;
				data_received_flag <= 1'b0;
			end
		else
			begin
				state <= next_state;
				bit_cnt <= next_bit_cnt;
				data_received_flag <= next_data_received_flag;
			end
	end

    // Output Logic & Next State Calculation (Combinational Logic)
	always_comb
		begin
			next_state = state;
			next_bit_cnt = bit_cnt;
			next_data_received_flag = data_received_flag;
			SDA_out = 1'b1; // Default release SDA bus (Do not pull low)

			case (state)
				IDLE:
					begin
						next_data_received_flag = 1'b0; // Reset flag when idle

						// Detect START condition: SCL=1 and SDA changes from 1 to 0
						if (SCL_in == 1'b1 && sda_meta_value == 1'b0 && sda_sync == 1'b1)
							begin
								next_state = RCV_ADDR; // Immediately enter receive address
								next_bit_cnt = 0;
							end
					end

				// Receive 7-bit address and R/W bit (Total 8 bits)
				RCV_ADDR:
					begin
						// Only when SCL rising edge/high level, Master changes SDA
						// Slave should prepare when SCL low, and sample after/during SCL high

						// Simplified here to sample at SCL low (or middle count)
						// For simplicity, we sample a small delay after SCL rising edge, and count
						if (bit_cnt < 8)
							begin
								// Need precise timing logic to sample SDA here,
								// Temporarily use a simple count and sample point
								if (scl_rising)
									begin
									// SCL Rising Edge Sample
									rcv_byte[7 - bit_cnt] = SDA_in; // Receive bit
									next_bit_cnt = bit_cnt + 1;
									end
							end
						else if (scl_falling)
							begin
								// 8 bits received, wait for SCL falling edge to enter ACK phase
								next_state = SEND_ACK;
								next_bit_cnt = 0;
							end
					end

				// Send ACK (Pull SDA Low) or NACK (Release SDA)
				SEND_ACK:
					begin
						// Compare if received address matches
						if (rcv_byte[7:1] == MY_ADDR)
							begin
								// Address Match! Prepare to send ACK
								SDA_out = 1'b0; // Pull SDA Low

								// Wait for ACK cycle end (SCL falling edge)
								if (scl_falling)
								begin
								// ACK sent, enter data phase or wait for STOP
								rw_captured = rcv_byte[0]; // Capture R/W bit
								next_data_received_flag = 1'b1;
								next_state = WAIT_STOP; // Simplified: Jump directly to wait STOP
								end
							end
						else
							begin
								// Address Mismatch (Send NACK - Release SDA)
								SDA_out = 1'b1; // Keep Released (NACK)
								if (scl_falling)
								begin
								next_state = WAIT_STOP; // Wait for Master to end communication
								end
							end
					end

				// Wait for STOP condition (Master sets SCL=1, SDA changes from 0 to 1)
				WAIT_STOP:
					begin
						SDA_out = 1'b1; // Ensure Slave releases SDA

						// Detect STOP condition: SCL=1 and SDA changes from 0 to 1
						if (SCL_in == 1'b1 && sda_meta_value == 1'b1 && sda_sync == 1'b0)
							begin
								next_state = IDLE;
							end
					end

				default:
					next_state = IDLE;
			endcase
		end

endmodule
