

parse:
	./genyaml parse $$PDK_ROOT/sky130A/libs.tech/ngspice/sky130.lib.spice

process:
	./genyaml process spice.yaml --prefix K --exclude "rf_(n|p)fet|fet_g5v0|fet_03v3|fet_20v0|fet_05v0|esd_nfet|_(l|h)vt"
