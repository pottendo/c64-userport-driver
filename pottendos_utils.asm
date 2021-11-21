#importonce
#import "globals.asm"

.namespace CIA1 {
    .label base = $dc00 
    .label PORTA = base
    .label PORTB = base + 1
    .label DIRA = base + 2
    .label DIRB = base + 3
    .label TIA = base + 4
    .label TIB = base + 6
    .label SDR = base + 12
    .label ICR = base + 13
    .label CRA = base + 14
    .label CRB = base + 15
}

.namespace CIA2 {
    .label base = $dd00 
    .label PORTA = base
    .label PORTB = base + 1
    .label DIRA = base + 2
    .label DIRB = base + 3
    .label TIA = base + 4
    .label TIB = base + 6
    .label SDR = base + 12
    .label ICR = base + 13
    .label CRA = base + 14
    .label CRB = base + 15
}

.namespace STD {
    .label IRQ = $ea31
    .label NMI = $fe56
    .label IRQ_VEC = $314
    .label NMI_VEC = $318
    .label BSOUT = $ffd2
    .label CLSCR = $e544
    .label PLOT = $fff0
    .label GETIN = $ffe4
    .label BASIN = $ffcf
}

.namespace VIC {
    .label base = $d000
    .label MEM = base + $18
    .label IRR = base + $19
    .label IMR = base + $1A
    .label CR1 = base + $11
    .label RASTER = base + $12
    .label SprEnable = base + $15
    .label CR2 = base + $16
    .label SprExpY = base + $17
    .label SprExpX = base + $1D
    .label BoC = base + $20
    .label BgC = base + $21
    .label SprColBase = base + $27
}

// utility functions
// .segment _pottendo_utils 

.namespace P {
    .label zpp1 = $fe    // zero-page general purpose pointers
    .label zpp2 = $fc
_print:             // prints '0' terminated strings from ($fe/$ff) via BSOUT 
    ldy #$0
!:
    lda (zpp1), y
    beq done 
    jsr STD.BSOUT
    inc zpp1
    bne !-
    inc zpp1 + 1
    jmp !-
done: 
    rts

_wscreen:
    ldy #$0
!next:
    lda (P.zpp1),y
    beq !+
    jsr STD.BSOUT
    inc P.zpp1
    bne !next-
    inc P.zpp1 + 1
    jmp !next-
!:
    rts

_readstr:
    ldx #$00
 _nc:
    jsr $E112
    cmp #$0d
    beq !+
_rdst:
    sta $BEEF,x
    inx
    cpx #$ff
    bcc _nc
!:
    rts

_readnum:
    poke16_(P.zpp1, 0)
    sta digitseen   // acc is 0 here
l1:
    jsr STD.BASIN
    bit digitseen
    bmi notfirst
    cmp #' '
    beq l1
notfirst:
    cmp #'0'    // check valid number literal
    bcc ex
    sbc #'0'      
    cmp #10
    bcs ex
    tax         // OK digit 0-9
    lda #$ff
    sta digitseen
    asl P.zpp1
    rol P.zpp1 + 1
    bcs err
    lda P.zpp1 + 1
    sta dezcount
    lda P.zpp1
    asl P.zpp1
    rol P.zpp1 + 1
    bcs err
    asl P.zpp1
    rol P.zpp1 + 1
    bcs err
    adc P.zpp1
    sta P.zpp1
    lda P.zpp1 + 1
    adc dezcount
    sta P.zpp1 + 1
    bcs err
    txa
    adc P.zpp1
    sta P.zpp1
    bcc l2
    inc P.zpp1 + 1
    beq err
l2:
    iny
    cpy #6
    bcc l1
err:
    sec
    rts
ex:
    bit digitseen
    bpl err
    clc
    lda P.zpp1
    ldy P.zpp1 + 1
    rts

digitseen:  .byte $00
dezcount:   .byte $00
binaries:   .byte $01, $02, $04, $08, $10, $20, $40, $80
joy_ack:    .byte $01
joyaction:  .byte $00
tmp:        .word $0000
}

// macros
.macro save_regs() {
    pha
    txa
    pha
    tya
    pha
} 

.macro restore_regs() {
    pla
    tay
    pla
    tax
    pla
}

.macro poke8_(addr, val) {
    lda #val
    sta addr
}

