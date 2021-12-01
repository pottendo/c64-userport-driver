//
// 2017-12-28, Groepaz
//
// char cpeekc (void)//
//

#import "soft80.inc"

soft80_cpeekc:
        jsr     soft80_cpeekchar
        //  0-1F -> A0-BF
        // 20-7F -> 20-7F
        cmp     #$20
        bcs     !sk+
        //clc
        adc     #$a0
!sk:
        ldx     #0
        rts

soft80_cpeekchar:

        sei
        lda #$34
        sta $01

        lda CURS_X
        and #$01

        beq !+
        jmp !l1a+       // jne
!:               
        // test non-inverted character (left side)

        ldx #0
l2aa:
        ldy #0

/*        .repeat 8,line
        lda (SCREEN_PTR),y
        and #$f0
        cmp soft80_hi_charset+(line*$80),x
        bne l2b
        .if (line < 7)
        iny
        .endif
        .endrepeat
*/
        .for (var line = 0; line < 8; line++) {
                lda (SCREEN_PTR),y
                and #$f0
                cmp soft80_hi_charset+(line*$80),x
                bne l2b
                .if (line < 7) {
                        iny
                }
        }
backok:
        lda #$36
        sta $01
        cli
        txa         // return char in A
        ldx #$00    // revers flag
        rts
l2b:
        inx
        cpx #$80
        bne l2aa        // jne

        // test inverted character (left side)

        ldx #0
l2aa2:
        ldy #0

/*        .repeat 8,line
        lda (SCREEN_PTR),y
        and #$f0
        eor #$f0
        cmp soft80_hi_charset+(line*$80),x
        bne l2b2
        .if (line < 7)
        iny
        .endif
        .endrepeat
*/
        .for (var line = 0; line < 8; line++) {
                and #$f0
                eor #$f0
                cmp soft80_hi_charset+(line*$80),x
                bne l2b2
                .if (line < 7) {
                        iny
                }
        }
backokrevers:
        lda #$36
        sta $01
        cli
        txa         // return char in A
        ldx #$01    // revers flag
        rts

l2b2:
        inx
        cpx #$80
        bne l2aa2       // XXX jne

backerr:
        lda #$36
        sta $01
        cli
        ldx #0
        txa
        rts

        // test non-inverted character (right side)

!l1a:
        ldx #0
l1aa:
        ldy #0
/*        .repeat 8,line
        lda (SCREEN_PTR),y
        and #$0f
        eor soft80_lo_charset+(line*$80),x
        bne l2bb
        .if line < 7
        iny
        .endif
        .endrepeat
*/
        .for (var line = 0; line < 8; line++) {
                lda (SCREEN_PTR),y
                and #$0f
                eor soft80_lo_charset+(line*$80),x
                bne l2bb
                .if (line < 7) {
                        iny
                }
        }

        jmp backok
l2bb:
        inx
        cpx #$80
        bne l1aa

        // test inverted character (right side)

        ldx #0
l1aa2:
        ldy #0
/*        .repeat 8,line
        lda (SCREEN_PTR),y
        and #$0f
        eor #$0f
        eor soft80_lo_charset+(line*$80),x
        bne l2bb2
        .if line < 7
        iny
        .endif
        .endrepeat
*/
        .for (var line = 0; line < 8; line++) {
                lda (SCREEN_PTR),y
                and #$0f
                eor #$0f
                eor soft80_lo_charset+(line*$80),x
                bne l2bb2
                .if (line < 7) {
                        iny
                }
        }

        jmp backokrevers
l2bb2:
        inx
        cpx #$80
        bne l1aa2

        jmp backerr

