#define HANDLE_MEM_BANK // must be set to enable proper handling in userport-drv along soft80

.pc=$801
.var ccgms_bin = LoadBinary("ccgms-2021.prg", "C64FILE")
.fill ccgms_bin.getSize(), ccgms_bin.get(i)

#import "64tass_labels.inc"

#import "globals.asm"
#import "pottendos_utils.asm"

.label ccgms_ext_entry = $6700  // pointers to extension entries: 
                                // +0 -> soft80_init
                                // +2 -> soft80_out
                                // +4 -> soft80_toggle4080
                                // must consistent with 'pottendosetup' line ~7267 in ccgms-2021.asm
.pc=ccgms_ext_entry       
#import "ccgms-s80drv.asm"

// empty to build & link everything together
