//
// Groepaz/Hitmen, 11.10.2015
//
// high level implementation for the soft80 implementation
//
// char cgetc (void)//
//

#import "soft80.inc"
cursor: .byte $00

soft80_cgetc:
        lda     KEY_COUNT       // Get number of characters
        bne     L3             // Jump if there are already chars waiting

        sec
        jsr     invertcursor    // set cursor on or off accordingly

L1:     lda     KEY_COUNT       // wait for key
        beq     L1

        clc
        jsr     invertcursor    // set cursor on or off accordingly

L3:     jsr     KBDREAD         // Read char and return in A
        ldx     #0
        rts

// Switch the cursor on or off (invert)

invertcursor:
        lda     cursor
        bne     invert
        rts
invert:

        sei
        lda     $01             // enable RAM under I/O
        pha
        lda     #$34
        sta     $01

        // do not use soft80_putcolor here to make sure the cursor is always
        // shown using the current textcolor without disturbing the "color voodoo"
        // in soft80_cputc
        ldy     #0
        bcs     set
        // restore old value
        lda     soft80.tmp1
        bcc     lp0
set:
        // save old value
        lda     (CRAM_PTR),y    // vram
        sta     soft80.tmp1
        lda     soft80_internal_cellcolor
lp0:
        sta     (CRAM_PTR),y    // vram
        ldx     soft80_internal_cursorxlsb
        ldy     #7
!:
        lda     (SCREEN_PTR),y
        eor     nibble,x
        sta     (SCREEN_PTR),y
        dey
        bpl     !-

        pla
        sta     $01             // enable I/O
        cli
        rts

nibble: .byte $f0, $0f

