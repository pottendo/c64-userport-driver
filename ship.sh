#!/bin/bash
export PI1541=http://192.168.188.33
echo ${PI1541}
rm 0uCoProc.d64
c1541 -format ucoproc,42 d64 0uCoProc.d64 -attach 0uCoProc.d64 -write ui128-main.prg 128ui -write ui-main.prg ui -write ccgms-drv.prg cc -write vdc-tests.prg

#-write 80col-ccgms-2021.prg cs -write ccgms-drv.prg c2 
#-write ccgms-drv.prg c
#-write ui-main.prg ui 

if [ -d /media/pottendo/PI1541/1541 ] ; then 
    cp 0uCoProc.d64 /media/pottendo/PI1541/1541
fi
/work/src/cbm-retro/wip-pi1541/pottendo-Pi1541/pi1541-util.sh -u ./0uCoProc.d64 
