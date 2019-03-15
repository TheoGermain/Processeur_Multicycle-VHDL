vlib work

vcom -93 ../src/VIC.vhd

vcom -93 VIC_tb.vhd

vsim -novopt test_VIC(TB)

view signals
add wave *

run 300 ns