#set VDD AVDD
#set GND AVSS
set SUB 0
load {PATH}/{CELL}.mag

set OPATH lpe/exth

select top cell

extract path ${OPATH}

extract all


ext2spice lvs
ext2spice format ngspice
ext2spice resistor off
ext2spice cthresh 0.1
ext2spice -p ${OPATH} -o lpe/{CELL}_lpe.spi
quit
