#import "pottendos_utils.asm"

.macro uport_read(dest, len) {
    lda #<dest
    ldy #>dest
    sta parport.len
    sta parport.buffer
    sta parport.dest
    sty parport.len + 1
    sty parport.buffer + 1
    sty parport.dest + 1

    clc
    adc #<len
    sta parport.len
    bcc !+
    inc parport.len + 1
!:
    lda parport.len + 1
    clc
    adc #>len
    sta parport.len + 1
    inc $d020    
    jsr parport.start_isr
}

.macro uport_stop() {
    jsr parport.stop_isr
}

.macro uport_write(from, len) {
    poke16(parport.buffer, from)
    poke16(parport.len, len)
    jsr parport.start_write
}

*=$2500
parport: {
    .label buffer = $fe   // pointer to destination buffer
len:
    .word $0000     // len of requested read
dest:
    .word $0400     // destination address
start_isr:
    poke8(CIA2.ICR, $7f)            // stop all interrupts
    poke16(STD.NMI_VEC, flag_isr)   // reroute NMI
    poke8(CIA2.DIRB, $00)           // direction bit 0 -> input
    setbits(CIA2.PORTA, %00000100)  // set PA2 to high to signal we're ready to receive
    lda CIA2.ICR                    // clear interrupt flags by reading
    poke8(CIA2.ICR, %10010000)      // enable FLAG pin as interrupt source
    rts

stop_isr:
    poke8(CIA2.ICR, $7f)            // stop all interrupts
    poke16(STD.NMI_VEC, STD.NMI)    // reroute NMI
    poke8(CIA2.DIRB, $00)           // direction bits 0 -> input
    poke8(CIA2.ICR, $80)            // enable interrupts    
    rts
    
flag_isr:
    save_regs()
    lda CIA2.ICR
    and #%10000 // FLAG pin interrupt (bit 4)
    bne !+
    jmp STD.NMI
    // receive char now
!:
    clearbits(CIA2.PORTA, %11111011)   // set PA2 to low to signal we're busy receiving
    ldy #$00
    lda CIA2.PORTB  // read chr from the parallel input
    sta (buffer), y
    inc buffer      
    bne !+
    inc buffer + 1
!:
    lda buffer + 1
    cmp len + 1
    bne out
    lda buffer
    cmp len
    bne out
    // reset rcv buffer
    //lda parport.dest
    //sta buffer
    //lda parport.dest + 1
    //sta buffer + 1
    uport_stop()
    jmp !+
out:
    setbits(CIA2.PORTA, %00000100)  // set PA2 to high to signal we're ready to receive
    // done
!:
    restore_regs()
    rti

start_write:
    // sanity check for len == 0
    lda len + 1
    bne cont
    lda len
    bne cont
    rts
cont:
    uport_stop()                    // ensure that NMIs are not handled
    setbits(CIA2.PORTA,%00000100)   // set PA2 to high
    poke8(CIA2.DIRB, $ff)           // direction bits 1 -> output

loop:    
    lda #%10000     // check if receiver is read to accept next char
    bit CIA2.ICR
    beq *-3

    inc VIC.BoC

    ldy #$00
    lda (buffer), y
    sta CIA2.PORTB

    clearbits(CIA2.PORTA, %11111011)
    ora #%00000100                  // toggle PA2 line to signal that a char is ready
    sta CIA2.PORTA

    inc buffer
    bne !+
    inc buffer + 1
!:
    dec len
    bne loop
    lda len + 1
    beq done
    dec len + 1
    jmp loop
done:
    poke8(VIC.BoC, 14)
    rts
}
