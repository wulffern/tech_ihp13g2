

set OPATH ant/extf

crashbackups stop
drc off
snap internal
load {PATH}/{CELL}.mag -dereference

flatten {CELL}_flat
load {CELL}_flat

select top cell
extract path ${OPATH}
extract all
antennacheck debug
antennacheck -p ${OPATH}
quit
