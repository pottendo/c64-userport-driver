#import "pottendos_utils.asm"

.namespace irc {
seperator:  .text "----------------------------------------"
            .byte $00
.label inputaddr = $0400 + 23*40
crs:        .byte $00
.label rcvbuffer = $0400
.label msgbuf  = $0400 + 19*40 //$9000
.label msgptr = $14

setup:
    jsr parport.arm_msgcnt  // launch NMI counter for pending msgs
    jsr STD.CLSCR
    poke16_(msgptr, msgbuf)
    wstring(0, 22, seperator)
    poke8_(crs, 0)
    memset(inputaddr, ' ', 80)
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
    ldx crs
    //sta inputaddr, x
    jsr STD.BSOUT
    inx
    stx crs
    cpx #(40+38)
    bne inputloop
    inc VIC.BoC
    lda #0
    sta inputaddr, x
    rts

store_input:
    memcpy_d(rcvbuffer + 80, rcvbuffer, 80 * 5) 

    ldx crs
    stx rcvbuffer
!:  lda inputaddr,x
    sta rcvbuffer + 1, x 
    dex
    bpl !-
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
    ldy rcvbuffer
!:  lda rcvbuffer, y
    sta (msgptr), y
    dey
    bne !-
    lda rcvbuffer   // store length
    sta (msgptr), y
    clc
    adc #$01        // byte for len
    clc 
    adc msgptr
    sta msgptr
    lda #$00
    adc msgptr + 1
    cmp16_(msgptr, msgbuf + 20)
    bcc out
    inc VIC.BoC
    poke16_(msgptr, msgbuf)
out:
    rts
}