.macro poke8(addr1, addr2) {
    lda addr2
    sta addr1
}

.macro poke16_(addr, val) {
    lda #<val
    sta addr
    lda #>val
    sta addr + 1
}

.macro poke16(addr1, addr2) {
    lda addr2
    sta addr1
    lda addr2 + 1
    sta addr1 + 1
}

// input best as binary val: e.g. %00010001
.macro setbits(addr, val) {
    lda addr
    ora #val
    sta addr
}
// input best as binary val: e.g. %11101110
.macro clearbits(addr, val) {
    lda addr
    and #val
    sta addr
}

.macro tyx(save) {
    .if (save == 1) pha
    tya
    tax
    .if (save == 1) pla
}

.macro txy(save) {
    .if (save == 1) pha
    txa
    tay
    .if (save == 1) pla
}

.macro deb(c) {
    pha
    lda #c
    sta $0400 + 1000 - 1
    pla
}

// addr, scalar, addr of res-meme
.macro adc16(a, b, res) 
{   
    clc
    lda a
    adc #<b
    sta res
    lda a + 1
    adc #>b 
    sta res + 1
}
// scalar, scalar, addr of res-meme
.macro adc16_(a, b, res) 
{   
    clc
    lda #<a
    adc #<b
    sta res
    lda #>a
    adc #>b 
    sta res + 1
}

.macro adc8(a, b, res)
{
    clc
    lda a
    adc #<b
    sta res
}

// addr, scalar, addr of res-meme
.macro sbc16(a, b, res) 
{
    sec
    lda a
    sbc #<b
    sta res
    lda a + 1
    sbc #>b 
    sta res + 1
}

// addr, scalar, addr of res-meme
.macro sbc8(a, b, res) 
{
    sec
    lda a
    sbc #<b
    sta res
}

// dump acc as bits via BSOUT
.macro dumpbits() 
{
    tax
    ldy #%10000000
    sty $fc
    
    ldy #$8
nb:
    bit $fc
    beq zero
    lda #'1'
    jmp !+
zero:
    lda #'0'
!:
    jsr STD.BSOUT
    dey
    beq !+
    txa
    ror $fc
    jmp nb
    
!: 
    lda #13
    jsr STD.BSOUT
}

// print '0' terminated string via BSOUT
.macro print(loc)
{
    poke16_(P.zpp1, loc)
    jsr P._print
}

.macro cmp16_(a, b)
{
    lda a + 1
    cmp #>b
    bne !+
    lda a
    cmp #<b
!:
}

// compare 16 bit vals a/a+1 vs. b/b+1, 
// check BCC lower, BNE higher, BEQ same
.macro cmp16(a, b)
{
    lda a + 1
    cmp b + 1
    bne !+
    lda a
    cmp b
!:
}

// compare 8 bit in mem with scalar
.macro cmp8_(a, b)
{
    lda a
    cmp #b 
}

// compare 8 bit vars in mem
.macro cmp8(a, b)
{
    lda a
    cmp b 
}

.macro inc16(a)
{
    inc a
    bne !+
    inc a + 1
!:
}

.macro dec16(a)
{
    dec a
    lda a
    cmp #$ff
    bne !+
    dec a + 1
!:
}

.macro show_screen(clscr, what) 
{
    .if (clscr == 1) {
        jsr STD.CLSCR
    }
    lda #<what
    sta P.zpp1
    lda #>what
    sta P.zpp1 + 1
    jsr P._wscreen
}


.macro set_cursor(x, y)
{
    ldx #y
    ldy #x
    clc
    jsr STD.PLOT
}

.macro wstring(x, y, str)
{
    set_cursor(x, y)
    show_screen(0, str)
}

.macro rstring(addr)
{
    lda #<addr
    sta P._rdst + 1
    lda #>addr
    sta P._rdst + 2
    jsr P._readstr
    lda #$00
    sta addr, x
}

.macro rnum(addr)
{
rep:
    jsr P._readnum
    bcc !+
    lda #'?'
    jsr STD.BSOUT
    jmp rep
 !: sta addr
    sty addr + 1
}

// fill memory with val from acc
.macro memset(addr, val, no)
{
    poke16_(P.zpp1, addr)
    adc16(P.zpp1, no, P.zpp2)
    ldy #$00
!l1:
	cmp16(P.zpp1, P.zpp2)
    beq !+
	lda #val
    sta (P.zpp1), y
    inc16(P.zpp1)
    jmp !l1-
!: 
}

