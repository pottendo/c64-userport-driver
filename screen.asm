#import "pottendos_utils.asm"

.macro init_screen(l1, l2, mode_fun, rest_fun) {
    poke16_(screen.cb_mf + 1, mode_fun)  // modify operand
    poke16_(screen.cb_rf + 1, rest_fun)  // modify operand
    poke8_(screen.line2, l2)
    poke8_(screen.line1, l1)
    jsr screen.init_raster
}

.macro close_screen() {
    jsr screen.close
}

// .segment _screen

screen: {
line1:    .byte $00
line2:    .byte $00
scrstate: .byte $00
colsave:  .byte $00
colsave2: .byte $00
col:      .byte $bf
// init / close screen
toggle_screen:

    lda scrstate
    eor #$ff
    sta scrstate
    beq !+
    poke8(colsave, VIC.BgC)
    poke8_(VIC.BgC, BLACK)
    sprite(0, "on", -1)
    sprite(7, "on", -1)
    //init_screen(49, 153, noop, noop)
#if C128
    jsr vdc.set_graphics_mode
#else    
    jsr mode
#endif    
    rts
!:  
    //close_screen()
    sprite(0, "off", -1)
    sprite(7, "off", -1)
#if C128
    jsr vdc.set_text_mode
#else
    jsr rest
#endif
    poke8(VIC.BgC, colsave)
    rts

toggle_mc:
    lda scrstate
    beq !+
    lda VIC.CR2
    eor #%00010000     // bit 4 -> MC/HR
    sta VIC.CR2
    and #%00010000     // bit 4 -> MC/HR
    beq hr 
    memset_(gl.vic_videoram, $b2, $3f8)
    lda #1
    jsr gfx.toggle_mc
    rts
hr:
    memset_(gl.vic_videoram, $10, $3f8)
    lda #0
    jsr gfx.toggle_mc
!:  rts
    
init_raster:
    sei
    sta VIC.RASTER                      // acc still has l1 8bit
    clearbits(VIC.RASTER - 1, %01111111)// clear 9'th bit for line >255
    poke8_(VIC.IMR, %10000001)
    poke16_(STD.IRQ_VEC, raster_isr)
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
    //restore_regs()
    //rti
    jmp STD.IRQ
l2:
cb_rf:
    jsr $beef       // operand modified during initialization
    lda line1
    sta VIC.RASTER
    jmp out

tmp1: .byte $00
/* callbacks to set vic mode */
mode:
    clearbits(CIA2.base, %11111100) // select VIC bank2 $8000-$BFFF
    setbits(CIA2.base, %00000001)
    lda VIC.MEM                     // move VIC screen to base + $2000
    sta tmp1
    and #%00000111 // clear bits 4-7 -> VideoRAM to base + $0000-$03ff
    ora #%00001000 // screen to base + $2000 (Hires, bit3)
    sta VIC.MEM
    setbits(VIC.CR1, %00100000)     // bit 5 -> HiRes
    setbits(VIC.CR2, %00010000)     // bit 4 -> MC
    
    poke8(colsave2, VIC.BoC)
    poke8_(VIC.BoC, 0)
    sprite(0, "color", WHITE)
    sprite(7, "color", WHITE)
    sprite(0, "expx", "on")
    sprite(0, "expy", "on")
    sprite(7, "expx", "on")
    sprite(7, "expy", "on")
    rts
rest: 
    poke8(VIC.BoC, colsave2)
    setbits(CIA2.base, %00000011)
    //lda tmp1        
    lda VIC.MEM
    and #%11110111  // restore bits 4-7 -> VideoRAM to base + $0400-$07ff
    ora #%00010000
    sta VIC.MEM
    clearbits(VIC.CR1, %11011111)
    clearbits(VIC.CR2, %11101111)
    rts

close:
!:
    lda VIC.RASTER
    cmp #$ff
    bne !-
    poke8_(VIC.IMR, $00)
    sei
    poke16_(STD.IRQ_VEC, STD.IRQ)
    cli
    rts

} /* scope screen */