#import "pottendos_utils.asm"

.namespace irc {
crs:        .byte $00
inputrow:   .byte 23
tlen:       .word $0000
nick:       .byte 255   // color 
            .fill 16, $00
#if EXT80COLS
.encoding "petscii_mixed"
defnick:    .byte 254   // revers ib
            .text "pottendosC64"
            .byte 254   // revers off
            .text ">"
seperator:  .text "-----------------------------------------------------------------> pottendos IRC"
            .byte $00
et:         .text "*qui*"
.encoding "screencode_mixed"
#else
seperator:  .text "----------------------------------------"
            .byte $00
defnick:    .text "pottendo> "
et:         .text "*qui*"
#endif
            .byte $00
_t1:        .byte $00
_t2:        .byte $00
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
    memset_(inputaddr, ' ', 80)
    memcpy(nick + 1, defnick, 16)   // +1 as color is fixed as first byte
#if !EXT80COLS
    jsr STD.CLSCR
    lda #$0e 
    jsr STD.BSOUT
    wstring(0, 22, seperator)
    set_cursor(0, 23)
#else
    jsr soft80.soft80_init
    jsr setup_sprites
    soft80_doio(setup_sprites2)
    soft80_wstring(0, 22, seperator)
    soft80_pos_(0, 23)
#endif
    jsr inputloop
    jsr soft80.soft80_shutdown
    jmp main_.cmd4
    rts

setup_sprites:
    memcpy($c800, parport.sprstart, parport.sprend - parport.sprstart) // move sprite data to matching vic address
    sprite(1, "color_", LIGHT_GREEN)
    sprite(2, "color_", LIGHT_RED)
    sprite_pos_(1, 324, 50)
    sprite_pos_(2, 324, 50)
    rts

setup_sprites2:
    sprite_sel_(soft80_vram, $0800, 1, 0)
    sprite_sel_(soft80_vram, $0800, 2, 1)
    rts

reset_sprites:
    jsr parport.init
    rts

crow:
    clear_row(23)
    rts
    
inputloop:
#if !TEST_IRC
    jsr rcv_msgs
#endif
    jsr STD.GETIN 
    beq inputloop
    cmp #13
    bne !+
st: jsr store_input
#if !EXT80COLS
    set_cursor(0, 23)
#else
    jsr crow
    poke8_(crs, 0)
#endif
    jmp inputloop

    // process individual char
!:
#if !EXT80COLS
    //jsr STD.BSOUT     // BSOUT conflicts with ZP addresses of Soft80
#endif
    cmp #$14            // handle BS
    bne !+
    soft80_delc()
    ldx crs
    beq inputloop
    dec crs
    jmp inputloop
!:
    ldx crs
    sta inputaddr,x
    save_regs()
    soft80_putcxy(crs, inputrow)
    restore_regs()
    inc crs
    ldx crs
    cpx #(40+30)
    beq !+
    jmp inputloop
!:
    //lda #0
    //sta inputaddr, x
    jmp st

out:
    poke8_(rcvbuffer, 5)
    memcpy(rcvbuffer+1, et, 5)  // prepare from _quit
#if !TEST_IRC
    jsr send_msg                // won't arm NMI after write
    uport_stop()
#endif
    poke8_(crs, 0)
    jsr reset_sprites
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
    memcpy_d(rcvbuffer + 16, rcvbuffer, 80)
    memcpy(rcvbuffer + 1, nick, 16)
    lda rcvbuffer
    clc
    adc #16
    sta rcvbuffer
    jsr cpy2msgbuf
    rts

#if !TEST_IRC
rcv_msgs:
    lda parport.pinput_pending
    bne !+
    rts
!:
    ldx #1
    uport_sread_f(rcvbuffer)
    ldx rcvbuffer
    cmp #81                 
    bcc !+                 // larger tan 80
    ldx #80                // truncate to 80
    inc VIC.BoC
!:  uport_sread_f(rcvbuffer + 1)
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
    memset_(newentrypos, ' ', 80)
    lda #(newentrypos - 41)
    sta p1 + 1
    jmp update_dsp
!:  
    memcpy($0400, $0400 + 40, 17 * 40)      // just one line
    memset_(newentrypos, ' ', 80)
    lda #(newentrypos - 1)
    sta p1 + 1
#else
    jsr scroll17
    clear_row(17)
#endif
    jmp update_dsp

update_dsp:
    soft80_pos_(0, 17)
    clear_row(17)
    ldy #$00
    lda (currptr), y
    sta _t1     // store length 
!nb:
    iny         // skip length byte
    lda (currptr), y  // min one char (len 0 must be handled elsewhere)
#if !EXT80COLS
p1: sta newentrypos - 1, y  // modified operand dep. 1 or 2 lines
#else
    cmp #254
    bne !+
    lda RVS 
    eor #$ff
    sta RVS 
    jmp !skp+
!:
    .for(var co = 0; co < 4; co++) {
    cmp #(253 - co)
    bne !+
    lda #((6 << 4) | (15 - co))
    sta soft80_internal_cellcolor
    jmp !skp+
!:
    }
    cmp #255
    bne !+
    lda #((6 << 4) | 1) // white, hardcoded for local user
    sta soft80_internal_cellcolor
    jmp !skp+
!:
    sty _t2
    jsr soft80_cputc
    ldy _t2
!skp:
#endif
    cpy _t1     
    bne !nb-
    inc _t1     // +1 to correct len to cover len byte
    lda _t1     // get length again 
    clc 
    adc currptr // mov curr ptr accordingly
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

scroll17:
    soft80_scroll(17)
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

