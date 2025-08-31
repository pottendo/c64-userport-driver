#import "globals.asm"
#import "userport-drv.asm"
#import "screen.asm"

// .segment _cmds
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
    ldx #6
    uport_write_f(cmd_lit)
do_rcv:
    uport_read(gl.dest_mem, cmd_args)
    rts
cmdread:
    lda #$03
    jsr prep_cmd
    ldx #6
    uport_write_f(cmd_lit)
    uport_sread(gl.dest_mem, cmd_args)
    delay(16)
    roms_off()
    uport_write(gl.dest_mem, cmd_args) // dump back what we read
    roms_on()
    rts
mandel:
    lda #$04
    jsr prep_cmd
    ldx #10         // 4 byte cmd, 2x3byte for coordinates
    uport_write_f(cmd_lit)
    //poke16_(cmd_args, 8000)
    //uport_sread(gl.dest_mem, cmd_args)
    jsr gfx.do_cmds_entry
    rts
dump2:
    lda #$05
    jsr prep_cmd
    ldx #6
    uport_write_f(cmd_lit)
    // dump back our rcv buffer with requested length
    uport_write(gl.dest_mem, cmd_args)
    rts
irc_:
    lda #$06
    jsr prep_cmd
    ldx #4
    uport_write_f(cmd_lit)
    rts
dump3:
    lda #$02
    jsr prep_cmd
    ldx #6
    uport_write_f(cmd_lit)
    uport_sread(gl.dest_mem, cmd_args)
    rts
do_arith:
    lda #$08
    jsr prep_cmd
    ldx gfx.cmd_len
    uport_write_f(cmd_lit)   // XXX be smarter and optimze
    //uport_write(cmd_lit, gfx.cmd_len)
    //poke16_(cmd_args, 6)
    //uport_sread(STD.FAC1, cmd_args) // expect one FLPT result
    ldx #6
    uport_sread_f(STD.FAC1) // expect one FLPT result
    rts

do_espplot:
    lda #$09
    jsr prep_cmd
    ldx #5
    uport_write_f(cmd_lit)
    jsr gfx.do_cmds_entry
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
cmd_read:   .text "READ"        /* READ<len> read from ESP and dump back*/
cmd_mandel: .text "MAND"        /* MAND<16bx8by> */
cmd_dump2:  .text "DUM2"        /* DUM2<len> */
cmd_irc:    .text "IRC_"        /* IRC_ */
cmd_dump3:  .text "DUM3"        /* DUM3<len> - synchronous read*/
cmd_arith:  .text "ARIT"        /* ARIT<fn-code byte><args> - uC math funcs */
cmd_esppl:  .text "PLOT"        /* PLOT<plot# as one byte> */
.align $100 // needed to support optimized write
cmd_lit:    .fill 4, $00        // here the command is put
cmd_args:   .fill 256, i        // poke the args here
cmd_inv:    .text "INVALID COMMAND."
            .byte $00
