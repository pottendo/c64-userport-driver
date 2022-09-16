#define EXT80COLS
#define HANDLE_MEM_BANK // must be set to enable proper handling in userport-drv along soft80
#define POTTENDO_PPDRV 
#define REU
.pc=$801
.var ccgms_bin = LoadBinary("ccgms-2021.prg", "C64FILE")
.fill ccgms_bin.getSize(), ccgms_bin.get(i)

#import "64tass_labels.inc"

#import "globals.asm"
#import "pottendos_utils.asm"
#import "userport-drv.asm"


.label ccgms_ext_entry = $6700  // pointers to extension entries: 
                                // +0 -> soft80_init
                                // +2 -> soft80_out
                                // +4 -> soft80_toggle4080
                                // must consistent with 'pottendosetup' line ~7267 in ccgms-2021.asm
.pc=ccgms_ext_entry       
#import "ccgms-s80drv.asm"
#if REU
#import "reu.asm"
#endif
.namespace ccgms_drv {
pottendo_init: .byte $00    // flag to avoid double init
_t1:    .byte $00           // tmp for acc

pottendo_setup:
#if EXT80COLS
    jsr setup_sprites
    soft80_doio(setup_sprites2)    
#endif
    jsr parport.init
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
    cmp #02 // modem
    bne !+
    pla
    jsr parport.write_byte
    jsr parport.start_isr       // back to reading
    rts
!:
#if EXT80COLS
    jmp eccgms.soft80_ccgms_out
#else
    pla
    jmp ccgms.oldout
#endif

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
    beq !empty+             // skip (empty buffer, return with carry set)
    lda ccgms.ribuf,x
	pha
    inx
    stx ccgms.rhead
    lda ccgms.rtail
    sec
    sbc ccgms.rhead
/*  orig code, wrong IMHO
    txa
    sec
    sbc ccgms.rtail
*/
    cmp #24
    bcc !+  
    clc 
    pla
!empty:
    rts
!:
#if HANDLE_MEM_BANK
        sei
        lda     $01
        pha
        lda     #$37
        sta     $01          
#endif
    //poke8_(VIC.BoC, BLACK)
    clearbits(CIA2.PORTA, %11111011)   // clear PA2 to low to signal we're ready to receive
#if HANDLE_MEM_BANK
        pla
        sta $01
        cli
#endif
    clc
	pla
    rts 

setup_sprites:
    sprite(1, "color_", LIGHT_GREEN)
    sprite(2, "color_", LIGHT_RED)
    sprite_pos_(1, 324, 50)
    sprite_pos_(2, 324, 50)
    rts
setup_sprites2:
    memcpy(soft80_bitmap + $1f40, parport.sprstart, parport.sprend - parport.sprstart) // move sprite data to matching vic address
    sprite_sel_(soft80_vram, $e000 + $1f40, 1, 0)
    sprite_sel_(soft80_vram, $e000 + $1f40, 2, 1)    
    rts
}