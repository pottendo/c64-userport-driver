
BasicUpstart2(main_entry)
#import "globals.asm"
#import "pottendos_utils.asm"

//#define CLEAR
#define GFXON


//| 6510/8502 address | RISC-V address        | Function                    |
//| ----------------- | --------------------- | --------------------------- |
//| $DEC0-$DEFA       | 0xe0000000-0xe000003a | General purpose RAM         |
//| $DEFB             | 0xe000003b            | RISC-V → 6510/8502 doorbell |
//| $DEFC-$DEFF       | 0xe000003c-0xe000003f | 6510/8502 → RISC-V doorbell |

.label oc_shm       = $dec0
.label oc_interrupt = $defb
.label oc_triggeroc = $defc
.label coproc = oc_shm

.const CLINE    = 1
.const CCIRCLE  = 2
.const CCIRCLE_EL = 3
.const CEXIT    = $ff 
.const CNOP     = 0

delcnt:     .word $0000
ctrl_save:  .byte $00
tmp1:       .byte $00
deltmp:     .byte $00
startval:   .byte $00
crsync:     .byte $00

.macro enable_roms()
{ 
    sei
    lda $01
    sta ctrl_save
    clearbits($01, %11111000)
    setbits($01, %00000100)
    cli
}

.macro restore_mems()
{
    sei
    lda ctrl_save
    sta $01
    poke16_($fffe, STD.NMI)
    poke8_(CIA1.ICR, $ff)           // enable all interrupts again
    cli
}

.macro wait4cr()
{
!:
    lda VIC.BoC
    lda crsync
    beq !-
}
.macro trigger_oc()
{
//    poke8_(oc_triggeroc, $ff);
    poke8_(crsync, 0);
    //poke16_(oc_triggeroc, $ffff)
    poke8_(oc_triggeroc+3, $ff)
    wait4cr()
}

oc_req:
    pha
    lda oc_interrupt
    inc crsync
    pla
    jmp STD.IRQ

do_test:
    poke8_(P.zpp1 , 0)
    ldy #$20

!next:
    ldx #$3b
!:  
    txa
    clc 
    adc P.zpp1
    sta oc_shm, x
    dex
    bne !-
    stx oc_shm

    poke8_(oc_shm + 1, $fe) // request cr-test
    trigger_oc()

    inc P.zpp1
    dey
    bne !next-

    rts

delay:
    poke16_(delcnt, $1000)
!:  inc VIC.BoC
    dec16(delcnt);
    bne !-
    rts

do_circles:

    // lines
    poke8_(deltmp, 40)   // iterator counter
    poke16_(coproc+3, 10)
    poke8_(coproc+5, 100)
    poke16_(coproc+6, 99)
!again:
    poke8_(coproc, 0)
    poke8_(coproc+2, $1)
    poke8_(coproc+1, CCIRCLE)
    trigger_oc()
    jsr delay
#if CLEAR
    poke8_(coproc, 0)
    poke8_(coproc+2, $61)
    poke8_(coproc+1, CCIRCLE)
    trigger_oc()
#endif

    //inc coproc+3
    //inc coproc+3
    //inc coproc+3
    //dec coproc+6
    //dec coproc+6
    dec deltmp
    beq !+
    jmp !again-
!:
    rts

main_entry:
#if GFXON
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
#endif
    sei
    poke16_($0314, oc_req)
    cli

    poke8_(startval, 0)
!next:
    jsr do_test
    //jsr do_circles
    inc startval
!:
    jsr STD.GETIN
    beq !-

    cmp #' '
    beq !+
    jmp !next-
!:

    sei
    poke16_($0314, STD.IRQ)
    cli
    poke8_(VIC.BoC, 14)
#if GFXON
    setbits(CIA2.base, %00000011)
    lda tmp1        
    //and #%11110000
    //ora VIC.MEM
    sta VIC.MEM
    clearbits(VIC.CR1, %11011111)
    //clearbits(VIC.CR2, %11101111)
#endif
    rts

