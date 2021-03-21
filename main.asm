#import "userport-drv.asm"
#import "screen.asm"

//BasicUpstart2(main)
*=$2000
main:
    jsr process_cmd
    rts
process_cmd:
    lda cmd
    bne !next+
    // init / close screen
    lda cmd_args
    cmp #48         // ascii code of '0'
    beq !+
    init_screen(49, 153, screen.mode, screen.rest)
    rts
!:  close_screen()
    rts
!next:
    cmp #$01
    bne !next+
    // echo
    jmp send_string
!next:
    cmp #$02
    bne !next+
    jmp dump
!next:
    cmp #$03
    bne !next+
    jmp read
!next:
test_send:
    uport_write(text, 20 + 16)
    rts
test_rcv:
    uport_read($c000, 20)
    rts
text: .text "12345678900987654321DEMOTEXTdemotext"
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
send_string:
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
    rts
dump:
    jsr prep_cmd
    rts
read:
    jsr prep_cmd
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
cmd_args:   .fill 256, $00      // poke the args here
.print "argaddress: poke " + cmd_args + ",1"
.print "cmdaddress: poke " + cmd + ",1"
.print "run: sys " + main
.print "paste from here =================="
.print "new"
.print @"10 input \"command\"; a$"
.print @"12 c=asc(mid$(a$,1,1))-asc(\"0\")"
.print @"13 if c>3 then print \"invalid command\":print:goto10"
.print "15 poke " + cmd + ",c"
.print @"20 input \"arg\";a$"
.print "40 for i=1 to len(a$)"
.print "50 x=asc(mid$(a$, i, 1))"
.print "55 poke " + cmd_args + "+(i-1),x"
.print "60 next i"
.print "65 poke " + cmd_args + " + (i-1), 0"
.print "70 sys " + main
.print "80 print"
.print "100 goto 10"
.print "run"

.var testdriver = createFile("testdriver.bas")
.eval testdriver.writeln(@"10 input \"command\"; a$")
.eval testdriver.writeln(@"12 c=asc(mid$(a$,1,1))-asc(\"0\")")
.eval testdriver.writeln(@"13 if c>3 then print \"invalid command\":print:goto10")
.eval testdriver.writeln("15 poke " + cmd + ",c")
.eval testdriver.writeln(@"20 input \"arg\";a$")
.eval testdriver.writeln("40 for i=1 to len(a$)")
.eval testdriver.writeln("50 x=asc(mid$(a$, i, 1))")
.eval testdriver.writeln("55 poke " + cmd_args + "+(i-1),x")
.eval testdriver.writeln("60 next i")
.eval testdriver.writeln("65 poke " + cmd_args + " + (i-1), 0")
.eval testdriver.writeln("70 sys " + main)
.eval testdriver.writeln("80 print")
.eval testdriver.writeln("100 goto 10")
