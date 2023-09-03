
BasicUpstart2(main_entry)
#import "globals.asm"
#import "pottendos_utils.asm"

#define CLEAR

.label coproc   = $c000;
.const CLINE    = 1
.const CCIRCLE  = 2
.const CEXIT    = $ff 
.const CNOP     = 0
tmp1: .byte $00

.macro wait4cr(sync)
{
.if (sync == 1) 
{
!:
    lda VIC.RASTER
    cmp #200
    bne !-
}
!w:
    inc $d000
    dec $d000
    inc $d000
    dec $d000
    inc $d000
    dec $d000
    inc $d000
    dec $d000
    lda coproc
    beq !w-

#if BLA
!w:
    inc $d000
    dec $d000
    inc $d000
    dec $d000
    inc $d000
    dec $d000
    inc $d000
    dec $d000
    lda coproc
    beq !w-

!:
    txa
    pha
!w:
    ldx #3
!:  inc VIC.BoC
    dec VIC.BoC
    dex
    bne !-
    lda coproc
    beq !w-
    pla
    tax
#endif
}

do_lines:
    // lines
    poke8_(coproc+10, 20)   // iterator counter
    poke16_(coproc+3, 10)
    poke8_(coproc+5, 0)
    poke16_(coproc+6, 310)
    poke8_(coproc+8, 199)
!again:
    poke8_(coproc, 0)
    poke8_(coproc+2, 1)
    poke8_(coproc+1, CLINE)
    wait4cr(0)
    poke8_(coproc, 0)
    poke8_(coproc+2, 0)
    poke8_(coproc+1, CLINE)
    wait4cr(1)
    inc coproc+3
    inc coproc+3
    inc coproc+3
    dec coproc+6
    dec coproc+6
    dec coproc+6
    dec coproc+10
    bne !again-
    rts

do_circles:
    // lines
    poke8_(coproc+10, 20)   // iterator counter
    poke16_(coproc+3, 10)
    poke8_(coproc+5, 100)
    poke16_(coproc+6, 99)
!again:
    poke8_(coproc, 0)
    poke8_(coproc+2, 1)
    poke8_(coproc+1, CCIRCLE)
    wait4cr(0)
#if CLEAR
    poke8_(coproc, 0)
    poke8_(coproc+2, 0)
    poke8_(coproc+1, CCIRCLE)
    wait4cr(1)
#endif

    inc coproc+3
    inc coproc+3
    inc coproc+3
    dec coproc+6
    dec coproc+6
    dec coproc+10
    bne !again-
    rts

do_fcircles:
    // circles filled
    poke8_(coproc+10, 40)   // iterator counter
    poke16_(coproc+3, 310)
    poke8_(coproc+5, 100)
    poke16_(coproc+6, 99)
!again:
    poke8_(coproc, 0)
    poke8_(coproc+2, $81)    // #%1xxxxxxx signals filling
    poke8_(coproc+1, CCIRCLE)
    wait4cr(0)

#if CLEAR
    poke8_(coproc, 0)
    poke8_(coproc+2, $80)
    poke8_(coproc+1, CCIRCLE)
    wait4cr(1)
#endif 

    sbc16(coproc+3, 3, coproc+3);
    dec coproc+6
    dec coproc+6
    dec coproc+10
    bne !again-
    rts

do_lines2:
    // lines
    poke8_(coproc+10, 16)   // iterator counter
    poke16_(coproc+3, 0)
    poke8_(coproc+5, 0)
    poke16_(coproc+6, 16)
    poke8_(coproc+8, 0)
!again:
    poke8_(coproc, 0)
    poke8_(coproc+2, 1)
    poke8_(coproc+1, CLINE)
    wait4cr(0)
    poke8_(coproc, 0)
    poke8_(coproc+2, 0)
    poke8_(coproc+1, CLINE)
    wait4cr(1)
    inc coproc+3
    inc coproc+5
    inc coproc+6
    inc coproc+8
    dec coproc+10
    bne !again-
    rts

    rts

main_entry:

    memset_($4000, $0, 8000)
    memset_($7c00, $10, $3f8)
    memset_($d800, $0, 1000)
    clearbits(CIA2.base, %11111100) // select VIC bank $4000-$7FFF
    setbits(CIA2.base, %00000010)
    lda VIC.MEM                     // move VIC screen to base + $0000
    sta tmp1
    and #%00001111
    ora #%11110000 // screen to base + $3C00
    sta VIC.MEM
    setbits(VIC.CR1, %00100000)     // bit 5 -> HiRes

    jsr do_lines2
    jsr do_lines
    jsr do_circles
    jsr do_fcircles

    poke8_(VIC.BoC, 14)
    setbits(CIA2.base, %00000011)
    lda tmp1        
    //and #%11110000
    //ora VIC.MEM
    sta VIC.MEM
    clearbits(VIC.CR1, %11011111)
    //clearbits(VIC.CR2, %11101111)

    rts

