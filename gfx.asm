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

pi80th: .fill 5, 0      // MFLPT format, 5 byte
pi80th_FLPT: .fill 6, 0 // FLPT format, 6 byte
scale: .fill 5, 0       // FP represenatation of C2
scale_FLPT: .fill 6, 0       // FP represenatation of C2
C1: .fill 1, 100        // shift
C2: .fill 1, 100        // scale
cmd_len:    .byte 11   // full command len incl. 4 byte ARIT - minimum 11byte: 4 + 1 + 6 (ARIT + fn# + one arg)

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

    ldy C2
    jsr STD.LUY
    ldx #<scale
    ldy #>scale
    jsr STD.SFAC1
    memcpy_f(scale_FLPT, STD.FAC1, 6)  // store also FLPT format to avoid another converion need

    rts
    
doit:
    ldy #0
    ldx #160
!:  
    save_regs()
    //ldy sine,x    // table driven
    jsr calc_sine   // native 6502 calculated
    jsr plot
    restore_regs()
    dex
    bne !- 
    rts

// this code is borrowed from here
// https://codebase64.org/doku.php?id=base:various_techniques_to_calculate_adresses_fast_common_screen_formats_for_pixel_graphics    
plot:
    lda yaddrlow,y
    clc
    adc xaddrlow,x
    sta P.zpp1

    lda yaddrhigh,y
    adc xaddrhigh,x
    sta P.zpp1+1

    ldy #0
    lda (P.zpp1),y
    ora xmask,x
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
xaddrlow:
    .for (var x = 0; x < 320; x+=8)
    {
        .for (var t = 0; t < 4; t++)
        {
            .var r = <x
            .byte r
        }
    }
xaddrhigh:
    .for (var x = 0; x < 320; x+=8)
    {
        .for (var t = 0; t < 4; t++)
        {
            .var r = >x
            .byte r
        }
    }
xmask:
    .for (var x = 0; x < 320; x+=2)
    {
        .var r1 = (%11 << (6-((x-8) & $7)))
        .byte r1
    }

sine:
    .fill 160, 100 + 100*sin(toRadians(i*360/160)) // Generates a sine curve

// calc C1 + C2 * sin(i * PI/180)
calc_sine:
    txa
    pha
    tay
    jsr STD.LUY
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
    pla
    tax
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