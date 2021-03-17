#import "pottendos_utils.asm"

.macro init_screen(l1, l2, mode_fun, rest_fun) {
    lda #<mode_fun
    ldy #>mode_fun
    sta screen.cb_mf + 1   // modify operand
    sty screen.cb_mf + 2
    lda #<rest_fun
    ldy #>rest_fun
    sta screen.cb_rf + 1   // modify operand
    sty screen.cb_rf + 2
    lda #l2
    sta screen.line2
    lda #l1
    sta screen.line1
    jsr screen.init_raster
}

screen: {
line1:
    .byte 00
line2:
    .byte 00
init_raster:
    sei
    sta VIC.RASTER
    lda VIC.RASTER - 1
    and #%01111111
    sta VIC.RASTER - 1
    lda #%10000001
    sta VIC.IMR
    lda #<raster_isr
    ldy #>raster_isr
    sta STD.IRQ_VEC
    sty STD.IRQ_VEC + 1
    cli
    rts
    
raster_isr:
    lda VIC.IRR
    sta VIC.IRR
    and #%00000001
    bne !+
    jmp STD.IRQ
!:
    lda VIC.RASTER
    cmp line2
    bcs l2
cb_mf:
    jsr $beef       // operand modified during initialization
    lda line2
    sta VIC.RASTER
out:
    restore_regs()
    rti
l2:
cb_rf:
    jsr $beef       // operand modified during initialization
    lda line1
    sta VIC.RASTER
    jmp out

tmp1: .byte $00
/* callbacks to set vic mode */
mode: 
    lda #%00000011
    ora CIA2.DIRA
    sta CIA2.DIRA

    lda #%11111100  // select VIC bank $C000-$FFFF
    and CIA2.base
    sta CIA2.base
    
    lda VIC.MEM     // move VIC screen to base + $0000
    sta tmp1
    and #%00001111
    sta VIC.MEM

    lda #%00100000  // bit 5 -> HiRes
    ora VIC.CR1
    sta VIC.CR1

    lda #%00010000
    ora VIC.CR2
    sta VIC.CR2
    
    set_color(VIC.BoC, 0)
    rts
rest: 
    set_color(VIC.BoC, 14)
    lda #%00000011
    ora CIA2.DIRA
    sta CIA2.DIRA

    lda #%00000011
    ora CIA2.base
    sta CIA2.base

    lda tmp1        
    and #%11110000
    ora VIC.MEM
    sta VIC.MEM

    lda #%11011111
    and VIC.CR1
    sta VIC.CR1

    lda #%11101111
    and VIC.CR2
    sta VIC.CR2
    rts

} /* scope screen */