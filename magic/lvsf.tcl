
set SUB 0
set OPATH lvs/extf
load {PATH}/{CELL}.mag
flatten {CELL}_flat
load {CELL}_flat
extract path ${OPATH}
extract all
ext2spice lvs
ext2spice format ngspice
#ext2spice hierarchy off
#ext2spice subcircuits off
ext2spice -p ${OPATH} -o lvs/{CELL}.spi
quit
