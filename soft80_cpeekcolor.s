//
// 2017-12-27, Groepaz
//
// unsigned char cpeekcolor (void)//
//
#import        "soft80.inc"
soft80_cpeekcolor:
        ldy     #0
        lda     (CRAM_PTR),y
        and     #$0f
        ldx     #0
        rts
