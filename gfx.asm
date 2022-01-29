#import "pottendos_utils.asm"
#import "globals.asm"

//#define NATIVE_FP

.namespace gfx {

// uC math fn codes
// upper nibble: code of artihmetic function, bit3: 1->MFLPT 0->FLPT, bit-2: #of args
.label uCFADD = %00010010
.label uCFSUB = %00100010
.label uCFMUL = %00110010
.label uCFDIV = %01000010
.label uCFSIN = %01010001
.label uCFCOS = %01010001

pi80th:         .fill 5, 0 // MFLPT format, 5 byte
pi80th_FLPT:    .fill 6, 0 // FLPT format, 6 byte
scale:          .fill 5, 0 // FP represenatation of C2
scale_FLPT:     .fill 6, 0 // FP represenatation of C2
C1:             .byte 100  // y shift
C2:             .byte 100  // y scale
cmd_len:        .byte 11   // full command len incl. 4 byte ARIT - minimum 11byte: 4 + 1 + 6 (ARIT + fn# + one arg)
xwidth:         .word 160  // or 320 for hires - toggled by mc/hr toggle
_xwidth:        .word 160  // or 320 for hires - counter for plot
pixelcol:       .byte $00

_tmp1: .fill 5, 0

dbg: .text "DEBUG: "
.byte $00

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

// acc == 1 -> mc, acc == 0 -> hires
// patch plot function to adjust to MC or Hires mode
toggle_mc:
    cmp #0
    beq !hr+
    poke8_(_p1+1, >xaddrhighmc)
    poke8_(_p2+1, >xaddrhighmc + $ff)
    poke16_(_p3+1, xaddrlowmc)
    poke16_(_p4+1, xaddrhighmc)
    poke16_(_p5+1, xmaskmc)
    poke16_(xwidth, 160)
    poke8_(_d1+1, $03)
    poke16_(_d2+1, xpixelmc)
    rts
!hr:
    poke8_(_p1+1, >xaddrhighhr)
    poke8_(_p2+1, >xaddrhighhr + $ff)
    poke16_(_p3+1, xaddrlowhr)
    poke16_(_p4+1, xaddrhighhr)
    poke16_(_p5+1, xmaskhr)
    poke16_(xwidth, 320)
    poke8_(_d1+1, $07)
    poke16_(_d2+1, xpixelhr)
    rts

doit:
    ldy C2
    jsr STD.LUY
    ldx #<scale
    ldy #>scale
    jsr STD.SFAC1
    memcpy_f(scale_FLPT, STD.FAC1, 6)  // store also FLPT format to avoid another conversion need
    poke16(_xwidth, xwidth)
!:  
    dec16(_xwidth)
    //ldx _xwidth
    //ldy sine,x    // table driven
    lda _xwidth
_d1:and #$03
    tax
_d2:lda xpixelmc,x
    sta pixelcol

    jsr calc_sine
    jsr plot
    cmp16_(_xwidth, 0)
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
    cmp16(xwidth, gl.dest_mem)
    bcc !out+
    cmp8_(gl.dest_mem + 2, 200)
    bcs !out+
    poke16(_xwidth, gl.dest_mem)
    ldy gl.dest_mem + 2
    lda gl.dest_mem + 3     // col is already shifted into the correct location acc. x-coord
    sta pixelcol
    jsr plot
    rts
!out:
    inc VIC.BoC
    dec VIC.BoC
    rts
    
// this code is borrowed from here
// https://codebase64.org/doku.php?id=base:various_techniques_to_calculate_adresses_fast_common_screen_formats_for_pixel_graphics    
plot:
_p1:lda #>xaddrhighmc
    sta XTBmdf + 2
    lda _xwidth + 1
    beq skipadj

_p2:lda #>xaddrhighmc + $FF
    sta XTBmdf + 2		
skipadj:
    ldx _xwidth
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
    rts

    .var i
yaddrlow:
    .for (var y = 0; y < 200; y++)
    {  
        .var r = <(gl.vic_base + ((y & $07) + (320 * floor(y / 8))))
        .byte r
    }
yaddrhigh:
    .for (var y = 0; y < 200; y++)
    {
        .byte >(gl.vic_base + ((y & $07) + (320 * floor(y / 8))))
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

xpixelmc:
    .byte $c0, $30, $0c, $03
xpixelhr:
    .byte $80, $40, $20, $10, $08, $04, $02, $01

sine:
    .fill 320, 100 + 100*sin(toRadians(i*360/320)) // Generates a sine curve

// calc C1 + C2 * sin(i * PI/180)
calc_sine:
    ldy _xwidth
    lda _xwidth + 1
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
    lda $66         // invert sign
    eor %10000000
    sta $66
    jsr STD.F2INT
    lda C1        
    clc
    adc $65         // F2INT -> BigEndian $68-$65
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