
# Compile vhdl file
proc comp {filename} {
  set UVM_PATH $::env(V_UVM_PATH)
  set PROJECT_PATH $::env(V_PROJECT_PATH)
  echo "The project path is: $PROJECT_PATH"
  if {[file exists ${PROJECT_PATH}/${filename}]} {
    set ext [file extension ${PROJECT_PATH}/${filename}]
    puts "## Compiling $filename"
    if {$ext eq ".vhd" || $ext eq ".vhdl"} {
      vcom -93 -quiet ${PROJECT_PATH}/${filename} -work work -lint
    } elseif {$ext eq ".sv" || $ext eq ".v"} {
      vlog +incdir+${UVM_PATH}  +incdir+[file dirname ${PROJECT_PATH}/${filename}] ${PROJECT_PATH}/${filename} -work work
    } else {
      puts "## WARNING: Unknown file extension: ${filename}"
    }
  } else {
    puts "## WARNING: File not found: ${filename}"
  }
}

# Create library "work" if necessary
catch {vlib work}

# Compile all sources in an order that respects dependencies
# 1. DUTs
comp src/design/i2c_Master.sv
comp src/design/i2c_Slave.sv

# 2. UVM Testbench (Interface -> Package -> Sequence -> Test -> Top)
comp src/testbench/i2c_if.sv
comp src/testbench/i2c_pkg.sv
comp src/testbench/i2c_base_test.sv
comp src/testbench/i2c_top.sv