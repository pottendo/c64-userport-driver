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
    lda #<from
    ldy #>from
    sta parport.buffer
    sty parport.buffer + 1
    lda #<len
    ldy #>len
    sta parport.len
    sty parport.len + 1

    jsr parport.start_write
}

parport: {
    .label buffer = $fe   // pointer to destination buffer
len:
    .word $0000     // len of requested read
dest:
    .word $0400     // destination address
start_isr:
    lda #$7f        // stop all interrupts
    sta CIA2.ICR
    lda #<flag_isr  // setup isr for FLAG PIN
    sta STD.NMI_VEC
    lda #>flag_isr
    sta STD.NMI_VEC + 1

    lda #$00        // direction bit 0 -> input
    sta CIA2.DIRB

    lda CIA2.PORTA   // set PA2 to high to signal we're ready to receive
    ora #%00000100
    sta CIA2.PORTA

    lda CIA2.ICR    // clear interrupt flags by reading
    lda #%10010000  // set FLAG pin as interrupt source
    sta CIA2.ICR    // enable interrupts for FLAG line

    rts

stop_isr:
    lda #$7f        // stop all interrupts
    sta CIA2.ICR
    lda #<STD.NMI
    sta STD.NMI_VEC
    lda #>STD.NMI
    sta STD.NMI_VEC + 1
    lda #$80
    sta CIA2.ICR    // enable interrupts    
    rts
    
flag_isr:
    save_regs()
    lda CIA2.ICR
    and #%10000 // FLAG pin interrupt (bit 4)
    bne !+
    jmp STD.NMI
    // receive char now
!:
    lda CIA2.PORTA   // set PA2 to low to signal we're busy receiving
    and #%11111011
    sta CIA2.PORTA
    ldy #$00
    lda CIA2.PORTB
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
    lda CIA2.PORTA   // set PA2 to high to signal we're ready to receive
    ora #%00000100
    sta CIA2.PORTA

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

    uport_stop()     // ensure that NMIs are not handled
    lda CIA2.PORTA   // set PA2 to high
    ora #%00000100
    sta CIA2.PORTA
    lda #$ff        // direction bit 1 -> output
    sta CIA2.DIRB

loop:    
    lda #%10000     // check if receiver is read to accept next char
    bit CIA2.ICR
    beq *-3

    inc VIC.BoC

    ldy #$00
    lda (buffer), y
    sta CIA2.PORTB

    lda CIA2.PORTA  // toggle PA2 line to signal that a char is ready
    and #%11111011
    sta CIA2.PORTA
    ora #%00000100
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
    set_color(VIC.BoC, 14)
    rts
}
