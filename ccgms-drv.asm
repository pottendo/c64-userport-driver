#define EXT80COLS
#define HANDLE_MEM_BANK // must be set to enable proper handling in userport-drv along soft80

/*
#if EXT80COLS
.file [name="ccgms-ext.prg", segments="Code"]
#else
.file [name="ccgms.prg", segments="Code"]
#endif
.segment Code[]
*/
.pc=$801
.var ccgms_bin = LoadBinary("ccgms-2021.prg", "C64FILE")
.fill ccgms_bin.getSize(), ccgms_bin.get(i)

#import "64tass_labels.inc"

#import "globals.asm"
#import "pottendos_utils.asm"
#import "userport-drv.asm"

.pc=$6700       // to be consistent with 'pottendosetup' line ~7267 in ccgms-2021.asm

.namespace ccgms_drv {
.word pottendo_setup
pottendo_init: .byte $00    // flag to avoid double init
_t1:    .byte $00           // tmp for acc
_tx:    .byte $00           // tmp for X
_ty:    .byte $00           // tmp for y


pottendo_setup:
#if EXT80COLS
    jsr ext80cols_init 
#endif
    lda pottendo_init
    //bne !+
    jsr parport.init
    poke16_($326, pottendo_out)
    poke16_($32a, pottendo_in)
    jsr ccgms.clear232
    poke16_(parport.rt1 + 1, ccgms.rtail)       // modify rtail operand for loopread
    poke16_(parport.rt2 + 1, ccgms.ribuf)
    poke16_(parport.rt3 + 1, ccgms.rtail)
    poke16_(parport.rt4 + 1, ccgms.rhead)
    uport_lread(ccgms.ribuf)                    // activate background read
    inc pottendo_init
!:
    rts

pottendo_out:
    sta _t1             
    lda $9a
    cmp #02 // modem
    bne !+
    lda _t1
    jsr parport.write_byte
    jsr parport.start_isr       // back to reading
    rts
#if EXT80COLS
!:
    cmp #03     // screen
    bne !+
    save_regs()
    lda _t1
    jsr ext80cols_bsout
    restore_regs()
    lda _t1     // restor char
    rts
#endif
!:
    lda _t1
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
    
#if EXT80COLS
#import "soft80_conio.s"

ext80cols_init:
    poke8_(CHARCOLOR, 1)
    poke8_(VIC_BG_COLOR0, 0)
    poke8_(VIC_CLEARCOL, 0)
    jsr soft80.soft80_init
    soft80_pos_(0, 0)
    rts

.macro map_colors()
{
    .var collist = List().add(144, 5, 28, 159, 156, 30, 31, 158, 129, 149, 150, 151, 152, 153, 154, 155)
    .for (var i = 0; i < 16; i++) {
        cmp #(collist.get(i))
        bne !+
        lda soft80_internal_bgcolor
        and #$f0
        ora #i
        sta soft80_internal_cellcolor
        rts
    !:
    }
}
.macro map_ignores()
{
    .var ignlist = List().add(2, 3, 8, 14, 15, 16, $82, $8e, $8f)
    .var l = ignlist.size()
    .for (var i = 0; i < l; i++)
    {
        cmp #(ignlist.get(i))
        bne !+
        rts
    !:
    }
}

ext80cols_bsout:
    cmp #7     // bell
    bne !+
    jsr ccgms.bell
    rts
!:
    cmp #17     // crs down
    bne !+
    poke8(_ty, CURS_Y)
    // acc has CURS_Y
    cmp #(screenrows - 1)
    bne move_crs 
    jsr scroll24
    jsr clear_row24
    rts
move_crs:
    poke8(_tx, CURS_X)
    inc _ty
    soft80_pos(_tx, _ty)
    rts
!:
    cmp #18     // revers on
    bne !+
    lda #1
    sta RVS
    rts
!:
    cmp #19     // home
    bne !+
    soft80_pos_(0, 0)
    rts
!:
    cmp #20     // del
    bne !+
    soft80_delc()
    rts
!:
    cmp #157     // crs left
    bne !+
    poke8(_tx, CURS_X)
    poke8(_ty, CURS_Y)
    dec _tx
    soft80_pos(_tx, _ty)
    rts
!:
    cmp #29     // crs right
    bne !+
    poke8(_tx, CURS_X)
    poke8(_ty, CURS_Y)
    inc _tx
    soft80_pos(_tx, _ty)
    rts
!:
    cmp #145     // crs up
    bne !+
    poke8(_tx, CURS_X)
    poke8(_ty, CURS_Y)
    dec _ty
    soft80_pos(_tx, _ty)
    rts
!:
    cmp #146     // revers on
    bne !+
    lda #0
    sta RVS
    rts
!:
    cmp #147     // clear screen
    bne !+
    jsr soft80_kclrscr
    soft80_pos_(0, 0)
    rts
!:
    map_ignores()
!:  
    map_colors()
!:
    cmp #$0d    // lf
    bne !+
    jsr soft80_cputc
    lda #0
    sta RVS
    lda #$0a    // cr
!:
    pha
    lda CURS_Y
    cmp #(screenrows)
    bcc out
    jsr scroll24
    jsr clear_row24
    soft80_pos_(0, 24)
out:              // just output
    pla
    jsr soft80_cputc
    rts

// expand macros only once
scroll24:
    soft80_scroll(24)
    rts
clear_row24:
    clear_row(24)
    rts
#endif
}