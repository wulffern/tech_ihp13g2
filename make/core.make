######################################################################
##        Copyright (c) 2022 Carsten Wulff Software, Norway
## ###################################################################
## Created       : wulff at 2022-4-27
## ###################################################################
##  The MIT License (MIT)
##
##  Permission is hereby granted, free of charge, to any person obtaining a copy
##  of this software and associated documentation files (the "Software"), to deal
##  in the Software without restriction, including without limitation the rights
##  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
##  copies of the Software, and to permit persons to whom the Software is
##  furnished to do so, subject to the following conditions:
##
##  The above copyright notice and this permission notice shall be included in all
##  copies or substantial portions of the Software.
##
##  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
##  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
##  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
##  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
##  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
##  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
##  SOFTWARE.
##
######################################################################


PRCELL = ${CELL}

PDKPATH=${PDK_ROOT}/${PDK}

.PHONY: drc lvs lpe gds cdl xsch ant


#----------------------------------------------------------------------------
# Figure out what where running on
#----------------------------------------------------------------------------
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Darwin)
ECHO=echo
endif

ifeq ($(UNAME_S),Linux)

#- Seems to be a difference between centos and ubuntu here. Ubuntu does not like echo -e
ifeq ($(shell lsb_release -si),Ubuntu)
ECHO=echo
else
ECHO=echo -e
endif
endif

#----------------------------------------------------------------------------
# VERIFICATION
#----------------------------------------------------------------------------
LMAG=../design/${LIB}
NCELL=${LMAG}/${PRCELL}
MCELL=${NCELL}.mag

#- Options
OPT=

SUB=BULKN

BUILD=../design/


CICEXCLUDE?=""

#- Cicpy
CICPY=cicpy

#- Ciccreator
CICDIR=../../ciccreator
ifneq "$(wildcard $(CICDIR) )" ""
CIC=${CICDIR}/bin/cic
CICGUI=${CICDIR}/bin/cic-gui
else
CIC=cic
CICGUI=cic-gui
endif

CICVIEWS =   --xschem --magic

RDIR=2>&1

TECH=ihp-sg13g2


define TECH_HELP
*****************************************************************
                 Technology make system
******************************************************************
I know I will forget, so I write everything down in a Makefile

The command 'make' reads a Makefile, and runs the first command.

You can specify the commands by adding them after 'make'
, for example 'make help' prints this text

Most commands in this Makefile use two parameters, LIB, and CELL.
For example:

	make xsch LIB=LELO_TR_IHP13G2 CELL=LELOTR_TOP

generates a netlist from schematic in xsch/LELOTR_TOP.spice

To see what a make command does, add a '-n' option
For example:
	make xsch LIB=LELO_TR_IHP13G2 CELL=LELOTR_TOP -n

Outputs:
	test -d xsch || mkdir xsch
	xschem -q -x -b -s -n ../design/LELO_TR_IHP13G2/LELOTR_TOP.sch

Commands:
   gds    Generate GDSII from layout
   xsch   Generate spice netlist from schematic
   cdl    Generate spice netlist from schematic for LVS
   lvs   Run Layout Versus Schematic
   drc    Run Design Rule Checks
   doc    Use pandoc to convert README.md into README.html
   xview  Start Xschem
endef

export TECH_HELP

help:
	@echo "$${TECH_HELP}"



ip:
	-test -f ../cic/ip.py && python3 ../cic/ip.py
	cd ${BUILD};${CIC}  --I ../cic ../cic/ip.json  ../cic/${TECH}.tech ${LIB} ${CICOPT}
	cd ${BUILD}; ${CICPY}  transpile ${LIB}.cic ../cic/${TECH}.tech ${LIB}  ${CICVIEWS} --smash "(P|N)CHIOA" --exclude ${CICEXCLUDE}
	-test -f ../cic/post.py && python3 ../cic/post.py

view:
	@cd ${BUILD}; ${CICGUI} ${LIB}.cic ../cic/${TECH}.tech

gds:
	test -d gds || mkdir gds
	${ECHO} "load ${NCELL}.mag\ncalma write gds/${PRCELL}.gds \nquit" > gds/${PRCELL}.tcl
	magic -noconsole -dnull gds/${PRCELL}.tcl > gds/${PRCELL}.log  ${RDIR}


xsch:
	@test -d xsch || mkdir xsch
	-xschem -q -x -b -s -n ../design/${LIB}/${CELL}.sch
	cp xsch/${CELL}.spice xsch/${CELL}.spice.bak
	cat xsch/${CELL}.spice.bak | perl ../tech/script/fixsubckt > xsch/${CELL}.spice
	-rm xsch/${CELL}.spice.bak

