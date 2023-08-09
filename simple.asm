BasicUpstart2(main_entry)
main_entry:
    lda #$01
    sta $d020
exit:
    rts