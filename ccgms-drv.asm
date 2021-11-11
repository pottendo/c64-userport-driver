.pc=$801
.var ccgms_bin = LoadBinary("ccgms-2021.prg", "C64FILE")
.fill ccgms_bin.getSize(), ccgms_bin.get(i)

#import "64tass_labels.inc"

#import "globals.asm"
#import "pottendos_utils.asm"
#import "cmds.asm"

.pc=$9000

.word pottendo_setup
.word pottendo_out
.word pottendo_in

pottendo_setup:
    inc VIC.BoC
    poke16_($326, pottendo_out)
    poke16_($32a, pottendo_in)
    jsr ccgms.clear232

    rts

pottendo_out:
    pha             
    lda $9a
    cmp #02
    bne !+
    pla

    rts
!:
    pla
	jmp  ccgms.oldout

pottendo_in:
    inc VIC.BoC
    jmp ccgms.rsget
