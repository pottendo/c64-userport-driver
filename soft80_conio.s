//
// Groepaz/Hitmen, 11.10.2015
//
// Low level init code for soft80 screen output/console input
//

#import "soft80.inc"
#if SOFT80STANDALONE
BasicUpstart2(soft80.start_)
#endif
CHARCOLOR:      .byte $01
VIC_BG_COLOR0:  .byte $06
VIC_CLEARCOL:   .byte $66 // set to ((VIC_BG_COLOR0 << 4) | VIC_BG_COLOR0)
soft80_internal_bgcolor:        .byte $00 
soft80_internal_cellcolor:      .byte $00       
soft80_internal_cursorxlsb:     .byte $00

.namespace soft80 {
tmp1: .byte $00
tmp2: .byte $00
tmp3: .byte $00
tmp4: .byte $00

#if SOFT80STANDALONE
{
start_:
        lda #$00
        sta RVS
        jsr soft80_init
        jsr fill_canvas
entry:
!loop:  jsr STD.GETIN
        beq !loop-
        pha
        cmp #'+'
        beq out
        cmp #'-'
        bne !+
        jsr scroll17
        pla
        jmp !loop-
!:      cmp #$14  // backspace
        bne !+
        soft80_delc()
        pla
        jmp !loop-
!:      cmp #$0d
        bne !+
        jsr soft80_cputc
        lda #$0a
!:      jsr soft80_cputc
        pla
        rts
        jmp !loop-
out:
        pla
        jsr soft80_shutdown
        rts

scroll17:
    soft80_scroll(17)
    rts        
}
#endif

soft80_init:
        lda     soft80_first_init
        bne     skp
        jsr     firstinit
skp:
        // the "color voodoo" in other parts of the code relies on the vram and
        // colorram being set up as expected, which is why we cant use the
        // _bgcolor and _textcolor functions here.

        lda     CHARCOLOR       // use current textcolor
        and     #$0F            // make sure the upper nibble is 0s
        sta     CHARCOLOR

        lda     VIC_BG_COLOR0   // use current bgcolor
        and     #$0F
        sta     soft80_internal_bgcolor
        asl     //a
        asl     //a
        asl     //a
        asl     //a
        ora     CHARCOLOR
        sta     soft80_internal_cellcolor

        lda     #$3B            // Bitmap, Screen On, 25line, y-scroll by 3pix
        sta     VIC.CR1         // VIC_CTRL1
//        lda     #$00
//        sta     CIA2.PORTA      // CIA2_PRA
        clearbits(CIA2.PORTA, %11111100)
        lda     #$68            // VideoRam->base + $1800, charset 4*2048
        sta     VIC.VideoAdr    // VIC_VIDEO_ADR
        lda     #$08            // Bitmap, 40 chars, x-scroll 0
        sta     VIC.CR2         // VIC_CTRL2

        jmp     soft80_kclrscr

soft80_shutdown:

        //lda     #$03            // VIC -> Bank0 (0-16k)
        //sta     CIA2.PORTA      // CIA2_PRA
        setbits(CIA2.PORTA, %00000011)
        jmp     $FF5B           // Initialize video I/O

firstinit:
        // copy charset to RAM under I/O
        sei
        lda     $01
        pha
        lda     #$34
        sta     $01

        inc     soft80_first_init

        // soft80_lo_charset and soft80_hi_charset are page-aligned
        ldy     #0
        lda     #<soft80_charset
        ldx     #>soft80_charset
        sta     ptr1
        stx     ptr1+1
        ldx     #>soft80_lo_charset
        sty     ptr2
        stx     ptr2+1
        ldx     #>soft80_hi_charset
        sty     ptr3
        stx     ptr3+1

        ldx     #4
l1:
        lda     (ptr1),y
        sta     (ptr2),y
        asl     //a
        asl     //a
        asl     //a
        asl     //a
        sta     (ptr3),y
        iny
        bne     l1
        inc     ptr1+1
        inc     ptr2+1
        inc     ptr3+1
        dex
        bne     l1

        // copy the kplot tables to ram under I/O
        //ldx     #0             // is 0
l2:
        lda     soft80_tables_data_start,x
        sta     soft80_bitmapxlo,x
        lda     soft80_tables_data_start + (soft80_tables_data_end - soft80_tables_data_start - $0100),x
        sta     soft80_bitmapxlo + (soft80_tables_data_end - soft80_tables_data_start - $0100),x
        inx
        bne     l2

        pla
        sta     $01
        cli
        rts

fill_canvas:
        ldx #4
!l2:    txa
        pha

        ldy #$ff
!l1:    tya
        pha
        jsr soft80_cputc
        pla
        tay
        dey
        bne !l1-
        jsr soft80_crlf
        pla
        tax
        dex
        bne !l2-

        rts
        
// clear row 
clear_row_:
        save_regs()
        sei
        lda     $01
        pha
        lda     #$34
        sta     $01

        ldx #$a0
        lda #$ff
a1:     sta $beef, x
a2:     sta $beef, x
        dex
        bne a1
        
!dovram:
        // $01 == $34 -> vram
        ldx #40
        lda VIC_CLEARCOL
c1:     sta $beef, x
        dex
        bne c1

        inc $01      // $01 == $35 -> now cram
        lda $01
        cmp #$35
        beq !dovram-
!:
        pla
        sta $01
        restore_regs()
        cli
        rts

// the following tables take up 267 bytes, used by kplot
soft80_tables_data_start:

soft80_bitmapxlo_data:
        //.repeat 80,col
        //.byte <((col/2)*8)
        //.endrepeat
        .for(var col = 0; col < 80; col++) .byte <((col/2)*8)
soft80_bitmapxhi_data:
        //.repeat 80,col
        //.byte >((col/2)*8)
        //.endrepeat
        .for(var col = 0; col < 80; col++) .byte >((col/2)*8)
soft80_vramlo_data:
        //.repeat 25,row
        //.byte <(soft80_vram+(row*40))
        //.endrepeat
        .for(var row = 0; row < 25; row++) .byte <(soft80_vram+(row*40))
        .byte 0,0,0,0,0,0,0     // padding to next page
soft80_vramhi_data:
        //.repeat 25,row
        //.byte >(soft80_vram+(row*40))
        //.endrepeat
        .for(var row = 0; row < 25; row++) .byte >(soft80_vram+(row*40))
soft80_bitmapylo_data:
        //.repeat 25,row
        //.byte <(soft80_bitmap+(row*40*8))
        //.endrepeat
        .for(var row = 0; row < 25; row++) .byte <(soft80_bitmap+(row*40*8))

soft80_bitmapyhi_data:
        //.repeat 25,row
        //.byte >(soft80_bitmap+(row*40*8))
        //.endrepeat
        .for(var row = 0; row < 25; row++) .byte >(soft80_bitmap+(row*40*8))

soft80_tables_data_end:

//-------------------------------------------------------------------------------
soft80_first_init:
        .byte 0                 // flag to check first init, this really must be in .data

#import "soft80_charset.s"
#import "soft80_kclrscr.s"
#import "soft80_kplot.s"
#import "soft80_cgetc.s"
#import "soft80_cputc.s"
#import "soft80_color.s"
#import "soft80_scrsize.s"
#import "soft80_cpeeks.s"
#import "soft80_cpeekc.s"
#import "soft80_cpeekcolor.s"
#import "soft80_cpeekrevers.s"
}

