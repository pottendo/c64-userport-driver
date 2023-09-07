
BasicUpstart2(main_entry)
#import "globals.asm"
#import "pottendos_utils.asm"

#define CLEAR

//.label coproc   = $c000;
.label coproc   = $e0;
.const CLINE    = 1
.const CCIRCLE  = 2
.const CCIRCLE_EL = 3
.const CEXIT    = $ff 
.const CNOP     = 0
tmp1: .byte $00
tmp2: .word $0000
ctrl_save: .byte $00

.macro wait4cr(sync)
{
!w:
    sei
    lda $01
    ora #%00000111
    sta $01
    inc $d000
    dec $d000
    inc $d000
    dec $d000
    inc $d000
    dec $d000
    inc $d000
    dec $d000
    and #%11111100
    sta $01
    cli

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
    beq !+
    jmp !again-
!:
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
    poke8_(coproc+2, $61)
    poke8_(coproc+1, CCIRCLE)
    wait4cr(1)
#endif

    inc coproc+3
    inc coproc+3
    inc coproc+3
    dec coproc+6
    dec coproc+6
    dec coproc+10
    beq !+
    jmp !again-
!:
    rts

do_fcircles:
    // circles filled
    poke8_(coproc+10, 24)   // iterator counter
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
    poke8_(coproc+2, $E1)
    poke8_(coproc+1, CCIRCLE)
    wait4cr(1)
#endif 

    sbc16(coproc+3, 3, coproc+3);
    dec coproc+6
    dec coproc+6

    dec coproc+10
    beq !+ 
    jmp !again-
!:
    rts

do_felcircles:
    // circles filled
    poke8_(coproc+10, 50)   // iterator counter
    poke16_(coproc+3, 0)
    poke16_(coproc+5, 0)
    poke16_(coproc+7, 0)
!again:
    poke8_(coproc, 0)
    poke8_(coproc+2, $E1)    // #%1xxxxxxx signals filling
    poke8_(coproc+1, CCIRCLE_EL)
    wait4cr(0)

#if CLEAR
    poke8_(coproc, 0)
    poke8_(coproc+2, $E1)
    poke8_(coproc+1, CCIRCLE_EL)
    wait4cr(1)
#endif 

    adc16(coproc+3, 5, coproc+3);
    adc16(coproc+5, 3, coproc+5);
    adc16(coproc+7, 1, coproc+7);

    dec coproc+10
    beq !+ 
    jmp !again-
!:
    rts

do_lines2:
    // lines
    poke8_(coproc+10, 8)   // iterator counter
    poke16_(coproc+3, 256)
    poke8_(coproc+5, 0)
    poke16_(coproc+6, 256)
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
    inc16(coproc+3)
    inc16(coproc+6)
    dec coproc+10
    beq !+
    jmp !again-
!:
    rts

do_tiny_circles:

    // circles filled
    poke8_(coproc+10, 8)   // iterator counter
    poke16_(coproc+3, 8)
    poke8_(coproc+5, 100)
    poke16_(coproc+6, 1)
!again:
    poke8_(coproc, 0)
    poke8_(coproc+2, $81)    // #%1xxxxxxx signals filling
    poke8_(coproc+1, CCIRCLE)
    wait4cr(0)

#if CLEAR
    poke8_(coproc, 0)
    poke8_(coproc+2, $E1)
    poke8_(coproc+1, CCIRCLE)
    wait4cr(1)
#endif 

    adc16(coproc+3, 4, coproc+3)
    adc8(coproc+5, 1, coproc+5)
    //adc16(coproc+6, 1, coproc+6)
    dec coproc+10
    beq !out+
    jmp !again-
!out:
    rts
    
do_tiny_lines:
    poke8_(coproc+10, 16)   // iterator counter
    poke16_(coproc+3, 0)
    poke8_(coproc+5, 100)
    poke16_(coproc+6, 1)
    poke8_(coproc+8, 100)
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
    inc coproc+6
    sbc8(coproc+5, 1, coproc+5)
    sbc8(coproc+8, 1, coproc+8)

    dec coproc+10
    beq !+ 
    jmp !again-
!:
    rts

do_tiny_lines2:
    poke8_(coproc+10, 16)   // iterator counter
    poke16_(coproc+3, 0)
    poke8_(coproc+5, 0)
    poke16_(coproc+6, 0)
    poke8_(coproc+8, 199)
!again:
    poke8_(coproc, 0)
    poke8_(coproc+2, $61)
    poke8_(coproc+1, CLINE)
    wait4cr(0)
    poke8_(coproc, 0)
    poke8_(coproc+2, $61)
    poke8_(coproc+1, CLINE)
    wait4cr(1)
    inc coproc+3
    inc coproc+6

    dec coproc+10
    beq !+ 
    jmp !again-
!:
   
    rts

do_lines3:
    poke16_(coproc+10, 320)   // iterator counter
    poke16_(coproc+3, 319)
    poke8_(coproc+5, 0)
    poke16_(coproc+6, 0)
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
    dec16(coproc+3)
    inc16(coproc+6)

    dec16(coproc+10)
    dec16(coproc+10)
    cmp16_(coproc+10, 0)
    beq !+ 
    jmp !again-
!:
   
    rts

do_lines4:
    poke16_(coproc+10, 320)   // iterator counter
    poke16_(coproc+3, 0)
    poke8_(coproc+5, 0)
    poke16_(coproc+6, 319)
    poke8_(coproc+8, 199)
!again:
    poke8_(coproc, 0)
    poke8_(coproc+2, %01000001)
    poke8_(coproc+1, CLINE)
    wait4cr(0)
    //poke8_(coproc, 0)
    //poke8_(coproc+2, 0)
    //poke8_(coproc+1, CLINE)
    //wait4cr(1)
    inc16(coproc+3)
    inc16(coproc+3)
    dec16(coproc+6)
    dec16(coproc+6)

    dec16(coproc+10)
    dec16(coproc+10)
    cmp16_(coproc+10, 0)
    beq !+ 
    jmp !again-
!:
    rts

// -------------------------------------------
loop_col:
    poke16_(tmp2, $3fff)
!:
    poke8($4000, tmp2)
    inc VIC.BoC
    dec16(tmp2)
    beq outx2
    jmp !-
outx2:
    rts

nmiisrab:
    save_regs()
    inc $4000 + 8
    poke8_(CIA2.ICR, $ff)            // stop all interrupts
    ldy CIA2.ICR

    restore_regs()
    cli
    rti

irqisrcd:
    pha
    lda $d019
    ora #%10000000
    sta $d019
    poke8_(CIA1.ICR, $7f)            // stop all interrupts
    lda CIA1.ICR
    inc $4000 + 320 * 1

    pla
    rti

nmiisref:
    pha
    inc $4000 + 8 * 5 + 320 * 3
    lda $01
    pha
    ora #%000000111
    sta $01
    poke8_(CIA1.ICR, $7f)           // stop all interrupts to avoid constant NMIs
    lda CIA1.ICR                    // acknowledge
    pla
    sta $01
    pla
    rti

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

    poke16_($fffe, nmiisref)        // ensure vector if kernal is switched off

    sei
    lda $01
    sta ctrl_save
    clearbits($01, %11111000)
    setbits($01, %00000100)
    cli

    jsr do_lines4
    jsr do_felcircles
    jsr do_tiny_lines2
    jsr do_tiny_circles
    jsr do_circles
    jsr do_fcircles
    jsr do_lines3
    jsr do_lines2
    jsr do_tiny_lines
    jsr do_lines
    
    sei
    lda ctrl_save
    sta $01
    poke16_($fffe, STD.NMI)
    poke8_(CIA1.ICR, $ff)           // enable all interrupts again
    cli

    poke8_(VIC.BoC, 14)
    setbits(CIA2.base, %00000011)
    lda tmp1        
    //and #%11110000
    //ora VIC.MEM
    sta VIC.MEM
    clearbits(VIC.CR1, %11011111)
    //clearbits(VIC.CR2, %11101111)

    rts

