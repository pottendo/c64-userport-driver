#import "pottendos_utils.asm"

.namespace irc {
seperator:  .text "----------------------------------------"
            .byte $00
crs:        .byte $00
tlen:       .word $0000
nick:       .fill 16, $00
#if EXT80COLS
defnick:    .text "POTTENDO> "
#else
defnick:    .text "pottendo> "
#endif
            .byte $00
et:         .text "*qui*"
_t:         .byte $00
.label msgbuf  = $9000
.label buflen = $0800
.label rcvbuffer = msgbuf + buflen
.label inputaddr = rcvbuffer + 160
.label msgptr = $14
.label currptr = $16
.label newentrypos = $0400 + 17 * 40

setup:
#if !TEST_IRC
    jsr parport.arm_msgcnt  // launch NMI counter for pending msgs
#endif
    poke16_(msgptr, msgbuf)
    poke16_(currptr, msgbuf)
    poke8_(crs, 0)
    memset(inputaddr, ' ', 80)
    memcpy(nick, defnick, 10)
#if !EXT80COLS
    jsr STD.CLSCR
    lda #$0e 
    jsr STD.BSOUT
    wstring(0, 22, seperator)
    set_cursor(0, 23)
#else    
    jsr soft80.soft80_init
    soft80_pos_(0, 23)
#endif
    jsr inputloop
    jsr soft80.soft80_shutdown
    jmp main_.cmd4
    rts
    
inputloop:
#if !TEST_IRC
    jsr rcv_msgs
#endif
    jsr STD.GETIN 
    beq inputloop
    cmp #13
    bne !+
    jsr store_input
    clear_row(23)
    poke8_(crs, 0)
    //memset(inputaddr, ' ', 80)
#if !EXT80COLS
    set_cursor(0, 23)
#endif
    jmp inputloop
    rts
!:
#if !EXT80COLS
    //jsr STD.BSOUT     // BSOUT conflicts with ZP addresses of Soft80
#endif
    // need to handle BS XXX
    ldx crs
    sta inputaddr,x
    save_regs()
    ldy #23
    sty _t
_d:
    soft80_putcxy(crs, _t)
    //jsr soft80_cputc
    restore_regs()
    inc crs
    ldx crs
    cpx #(40+38)
    beq !+
    jmp inputloop
!:
    lda #0
    sta inputaddr, x
    rts

out:
    poke8_(rcvbuffer, 5)
    memcpy(rcvbuffer+1, et, 5)  // prepare from _quit
#if !TEST_IRC
    jsr send_msg                // won't arm NMI after write
    uport_stop()
#endif
    poke8_(crs, 0)
    pla                         // stop IRC to main loop
    pla
    rts
    
store_input:
    ldx crs
    beq out                     // exit IRC by empty line
    stx rcvbuffer
!:  lda inputaddr,x
    sta rcvbuffer + 1, x 
    dex
    bpl !-
#if !TEST_IRC
    jsr send_msg
    jsr parport.arm_msgcnt
#endif
    memcpy_d(rcvbuffer + 10, rcvbuffer, 80)
    memcpy(rcvbuffer + 1, nick, 10)
    lda rcvbuffer
    clc
    adc #10
    sta rcvbuffer
    jsr cpy2msgbuf
    rts

#if !TEST_IRC
rcv_msgs:
    lda parport.pinput_pending
    bne !+
    rts
!:
    poke8_(rcvbuffer + 1, 0)                // high byte 0, to support 16 bit len in addr - ugly misuse but efficient
    uport_read_(rcvbuffer, 1)
    uport_read(rcvbuffer + 1, rcvbuffer)    // len is stored here
    dec parport.pinput_pending
    jsr parport.arm_msgcnt
#endif

cpy2msgbuf:
    ldy rcvbuffer
    cpy #$00
    bne !+
    rts
!:  lda rcvbuffer, y
    sta (msgptr), y
    dey
    bne !-
    lda rcvbuffer   // store length
    pha
    sta (msgptr), y
    clc
    adc #$01        // byte for len
    clc 
    adc msgptr
    sta msgptr
    lda #$00
    adc msgptr + 1
    sta msgptr + 1
    cmp16_(msgptr, msgbuf + buflen)
    bcc !+
    poke16_(msgptr, msgbuf) // reset to begin
!:
    pla // recover len to move output canvas
#if !EXT80COLS
    cmp #40
    bcc !+
    memcpy($0400, $0400 + 80, 16 * 40)      // two lines
    memset(newentrypos, ' ', 80)
    lda #(newentrypos - 41)
    sta p1 + 1
    jmp update_dsp
!:  
    memcpy($0400, $0400 + 40, 17 * 40)      // just one line
    memset(newentrypos, ' ', 80)
    lda #(newentrypos - 1)
    sta p1 + 1
#else
    jsr soft80.soft80_scroll
    clear_row(17)
#endif
    jmp update_dsp

update_dsp:
    soft80_pos_(0, 17)
    clear_row(17)
    ldy #$00
    lda (currptr), y
    tay
!:  lda (currptr), y
#if !EXT80COLS
p1: sta newentrypos - 1, y  // modified operand dep. 1 or 2 lines
#endif
    dey
    save_regs()
    jsr soft80_cputc
    restore_regs()
    cpy #$00
    bne !-
    lda (currptr), y        // length
    clc
    adc #$01                // byte for len
    clc 
    adc currptr
    sta currptr
    lda #$00
    adc currptr + 1
    sta currptr + 1
    cmp16_(currptr, msgbuf + buflen)
    bcc !+
    poke16_(currptr, msgbuf)
    //jsr soft80_crlf
!:
    rts

#if !TEST_IRC
send_msg:
    ldy rcvbuffer
    cpy #$00
    bne !+
    rts
!:  
    iny
    sty tlen
    lda #$00
    sta tlen + 1        // highbyte of len to be sent alway 0 as input < 80 chars
    lda #$a0            // end-marker $a0, as 0 is char '@' in screencode
    sta rcvbuffer, y
!:  
    lda rcvbuffer, y
    sta cmd_args - 1, y // -1 to copy just data
    dey
    bne !-
    uport_write(cmd_args, tlen)
    rts
#endif

}

