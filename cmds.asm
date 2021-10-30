//BasicUpstart2(main)
//.segment main [outPrg="main.prg", start=$2000]

#import "userport-drv.asm"
#import "screen.asm"

.label dest_mem = $c000

// init / close screen
toggle_screen:
    lda cmd_args
    beq !+
    init_screen(49, 153, screen.mode, screen.rest)
    rts
!:  close_screen()
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
    poke16(parport.buffer, cmd_lit)
    jsr parport.start_write
    dex             // 4 chars command + '0'
    dex
    dex
    dex
    dex
    lda #$0
    sta dest_mem,x      // terminate string
    stx cmd_args
    ldx #0
    stx cmd_args + 1
    jsr do_rcv
    print(dest_mem)
    rts
dump:
    lda #$02
    jsr prep_cmd
    ldx #0
    stx parport.len + 1
    ldx #06         // 4 byte cmd + 2 byte length
    stx parport.len
    //adc16(parport.len, dest_mem, parport.len)
    poke16(parport.buffer, cmd_lit)
    jsr parport.start_write
do_rcv:
    adc16(cmd_args, dest_mem, parport.len)
    poke16(parport.buffer, dest_mem)    // destination address should match VIC window
    jsr parport.start_isr               // launch interrupt driven read
    //jsr parport.sync_read
    lda parport.read_pending            // busy wait until read is completed
    bne *-3
    rts
read:
    jmp dump
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
cmd_lit:    .fill 4, $00        // here the command is put
cmd_args:   .fill 256, i        // poke the args here
cmd_inv:    .text "INVALID COMMAND."
            .byte $00
