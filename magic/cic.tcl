
#- Create an array of CIC cells
proc cicarray {args} {
    suspendall
    set x [lindex $args 0]
    set y [lindex $args 1]


    #- Load selected cell and get bounding box
    pushstack
    set fbbox [property FIXED_BBOX]
    set m [lindex [tech lambda] 1]
    set px [expr [lindex $fbbox 2]/$m]
    set py [expr [lindex $fbbox 3]/$m]
    popstack

    set b_height [box height]
    set b_width [box width]

    set b_origin [expr "($b_width - $px)/2"]

    echo "PX:" $px  "PY:" $py

    #- Change box size
    box size $px $py

    #- Make an array
    array $x $y

    resumeall

}
