#import "pottendos_utils.asm"
#import "globals.asm"

#define NATIVE_FP

.namespace gfx {

// uC math fn codes
// upper nibble: code of artihmetic function, bit3: 1->MFLPT 0->FLPT, bit-2: #of args
.label uCFADD = %00010010
.label uCFSUB = %00100010
.label uCFMUL = %00110010
.label uCFDIV = %01000010
.label uCFSIN = %01010001
.label uCFCOS = %01010001
.label plPLOT = $14
.label plFLH = $26    // col(1byte), p1(3byte), len(2byte)
.label plFLV = $35    // col, p1, len(1byte)
.label plLINE = $47   // col, p1, p2
.label plFILLSC = $51 // col
.label plFILLR = $67  // col, p1, p2
.label plPLOTR = $77  // col, p1, p2
.label plPLEND = $f0  // end marker

pi80th:         .fill 5, 0 // MFLPT format, 5 byte
pi80th_FLPT:    .fill 6, 0 // FLPT format, 6 byte
scale:          .fill 5, 0 // FP represenatation of C2
scale_FLPT:     .fill 6, 0 // FP represenatation of C2
C1:             .byte 100  // y shift
C2:             .byte 100  // y scale
cmd_len:        .byte 11   // full command len incl. 4 byte ARIT - minimum 11byte: 4 + 1 + 6 (ARIT + fn# + one arg)
#if C128
xwidth:         .word 640  // or 320 for hires - toggled by mc/hr toggle
_x:             .word 640  // or 320 for hires - counter for plot
#else
xwidth:         .word 160  // or 320 for hires - toggled by mc/hr toggle
_x:             .word 160  // or 320 for hires - counter for plot
#endif
_y:             .byte 00
pixelcol:       .byte $01
x1: .word 0
y1: .byte 100
x2: .word 319
y2: .byte 199
dx: .word 0
dy: .word 0
xadd: .word 0
yadd: .word 0
rest: .word 0
lin: .word 0

_tmp1: .fill 5, 0

dbg: .text "DEBUG: "
.byte $00

#if NOTUSED
// working
setup:
    // prepare PI constant
    wstring(0, 20, dbg)
    ldy #<80
    lda #>80
    jsr STD.LINT

    lda #<STD.PI
    ldy #>STD.PI
    jsr STD.FDIV
    ldx #<pi80th
    ldy #>pi80th
    jsr STD.SFAC1
    memcpy_f(pi80th_FLPT, STD.FAC1, 6)  // store also FLPT format to avoid another converion need
    jsr STD.FAC2STR
    jsr $ab1e

    ldy #100    // initialze scale with 100
    sty C2
    rts
#endif

setup:
    // prepare PI constant
    wstring(0, 20, dbg)

    lda #<STD.PI
    ldy #>STD.PI
    jsr STD.LFAC1
    jsr STD.MOVFAC1FAC2
    ldy #<80
    lda #>80
    jsr STD.LINT
    jsr STD.FDIV
    ldx #<pi80th
    ldy #>pi80th
    jsr STD.SFAC1
    memcpy_f(pi80th_FLPT, STD.FAC1, 6)  // store also FLPT format to avoid another converion need
    jsr STD.FAC2STR
    jsr STD.PRTSTR

    ldy #100    // initialze scale with 100
    sty C2
    rts

// acc == 1 -> mc, acc == 0 -> hires
// patch plot function to adjust to MC or Hires mode
toggle_mc:
    cmp #0
    beq !hr+
#if C128

#else    
    poke8_(_p1+1, >xaddrhighmc)
    poke8_(_p2+1, >xaddrhighmc + $ff)
    poke16_(_p3+1, xaddrlowmc)
    poke16_(_p4+1, xaddrhighmc)
    poke16_(_p5+1, xmaskmc)
    poke16_(xwidth, 160)
    poke8_(_d1+1, $03)
    poke16_(_d2+1, xpixelmc11)
    poke16_(_d3 + 1, _d3 + 3)
    /*
    poke16_(x1, 5)
    poke8_(y1, 10)
    poke16_(x2, 159)
    poke8_(y2, 180)
    poke8_(pixelcol, 2)
    jsr fdraw_line_x
    poke8_(pixelcol, 3)
    jsr fdraw_line_y
    */
#endif    
    rts
!hr:
#if C128

#else
    poke8_(_p1+1, >xaddrhighhr)
    poke8_(_p2+1, >xaddrhighhr + $ff)
    poke16_(_p3+1, xaddrlowhr)
    poke16_(_p4+1, xaddrhighhr)
    poke16_(_p5+1, xmaskhr)
    poke16_(xwidth, 320)
    poke8_(_d1+1, $07)
    poke16_(_d2+1, xpixelhr)
    poke16_(_d3 + 1, prep_pcol_)

    /*    
    poke16_(gl.gfx_buf+1, 10)
    poke8_(gl.gfx_buf+3, 10)
    poke16_(gl.gfx_buf+4, 250)
    poke8_(gl.gfx_buf+6, 180)
    poke8_(gl.gfx_buf, 1)
    poke16_(x1, 20)
    poke8_(y1, 20)
    poke16_(x2, 310)
    poke8_(y2, 170)
    poke8_(pixelcol, 1)
    jsr fdraw_line_x
    poke8_(pixelcol, 1)
    jsr fdraw_line_y
    */
#endif
    rts

doit:
    ldy C2
    jsr STD.LUY
    ldx #<scale
    ldy #>scale
    jsr STD.SFAC1
    memcpy_f(scale_FLPT, STD.FAC1, 6)  // store also FLPT format to avoid another conversion need
    poke16(_x, xwidth)
!:  
    dec16(_x)
    //ldx _x
    //ldy sine,x    // table driven
    jsr calc_sine
    jsr prep_pcol
    jsr plot
    cmp16_(_x, 0)
    bne !- 

    lda C2
    sbc8(C2, 10, C2)
    cmp #0
    beq !out+
    jmp doit
!out:
    ldy #100    // reset scale to 100
    sty C2
    rts

plot_pixel:
    cmp16(_x, xwidth)
    bcc !out+
    cmp8_(_y, 200)
    bcs !out+
    jsr prep_pcol    
    jsr plot_
    rts
!out:
    inc VIC.BoC
    dec VIC.BoC
    rts
    
// this code is borrowed from here
// https://codebase64.org/doku.php?id=base:various_techniques_to_calculate_adresses_fast_common_screen_formats_for_pixel_graphics    
plot_:
    ldy _y
#if C128
plot:
    lda _x
    ldx _x + 1
    jmp vdc.set_pixel
#else
plot:
    roms_off()
_p1:lda #>xaddrhighmc
    sta XTBmdf + 2
    lda _x + 1
    beq skipadj

_p2:lda #>xaddrhighmc + $FF
    sta XTBmdf + 2		
skipadj:
    ldx _x
    lda yaddrlow,y
    clc
_p3:adc xaddrlowmc,x
    sta P.zpp1

    lda yaddrhigh,y
XTBmdf:
_p4:adc xaddrhighmc,x
    sta P.zpp1+1

    ldy #0
_p5:lda xmaskmc,x 
    eor #$ff
    and (P.zpp1),y
    ora pixelcol
    sta (P.zpp1),y
    roms_on()
    rts
#endif
    .var i
yaddrlow:
    .for (var y = 0; y < 200; y++)
    {  
        .var r = <(gl.dest_mem + ((y & $07) + (320 * floor(y / 8))))
        .byte r
    }
yaddrhigh:
    .for (var y = 0; y < 200; y++)
    {
        .byte >(gl.dest_mem + ((y & $07) + (320 * floor(y / 8))))
    }

xaddrlowmc:
    .for (var x = 0; x < 320; x+=8)
    {
        .for (var t = 0; t < 4; t++)
        {
            .var r = <x
            .byte r
        }
    }
xaddrhighmc:
    .for (var x = 0; x < 320; x+=8)
    {
        .for (var t = 0; t < 4; t++)
        {
            .var r = >x
            .byte r
        }
    }

xaddrlowhr:
    .for (var x = 0; x < 320; x+=8)
    {
        .for (var t = 0; t < 8; t++)
        {
            .var r = <x
            .byte r
        }
    }
xaddrhighhr:
    .for (var x = 0; x < 320; x+=8)
    {
        .for (var t = 0; t < 8; t++)
        {
            .var r = >x
            .byte r
        }
    }

xmaskmc:
    .for (var x = 0; x < 320; x+=2)
    {
        .var r1 = (%11 << (6-((x-8) & $7)))
        .byte r1
    }

xmaskhr:
    .for (var x = 0; x < 320; x++)
    {
        .var r1 = (%1 << (7-(x & $7)))
        .byte r1
    }

xpixelmc11:
    .byte %11000000, %00110000, %00001100, %00000011
xpixelmc01:
    .byte %01000000, %00010000, %00000100, %00000001
xpixelmc10:
    .byte %10000000, %00100000, %00001000, %00000010
xpixelmc00:
    .byte $0, $0, $0, $0
xpixelhr:
    .byte $80, $40, $20, $10, $08, $04, $02, $01

sine:
    .fill 320, 100 + 100*sin(toRadians(i*360/320)) // Generates a sine curve

prep_pcol:
_d3:jmp * + 3   // operand modified for hr/mc
    lda pixelcol
    cmp #%11
    bne !+
    poke16_(_d2 + 1, xpixelmc11)
    jmp prep_pcol_
!:
    cmp #%10
    bne !+
    poke16_(_d2 + 1, xpixelmc10)
    jmp prep_pcol_
!:
    cmp #%01
    bne !+
    poke16_(_d2 + 1, xpixelmc01)
    jmp prep_pcol_
!:
    cmp #%00
    bne !+
    poke16_(_d2 + 1, xpixelmc00)
!:
prep_pcol_:
    lda _x
_d1:and #$03
    tax
_d2:lda xpixelmc11,x
    sta pixelcol
!out:
    rts

!out_plot:
    ldx #1
//    uport_write_f(dbg)
    rts
do_cmds:
    ldx #1
//    uport_write_f(dbg)
do_cmds_entry:
    ldx #1      // read command
    uport_sread_f(gl.gfx_buf)
    lda gl.gfx_buf 
    cmp #plPLEND
    beq !out_plot-
    cmp #plPLOT
    bne !+
    // plot
    ldx #4
    uport_sread_f(gl.gfx_buf)
    poke8(pixelcol, gl.gfx_buf)
    poke16(_x, gl.gfx_buf + 1)
    ldy gl.gfx_buf + 3
    jsr plot
    jmp do_cmds
!:  
    cmp #plFILLSC
    bne !+
    // fill screen
    ldx #1
    uport_sread_f(gl.gfx_buf)
    memset_(gl.dest_mem, 0, 8000)
    memset(gl.vic_videoram, gl.gfx_buf, $3f8)

    jmp do_cmds
!:
    cmp #plFLH
    bne !+
    // fast line horizontal
    ldx #6
    uport_sread_f(gl.gfx_buf)
    poke8(pixelcol, gl.gfx_buf)
    poke16(x1, gl.gfx_buf + 1)
    poke8(y1, gl.gfx_buf + 3)
    poke16(x2, gl.gfx_buf + 4)
    jsr fdraw_line_x
    jmp do_cmds
!:
    cmp #plFLV
    bne !+
    // fast line vertical
    ldx #5
    uport_sread_f(gl.gfx_buf)
    poke8(pixelcol, gl.gfx_buf)
    poke16(x1, gl.gfx_buf + 1)
    poke8(y1, gl.gfx_buf + 3)
    poke8(y2, gl.gfx_buf + 4)
    jsr fdraw_line_y
    jmp do_cmds
!:
    cmp #plPLOTR
    bne !+
    // draw rectangle
    ldx #7
    uport_sread_f(gl.gfx_buf)
    poke8(pixelcol, gl.gfx_buf)
    poke16(x1, gl.gfx_buf + 1)
    poke8(y1, gl.gfx_buf + 3)
    poke16(x2, gl.gfx_buf + 4)
    poke8(y2, gl.gfx_buf + 6)
    jsr fdraw_line_x
    poke8(pixelcol, gl.gfx_buf)
    jsr fdraw_line_y
    poke8(y1, gl.gfx_buf + 6)
    poke8(pixelcol, gl.gfx_buf)
    jsr fdraw_line_x
    poke16(x1, gl.gfx_buf + 4)
    poke8(y1, gl.gfx_buf + 3)
    poke8(pixelcol, gl.gfx_buf)
    jsr fdraw_line_y
    jmp do_cmds
!:
    cmp #plFILLR
    bne !+
    // fill rectangle
    ldx #7
    uport_sread_f(gl.gfx_buf)
    poke16(x1, gl.gfx_buf + 1)
    poke8(y1, gl.gfx_buf + 3)
    poke16(x2, gl.gfx_buf + 4)
    poke8(y2, gl.gfx_buf + 6)
!_f1:
    poke8(pixelcol, gl.gfx_buf)
    jsr fdraw_line_y
    inc16(x1)
    cmp16(x1, x2)
    bcc !_f1-
    beq !_f1-
    jmp do_cmds
!:
    cmp #plLINE
    bne !+
    // draw line
    ldx #7
    uport_sread_f(gl.gfx_buf)
    poke8(pixelcol, gl.gfx_buf)
    poke16(x1, gl.gfx_buf + 1)
    poke8(y1, gl.gfx_buf + 3)
    poke16(x2, gl.gfx_buf + 4)
    poke8(y2, gl.gfx_buf + 6)
    jsr draw_line
    jmp do_cmds
!:
    // unknown command
    inc VIC.BoC
    //jmp do_cmds
    rts
    
fdraw_line_x:
    poke16(_x, x1)
    poke8(_y, y1)
!:
    jsr prep_pcol
    jsr plot_
    inc16(_x)
    cmp16(_x, x2)
    bcc !-
    beq !-
    rts

fdraw_line_y:
    poke8(_y, y1)
    poke16(_x, x1)
    jsr prep_pcol
!:
    jsr plot_
    inc _y
    cmp8(_y, y2)
    bcc !-
    beq !-
    rts
    
draw_line:
    cld
    sbc16m(x2, x1, dx)
    bpl line1
    eor #$ff
    sta dx + 1
    lda dx
    clc
    eor #$ff
    adc #$01
    sta dx
    bcc !+ 
    inc dx+1
!:  lda #$ff
    sta xadd
    sta xadd + 1
    jmp line2
line1:
    poke16_(xadd, 1)
line2:
    lda dx + 1
    bne line3
    lda dx
    bne line3
    lda #0
    sta rest
    sta rest + 1
    jmp line4
line3:
    lda #$ff
    sta rest
    sta rest + 1 
line4:
    sec
    lda y2 
    sbc y1
    sta dy
    lda #$00
    sbc #$00
    sta dy + 1
    bpl line5
    eor #$ff
    sta dy + 1
    lda dy 
    eor #$ff
    clc 
    adc #$01
    sta dy 
    bcc !+
    inc dy + 1
!:  lda #$ff
    sta yadd
    jmp line6
line5:
    lda #$01
    sta yadd
line6:
    lda dy + 1
    cmp dx + 1
    bcc line7
    lda dy 
    cmp dx
    bcc line7
    lda #$ff
    sta lin 
    jmp line8
line7:
    lda #$01
    sta lin 
line8:
    poke16(_x, x1)
    poke8(_y, y1)
    jsr prep_pcol
    jsr plot_

line9:
    lda y1
    cmp y2
    bne line10
    lda x1
    cmp x2
    bne line10
    lda x1+1
    cmp x2+1
    bne line10
    rts
line10:
    lda rest + 1
    bmi zweig1
zweig2:
    sbc16m(rest, dx, rest)
    clc
    lda y1
    adc yadd
    sta y1
    lda lin 
    bmi line8
    jmp line9
zweig1:
    adc16m(rest, dy, rest)
    adc16m(x1, xadd, x1)
    lda lin
    bmi line9
    jmp line8

// calc C1 + C2 * sin(i * PI/180)
calc_sine:
    ldy _x
    lda _x + 1
#if C128
    jsr STD.PRLFAC1
#endif    
    jsr STD.LSYA

#if NATIVE_FP
    lda #<pi80th
    ldy #>pi80th
    jsr STD.FMUL
    jsr STD.SIN
    lda #<scale   
    ldy #>scale
    jsr STD.FMUL
#else
    memcpy_f(cmd_args + 1, pi80th_FLPT, 6)
    jsr calc_mul_uc
    jsr calc_sin_uc
    memcpy_f(cmd_args + 1, scale_FLPT, 6)
    jsr calc_mul_uc
#endif
    jsr STD.NEG
    jsr STD.F2INT
    lda C1        
    clc
    adc STD.FAC1 + 4 // $65         // F2INT -> BigEndian $62-$65
    tay
    rts

// sin (FAC1)
calc_sin_uc:
    memcpy_f(cmd_args + 1, STD.FAC1, 6)
    lda #uCFSIN 
    sta cmd_args
    lda #11
    sta cmd_len
    jmp do_arith
    rts

// mul FAC1 * (cmd_args +1)
calc_mul_uc:
    memcpy_f(cmd_args + 7, STD.FAC1, 6)
    lda #uCFMUL
    sta cmd_args
    lda #17
    sta cmd_len
    jmp do_arith
    rts

}

