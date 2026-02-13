// -----------------------------------------------------------
// File Name: i2c_master.sv
// Module Name: i2c_master
// Function: Implement basic I2C Master operations (START, STOP, Address)
// -----------------------------------------------------------

module i2c_master (
    // System Inputs
    input logic clk,     // System Clock (e.g., 50MHz)
    input logic reset,   // Reset Signal (Active High)

    // Control Inputs
    input logic start_cmd, // Command to start an I2C transfer (Pulse signal)
    input logic [6:0] slave_addr, // 7-bit Slave Address
    input logic rw_bit,          // Read/Write Bit (0=Write, 1=Read)

    // I2C Physical I/O (Need to connect to Pad)
    inout logic SCL, // I2C Clock Line
    inout logic SDA  // I2C Data Line
  );

  // ------------------- I2C Frequency Parameters -------------------
  // Assume system clock clk = 50 MHz
  // Set I2C speed to approx 100 kHz
  localparam SYS_CLK_FREQ  = 50_000_000; // 50 MHz
  localparam I2C_CLK_FREQ  = 100_000;    // 100 kHz
  localparam I2C_CLK_COUNT = SYS_CLK_FREQ / I2C_CLK_FREQ; // 500

  // ------------------- Internal Signals & State Machine Definition -------------------
  // Internal Control Signals
  logic SCL_out; // Master output SCL signal (1=Release/High-Z, 0=Pull Low)
  logic SDA_out; // Master output SDA signal (1=Release/High-Z, 0=Pull Low)
  logic SDA_in;  // Actual read bus SDA signal

  // I2C Master States
  typedef enum {
            IDLE,          // Idle state, waiting for start_cmd
            START_PULSE,   // Generate START condition
            SEND_ADDR,     // Transmit 7-bit address + R/W bit
            WAIT_ACK,      // Wait for Slave ACK/NACK
            STOP_PULSE     // Generate STOP condition
          } i2c_state_t;

  i2c_state_t state, next_state;

  reg [3:0] bit_cnt; // Bit counter (0 to 7)
  logic [3:0] next_bit_cnt;

  // Clock Divider Counter (Used to generate I2C frequency)
  reg [8:0] clk_div_cnt;
  reg i2c_clk_half; // Generate half I2C clock cycle signal (Used to control SCL edge)


  // ------------------- 1. Open-Drain I/O Processing -------------------
  // Simulate Open-Drain Output: Output 0 or Release (High-Z 1'bz)
  // After release, external pull-up resistor pulls it high
  assign SCL = SCL_out ? 1'bz : 1'b0;
  assign SDA = SDA_out ? 1'bz : 1'b0;

  // Read actual signal on the bus
  assign SDA_in = SDA;


  // ------------------- 2. I2C Clock Generator -------------------
  // Internal count to generate I2C frequency (SCL)
  always @(posedge clk)
  begin
    if (reset)
      begin
        clk_div_cnt <= 0;
        i2c_clk_half <= 0;
      end
    else
      begin
        if (clk_div_cnt == (I2C_CLK_COUNT/2 - 1))
          begin
            clk_div_cnt <= 0;
            i2c_clk_half <= ~i2c_clk_half; // Toggle, generate SCL cycle
          end
        else
          begin
            clk_div_cnt <= clk_div_cnt + 1;
          end
      end
  end

  // SCL Output Logic
  // SCL stays high (released) during IDLE/STOP states
  assign SCL_out = (state == IDLE || state == STOP_PULSE) ? 1'b1 : i2c_clk_half;


  // ------------------- 3. State Machine & Output Logic -------------------

  // State Register Update (Sequential Logic)
  always @(posedge clk)
  begin
    if (reset)
    begin
      state <= IDLE;
      bit_cnt <= 0;
    end
    else
    begin
      state <= next_state;
      bit_cnt <= next_bit_cnt;
    end
  end

  // Output Logic & Next State Calculation (Combinational Logic)
  always_comb
  begin
    next_state = state;
    next_bit_cnt = bit_cnt;
    SDA_out = 1'b1; // Default release SDA bus (Keep High)

    case (state)
      IDLE:
        begin
          if (start_cmd)
            begin
              next_state = START_PULSE;
            end
        end

      // Generate START condition: When SCL=1, SDA changes from 1 to 0
      START_PULSE:
        begin
          if (i2c_clk_half)
            begin
              // SCL High: Pull SDA Low (START)
              SDA_out = 1'b0;
            end
          else
            begin
              // SCL Low: Enter next state
              next_state = SEND_ADDR;
              next_bit_cnt = 0; // Reset bit counter
            end
        end

      // Transmit 8 bits (Address + R/W)
      SEND_ADDR:
        begin
          if (i2c_clk_half)
            begin
              // SCL High: Set SDA Data
              if (bit_cnt < 7)
                begin
                  // Transmit 7-bit address (Starting from MSB)
                  SDA_out = slave_addr[6 - bit_cnt];
                end
              else
                begin
                  // Transmit R/W bit
                  SDA_out = rw_bit;
                end
            end
          else
            begin
              // SCL Low: Prepare next bit
              if (bit_cnt == 7)
              begin
                next_state = WAIT_ACK;
                next_bit_cnt = 0;
              end
              else
              begin
                next_bit_cnt = bit_cnt + 1;
              end
            end
        end

      // Wait for Slave ACK/NACK
      WAIT_ACK:
        begin
          if (!i2c_clk_half)
            begin
              // SCL Low, Master prepares next action
              // Simplified here: Do not check ACK, go directly to STOP
              next_state = STOP_PULSE;
            end
          // In reality: When SCL High, Master reads SDA_in to determine ACK/NACK
        end

      // Generate STOP condition: When SCL=1, SDA changes from 0 to 1
      STOP_PULSE:
        begin
          if (i2c_clk_half)
            begin
              SDA_out = 1'b1; // SCL High, Release SDA (STOP Complete)
              next_state = IDLE;
            end
          else
            begin
              SDA_out = 1'b0; // SCL Low, Pull SDA Low
            end
        end

      default:
        next_state = IDLE;
    endcase
  end

endmodule
