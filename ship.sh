#!/bin/bash
rm 0uCoProc.d64
petcat -w2 -o ui.prg bin/testdriver.bas
c1541 -format ucoproc,42 d64 0uCoProc.d64 -attach 0uCoProc.d64 -write ui-main.prg ui -write ccgms-drv.prg cc 

#-write 80col-ccgms-2021.prg cs -write ccgms-drv.prg c2 

#-write ccgms-drv.prg c

if [ -d /media/pottendo/PI1541/1541 ] ; then 
    cp 0uCoProc.d64 /media/pottendo/PI1541/1541
fi
