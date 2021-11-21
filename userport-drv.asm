#import "pottendos_utils.asm"

// dest: addr, len: scalar
.macro uport_read_(dest, len) {
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

    lda #(parport.nread - parport.jm - 2)
    sta parport.jm + 1  // modify operand of ISR branch
    jsr parport.start_isr
    lda parport.read_pending            // busy wait until read is completed
    bne *-3
}
// dest: addr, len: addr
.macro uport_read(dest, len)
{
    adc16(len, dest, parport.len)
    poke16_(parport.buffer, dest)   
    lda #(parport.nread - parport.jm - 2)
    sta parport.jm + 1      // modify operand of ISR branch to
    jsr parport.start_isr   // launch interrupt driven read
    lda parport.read_pending            // busy wait until read is completed
    bne *-3
}

.macro uport_lread(dest)
{
    poke8_(parport.rtail, 0)
    lda #(parport.loopread - parport.jm - 2)
    sta parport.jm + 1  // modify jump address for loopread
    poke16_(parport.buffer, dest)
    jsr parport.start_isr
}

.macro uport_stop() {
    jsr parport.stop_isr
}

// from: addr, len: scalar
.macro uport_write_(from, len) {
    poke16_(parport.buffer, from)
    poke16_(parport.len, len)
    jsr parport.write_buffer
}

// from: addr, len: addr
.macro uport_write(from, len) {
    poke16_(parport.buffer, from)
    poke16(parport.len, len)
    jsr parport.write_buffer
}

.macro setup_write()
{
    uport_stop()                    // ensure that NMIs are not handled
    poke8_(CIA2.SDR, 0)             // line -> low to tell C64 wants to write
    poke8_(CIA2.DIRB, $ff)          // direction bits 1 -> output
    setbits(CIA2.DIRA, %00000100)   // PortA r/w for PA2
    setbits(CIA2.PORTA, %00000100)  // set PA2 to high
}

.macro close_write()
{
    clearbits(CIA2.PORTA, %11111011) // set PA2 low
    poke8_(CIA2.DIRB, $00)           // set for input, to avoid conflict by mistake
    poke8_(CIA2.SDR, $ff)            // send %11111111, to tell C64 finished writing
}

// write byte from acc to parport
.macro out_byte() {
    pha
    clearbits(CIA2.PORTA, %11111011)    // set PA2 low
    pla
    sta CIA2.PORTB
!:  
    lda #%10000     // check if receiver is ready to accept next char
    bit CIA2.ICR
    beq !-
    setbits(CIA2.PORTA, %00000100)    // set PA2 high
}

// .segment _par_drv

parport: {
                .label buffer = $9e   // pointer to destination buffer
len:            .word $0000     // len of requested read
dest:           .word $0400     // destination address
read_pending:   .byte $00       // flag if read is on-going
rtail:          .byte $00
pinput_pending: .byte $00       // #of msg the esp would like to send, inc'ed by NMI/Flag2

init:
    poke8_(read_pending, 0)
    sta pinput_pending          // acc still 0
    rts
    
// Interrupt driven read, finished when read_pending == 1
start_isr:
    poke8_(CIA2.ICR, $7f)            // stop all interrupts
    poke16_(STD.NMI_VEC, flag_isr)   // reroute NMI
    poke8_(CIA2.SDR, $ff)            // Signal C64 is in read-mode (safe for CIA)
    poke8_(CIA2.DIRB, $00)           // direction bit 0 -> input
    setbits(CIA2.DIRA, %00000100)    // PortA r/w for PA2
    clearbits(CIA2.PORTA, %11111011) // set PA2 to low to signal we're ready to receive
    lda CIA2.ICR                     // clear interrupt flags by reading
    poke8_(CIA2.ICR, %10010000)      // enable FLAG pin as interrupt source
    poke8_(read_pending, $01)
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
jm: bne nread  // modified operand in case of loop read
    jmp STD.NMI
    // receive char now
nread:
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
    uport_stop()
    poke8_(read_pending, $00)

out:
    clearbits(CIA2.PORTA, %11111011)   // clear PA2 to low to signal we're ready to receive
    restore_regs()
    rti

loopread:
    setbits(CIA2.PORTA, %00000100)  // set PA2 to high to signal we're busy receiving
    lda CIA2.PORTB  // read chr from the parallel port B
rt1:ldy rtail       // operand potentially modified to point to ccgms
rt2:sta gl.dest_mem,y
rt3:inc rtail       // operand potentially modified to point to ccgms
    tya 
    sec
rt4:sbc $beef       // modified to point to ccgms
    cmp #227
    bcc out         // enough room in buffer
    clearbits(CIA2.PORTA, %11111011) // clear PA2 to low to acknowledge last byte
    setbits(CIA2.PORTA, %00000100)   // set PA2 to high to signal we're busy -> FlowControl
    poke8_(VIC.BoC, RED)             // show wer're blocking
    restore_regs()
    rti

sync_read:
    poke8_(read_pending, 0)
    poke8_(CIA2.SDR, $ff)
    poke8_(CIA2.DIRB, $00)          // direction bit 0 -> input
    setbits(CIA2.DIRA, %00000100)   // PortA r/w for PA2
    ldy #$00
    lda CIA2.PORTB  // dummy read to trigger TC2
next:
    clearbits(CIA2.PORTA, %11111011)  // set PA2 to low to signal we're ready to receive
!:  inc VIC.BoC
    lda CIA2.ICR
    nop 
    nop
    nop
    and #%00010000
    beq !-

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

write_buffer:
    // sanity check for len == 0
    lda len + 1
    bne cont
    lda len
    bne cont
    rts
cont:
    setup_write()
loop:    
    ldy #$00
    lda (buffer), y
    out_byte()
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
    close_write()
    rts

write_byte:
    pha
    setup_write()
    pla
    out_byte()
    close_write()
    rts

arm_msgcnt:
    poke8_(CIA2.ICR, $7f)           // stop all interrupts
    poke16_(STD.NMI_VEC, msg_cnt)   // reroute NMI
    //clearbits(CIA2.PORTA, %11111011) // clear PA2 to low to allow sync for write
    setbits(CIA2.PORTA, %00000100)  // set PA2 to high to signal we're waiting for sync
    lda CIA2.ICR                     // clear interrupt flags by reading
    poke8_(CIA2.ICR, %10010000)      // enable FLAG pin as interrupt source
    rts
msg_cnt:
    save_regs()
    lda CIA2.ICR
    and #%10000 // FLAG pin interrupt (bit 4)
    bne !+
    jmp STD.NMI   
!:  inc pinput_pending
    restore_regs()
    rti
}

    
__END__:    nop