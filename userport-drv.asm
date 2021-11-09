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

// from: addr, len: scalar
.macro uport_write_(from, len) {
    poke16_(parport.buffer, from)
    poke16_(parport.len, len)
    jsr parport.start_write
}

// from: addr, len: addr
.macro uport_write(from, len) {
    poke16_(parport.buffer, from)
    poke16(parport.len, len)
    jsr parport.start_write
}

// .segment _par_drv

parport: {
                .label buffer = $9e   // pointer to destination buffer
len:            .word $0000     // len of requested read
dest:           .word $0400     // destination address
read_pending:   .byte $00       // flag if read is on-going

// Interrupt driven read, finished when read_pending == 1
start_isr:
    poke8_(CIA2.ICR, $7f)            // stop all interrupts
    poke16_(STD.NMI_VEC, flag_isr)   // reroute NMI
    poke8_(CIA2.DIRB, $00)           // direction bit 0 -> input
    setbits(CIA2.DIRA, %00000100)   // PortA r/w for PA2
    //setbits(CIA2.PORTA, %00000100)  // set PA2 to high to signal we're sending
    clearbits(CIA2.PORTA, %11111011)  // set PA2 to low to signal we're ready to receive
    poke8_(CIA2.SDR, $ff)
    lda CIA2.ICR                    // clear interrupt flags by reading
    poke8_(CIA2.ICR, %10010000)      // enable FLAG pin as interrupt source
    poke8_(read_pending, $01)
    deb(65)
    rts

stop_isr:
    poke8_(CIA2.ICR, $7f)            // stop all interrupts
    poke16_(STD.NMI_VEC, STD.NMI)    // reroute NMI
    poke8_(CIA2.DIRB, $00)           // direction bits 0 -> input
    poke8_(CIA2.ICR, $80)            // enable interrupts    
    rts
    
flag_isr:
    save_regs()
    lda CIA2.ICR
    and #%10000 // FLAG pin interrupt (bit 4)
    bne !+
    jmp STD.NMI
    // receive char now
!:
    setbits(CIA2.PORTA, %00000100)  // set PA2 to high to signal we're busy receiving
    ldy #$00
    lda CIA2.PORTB  // read chr from the parallel port B
    sta (buffer), y
    inc buffer      
    bne !+
    inc buffer + 1
!:
    cmp16(buffer, len) 
    bcc out
    // reset rcv buffer
    //lda parport.dest
    //sta buffer
    //lda parport.dest + 1
    //sta buffer + 1
    uport_stop()
    poke8_(read_pending, $00)
//    jmp !+
out:
!:
    clearbits(CIA2.PORTA, %11111011)   // clear PA2 to low to signal we're ready to receive
    //setbits(CIA2.PORTA, %00000100)  // set PA2 to high to signal we're busy
    restore_regs()
    rti

sync_read:
    poke8_(read_pending, 0)
    poke8_(CIA2.SDR, $ff)
    poke8_(CIA2.DIRB, $00)           // direction bit 0 -> input
    setbits(CIA2.DIRA, %00000100)   // PortA r/w for PA2
    ldy #$00
next:
    clearbits(CIA2.PORTA, %11111011)  // set PA2 to low to signal we're ready to receive
//    lda #%10000
//!:  bit CIA2.ICR
//    beq !-
!:  inc VIC.BoC
    lda CIA2.ICR
    and #%00010000
    bne !-

    setbits(CIA2.PORTA, %00000100)  // set PA2 to high to signal we're busy
    lda CIA2.PORTB
    sta (buffer), y
    inc buffer      
    bne !+
    inc buffer + 1
!:
    cmp16(buffer, len) 
    bcc next
    clearbits(CIA2.PORTA, %11111011)
    poke8_(read_pending, 0);
    rts

start_write:
    // sanity check for len == 0
    lda len + 1
    bne cont
    lda len
    bne cont
    rts
cont:
    uport_stop()                    // ensure that NMIs are not handled
    poke8_(CIA2.SDR, 0)             // line -> low to tell C64 wants to write
    poke8_(CIA2.DIRB, $ff)          // direction bits 1 -> output
    setbits(CIA2.DIRA, %00000100)   // PortA r/w for PA2
    setbits(CIA2.PORTA, %00000100)  // set PA2 to high

loop:    
    ldy #$00
    clearbits(CIA2.PORTA, %11111011)    // set PA2 low
    lda (buffer), y
    sta CIA2.PORTB
    
!:  inc VIC.BoC
    lda #%10000     // check if receiver is ready to accept next char
    bit CIA2.ICR
    beq !-
    setbits(CIA2.PORTA, %00000100)    // set PA2 high
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
    //lda #%10000     // ensure last bits have sent
    //bit CIA2.ICR
    //beq *-3
    clearbits(CIA2.PORTA, %11111011)    // set PA2 low
    poke8_(CIA2.DIRB, $00)           // set for input, to avoid conflict by mistake
    poke8_(CIA2.SDR, $ff)           // send %11111111, to tell C64 finished writing
    rts
}

__END__:    nop