#if !REU
.macro soft80_scroll(lines)
{
        sei
        lda     $01
        pha
        lda     #$34
        sta     $01

        // pixel ram
        ldx #$a0
!loop:  .for (var base = (soft80_bitmap - 1); base < ((soft80_bitmap - 1) + (lines*320)); base += 320) {
                lda (base + 320), x             // left half
                sta (base + 0), x
                lda (base + 320 + $a0), x       // right half
                sta (base + $a0), x
        }
        dex
        beq !dovram+
        jmp !loop-
!dovram:
        // $01 == $34 -> vram ram
        ldx #40
!cloop:
        .for (var cbase = (soft80_colram - 1); cbase < ((soft80_colram - 1) + (lines * 40)); cbase += 40) {
                lda (cbase + 40), x
                sta (cbase + 0), x
        }
        dex
        beq !d+
        jmp !cloop-
!d:
        inc $01         // $01 == $35 -> cram
        lda $01
        cmp #$35
        bne !+
        jmp !dovram-
!:
        pla
        sta $01
        cli
}

.macro clear_row(r)
{
        .var a1_ = (soft80_bitmap -1) + r * 320
        .var a2_ = a1_ + 160
        poke16_(soft80.a1+1, a1_)
        poke16_(soft80.a2+1, a2_)
        .var c1_ = (soft80_colram - 1) + r * 40
        poke16_(soft80.c1+1, c1_)
        jsr soft80.clear_row_
}

#else

// REU Speedup
.macro soft80_scroll(lines)
{
        sei
        lda $01
        pha
        reu_out_(1, 0, soft80_bitmap + 320, lines * 320)
        lda #$34
        sta $01
        reu_kick()
        pla
        sta $01
        pha
        reu_in_(1, soft80_bitmap, 0, lines * 320)
        lda #$34
        sta $01
        reu_kick()
        pla
        sta $01
        pha
        reu_out_(2, 0, soft80_colram + 40, lines * 40)
        lda #$34
        sta $01
        reu_kick()
        pla
        sta $01
        pha
        reu_in_(2, soft80_colram, 0, lines * 40)
        lda #$34
        sta $01
        reu_kick()
        pla
        sta $01
        pha
        reu_out_(2, 0, soft80_colram + 40, lines * 40)
        lda #$35
        sta $01
        reu_kick()
        pla
        sta $01
        pha
        reu_in_(2, soft80_colram, 0, lines * 40)
        lda #$35
        sta $01
        reu_kick()
        pla
        sta $01
        cli
}

.macro clear_row(r)
{
        sei
        lda $01
        pha
        lda #$ff
        sta P.zpp1
        reu_fill(soft80_bitmap + (r * 320), P.zpp1, 320)
        lda #$34
        sta $01
        reu_kick()
        pla
        sta $01
        pha
        lda VIC_CLEARCOL
        sta P.zpp1
        reu_fill(soft80_colram + r * 40, P.zpp1, 40)
        lda #$34
        sta $01
        reu_kick()
        pla
        sta $01
        pha
        reu_fill(soft80_colram + r * 40, P.zpp1, 40)
        lda #$35
        sta $01
        reu_kick()
        pla
        sta $01
        cli
}
#endif // REU

// call function with RAM visible - e.g. to set Sprite pointers after vram
.macro soft80_doio(fn)
{
        sei
        lda     $01
        pha
        lda     #$34
        sta     $01
        jsr fn 
        pla
        sta     $01
        cli
}

