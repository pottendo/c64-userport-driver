//
// Groepaz/Hitmen, 12.10.2015
//
// internal constants for the soft80 implementation

#importonce

.label ptr1 = $43
.label ptr2 = $45
.label ptr3 = $47
.label SCREEN_PTR = $d1
.label CURS_X = $d3
.label CURS_Y = $d6
.label KEY_COUNT = $c6
.label KBDREAD = $e5b4
.label CRAM_PTR = $F3
.label RVS = $c7

.label soft80_lo_charset       = $d000
.label soft80_hi_charset       = $d400
.label soft80_vram             = $d800 // ram under i/o
.label soft80_colram           = $d800 // color ram (used for temp. storage)
.label soft80_spriteblock      = $dc00 // 64 bytes reserved for pointer sprite data

// tables for kplot
.label soft80_bitmapxlo        = $dc40       // (80 bytes)
.label soft80_bitmapxhi        = $dc40 + 80  // (80 bytes)
.label soft80_vramlo           = $dc40 + 160 // (25 bytes)
// align to next page for speed
.label soft80_vramhi           = $dd00       // (25 bytes)
.label soft80_bitmapylo        = $dd00 + 25  // (25 bytes)
.label soft80_bitmapyhi        = $dd00 + 50  // (25 bytes)

.label soft80_bitmap           = $e000

.label charsperline            = 80
.label screenrows              = 25

// FIXME: these should match petscii and perhaps come from a common cbm.inc?
.label CH_ESC                  = 95
.label CH_HLINE                = 96
.label CH_CROSS                = 123
.label CH_VLINE                = 125
.label CH_PI                   = 126
.label CH_LTEE                 = 171
.label CH_URCORNER             = 174
.label CH_LLCORNER             = 173
.label CH_ULCORNER             = 176
.label CH_BTEE                 = 177
.label CH_TTEE                 = 178
.label CH_RTEE                 = 179
.label CH_LRCORNER             = 189

//-------------------------------------------------------------------------------
// set to 0 to disable the color-ram "voodoo" for debugging purposes
#define SOFT80COLORVOODOO
// set to 0 to disable special case optimization for the "space" character
#define SOFT80FASTSPACE
// standalone testprogram
//#define SOFT80STANDALONE