ver:
	@test -d xsch  && cd xsch &&  ../../tech/script/genver ${CELL}.spice ${CELL}



cdl:
	@test -d cdl || mkdir cdl
	-xschem -q -x -b -s --tcl " set netlist_dir ${PWD}/cdl/; set bus_replacement_char {[]};" -n ../design/${LIB}/${PRCELL}.sch


#--------------------------------------------------------------------------------------
#- LVS commands
#--------------------------------------------------------------------------------------

lvs: cdl
	test -d lvs || mkdir lvs
	cat ../tech/magic/lvs.tcl|perl -pe 's#{PATH}#${LMAG}#ig;s#{CELL}#${PRCELL}#ig;' > lvs/${PRCELL}_spi.tcl
	magic -noconsole -dnull lvs/${PRCELL}_spi.tcl > lvs/${PRCELL}_spi.log ${RDIR}
	netgen -batch lvs "lvs/${PRCELL}.spi ${PRCELL}"  "cdl/${PRCELL}.spice ${PRCELL}" ${PDKPATH}/libs.tech/netgen/${TECH}_setup.tcl lvs/${PRCELL}_lvs.log > lvs/${PRCELL}_netgen_lvs.log
	cat lvs/${PRCELL}_lvs.log | ../tech/script/checklvs ${PRCELL} ${OPT}

flvs: cdl
	@test -d lvs || mkdir lvs
	cat ../tech/magic/lvsf.tcl|perl -pe 's#{PATH}#${LMAG}#ig;s#{CELL}#${PRCELL}#ig;' > lvs/${PRCELL}_spi.tcl
	magic -noconsole -dnull lvs/${PRCELL}_spi.tcl > lvs/${PRCELL}_spi.log ${RDIR}
	netgen -batch lvs "lvs/${PRCELL}.spi ${PRCELL}"  "cdl/${PRCELL}.spice ${PRCELL}" ${PDKPATH}/libs.tech/netgen/${TECH}_setup.tcl lvs/${PRCELL}_lvs.log > lvs/${PRCELL}_netgen_lvs.log
	cat lvs/${PRCELL}_lvs.log | ../tech/script/checklvs ${PRCELL} ${OPT}


#--------------------------------------------------------------------------------------
#- Run DRC
#--------------------------------------------------------------------------------------
drc:
	@test -d drc || mkdir drc
	cat ../tech/magic/drc.tcl|perl -pe 's#{PATH}#${LMAG}#ig;s#{CELL}#${PRCELL}#ig;'> drc/${PRCELL}_drc.tcl
	@magic -noconsole -dnull drc/${PRCELL}_drc.tcl > drc/${PRCELL}_drc.log ${RDIR}
	@tail -n 1 drc/${PRCELL}_drc.log| perl -ne "\$$exit = 0;use Term::ANSIColor;print(sprintf(\"%-40s\t[ \",${PRCELL}));if(m/:\s+0\n/ig){print(color('green').'DRC OK  '.color('reset'));}else{print(color('red').'DRC FAIL'.color('reset'));\$$exit = 1;};print(\" ]\n\");exit \$$exit;" || tail -n 10 drc/${PRCELL}_drc.log

kdrc:
	test -d drc || mkdir drc
	klayout -b -r ${PDK_ROOT}/${TECH}/libs.tech/klayout/tech/drc/sg12g2_minimal.lydrc  -rd input=gds/${PRCELL}.gds -rd topcell=${PRCELL} -rd report=../drc/${PRCELL}_drc.xml -rd thr=8 -rd feol=true -rd beol=true -rd offgrid=true  >& drc/${PRCELL}_kdrc.log

#--------------------------------------------------------------------------------------
#- Antenna
##--------------------------------------------------------------------------------------

ant:
	@test -d ant || mkdir ant
	cat ../tech/magic/antenna.tcl |perl -pe 's#{PATH}#${LMAG}#ig;s#{CELL}#${PRCELL}#ig;'  > ant/${PRCELL}_ant.tcl
	@magic -noconsole -dnull ant/${PRCELL}_ant.tcl > ant/${PRCELL}_ant.log ${RDIR}
	../tech/script/checkant ant/${PRCELL}_ant.log

antf:
	@test -d ant || mkdir ant
	cat ../tech/magic/antenna_flat.tcl |perl -pe 's#{PATH}#${LMAG}#ig;s#{CELL}#${PRCELL}#ig;'  > ant/${PRCELL}_antf.tcl
	@magic -noconsole -dnull ant/${PRCELL}_antf.tcl > ant/${PRCELL}_antf.log ${RDIR}
	../tech/script/checkant ant/${PRCELL}_antf.log

