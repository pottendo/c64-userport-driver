#import "userport-drv.asm"
#import "screen.asm"

.label dest_mem = $c000
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
    // dump
    jmp dump
!next:
    cmp #$03
    bne !next+
    //read
    jmp read
!next:
test_send:
    uport_write(text, 20 + 16)
    rts
test_rcv:
    uport_read(dest_mem, 20)
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
    ldx #0
    stx parport.len + 1
    ldx #06         // 4 byte cmd + 2 byte leng
    stx parport.len
    poke16(parport.buffer, cmd_lit)
    jsr parport.start_write
do_rcv:
    ldx cmd_args
    stx parport.len
    ldx cmd_args + 1
    stx parport.len + 1
    poke16(parport.buffer, dest_mem)   // destination address should match VIC window
    jsr parport.start_isr       // launsch interrupt driven read
    lda parport.read_pending    // busy wait until read is completed
    bne *-3
    rts
read:
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
cmd_lit:    .fill 4, $00        // here the command is put
cmd_args:   .fill 256, $00      // poke the args here
.print "argaddress: poke " + cmd_args + ",1"
.print "cmdaddress: poke " + cmd + ",1"
.print "run: sys " + main
.print "paste from here =================="
.print "new"
.print @"10 input \"command\"; a$"
.print @"12 c=asc(mid$(a$,1,1))-asc(\"0\")"
.print @"13 if c < 0 or c>3 then print \"invalid command\":print:goto10"
.print "15 poke " + cmd + ",c"
.print "24 r = 1"
.print "25 if c = 0 or c = 1 then gosub 40"
.print "26 if c = 2 or c = 3 then gosub 100"
.print "29 if r = 1 then sys " + main
.print "30 if c <> 3 goto 10"
.print @"32 for x = " + dest_mem + " to " + dest_mem + " + l"
.print "33 if peek(x) = 0 goto 10"
.print "34 print chr$(peek(x));"
.print "35 next x"
.print "39 goto 10"
.print @"40 input \"enter string: \";a$"
.print "45 for i=1 to len(a$)"
.print "50 x=asc(mid$(a$, i, 1))"
.print "55 poke " + cmd_args + "+(i-1),x"
.print "60 next i"
.print "65 poke " + cmd_args + "+(i-1), 0"
.print "70 return"
.print @"100 input \"enter length (read/dump)\"; l"
.print @"105 if l > 32767 then print \"val too high\": err=0 : return"
.print "110 poke " + cmd_args + ", (l and 255)"
.print "120 poke " + cmd_args + " + 1, int(l / 256)"
.print "150 return"
.print "run"

.var testdriver = createFile("testdriver.bas")
.eval testdriver.writeln(@"10 input \"command\"; a$")
.eval testdriver.writeln(@"12 c=asc(mid$(a$,1,1))-asc(\"0\")")
.eval testdriver.writeln(@"13 if c<0 or c>3 then print \"invalid command\":print:goto10")
.eval testdriver.writeln("15 poke " + cmd + ",c")
.eval testdriver.writeln("24 r=1")
.eval testdriver.writeln("25 if c = 0 or c = 1 then gosub 40")
.eval testdriver.writeln("26 if c = 2 or c = 3 then gosub 100")
.eval testdriver.writeln("29 if r = 1 then sys " + main)
.eval testdriver.writeln("30 if c <> 3 goto 10")
.eval testdriver.writeln(@"32 for x = " + dest_mem + " to " + dest_mem + " + l")
.eval testdriver.writeln("33 if peek(x) = 0 goto 10")
.eval testdriver.writeln("34 print chr$(peek(x));")
.eval testdriver.writeln("35 next x")
.eval testdriver.writeln("39 goto 10")
.eval testdriver.writeln(@"40 input \"enter String:\";a$")
.eval testdriver.writeln("45 for i=1 to len(a$)")
.eval testdriver.writeln("50 x=asc(mid$(a$, i, 1))")
.eval testdriver.writeln("55 poke " + cmd_args + "+(i-1),x")
.eval testdriver.writeln("60 next i")
.eval testdriver.writeln("65 poke " + cmd_args + "+(i-1), 0")
.eval testdriver.writeln("70 return")
.eval testdriver.writeln(@"100 input \"enter length (read/dump)\"; l")
.eval testdriver.writeln(@"105 if l > 32767 then print \"val too high\": r=0: return")
.eval testdriver.writeln("110 poke " + cmd_args + ", (l and 255)")
.eval testdriver.writeln("120 poke " + cmd_args + " + 1, int(l / 256)")
.eval testdriver.writeln("150 return")
