#----------------------------------*-tcl-*-

# Define reload command to recompile everything
# and rerun the simulation
proc reload {} {
  do Comp.do
  do uvm_sim.do
}

# Define top entity of the design
set top i2c_top

# Load design into simulation
echo "UVM Sim: load design with access permissions for waveform logging"
vsim -voptargs="+acc" work.${top}

# Load wave file configuration if it exists (for GUI mode)
echo "Sim: load wave-file(s)"
catch {do wave.do}

# Open Wave window and add all signals automatically
view wave
echo "Sim: add signals to wave window"
add wave -r /${top}/*

# Set all signals under the top module to be logged to vsim.wlf
echo "Sim: log signals"
log -r /${top}/*

# Run simulation
echo "Sim: run ..."
run -all

# Quit simulation
# quit -f