#--------------------------------------------------------------------------------------
#- Run parasitic extraction
#--------------------------------------------------------------------------------------
lpe: xsch
	test -d lpe || mkdir lpe
	-rm lpe/${PRCELL}_lpe.spi
	cat ../tech/magic/lpe.tcl |perl -pe 's#{PATH}#${LMAG}#ig;s#{CELL}#${PRCELL}#ig;'  > lpe/${PRCELL}_lpe.tcl
	magic -noconsole -dnull lpe/${PRCELL}_lpe.tcl ${RDIR} | tee lpe/${PRCELL}_magic_lpe.log
	perl -pi -e "s/_flat//ig;" lpe/${PRCELL}_lpe.spi
	../tech/script/fixlpe lpe/${PRCELL}_lpe.spi xsch/${PRCELL}.spice ${PRCELL}
#- Check LVS on the parasitic netlist to make sure it is a match
	echo "Running LVS on the extracted netlist to confirm it's the same"
	cat lpe/${PRCELL}_lpe.spi |egrep -v "^C" > lpe/${PRCELL}_lpe_noc.spi
	netgen -batch lvs "lpe/${PRCELL}_lpe_noc.spi ${PRCELL}"  "cdl/${PRCELL}.spice ${PRCELL}" ${PDKPATH}/libs.tech/netgen/${TECH}_setup.tcl lpe/${PRCELL}_lvs.log > lpe/${PRCELL}_netgen_lvs.log
	cat lpe/${PRCELL}_lvs.log | ../tech/script/checklvs ${PRCELL} --short

lper: xsch
	test -d lpe || mkdir lpe
	-rm lpe/${PRCELL}_lper.spi
	cat ../tech/magic/lper.tcl |perl -pe 's#{PATH}#${LMAG}#ig;s#{CELL}#${PRCELL}#ig;'  > lpe/${PRCELL}_lper.tcl
	magic -noconsole -dnull lpe/${PRCELL}_lper.tcl ${RDIR} | tee lpe/${PRCELL}_magic_lper.log
	perl -pi -e "s/_flat//ig;" lpe/${PRCELL}_lper.spi
	../tech/script/fixlpe lpe/${PRCELL}_lper.spi xsch/${PRCELL}.spice ${PRCELL}
#- Check LVS on the parasitic netlist to make sure it is a match
	echo "Running LVS on the extracted netlist to confirm it's the same"
	cat lpe/${PRCELL}_lper.spi |egrep -v "^C" |perl -ne '$$skip=0;if(m/^R/ig){unless(m/sky130/ig){$$skip = 1;}};unless($$skip){print $$_};'|perl -pe 's/\.(n|t)\d+\s/ /ig'> lpe/${PRCELL}_lper_norc.spi
	netgen -batch lvs "lpe/${PRCELL}_lper_norc.spi ${PRCELL}"  "cdl/${PRCELL}.spice ${PRCELL}" ${PDKPATH}/libs.tech/netgen/${TECH}_setup.tcl lpe/${PRCELL}_lvsr.log > lpe/${PRCELL}_netgen_lvsr.log
	cat lpe/${PRCELL}_lvsr.log | ../tech/script/checklvs ${PRCELL} --short


lpeh: xsch
	test -d lpe || mkdir lpe
	cat ../tech/magic/lpeh.tcl |perl -pe 's#{PATH}#${LMAG}#ig;s#{CELL}#${PRCELL}#ig;'  > lpe/${PRCELL}_lpe.tcl
	magic -noconsole -dnull lpe/${PRCELL}_lpe.tcl ${RDIR} | tee lpe/${PRCELL}_magic_lpe.log
	perl -pi -e "s/_flat//ig;" lpe/${PRCELL}_lpe.spi
	../tech/script/fixlpe lpe/${PRCELL}_lpe.spi xsch/${PRCELL}.spice ${PRCELL}

lvsall:
	@${foreach b, ${CELLS}, ${MAKE} -s cdl lvs CELL=$b;}

xlvsall:
	@${foreach b, ${CELLS}, ${MAKE} -s xlvs CELL=$b OPT="--short";}

xflvsall:
	@${foreach b, ${CELLS}, ${MAKE} -s xflvs CELL=$b;}

lpeall:
	@${foreach b, ${CELLS}, ${MAKE} -s lpe CELL=$b;}

drcall:
	@${foreach  b, ${CELLS}, ${MAKE} -s drc CELL=$b;}

clean:
	-rm -rf lvs drc lpe cdl gds *.ext *.sim *.nodes

spi:
	test -d xsch || mkdir xsch
	-xschem -q -x -b -s -n ../design/${LIB}/${CELL}.sch
	cat xsch/${CELL}.spice| ../tech/script/fixspi > ../cic/${CELL}.spi

xview:
	xschem -b  ../design/${LIB}/${CELL}.sch &
