#import "globals.asm"
#import "userport-drv.asm"
#import "screen.asm"

// .segment _cmds

// init / close screen
toggle_screen:
    lda cmd_args
    beq !+
    sprite(0, "on")
    sprite(7, "on")
    init_screen(49, 153, main_.get_jst, main_.get_jst)
    jsr screen.mode
    rts
!:  
    //close_screen()
    sprite(0, "off")
    sprite(7, "off")
    jsr screen.rest
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
    poke16_(parport.buffer, cmd_lit)
    jsr parport.start_write
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
    print(gl.dest_mem)
    rts
dump:
    lda #$02
    jsr prep_cmd
    uport_write(cmd_lit, 6)
do_rcv:
    adc16(cmd_args, gl.dest_mem, parport.len)
    poke16_(parport.buffer, gl.dest_mem)    // destination address should match VIC window
    jsr parport.start_isr               // launch interrupt driven read
    //jsr parport.sync_read
    lda parport.read_pending            // busy wait until read is completed
    bne *-3
    rts
read:
    lda #$03
    jmp dump
    rts
mandel:
    lda #$04
    jsr prep_cmd
    uport_write(cmd_lit, 10)    // 4 byte cmd, 2x3byte for coordinates
    poke16_(cmd_args, 8000)
    jsr do_rcv
    rts
    
// numeric int args: max 16bit in little endian format
// string args: '0' as terminator
// commands must have exactly 4 chars
cmd:        .byte $00           // poke the cmd nr. here
cmd_start:
cmd_init:   .text "INIT"        /* INIT<1|0> vic on or off */
cmd_sndstr: .text "ECHO"        /* ECHO<addr> */
cmd_dump:   .text "DUMP"        /* DUMP<len> */
cmd_read:   .text "READ"        
cmd_mandel: .text "MAND"        
cmd_lit:    .fill 4, $00        // here the command is put
cmd_args:   .fill 256, i        // poke the args here
cmd_inv:    .text "INVALID COMMAND."
            .byte $00
