// VDC Graphics Routines for Commodore 128
// Converted from disassembly to KickAssembler syntax

.namespace vdc_graphics

.pc = $c0c4

jmp enable_graphics_clear ; Einschalten der Grafik + Löschen
jmp clear_graphics        ; Löschen der Grafik
jmp back_to_text          ; Zurück in Textmodus
jmp set_pixel             ; Setzen eines Punktes
jmp clear_pixel           ; Löschen eines Punktes

.pc = $c0f

write_vdc:
    stx $d600              ; Register übermitteln
    bit $d600              ; Teste Status bit
    bpl write_vdc          ; noch nicht
    sta $d601              ; Wert übergeben
    rts                    ; Rücksprung aus Unterprogramm

.pc = $c1b

read_vdc:
    stx $d600              ; Register übergeben
    bit $d600              ; Teste Status bit
    bpl read_vdc           ; noch nicht
    lda $d601              ; Hole aktuellen Registerwert
    rts                    ; Rücksprung aus Unterprogramm

.pc = $c27

set_graphics_mode:
    ldx #$19               ; Register 25 auswählen
    lda #$80               ; Bit 7 setzen - Grafikmodus
    jsr write_vdc          ; Register 25 setzen
    rts

.pc = $c2e

clear_screen:
    ldy #$40               ; $40 Blöcke
clear_loop:
    ldx #$12               ; Register 18 - Update-Hi
    tya                    ; Hi-Byte nach Akku
    jsr write_vdc          ; Setze Update-Hi
    ldx #$1f               ; Register 31 - DATA-Register
    lda #$00               ; 0, da gelöscht wird
    jsr write_vdc          ; DATA-Register beschreiben
    ldx #$1e               ; WORDCOUNT-Register
    lda #$00               ; Mit Null belegen
    jsr write_vdc
    dey                    ; Erniedrige den Zähler
    bpl clear_loop         ; nächsten Block löschen
    rts                    ; Rücksprung aus Löschroutine

.pc = $c46

plot_pixel:
    php                    ; Carry: Zeichen für Setzen/Löschen
    lda $fa                ; Lo-Byte von X-Koordinate
    sta $fe                ; zwischenspeichern
    lda $fb                ; Hi-Byte von X
    lsr                    ; durch zwei
    ror $fa                ; Carry nach Lo-Byte übertragen
    lsr                    ; s.o.
    ror $fa                ; s.o.
    lsr                    ; ergibt zusammen INT(X/8)
    ror $fa
    lda $fc                ; Y-Koordinate in Akku merken
    asl                    ; Y mal zwei
    rol $fd                ; Carry übertragen
    asl                    ; nochmal mal zwei ergibt
    rol $fd                ; insgesamt mal 4, plus einmal Y
    adc $fc                ; ergibt Y*5.
    sta $fc
    bcc no_carry1          ; Kein Übertrag
    inc $fd                ; Übertrag nach Hi-Byte
no_carry1:
    ldx #$04               ; Es wird jetzt noch 4 mal
multiply_loop:
    asl $fc                ; mit zwei multipliziert.
    rol $fd                ; ergibt eine Multiplikation mit 16
    dex                    ; und 16*5 ergibt 80. Y wird also
    bne multiply_loop      ; mit 80 multipliziert.
    lda $fa                ; INT(X/8)
    adc $fc                ; Addiere zu Y*80
    sta $fc                ; und abspeichern
    bcc no_carry2          ; Kein Übertrag
    inc $fd                ; Übertrag berücksichtigen
no_carry2:
    ldx #$12               ; Register 18 - Update-Hi
    lda $fd                ; Hi-Byte der errechneten Adresse
    jsr write_vdc          ; Wert setzen
    inx                    ; Update-Lo
    lda $fc                ; Lo-Byte der Adresse
    jsr write_vdc          ; Setzen des Lo-Bytes
    ldx #$1f               ; DATA-Register
    jsr read_vdc           ; Holen des Speicherinhaltes
    pha                    ; Rette Wert auf Stack
    lda $fe                ; Hole X-Koordinate (Lo)
    and #$07               ; Nur der Rest X AND 7 ist wichtig
    tax                    ; als Pointer nach X
    pla                    ; Hole Speicherwert zurück
    plp                    ; Hole Carry zurück
    bcs set_point          ; Setzen des Punktes
    and clear_mask,x       ; Löschen des Punktes
    jmp write_back
set_point:
    ora set_mask,x         ; Setzen des Punktes
write_back:
    pha                    ; Rette neuen Wert
    ldx #$12               ; Update-Hi
    lda $fd                ; Hi-Byte von Zieladresse
    jsr write_vdc          ; Setzen des Wertes
    inx                    ; Update-Lo
    lda $fc                ; Lo-Byte der Adresse
    jsr write_vdc          ; Setzen des Lo-Bytes
    ldx #$1f               ; DATA-Register
    pla                    ; Hole Wert wieder von Stack
    jsr write_vdc          ; Setzen des neuen Wertes
    rts

set_mask:
    .byte $80, $40, $20, $10, $08, $04, $02, $01 ; Tabelle zum Setzen der Punkte

clear_mask:
    .byte $7f, $bf, $df, $ef, $f7, $fb, $fd, $fe ; Tabelle zum Löschen der Punkte

.pc = $ccd

enable_graphics_clear:
    jsr set_graphics_mode
    jmp clear_screen

.pc = $cd0

clear_graphics:
    jmp clear_screen

.pc = $cd3

back_to_text:
    ldx #$19               ; Register 25 auswählen
    lda #$47               ; ATR-Bit setzen, TXT-Bit löschen
    jsr write_vdc          ; Setzen des Textmodus
    rts

.pc = $cda

copy_charrom:
    jmp $cec               ; Kopieren des CHARROM

.pc = $cdd

clear_pixel:
    clc                    ; Lösche Carry für Punkt
    bcc set_pixel_entry    ; unbedingter Sprung

.pc = $ce0

set_pixel:
    sec                    ; Setze Carry für Punkt

set_pixel_entry:
    sta $fa                ; Abspeichern X-Lo
    stx $fb                ; Abspeichern X-Hi
    sty $fc                ; Abspeichern Y-Koordinate
    jmp plot_pixel         ; Punkt setzen/löschen