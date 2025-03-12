#set VDD AVDD
#set GND AVSS
set SUB 0
set OPATH lpe/extr

load {PATH}/{CELL}.mag

flatten {CELL}_flat
load {CELL}_flat

cellname delete {CELL}

select top cell
extract path ${OPATH}
extract do resistance
extract do capacitance
extract do coupling
extract all
ext2sim labels on
ext2sim -p ${OPATH}
extresist tolerance 10
extresist all
ext2spice lvs
ext2spice cthresh 0.01
ext2spice extresist on
ext2spice -p ${OPATH} -o lpe/{CELL}_lper.spi
quit
