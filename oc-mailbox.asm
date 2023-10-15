
BasicUpstart2(main_entry)
#import "globals.asm"
#import "pottendos_utils.asm"

#define CLEAR
#define GFXON

//| 6510/8502 address | RISC-V address        | Function                    |
//| ----------------- | --------------------- | --------------------------- |
//| $DEC0-$DEFA       | 0xe0000000-0xe000003a | General purpose RAM         |
//| $DEFB             | 0xe000003b            | RISC-V → 6510/8502 doorbell |
//| $DEFC-$DEFF       | 0xe000003c-0xe000003f | 6510/8502 → RISC-V doorbell |

.label oc_shm       = $dec0
.label oc_interrupt = $defb
.label oc_triggeroc = $deff
.label oc_intc      = $de40
.label oc_irqenable = $de41
.label oc_nmienable = $de42
.label coproc = oc_shm
//.label coproc = $c000

.const CLINE    = 1
.const CCIRCLE  = 2
.const CCIRCLE_EL = 3
.const CEXIT    = $ff 
.const CNOP     = 0

delcnt:     .word $0000
ctrl_save:  .byte $00
tmp1:       .byte $00
deltmp:     .word $00
startval:   .word $00
crsync:     .byte $01
taddrp:     .word $1000

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
    poke16_($fffe, STD.NMI)
    poke8_(CIA1.ICR, $ff)           // enable all interrupts again
    cli
}

.macro wait4cr()
{
!:
    lda $62    //crsync          // poll the sync variable
    sta $63     // write cycle to enable orangecart memaccess
    bne !-
}

.macro trigger_oc()
{
    //poke8_(crsync, 0)
    //dec crsync
    poke8_(oc_triggeroc, $ff)   // trigger OCs ISR
    sta $62
    wait4cr()   // if coproc is still working, we block here, busy waiting
}

do_test:
    poke8_(P.zpp1 , 0)      // P.zzp1 is a zeropage tmp address
    ldy #$20                // loop 32x

!next:
    ldx #$3a                // fill the entire mailbox shm after addr + len (total 6b)
!:  
    txa
    clc 
    adc P.zpp1              // add something
_beef1:
    sta $beef, x           // put in in the oc_shm
    dex
    bne !-
_beef2:
    stx $beef              // also fill byte 0 (always with #0)
    poke8_(oc_shm + 1, $fe) // request cr-test
    poke16(oc_shm + 2, taddrp)  // c64 address where oc shall read from
    poke16_(oc_shm + 4, $3b)   // read len (<shm size)
    trigger_oc()            // trigger oc by issuing an interrupt and busy wait for finish

    inc P.zpp1              // change for the next iteration
    dey
    bne !next-

    rts

do_test2:

    memset($4000, startval, 8000)
    memset($7c00, startval, $3f8)
    memset($d800, startval, 1000)

    poke8_(coproc + 1, 0)
    //    poke8_(oc_triggeroc, $ff)   // trigger OCs ISR
    trigger_oc()
    
    rts

delay:
    poke16_(delcnt, $0fff)
!:  //inc VIC.BoC
    dec16(delcnt);
    bne !-
    rts

do_lines3:
    poke16_(deltmp, 320)   // iterator counter
    poke16_(coproc+3, 319)
    poke8_(coproc+5, 0)
    poke16_(coproc+6, 0)
    poke8_(coproc+8, 199)
!again:
    poke8_(coproc, 0)
    poke8_(coproc+2, 1)
    poke8_(coproc+1, CLINE)
    trigger_oc()
    
    poke8_(coproc, 0)
    poke8_(coproc+2, 0)
    poke8_(coproc+1, CLINE)
    trigger_oc()
    
    dec16(coproc+3)
    inc16(coproc+6)

    dec16(coproc+10)
    dec16(coproc+10)

    dec16(deltmp)
    cmp16_(deltmp, 0)
    beq !+ 
    jmp !again-
!:
   
    rts
do_circles:
    poke8_(deltmp, 20)   // iterator counter
    poke16_(coproc+3, 50)
    poke8_(coproc+5, 100)
    poke16_(coproc+6, 49)
!again:
    //jsr delay
    poke8_(coproc, 0)
    poke8_(coproc+2, $c1)
    poke8_(coproc+1, CCIRCLE)
    trigger_oc()
    //jsr delay
 
#if CLEAR
    poke8_(coproc, 0)
    poke8_(coproc+2, $0)
    poke8_(coproc+1, CCIRCLE)
    trigger_oc()
#endif

    inc coproc+3
    inc coproc+3
    inc coproc+3
    dec coproc+6
    dec coproc+6

    dec deltmp
    beq !+
    jmp !again-
!:
    rts

irq_isr:
    lda oc_intc         // the oc driver triggers by writing $ff to trigger
    and oc_irqenable
    beq !+         
    lda #%00000001
    sta oc_intc         // clear interrupt state
    //inc crsync          // this can be polled to syncronize with finish of a co-routine
    inc VIC.BoC         // show something by setting background color
    restore_regs()      // restore registers as needed for proper ISRs
    rti
!:
    jmp STD.IRQ

nmi_isr2:
    pha
    lda oc_intc         // the oc driver triggers by writing $ff to trigger
    and oc_nmienable
    beq !+         
    lda #%00000001
    sta oc_intc         // clear interrupt state
    //inc crsync          // this can be polled to syncronize with finish of a co-routine
    inc VIC.BgC
!:  pla
    cli
    rti

nmi_isr:
    pha
    lda $01
    pha
    lda #$37
    sta $01

    lda oc_intc
    and oc_nmienable    // check if Orangecart mailbox NMI
    beq @out
    lda #$1
    sta $de40           // ack NMI
    inc $d020
    lda #0
    sta $62

@out:
    pla
    sta $01
    pla
    cli                 // re-enable interrupts
    rti                 // "ReTurn from Interrupt"

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
    //poke16_($0314, irq_isr)
    poke16_($0318, nmi_isr)
    //setbits(oc_irqenable, %00000001)
    setbits(oc_nmienable, %00000001)
    cli

    poke16_(startval, 1)

!next:
   
!:
    jsr STD.GETIN
    beq !-
    cmp #' '
    beq !+
    //jsr do_test2
    //poke16_(_beef1+1, oc_shm)
    //poke16_(_beef2+1, oc_shm)
    //poke16_(taddrp, oc_shm)
    //jsr do_test
    poke16_(_beef1+1, $1000)
    poke16_(_beef2+1, $1000)
    poke16_(taddrp, $1000)
    jsr do_test
    //jsr do_circles
    //jsr do_lines3
    inc startval
    //lda coproc+3
    //adc startval
    //sta coproc+3
    jmp !next-
!:
    sei
    poke16_($0314, STD.IRQ)
    poke16_($0318, STD.NMI)
    clearbits(oc_irqenable, %11111110)
    clearbits(oc_nmienable, %11111110)
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

