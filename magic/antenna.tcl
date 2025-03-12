
set OPATH ant/ext
crashbackups stop
drc off
snap internal
load {PATH}/{CELL}.mag -dereference

select top cell
extract path ${OPATH}
extract all
antennacheck debug
antennacheck -p ${OPATH}
quit
