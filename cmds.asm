#import "globals.asm"
#import "userport-drv.asm"
#import "screen.asm"

// .segment _cmds

// init / close screen
toggle_screen:
    lda cmd_args
    beq !+
    poke8_(VIC.BgC, BLACK)
    sprite(0, "on", -1)
    sprite(7, "on", -1)
    //init_screen(49, 153, noop, noop)
    jsr screen.mode
    rts
!:  
    //close_screen()
    sprite(0, "off", -1)
    sprite(7, "off", -1)
    jsr screen.rest
    poke8_(VIC.BgC, BLUE)
    rts

noop:
    rts
    
prep_cmd:
    tax     // cmd nr now in x
    lda #0
    clc
!:  adc #4  // all commands have exactly 4 chars
    dex
    bne !-
    tax
    ldy #0
!:
    lda cmd_start,x
    sta cmd_lit,y
    inx
    iny
    cpy #4 
    bne !-
    rts

echo:
    lda #$1
    jsr prep_cmd
    ldx #0
    stx parport.len + 1
    ldx #4
!l: lda cmd_lit,x
    beq !+
    inx
    jmp !l-
!:  inx             // send also the '0' char
    stx parport.len
    stx cmd_tmp
    poke16_(parport.buffer, cmd_lit)
    jsr parport.write_buffer
    ldx cmd_tmp
    dex             // 4 chars command + '0'
    dex
    dex
    dex
    dex
    lda #$0
    sta gl.dest_mem,x      // terminate string
    stx cmd_args
    ldx #0
    stx cmd_args + 1
    jsr do_rcv
    rts
dump1:
    lda #$02
    jsr prep_cmd
    uport_write_(cmd_lit, 6)
do_rcv:
    uport_read(gl.dest_mem, cmd_args)
    rts
read:
    lda #$03
    jmp dump1
    rts
mandel:
    lda #$04
    jsr prep_cmd
    uport_write_(cmd_lit, 10)    // 4 byte cmd, 2x3byte for coordinates
    poke16_(cmd_args, 8000)
    jsr do_rcv
    rts
dump2:
    lda #$05
    jsr prep_cmd
    uport_write_(cmd_lit, 6)
    // dump back our rcv buffer with requested length
    uport_write(gl.dest_mem, cmd_args)
    rts
irc_:
    lda #$06
    jsr prep_cmd
    uport_write_(cmd_lit, 4)
    rts
    
// numeric int args: max 16bit in little endian format
// string args: '0' as terminator
// commands must have exactly 4 chars
cmd_tmp:    .byte $00
cmd:        .byte $00           // poke the cmd nr. here
cmd_start:
cmd_init:   .text "INIT"        /* INIT<1|0> gfx on or off */
cmd_sndstr: .text "ECHO"        /* ECHO<addr> */
cmd_dump1:  .text "DUM1"        /* DUM1<len> */
cmd_read:   .text "READ"        
cmd_mandel: .text "MAND"        /* MAND<16bx8by> */
cmd_dump2:  .text "DUM2"        /* DUM2<len> */
cmd_irc:    .text "IRC_"        /* IRC_ */
cmd_lit:    .fill 4, $00        // here the command is put
cmd_args:   .fill 256, i        // poke the args here
cmd_inv:    .text "INVALID COMMAND."
            .byte $00