.macro memcpy(dst, src, n)
{
    poke16_(P.zpp1, dst)
    poke16_(P.zpp2, src)
    adc16(P.zpp1, n, P.tmp)
    ldy #$00
 l1:
    cmp16(P.zpp1, P.tmp)
    beq !+
    lda (P.zpp2), y
    sta (P.zpp1), y
    inc16(P.zpp2)
    inc16(P.zpp1)
    jmp l1
!:
}

.macro memcpy_d(dst, src, n)
{
.if (n == 0)
    {   
        .error "memcpy with 0 length"
    }
    poke16_(P.tmp, dst)
    adc16_(dst, n-1, P.zpp1)    // 0'th byte is also copied
    adc16_(src, n-1, P.zpp2)
    ldy #$00
 l1:
    lda (P.zpp2), y
    sta (P.zpp1), y
    cmp16(P.zpp1, P.tmp)
    beq !+
    dec16(P.zpp2)
    dec16(P.zpp1)
    jmp l1
!:
}

// Spr# 0-7, "on"/"off"
.macro sprite(sprno, a, b)
{
    .if (a == "on")
    {
        ldx #sprno
        lda P.binaries, x
        ora VIC.SprEnable
        sta VIC.SprEnable
    }
    .if (a == "off")
    {
        ldx #sprno
        lda P.binaries, x
        eor #$ff
        and VIC.SprEnable
        sta VIC.SprEnable
    }
    .if (a == "color")
    {
        ldx #sprno
        lda #b
        sta VIC.SprColBase, x
    }
    .if (a == "expx")
    {
        ldx #sprno
        lda P.binaries, x
        .if (b == "on")
        {
            ora VIC.SprExpX
            sta VIC.SprExpX
        } else {
            eor #$ff
            and VIC.SprExpX
            sta VIC.SprExpX
        }
    }
    .if (a == "expy")
    {
        ldx #sprno
        lda P.binaries, x
        .if (b == "on")
        {
            ora VIC.SprExpY
            sta VIC.SprExpY
        } else {
            eor #$ff
            and VIC.SprExpY
            sta VIC.SprExpY
        }
    }
}

.macro sprite_pos(sprno, x, y)
{
    lda x
    sta VIC.base + sprno * 2    // spr# 1-8
    lda y
    sta VIC.base + sprno * 2 + 1
    ldx #sprno
    lda P.binaries, x
    ldx x + 1
    beq clhb
    ora VIC.base + $10
    sta VIC.base + $10 
    jmp !+
clhb:
    eor #$ff
    and VIC.base + $10
    sta VIC.base + $10
!:
}

// immediate addressing
.macro sprite_pos_(sprno, x, y)
{
    lda #<x
    sta VIC.base + sprno * 2    // spr# 1-8
    lda #<y
    sta VIC.base + sprno * 2 + 1
    ldx #sprno
    lda P.binaries, x
    .if ((x & $ff00) > 0)
    {
        ora VIC.base + $10
        sta VIC.base + $10
    }
    else {
        eor #$ff
        and VIC.base + $10
        sta VIC.base + $10
    }
}

.macro sprite_sel_(sprno, sprptr)
{
    lda #(($2000 + sprptr * 64) / 64)
    sta gl.vic_videoram + $3f8 + sprno
}

// select sprite from acc
.macro sprite_sel_acc(sprno)
{
    sta gl.vic_videoram + $3f8 + sprno
}

.macro on_joy(a, fn)
{
    .if (a == "right"){
        lda CIA1.PORTA
        and #$08
    }    
    .if (a == "left"){
        lda CIA1.PORTA
        and #$04
    }
    .if (a == "down"){
        lda CIA1.PORTA
        and #$02
    }
    .if (a == "up"){
        lda CIA1.PORTA
        and #$01
    }
    bne !+
    jsr fn
    poke8_(P.joyaction, 1)
!: 
}
.macro on_joyfire(a, fn)
{
    .if (a == "fire"){
        lda #$10
        bit CIA1.PORTA
        bne not_pressed
        lda P.joy_ack
        beq out
        jsr fn
        dec P.joy_ack
        jmp out
    not_pressed:
        poke8_(P.joy_ack, 1)
    out:
    }
}