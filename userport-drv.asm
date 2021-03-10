BasicUpstart2(entry)

.label CIA2 = $DD00
.label CIA_PORTA = CIA2
.label CIA_PORTB = CIA2 + 1
.label CIA_DIR = CIA2 + 3
.label CIA_ICR = CIA2 + 13
.label CIA_TIA = CIA2 + 4
.label CIA_TIB = CIA2 + 6
.label CIA_CRA = CIA2 + 14
.label CIA_CRB = CIA2 + 15
.label STD_NMI = $fe56
.label NMI = $318
.label dest = $0400
.label buffer = $fe   // pointer to destination buffer

entry:

lda #<dest      // setup destination buffer
ldy #>dest
sta buffer
sty buffer + 1

lda #$00        // direction bit 0 -> input
sta CIA_DIR

lda CIA_PORTA   // set PA2 to high to signal we're ready to receive
ora #%00000100
sta CIA_PORTA

lda CIA_ICR     // clear interrupt flags by reading
lda #%10010000  // set FLAG pin as interrupt source
sta CIA_ICR

lda #<flag_isr  // setup isr for FLAG PIN
sta NMI
lda #>flag_isr
sta NMI + 1

rts

flag_isr:
    save_regs()
 
    lda CIA_ICR
    and #%10000 // FLAG pin interrupt (bit 4)
    bne !+
    jmp STD_NMI
    // receive char now
!:
    lda CIA_PORTA   // set PA2 to low to signal we're busy receiving
    and #%11111011
    sta CIA_PORTA

    set_color(1);
    ldy #$00
    lda CIA_PORTB
    sta (buffer), y
    inc buffer      // just $ff bytes for now

    lda CIA_PORTA   // set PA2 to high to signal we're ready to receive
    ora #%00000100
    sta CIA_PORTA

    // done
    restore_regs()
    rti

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

.macro set_color(col) {
    lda #col
    sta $d020
}