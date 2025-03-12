
set values [ cellname list all ]
set mrev [lindex [lreverse [split [exec magic --version] "."]] 0 ]
foreach x $values {
    if {${mrev} > 514} {
        flush $x -noprompt
    } else {
        flush $x
    }
}
