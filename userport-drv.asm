#import "pottendos_utils.asm"

.macro start_isr(dest, len) {
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
.macro stop_isr() {
    jsr parport.stop_isr
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
    sta CIA2.DIR

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

    set_color(1);
    ldy #$00
    lda CIA2.PORTB
    sta (buffer), y
    inc buffer      // just $ff bytes for now
    lda buffer
    cmp #$00
    bne !+
    inc buffer + 1
    inc $d020
!:
    lda buffer + 1
    cmp len + 1
    bne out
    inc $d021
    lda buffer
    cmp len
    bne out
    // reset rcv buffer
    lda parport.dest
    sta buffer
    lda parport.dest + 1
    sta buffer + 1
out:

    lda CIA2.PORTA   // set PA2 to high to signal we're ready to receive
    ora #%00000100
    sta CIA2.PORTA

    // done
    restore_regs()
    rti

* = $3000
test:
    ldy #$13
    lda $fd
    sta (buffer), y
    inc buffer      // just $ff bytes for now
    bne !+
    inc buffer + 1
    inc $d020
!:
    lda buffer + 1
    cmp len + 1
    bne out2
    inc $d021
    lda buffer
    cmp len
    bne out2
    // reset rcv buffer
    lda parport.dest
    sta buffer
    lda parport.dest + 1
    sta buffer + 1
out2:
    rts
    
}
