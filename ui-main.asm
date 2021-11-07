//.file [name="ui.prg", segments="_main, _cmds, _screen, _par_drv, _pottendo_utils, _data, _sprites"]
.filenamespace main_

BasicUpstart2(main_entry)

#import "globals.asm"
#import "pottendos_utils.asm"
#import "cmds.asm"

// .segment _main
main_entry:
    memset(gl.dest_mem, 0, $2000)
    memset(gl.dest_mem + $3c00, $bc, $400)
    memcpy(gl.vic_base + $2000, sprites.start, sprites.end - sprites.start) // move sprite data to matching vic address
    //memset($d800, $98, $200)
    poke8_(VIC.BgC, 0)
    // enable SP2 as another digital output
    poke16_(CIA2.TIA, $0001)        // load timer to enable shift
    //clearbits(CIA2.CRA, %10101110)  // needed that this works?!
    poke8_(CIA2.CRA, 0)
    setbits(CIA2.CRA, %01010001)    // shift->send, force load and enable timer in continous mode
    poke8_(CIA2.SDR, $ff)           // send %11111111, to start output

    show_screen(1, str.screen1)
    jsr prep_sprites
    jsr loopmenu
exit:
    rts

loopmenu:
    //jsr get_jst
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
    memset(gl.dest_mem, 0, 8000)
    rts
cmd5:
    print(str.inputnumber)
    rnum(cmd_args)
    sta loopc
    poke16_(cmd_args, (1024 * 4) - 1)
!:  jsr dump
    dec loopc
    bne !-
    rts
cmd6:
    sbc16(lu, $18, tmp)
    poke16(cmd_args, tmp)
    sbc8(lu + 6, $32, tmp)    
    poke8(cmd_args + 2, tmp)

    sbc16(rl, 24 - $18, tmp)  // -border($18) + spr-width(24px)
    poke16(cmd_args + 3, tmp)
    sbc8(rl + 6, 11, tmp)            // -border($32) + spr-height(21px)
    poke8(cmd_args + 5, tmp)
    jsr mandel
    rts
cmd7:
    lda CIA2.SDR
    bne unset
    poke8_(CIA2.SDR, $ff)
    poke8_(VIC.BoC, GREEN)
    rts
unset:
    poke8_(CIA2.SDR, $00)
    poke8_(VIC.BoC, RED)
    rts
cmd9:
    print(str.finished)
    pla         // clear stack from last return address
    pla
    jmp exit
lastcmd:
    rts

prep_sprites:
    sprite(0, "on")
    sprite(7, "on")

    sprite_sel_(0, 0)
    sprite_sel_(7, 1)
    rts

decx:
    lda selstate
    cmp #$02
    bne !+
    sprite_move("left", lu)
    rts
!:  
    sprite_move("left", rl)
    rts
incx:
    lda selstate
    cmp #$02
    bne !+
    sprite_move("right", lu)
    rts
!:
    sprite_move("right", rl)
    rts  
decy:
    lda selstate
    cmp #$02
    bne !+
    sprite_move("up", lu)
    rts
!:
    sprite_move("up", rl)
    rts
incy:
    lda selstate
    cmp #$02
    bne !+
    sprite_move("down", lu)
    rts
!:
    sprite_move("down", rl)

    rts
    
fire:
    dec selstate
    beq shipit 
    rts 
shipit:
    inc VIC.BoC
    lda #$02
    sta selstate
    jsr cmd6
    rts

get_jst:
    on_joy("left", decx)
    on_joy("right", incx)
    on_joy("up", decy)
    on_joy("down", incy)
    on_joy("fire", fire)
    sprite_pos(0, lu, lu + 6)
    sprite_pos(7, rl, rl + 6)
    rts
    
cmd_vec:
    cmdp('0', cmd0)
    cmdp('1', cmd1)
    cmdp('2', cmd2)
    cmdp('3', cmd3)
    cmdp('4', cmd4)
    cmdp('5', cmd5)
    cmdp('6', cmd6)
    cmdp('7', cmd7)
    cmdp('9', cmd9)
    cmdp($ff, lastcmd)

.macro cmdp(c, addr)
{
    .byte c
    .word addr
}

// .segment _data

cmd3_:  .text "COMMAND 3"
        .byte $0d, $00
scrstate:   .byte $00
scrfill:    .byte $00
loopc:      .byte $00
selstate:   .byte $02
tmp:        .word $0000
// left upper
lu:         .word $0018     // x-coord
            .word $0018     // x-coord lower boundary
            .word $0140     // x-coord upper boundary
            .byte $32       // y-coord
            .byte $32       // y-coord lower boundary
            .byte $e5       // y-coord upport boundry
// right lower
rl:         .word $0141
            .word $0018
            .word $0141
            .byte $e6
            .byte $32
            .byte $e6

.macro sprite_move(action, addr)
{
    .if (action == "left")
    {
        cmp16(addr, addr + 2)
        beq !+
        dec16(addr)
    !:
    }
    .if (action == "right")
    {
        cmp16(addr, addr + 4)
        beq !+
        inc16(addr)
    !:
    }
    .if (action == "up")
    {
        cmp8(addr + 6, addr + 7)
        beq !+
        dec addr + 6
    !:
    }
    .if (action == "down")
    {
        cmp8(addr + 6, addr + 8)
        beq !+
        inc addr + 6
    !:
    }
}
    
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
.text "7) TOGGLE ATN"
.byte $0d
.text "9) EXIT"
.byte $0d
.text "-------------SELECT#"
.byte $0d
.byte $00
}

//.pc=gl.vic_base + $2000   // 8k after vic base
.namespace sprites {
start:
//.segment _sprites [start = gl.vic_base + $2000]
left_upper:
    .fill 6, $ff
    .fill 19, [$c0, $00, $00]
    .byte 0
right_lower:
    .fill 19, [$00, $00, $03]
    .fill 6, $ff
    .byte 0
end:
}
// .print "argaddress: poke " + cmd_args + ",1"

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
.eval testdriver.writeln(@"32 for x = " + gl.dest_mem + " to " + gl.dest_mem + " + l")
.print "argaddress: poke " + cmd_args + ",1"
.print "argaddress: poke " + cmd_args + ",1"
.print "argaddress: poke " + cmd_args + ",1"
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
