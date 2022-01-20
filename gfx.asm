#import "pottendos_utils.asm"
#import "globals.asm"

.namespace gfx {

// uC math fn codes
.label uCFADD = %00010000
.label uCFSUB = %00100000
.label uCFMUL = %00110000
.label uCFDIV = %01000000
.label uCFSIN = %01010000

pi80th: .fill 5, 0
scale: .fill 5, 0       // FP represenatation of C2
C1: .fill 1, 100        // shift
C2: .fill 1, 100        // scale

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
    jsr STD.FAC2STR
    jsr $ab1e

    ldy C2
    jsr STD.LUY
    ldx #<scale
    ldy #>scale
    jsr STD.SFAC1

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
    lda #<pi80th
    ldy #>pi80th
    jsr STD.FMUL
    jsr STD.SIN
    lda #<scale   
    ldy #>scale
    jsr STD.FMUL
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

calc_sine_uc:
    lda #<STD.PI
    ldy #>STD.PI
    jsr STD.LFAC1
    memcpy_f(cmd_args + 1, STD.FAC1, 6)
    lda #uCFSIN 
    sta cmd_args
    jsr do_arith
    memcpy_f(STD.FAC1, gl.dest_mem, 6)

    ldy #1
    jsr STD.LUY
    memcpy_f(cmd_args + 1, STD.FAC1, 6)
    lda #uCFSIN 
    sta cmd_args
    jsr do_arith
    memcpy_f(STD.FAC1, gl.dest_mem, 6)
    
    rts
}
