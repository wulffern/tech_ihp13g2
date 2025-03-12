load {PATH}/{CELL}.mag
logcommands drc/{CELL}_drc.log
set b [view bbox]
box values [lindex \$$b 0] [lindex \$$b 1] [lindex \$$b 2] [lindex \$$b 3]
expand
expand
drc style drc(full)
drc catchup
drc why
drc count total
quit
