#import "pottendos_utils.asm"

.macro init_screen(l1, l2, mode_fun, rest_fun) {
    poke16(screen.cb_mf + 1, mode_fun)  // modify operand
    poke16(screen.cb_rf + 1, rest_fun)  // modify operand
    poke8(screen.line2, l2)
    poke8(screen.line1, l1)
    jsr screen.init_raster
}

.macro close_screen() {
    jsr screen.close
}

.segmentdef screen

screen: {
line1:
    .byte 00
line2:
    .byte 00
init_raster:
    sei
    sta VIC.RASTER                      // acc still has l1 8bit
    clearbits(VIC.RASTER - 1, %01111111)// clear 9'th bit for line >255
    poke8(VIC.IMR, %10000001)
    poke16(STD.IRQ_VEC, raster_isr)
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
    setbits(CIA2.DIRA, %00000011)

    clearbits(CIA2.base, %11111100) // select VIC bank $8000-$BFFF
    setbits(CIA2.base, %00000010)
    lda VIC.MEM                     // move VIC screen to base + $0000
    sta tmp1
    and #%00001111
    ora #%11110000  // screen to base + $3C00
    sta VIC.MEM
    setbits(VIC.CR1, %00100000)     // bit 5 -> HiRes
    //setbits(VIC.CR2, %00010000)     // bit 4 -> MC
    poke8(VIC.BoC, 0)
    rts
rest: 
    poke8(VIC.BoC, 14)
    setbits(CIA2.DIRA, %00000011)
    setbits(CIA2.base, %00000011)
    lda tmp1        
    and #%11110000
    ora VIC.MEM
    sta VIC.MEM
    clearbits(VIC.CR1, %11011111)
    clearbits(VIC.CR2, %11101111)
    rts

close:
!:
    lda VIC.RASTER
    cmp #$ff
    bne !-
    poke8(VIC.IMR, $00)
    sei
    poke16(STD.IRQ_VEC, STD.IRQ)
    cli
    rts

} /* scope screen */