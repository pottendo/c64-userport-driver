BasicUpstart2(m)
m:ldx #95
ldy #30
l:lda #42
p:sta 1237
lda $834,y
dey
bpl !+
ldy #30
!:dex
bmi !+
adc p+1 
sta p+1
lda #0
adc p+2
sta p+2
bne l
!:bmi *
.byte 27,2,4,2,4,2,25,4,2,4,2,4,23,6,6,6,23,4,2,4,2,4,25,2,4,2,4,2,27,6,6