#if C128
// VDC Graphics Routines for Commodore 128
// Converted from disassembly to KickAssembler syntax
.namespace vdc {
vdc_init:
    lda #80
    ldx #1
    jsr write_vdc
    lda #25
    ldx #6
    jsr write_vdc

    jsr enable_graphics_clear
    //jsr set_graphics_mode
    lda #$3e
    ldx #26
    jsr write_vdc

    lda #0
    ldx #25
    jsr read_vdc
    and #%11111000
    ora #%00000111
    ldx #25
    jsr write_vdc
    poke16_(x, $0000)
    poke16_(y, 0)

    //lda #$55
    //jsr write_mem
l:  
    lda x
    ldx x+1
    ldy y
    jsr set_pixel
    inc VIC.BoC
    //jmp out
    lda x
    and #7
    cmp #4
    bne !+
    inc y
!:    
    inc x
    bne !+
    inc x+1
!:    
    cmp16_(x, 640)
//    cmp8_(y, 200)
    bne l
    //jsr set_text_mode
    rts

x: .word 0
y: .word 0

write_mem:
    pha
    lda x+1
    ldx #18
    jsr write_vdc
    inx
    lda x
    jsr write_vdc
    pla
    ldx #$1f
    jsr write_vdc
    rts

write_vdc:
    stx $d600              // Register übermitteln
!:  bit $d600              // Teste Status bit
    bpl !-                 // noch nicht
    sta $d601              // Wert übergeben
    rts                    // Rücksprung aus Unterprogramm

read_vdc:
    stx $d600              // Register übergeben
!:  bit $d600              // Teste Status bit
    bpl !-                 // noch nicht
    lda $d601              // Hole aktuellen Registerwert
    rts                    // Rücksprung aus Unterprogramm

set_graphics_mode:
//#if NOTUSED
    ldx #12
    lda #$00
    jsr write_vdc
    inx
    lda #$00
    jsr write_vdc
//#endif
    ldx #$19               // Register 25 auswählen
    lda #$80               // Bit 7 setzen - Grafikmodus
    jsr write_vdc          // Register 25 setzen

    lda #0
    ldx #25
    jsr read_vdc
    and #%11111000
    ora #%00000111
    ldx #25
    jsr write_vdc
    ldx #8                 // reg 8 - interlace control
    lda #%00000001         // 11: on
    jsr write_vdc
    rts

set_text_mode:
    ldx #$19               // Register 25 auswählen
    lda #$47               // ATR-Bit setzen, TXT-Bit löschen
    jsr write_vdc          // Setzen des Textmodus
    rts

clear_screen:
    ldy #$40               // $40 Blöcke
clear_loop:
    ldx #$12               // Register 18 - Update-Hi
    tya                    // Hi-Byte nach Akku
    jsr write_vdc          // Setze Update-Hi
    ldx #$1f               // Register 31 - DATA-Register
    lda #$00               // 0, da gelöscht wird
    jsr write_vdc          // DATA-Register beschreiben
    ldx #$1e               // WORDCOUNT-Register
    lda #$00               // Mit Null belegen
    jsr write_vdc
    dey                    // Erniedrige den Zähler
    bpl clear_loop         // nächsten Block löschen
    rts                    // Rücksprung aus Löschroutine

plot_pixel:
    php                    // Carry: Zeichen für Setzen/Löschen
    lda $fa                // Lo-Byte von X-Koordinate
    sta $fe                // zwischenspeichern
    lsr $fb                // Hi-Byte von X / 2
    ror $fa                // Carry nach Lo-Byte übertragen
    lsr $fb                // s.o.
    ror $fa                // s.o.
    lsr $fb                // ergibt zusammen INT(X/8)
    ror $fa
    lda #$00
    sta $fd
    lda $fc                // Y-Koordinate in Akku merken
    asl $fc                // Y mal zwei
    rol $fd                // Carry übertragen
    asl $fc                // nochmal mal zwei ergibt
    rol $fd                // insgesamt mal 4, plus einmal Y
    adc $fc                // ergibt Y*5.
    sta $fc
    bcc no_carry1          // Kein Übertrag
    inc $fd                // Übertrag nach Hi-Byte
no_carry1:
    ldx #$04               // Es wird jetzt noch 4 mal
multiply_loop:
    asl $fc                // mit zwei multipliziert.
    rol $fd                // ergibt eine Multiplikation mit 16
    dex                    // und 16*5 ergibt 80. Y wird also
    bne multiply_loop      // mit 80 multipliziert.
    lda $fa                // INT(X/8)
    adc $fc                // Addiere zu Y*80
    sta $fc                // und abspeichern
    bcc no_carry2          // Kein Übertrag
    inc $fd                // Übertrag berücksichtigen
no_carry2:
    ldx #$12               // Register 18 - Update-Hi
    lda $fd                // Hi-Byte der errechneten Adresse
    jsr write_vdc          // Wert setzen
    inx                    // Update-Lo
    lda $fc                // Lo-Byte der Adresse
    jsr write_vdc          // Setzen des Lo-Bytes
    ldx #$1f               // DATA-Register
    jsr read_vdc           // Holen des Speicherinhaltes
    pha                    // Rette Wert auf Stack
    lda $fe                // Hole X-Koordinate (Lo)
    and #$07               // Nur der Rest X AND 7 ist wichtig
    tax                    // als Pointer nach X
    pla                    // Hole Speicherwert zurück
    plp                    // Hole Carry zurück
    bcs set_point          // Setzen des Punktes
    and clear_mask,x       // Löschen des Punktes
    bcc write_back
set_point:
    ora set_mask,x         // Setzen des Punktes
write_back:
    pha                    // Rette neuen Wert
    ldx #$12               // Update-Hi
    lda $fd                // Hi-Byte von Zieladresse
    jsr write_vdc          // Setzen des Wertes
    inx                    // Update-Lo
    lda $fc                // Lo-Byte der Adresse
    jsr write_vdc          // Setzen des Lo-Bytes
    ldx #$1f               // DATA-Register
    pla                    // Hole Wert wieder von Stack
    jsr write_vdc          // Setzen des neuen Wertes
    ldx #$12
    jsr read_vdc
    rts

set_mask:
    .byte $80, $40, $20, $10, $08, $04, $02, $01 // Tabelle zum Setzen der Punkte

clear_mask:
    .byte $7f, $bf, $df, $ef, $f7, $fb, $fd, $fe // Tabelle zum Löschen der Punkte

enable_graphics_clear:
    jsr set_graphics_mode
    jmp clear_screen

clear_graphics:
    jmp clear_screen

//copy_charrom:
//    jmp $cec               // Kopieren des CHARROM

clear_pixel:
    clc                    // Lösche Carry für Punkt
    bcc set_pixel_entry    // unbedingter Sprung

set_pixel:
    sec                    // Setze Carry für Punkt

set_pixel_entry:
    sta $fa                // Abspeichern X-Lo
    stx $fb                // Abspeichern X-Hi
    sty $fc                // Abspeichern Y-Koordinate
    jmp plot_pixel         // Punkt setzen/löschen

}
#endif