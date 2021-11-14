.pc=$801
.var ccgms_bin = LoadBinary("ccgms-2021.prg", "C64FILE")
.fill ccgms_bin.getSize(), ccgms_bin.get(i)

#import "64tass_labels.inc"

#import "globals.asm"
#import "pottendos_utils.asm"
#import "userport-drv.asm"

.pc=$6500       // to be consistent with 'pottendosetup' line ~7267 in ccgms-2021.asm

.word pottendo_setup
.word pottendo_out
.word pottendo_in

pottendo_setup:
    inc VIC.BoC
    poke16_($326, pottendo_out)
    poke16_($32a, pottendo_in)
    jsr ccgms.clear232
    poke16_(parport.rt1 + 1, ccgms.rtail)       // modify rtail operand for loopread
    poke16_(parport.rt2 + 1, ccgms.rtail)
    uport_lread(ccgms.ribuf)                    // activate background read
    rts

pottendo_out:
    pha             
    lda $9a
    cmp #02
    bne !+
    pla
    jsr parport.write_byte
    jsr parport.start_isr       // back to reading
    rts
!:
    pla
	jmp  ccgms.oldout

pottendo_in:
    jmp ccgms.rsget
