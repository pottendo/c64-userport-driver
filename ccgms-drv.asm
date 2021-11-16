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
    poke16_($326, pottendo_out)
    poke16_($32a, pottendo_in)
    jsr ccgms.clear232
    poke16_(parport.rt1 + 1, ccgms.rtail)       // modify rtail operand for loopread
    poke16_(parport.rt2 + 1, ccgms.ribuf)
    poke16_(parport.rt3 + 1, ccgms.rtail)
    poke16_(parport.rt4 + 1, ccgms.rhead)
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
	jmp ccgms.oldout

pottendo_in:
    //jmp ccgms.rsget
 	lda $99
    cmp #2              // see if default input is modem
    beq jbgetrs
    jmp ccgms.ogetin    // nope, go back to original
jbgetrs:
    jsr rsgetxfer
	bcs !+              // if no character, then return 0 in a
    rts
!:	clc
    lda #0
    rts
rsgetxfer:
	ldx ccgms.rhead
    cpx ccgms.rtail
    beq !++             // skip (empty buffer, return with carry set)
    lda ccgms.ribuf,x
	pha
    inx
    stx ccgms.rhead
    txa
    sec
    sbc ccgms.rtail
    cmp #24
    bcc !+           
    clearbits(CIA2.PORTA, %11111011)   // clear PA2 to low to signal we're ready to receive
    poke8_(VIC.BoC, GREEN)
!:  clc
	pla
!:	rts
