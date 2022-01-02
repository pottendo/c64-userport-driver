#import "pottendos_utils.asm"

//#define HANDLE_MEM_BANK      // enable this if kernal or I/O is potentially banked out

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
    sta parport.jm + 1          // modify operand of ISR branch
    jsr parport.start_isr
    lda parport.read_pending    // busy wait until read is completed
    bne *-3
}
// dest: addr, len: addr
.macro uport_read(dest, len)
{
    adc16(len, dest, parport.len)
    poke16_(parport.buffer, dest)   
    lda #(parport.nread - parport.jm - 2)
    sta parport.jm + 1          // modify operand of ISR branch to
    jsr parport.start_isr       // launch interrupt driven read
    lda parport.read_pending    // busy wait until read is completed
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
_wtmp:          .byte $00
init:
    poke8_(read_pending, 0)
    sta pinput_pending          // acc still 0

    // enable SP2 as another digital output
    poke16_(CIA2.TIA, $0001)        // load timer to enable shift
    // clearbits(CIA2.CRA, %10101110)  // doesn't work, need to set full reg to 0; see next line
    poke8_(CIA2.CRA, 0)             // needed that this works?!
    setbits(CIA2.CRA, %01010001)    // shift->send, force load and enable timer in continous mode
    poke8_(CIA2.SDR, $ff)           // send %11111111, to start output

    //sprite setup for IRC VIC config
    sprite_sel_($0400, $0340, 1, 0)
    sprite_sel_($0400, $0340, 2, 1)
    sprite(1, "color_", LIGHT_GREEN)
    sprite(2, "color_", LIGHT_RED)
    memcpy($0340, sprstart, sprend - sprstart) // move sprite data to matching vic address
    sprite_pos_(1, 324, 50)
    sprite_pos_(2, 324, 50)
    poke16_(rin+1, rindon)
    poke16_(rif+1, rindoff)
    poke16_(win+1, windon)
    poke16_(wif+1, windoff)
    rts
    
// Interrupt driven read, finished when read_pending == 1
start_isr:
rin:
    jsr $beef                        // operand modified
    poke8_(CIA2.ICR, $7f)            // stop all interrupts
    poke16_(STD.NMI_VEC, flag_isr)   // reroute NMI
#if HANDLE_MEM_BANK
    poke16_($fffa, flag_isr)         // also HW vector, if KERNAL is banked out (e.g. in soft80 mode, credits @groepaz)
#endif
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
    poke16_(STD.NMI_VEC, STD.CONTNMI)    // reroute NMI
#if HANDLE_MEM_BANK
    poke16_($fffa, STD.NMI_VEC)
#endif
    poke8_(CIA2.DIRB, $00)           // direction bits 0 -> input
    poke8_(CIA2.ICR, $80)            // enable interrupts    
rif:
    jsr $beef                        // operand modified
    rts
    
flag_isr:
    sei
    save_regs()
#if HANDLE_MEM_BANK
    lda $01
    pha               // save mem layout
    poke8_($01, $37)  // std mem layout for I/O access
#endif
    lda CIA2.ICR
    and #%10000 // FLAG pin interrupt (bit 4)
jm: bne nread  // modified operand in case of loop read
#if HANDLE_MEM_BANK
    pla             // restore mem layout
    sta $01
    jmp STD.CONTNMI
//    restore_regs()
//    rti
#else
    jmp STD.CONTNMI
#endif
    
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
#if HANDLE_MEM_BANK
    pla         // restore mem layout
    sta $01
#endif
    restore_regs()
    rti

loopread:
    setbits(CIA2.PORTA, %00000100)  // set PA2 to high to signal we're busy receiving
    jsr rindon
    lda CIA2.PORTB  // read chr from the parallel port B
rt1:ldy rtail       // operand potentially modified to point to ccgms
rt2:sta gl.dest_mem,y
rt3:inc rtail       // operand potentially modified to point to ccgms
    tya 
    sec
rt4:sbc $beef       // modified to point to ccgms
    cmp #227         // 227
    php
    jsr rindoff
    plp
    bcc out         // enough room in buffer
    //poke8_(VIC.BoC, RED)             // show wer're blocking
    clearbits(CIA2.PORTA, %11111011) // clear PA2 to low to acknowledge last byte
    ora #%00000100
    sta CIA2.PORTA                   // set PA2 to high to signal we're busy -> FlowControl
#if HANDLE_MEM_BANK
    pla             // restore mem layout
    sta $01
#endif
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

setup_write:
    uport_stop()                    // ensure that NMIs are not handled
win:    
    jsr $beef                       // operand modified, show W
    poke8_(CIA2.SDR, 0)             // line -> low to tell C64 wants to write
    poke8_(CIA2.DIRB, $ff)          // direction bits 1 -> output
    setbits(CIA2.DIRA, %00000100)   // PortA r/w for PA2
    setbits(CIA2.PORTA, %00000100)  // set PA2 to high
    rts

close_write:
    clearbits(CIA2.PORTA, %11111011) // set PA2 low
    poke8_(CIA2.DIRB, $00)           // set for input, to avoid conflict by mistake
    poke8_(CIA2.SDR, $ff)            // send %11111111, to tell C64 finished writing
wif:
    jsr $beef                       // operand modified
    rts


write_buffer:
    // sanity check for len == 0
    lda len + 1
    bne cont
    lda len
    bne cont
    rts
cont:
    jsr setup_write
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
    jsr close_write
    rts

write_byte:
    sta _wtmp       // save char to write
#if HANDLE_MEM_BANK
    lda $01
    pha               // save mem layout
    poke8_($01, $37)  // std mem layout for I/O access
#endif
    jsr setup_write
    lda _wtmp
    out_byte()
    jsr close_write
#if HANDLE_MEM_BANK
    pla             // restore mem layout
    sta $01
#endif
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

rindon:
    sprite(1, "on", -1)
    rts

rindoff:
    sprite(1, "off", -1)
    rts

windon:
    sprite(2, "on", -1)
    rts

windoff:
    sprite(2, "off", -1)
    rts

sprstart:
#import "drv-sprites.asm"
sprend:
}

    
__END__:    nop