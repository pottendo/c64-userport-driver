
BasicUpstart2(main_entry)
#import "globals.asm"
#import "pottendos_utils.asm"

#define CLEAR


//| 6510/8502 address | RISC-V address        | Function                    |
//| ----------------- | --------------------- | --------------------------- |
//| $DEC0-$DEFA       | 0xe0000000-0xe000003a | General purpose RAM         |
//| $DEFB             | 0xe000003b            | RISC-V → 6510/8502 doorbell |
//| $DEFC-$DEFF       | 0xe000003c-0xe000003f | 6510/8502 → RISC-V doorbell |

.label oc_shm       = $dec0
.label oc_interrupt = $defb
.label oc_triggeroc = $defc

delcnt:     .word $0000
ctrl_save:  .byte $00
tmp1:       .byte $00

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

oc_req:
    lda oc_interrupt
    sta VIC.BgC
    jmp STD.IRQ

do_test:

    ldx #20
    poke16_(oc_triggeroc, $ffff)
    poke16_(oc_triggeroc+2, $ffff)
!:
    adc16(oc_triggeroc, $ff, oc_triggeroc)
    sbc16(oc_triggeroc+2, $ff, oc_triggeroc + 2)
    jsr delay
    dex
    bne !-

    rts

delay:
    poke16_(delcnt, $a000)
!:  inc VIC.BoC
    dec16(delcnt);
    bne !-
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
    jsr delay
    jsr do_test

    sei
    //poke16_($0314, STD.IRQ)
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

