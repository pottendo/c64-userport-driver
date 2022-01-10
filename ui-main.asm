//.file [name="ui.prg", segments="_main, _cmds, _screen, _par_drv, _pottendo_utils, _data, _sprites"]
.filenamespace main_

BasicUpstart2(main_entry)
//#define TEST_IRC
#define EXT80COLS

#import "globals.asm"
#import "pottendos_utils.asm"
#import "cmds.asm"
#import "soft80_conio.s"
#import "irc.asm"

// .segment _main
main_entry:
    jsr parport.init
    memset(gl.dest_mem, 0, $2000)
    memset(gl.dest_mem + $3c00, $bc, $400)
    jsr prep_sprites
    //memset($d800, $98, $200)
    //poke8_(VIC.BgC, 0)

    show_screen(1, str.screen1)
    jsr loopmenu
exit:
    rts

loopmenu:
    jsr get_jst
    jsr delay
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
    jsr dump1
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
!:  jsr dump3
    jsr delay
    dec loopc
    bne !-
    rts
cmd6:
    sbc16(lu, $18, tmp)
    poke16(cmd_args, tmp)
    sbc8(lu + 6, $32, tmp)    
    poke8(cmd_args + 2, tmp)

    sbc16(rl, 24 - $18 * 2, tmp)  // -border($18) + spr-width(24px)
    poke16(cmd_args + 3, tmp)
    sbc8(rl + 6, 31*0 + 8, tmp)     // -border($32) + spr-height(21px)
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
cmd8:
    print(str.inputnumber)
    rnum(cmd_args)
    jsr dump2
    rts

cmdterminal:
    print(str.inputtext)
    uport_lread($0680)

!:  jsr STD.GETIN
    beq !-
    cmp #$0d
    beq !+
    jsr STD.BSOUT

    jmp !-
!:
    uport_stop()
    show_screen(1, str.screen1)
    rts
    
cmdirc:
#if !TEST_IRC
    jsr irc_
#endif
    jsr irc.setup
    rts

cmdsyncread:
    print(str.inputnumber)
    rnum(cmd_args)
    jsr dump3
    rts

cmd9:
    print(str.finished)
    pla         // clear stack from last return address
    pla
    jmp exit
lastcmd:
    rts

prep_sprites:
    memcpy(gl.vic_base + $2000, sprites.start, sprites.end - sprites.start) // move sprite data to matching vic address
    sprite_sel_(gl.vic_videoram, $2000, 0, 0)
    sprite_sel_(gl.vic_videoram, $2000, 7, 1)
    rts

decx:
    lda selstate
    cmp #$02
    bne !+
    sprite_move("left", lu)
    rts
!: 
    sbc16(lu, 22*2, P.tmp)
    cmp16(rl, P.tmp)
    beq !+
    sprite_move("left", rl)
!:  rts
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
    sbc8(lu + 6, 19*2, P.tmp)
    cmp8(rl + 6, P.tmp)
    beq !+
    sprite_move("up", rl)
!:  rts
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
    lda #$02
    sta selstate
    jsr cmd6
    rts

get_jst:
    poke8_(P.joyaction, 0)
    on_joy("left", decx)
    on_joy("right", incx)
    on_joy("up", decy)
    on_joy("down", incy)
    on_joyfire("fire", fire)
    sprite_pos(0, lu, lu + 6)
    sprite_pos(7, rl, rl + 6)
    rts

delay:
!:  dec16(delay_loop)
    cmp16_(delay_loop, 0)
    bne !-
    lda P.joyaction
    beq reload
    ldx delay_idx
    lda delays, x
    sta delay_loop + 1
    dex
    lda delays, x
    sta delay_loop
    dex
    cpx #$ff
    bne !+
    ldx #$01
!:  stx delay_idx
    rts
reload:
    poke8_(delay_idx, $07)
    poke16(delay_loop, delays+6)    // back to start
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
    cmdp('8', cmd8)
    cmdp('9', cmd9)
    cmdp('T', cmdterminal)
    cmdp('I', cmdirc)
    cmdp('S', cmdsyncread)
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
delay_loop: .word $0400
delays:     .word $100, $800, $800, $1000
delay_idx:  .byte $7
// left upper
lu:         .word $0018         // x-coord
            .word $0018         // x-coord lower boundary
            .word $18 + 320 - 1 // x-coord upper boundary: border + 320 - 1
            .byte $32           // y-coord
            .byte $32           // y-coord lower boundary: border
            .byte $32 + 200 - 1 // y-coord upper boundry: border + 200 - 1
// right lower
rl:         .word $18 + 320 - 24*2 // x-coord
            .word $0018 - 24*2 + 1 // x-coord lower boundary: border - sprw + 1
            .word $18 + 320 - 24*2 // x-coord upper boundary: border + 320 - sprw
            .byte $32 + 200 - 21*2 // ycoord
            .byte $32 - 21*2 + 1   // ycoord lower boundary: border - sprw + 1
            .byte $32 + 200 - 21*2 // ycoord upper boundary: border + 200 - sprh

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
.text "8) DUMP DATA C64->ESP"
.byte $0d
.text "T) TERMINAL"
.byte $0d
.text "I) IRC"
.byte $0d
.text "S) SYNC READ"
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
    .fill 3, $ff
    .fill 20, [$80, $00, $00]
    .byte 0
right_lower:
    .fill 20, [$00, $00, $01]
    .fill 3, $ff
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
