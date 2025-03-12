


cell:
	cicsim simcell  ${LIB} ${CELL} ../tech/cicsim/cell_spice/template.yaml

cellsv:
	cicsim simcell  ${LIB} ${CELL} ../tech/cicsim/cell_sv/template.yaml

netlist_cell:
	test -d ../../work/xsch || mkdir ../../work/xsch
	cd ../../work/ && make xsch LIB=${LIB} CELL=${CELL}
ifeq ($(VIEW),Lay)
	cd ../../work && make cdl lpe LIB=${LIB} CELL=${CELL}
endif

ver:
	test -d ../../work/xsch && cd ../../work/ && make ver LIB=${LIB} CELL=${CELL}

netlist: netlist_cell
#- I've seen port ordering change between xschem version, so I also
# generate a xdut.spi file that always has the right port ordering.
#- TODO: Should I add the view here? Either xsch or lpe??
	perl ../../tech/script/genxdut ../../work/xsch/${CELL}.spice ${CELL}


netlist_sv:
	perl ../../tech/script/netlist_mdl ../../rtl/${CELL}.ys ${LIB}
	cd ../../rtl; yosys ${CELL}.ys
	perl ../../tech/script/genxdut ../../rtl/${CELL}.spice ${CELL}
