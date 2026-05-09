*=$1c01
.word nextline      // pointer to next line
.word 10            // line number
.byte $9e           // SYS token
.byte $20           // space
.text "7182"        // address
.byte 0             // end of line
nextline:
.word 0             // end of BASIC program

main_entry:
    ldx #35
!:    
    jsr read_vdc          // Lese Register 35
    sta vdcregs,x
    dex
    bpl !-                 // Wiederhole für alle Register  
    rts

read_vdc:
    stx $d600              // Register übergeben
!:  bit $d600              // Teste Status bit
    bpl !-                 // noch nicht
    lda $d601              // Hole aktuellen Registerwert
    rts                    // Rücksprung aus Unterprogramm
.align $100
vdcregs: .fill 36, $ff
vdcregs_end: .byte $aa
