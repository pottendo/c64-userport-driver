#import "pottendos_utils.asm"

.namespace irc {
seperator:  .text "----------------------------------------"
            .byte $00
    .label inputaddr = $0400 + 23*40
crs:        .byte $00
    .label msgbuffer = $0400
setup:
    jsr parport.arm_msgcnt  // launch NMI counter for pending msgs
    jsr STD.CLSCR
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
    memcpy_d(msgbuffer + 80, msgbuffer, 80 * 5) 

    ldx crs
    stx msgbuffer
!:  lda inputaddr,x
    sta msgbuffer + 1, x 
    dex
    bpl !-
    rts

rcv_msgs:
    lda parport.pinput_pending
    beq out
    inc VIC.BoC
    poke8_(msgbuffer + 1, 0)                // high byte 0, to support 16 bit len in addr - ugly misuse but efficient
    uport_read_(msgbuffer, 1)
    uport_read(msgbuffer + 1, msgbuffer)    // len is stored here
    dec parport.pinput_pending
    jsr parport.arm_msgcnt
out:
    rts
}