vlib work
vlog DSP_TOP.v DSP_TB.v
vsim -voptargs=+acc work.DSP_TB
add wave *
run -all
#quit -sim
