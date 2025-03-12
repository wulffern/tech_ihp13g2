#set VDD AVDD
#set GND AVSS
set SUB 0
set OPATH lvs/ext
load {PATH}/{CELL}.mag

extract path ${OPATH}
extract all
ext2spice lvs
ext2spice -p ${OPATH} -o lvs/{CELL}.spi
quit
