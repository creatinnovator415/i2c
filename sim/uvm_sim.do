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
echo "UVM Sim: load design"
vsim -wlfdeleteonquit work.${top}

# Load wave file configuration
echo "Sim: load wave-file(s)"
catch {do wave.do}

# Set all signals to be logged
echo "Sim: log signals"
log -r /*

# Run simulation
echo "Sim: run ..."
run -all