vlib work


vcom -93 ../src/MAE.vhd
vcom -93 ../src/VIC.vhd
vcom -93 ../src/RAM64x32.vhd
vcom -93 ../src/REG32.vhd
vcom -93 ../src/RegLd.vhd
vcom -93 ../src/register_bank.vhd
vcom -93 ../src/MUX21.vhd
vcom -93 ../src/MUX41.vhd
vcom -93 ../src/imm_extender.vhd
vcom -93 ../src/ALU.vhd
vcom -93 ../src/DataPath.vhd

vcom -93 ../src/arm.vhd

vcom -93 test_arm.vhd

vsim -novopt test_arm(arc_test_arm)

view signals
add wave *

run 10 us