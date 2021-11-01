BasicUpstart2(main)
#import "cmds.asm"

main:
    memset(dest_mem, 0, $2000)
    memset(dest_mem + $3c00, $10, $400)
    show_screen(1, str.screen1)
    jsr loopmenu
exit:
    rts

loopmenu:
    jsr STD.GETIN
    beq loopmenu
    ldx #0
!ne:
    cmp cmd_vec,x
    bne !+
    inx
    ldy cmd_vec,x
    sty _s + 1
    inx
    ldy cmd_vec,x
    sty _s+2
_s: jsr $BEEF   // operand modified
    jmp loopmenu
!:
    inx
    inx
    inx
    pha
    lda #$ff    // check if last cmd reached
    cmp cmd_vec,x
    beq !+
    pla
    jmp !ne-
!:
    pla
    jmp loopmenu

cmd0:
    lda scrstate
    eor #$ff
    sta scrstate
    sta cmd_args
    jsr toggle_screen
    rts
cmd1:
    print(str.inputtext)
    rstring(cmd_args)
    jsr echo
    rts
cmd2:
    print(str.inputnumber)
    rnum(cmd_args)
    jsr dump
    rts
cmd3:
    wstring(0, 20, cmd3_)
    rts
cmd4:
    show_screen(1, str.screen1)
    memset(dest_mem, 0, 8000)
    rts
cmd5:
    print(str.inputnumber)
    rnum(cmd_args)
    sta loopc
    poke16(cmd_args, (1024 * 4) - 1)
!:  jsr dump
    dec loopc
    bne !-
    rts
cmd6:
    poke16(cmd_args, 8000)
    jsr mandel
    rts
cmd9:
    print(str.finished)
    pla         // clear stack from last return address
    pla
    jmp exit
lastcmd:
    rts

cmd_vec:
    cmdp('0', cmd0)
    cmdp('1', cmd1)
    cmdp('2', cmd2)
    cmdp('3', cmd3)
    cmdp('4', cmd4)
    cmdp('5', cmd5)
    cmdp('6', cmd6)
    cmdp('9', cmd9)
    cmdp($ff, lastcmd)

.macro cmdp(c, addr)
{
    .byte c
    .word addr
}

cmd0_: .text "COMMAND 0"
.byte $0d, $00
cmd3_: .text "COMMAND 3"
.byte $0d, $00
scrstate: .byte $00
scrfill: .byte $00
loopc: .byte $00

.namespace str {
inputtext:
    .text "TEXT:"
    .byte $00
inputnumber:
    .text "#TO READ:"
    .byte $00
finished: .text "FINISHED."
    .byte $00
invkey: .text "INVALID KEY PRESSED."
    .byte $00

screen1:
.text "0) SCREEN ON/OFF"
.byte $0d
.text "1) ECHO TEXT"
.byte $0d
.text "2) DUMP DATA ESP->C64"
.byte $0d
.text "3) READ"
.byte $0d
.text "4) CLEAR SCREEN"
.byte $0d
.text "5) LOOP RECEIVE"
.byte $0d
.text "6) MANDELBROT"
.byte $0d
.text "9) EXIT"
.byte $0d
.text "-------------SELECT#"
.byte $0d
.byte $00
}

.print "argaddress: poke " + cmd_args + ",1"
.print "cmdaddress: poke " + cmd + ",1"
.print "parport lenaddr: " + parport.len
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
//.print "29 if r = 1 then sys " + 
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
//.eval testdriver.writeln("29 if r = 1 then sys " + process_cmd)
.eval testdriver.writeln("30 if c <> 3 goto 10")
.eval testdriver.writeln(@"32 for x = " + dest_mem + " to " + dest_mem + " + l")
.eval testdriver.writeln("33 if peek(x) = 0 goto 10")
.eval testdriver.writeln("34 print chr$(peek(x));")
.eval testdriver.writeln("35 next x")
.eval testdriver.writeln("39 goto 10")
.eval testdriver.writeln(@"40 input \"enter string:\";a$")
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
