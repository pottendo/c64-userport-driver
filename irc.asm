#import "pottendos_utils.asm"

.namespace irc {
seperator:  .text "----------------------------------------"
            .byte $00
.label inputaddr = $0400 + 23*40
crs:        .byte $00
tlen:       .word $0000
nick:       .fill 16, $00
defnick:    .text "POTTENDO> "
            .byte $00
et:         .text "_quit"
.label msgbuf  = $9000
.label buflen = $0800
.label rcvbuffer = msgbuf + buflen
.label msgptr = $14
.label currptr = $16
.label newentrypos = $0400 + 17 * 40

setup:
    jsr parport.arm_msgcnt  // launch NMI counter for pending msgs
    jsr STD.CLSCR
    poke16_(msgptr, msgbuf)
    poke16_(currptr, msgbuf)
    wstring(0, 22, seperator)
    poke8_(crs, 0)
    memset(inputaddr, ' ', 80)
    memcpy(nick, defnick, 10)
    lda #$0e 
    jsr STD.BSOUT
    set_cursor(0, 23)
    jsr inputloop
    jmp main_.cmd4
    rts
    
inputloop:
    jsr rcv_msgs
    jsr STD.GETIN 
    beq inputloop
    cmp #13
    bne !+
    jsr store_input
    poke8_(crs, 0)
    memset(inputaddr, ' ', 80)
    set_cursor(0, 23)
    jmp inputloop
    rts
!:
    jsr STD.BSOUT
    inc crs
    ldx crs
    cpx #(40+38)
    bne inputloop
    inc VIC.BoC
    lda #0
    sta inputaddr, x
    rts

out:
    poke8_(rcvbuffer, 5)
    memcpy(rcvbuffer+1, et, 5)  // prepare from _quit
    jsr send_msg                // won't arm NMI after write
    uport_stop()
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
    jsr send_msg
    jsr parport.arm_msgcnt
    memcpy_d(rcvbuffer + 10, rcvbuffer, 80)
    memcpy(rcvbuffer + 1, nick, 10)
    lda rcvbuffer
    clc
    adc #10
    sta rcvbuffer
    jsr cpy2msgbuf
    rts

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
    poke16_(msgptr, msgbuf)
!:  pla // recover len to move output canvas
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
    jmp update_dsp

update_dsp:
    ldy #$00
    lda (currptr), y
    tay
!:  lda (currptr), y
p1: sta newentrypos - 1, y  // modified operand dep. 1 or 2 lines
    dey
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
!:
    rts

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
    sta rcvbuffer, y
!:  
    lda rcvbuffer, y
    sta cmd_args - 1, y // -1 to copy just data
    dey
    bne !-
    uport_write(cmd_args, tlen)
    rts
}

