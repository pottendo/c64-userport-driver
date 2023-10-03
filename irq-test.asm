
BasicUpstart2(main_entry)
#import "globals.asm"
#import "pottendos_utils.asm"


nmi_isr:
    tsx
    inc VIC.BgC
    lda #>other
    pha
    lda #<other
    pha
    lda $101,x
    pha
    cli
    rti

other:
    pla
    pla
    pla
    inc VIC.BoC
    jmp !next+

main_entry:
    sei
    //poke16_($0314, oc_req)
    poke16_($0318, nmi_isr)
    cli

!next:
    jmp !next-
   
!:
    jsr STD.GETIN
    beq !-
    cmp #' '
    beq !+

!:
    sei
    poke16_($0314, STD.IRQ)
    poke16_($0318, STD.NMI)
    cli
    poke8_(VIC.BoC, 14)
    rts

