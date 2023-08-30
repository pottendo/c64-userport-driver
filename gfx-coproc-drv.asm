
BasicUpstart2(main_entry)
#import "globals.asm"
#import "pottendos_utils.asm"

.label coproc = $c000;
.const CLINE=1
tmp1: .byte $00

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

    poke8_(coproc+10, 0)

    poke16_(coproc+3, 10)
    poke8_(coproc+5, 0)
    poke16_(coproc+6, 310)
    poke8_(coproc+8, 199)
again:
    poke8_(coproc, 0)
    poke8_(coproc+2, 1)
    poke8_(coproc+1, CLINE)
!:
    //inc $d020
    lda coproc
    beq !-
    poke8_(coproc, 0)
    poke8_(coproc+2, 0)
    poke8_(coproc+1, CLINE)
 
 !:
    lda coproc
    beq !-

    inc coproc+3
    inc coproc+3
    inc coproc+3
    dec coproc+6
    dec coproc+6
    dec coproc+6
    dec coproc+10
    bne again

    poke8_(VIC.BoC, 14)
    setbits(CIA2.base, %00000011)
    lda tmp1        
    //and #%11110000
    //ora VIC.MEM
    sta VIC.MEM
    clearbits(VIC.CR1, %11011111)
    //clearbits(VIC.CR2, %11101111)

    rts

