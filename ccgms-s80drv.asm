
#import "64tass_labels.inc"
#import "pottendos_utils.asm"

.namespace eccgms {

.word soft80_ccgms_init     // don't change this order, hardcoded in ccgms!
.word soft80_ccgms_out
.word soft80_toggle4080

s80_init:   .byte $00
mode4080:   .byte $00
_t1:        .byte $00       // tmp for acc
_tx:    .byte $00           // tmp for X
_ty:    .byte $00           // tmp for y

soft80_ccgms_init:
    lda mode4080
    beq !+
    lda s80_init
    cmp #$ff
    beq !+
    jsr ext80cols_init 
!:
#if POTTENDO_PPDRV 
    jsr ccgms_drv.pottendo_setup
#endif
    rts

soft80_ccgms_out:
    cmp #03     // screen
    bne !+
    lda mode4080
    cmp #00
    beq !+
    pla
    sta _t1
    save_regs()
    lda _t1
    jsr ext80cols_bsout
    restore_regs()
    //lda _t1     // restor char
    rts
!:
    pla
    jmp ccgms.oldout

#import "soft80_conio.s"

ext80cols_init:
    poke8_(CHARCOLOR, 1)
    poke8_(VIC_BG_COLOR0, 0)
    poke8_(VIC_CLEARCOL, 0)
    jsr soft80.soft80_init
    soft80_pos_(0, 0)
    rts

soft80_toggle4080:
    poke8_(s80_init, $ff)   // ensure that soft80 init isn't called anymore on modem init XXX separate modem & 40/80 screen better
    lda mode4080
    eor #$01
    sta mode4080 
    beq m40 
    jsr ext80cols_init
    rts
m40:
    jsr soft80.soft80_shutdown
    poke8_(VIC.BoC, BLACK)
    sta VIC.BgC
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
}