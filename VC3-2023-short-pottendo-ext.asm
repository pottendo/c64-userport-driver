BasicUpstart2(m)
m:	ldx #(t-d + 1) * 3 - 1
	ldy #(t-d-1)
l:	lda #'*'
p:	sta $0400 + 5 * 40 + 13
	lda d,y
	dey
	bpl !+
	ldy #(t-d-1)
!:	dex
	bmi !+
	adc p+1
	sta p+1
	lda #0
	adc p+2
	sta p+2
	bne l
!:	bmi *
d: 	.byte 27, 2, 4, 2, 4, 2, 25, 4, 2, 4, 2, 4, 23, 6, 6, 6, 23, 4, 2, 4, 2, 4, 25, 2, 4, 2, 4, 2, 27, 6, 6
t: