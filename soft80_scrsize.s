//
// Groepaz/Hitmen, 12.10.2015
//
// lowlevel screensize function for the soft80 implementation
//

#import "soft80.inc"

soft80_screensize:
        ldy     #screenrows
        ldx     #charsperline
        rts
