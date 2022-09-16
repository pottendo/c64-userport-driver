#import "pottendos_utils.asm"

.namespace reu {

.label status       = $df00
.label cmd          = $df01     // Bit 7:     EXECUTE  (1 = transfer per current configuration)
                                // This bit must be set to execute a command.
                                // Bit 6:     reserved  (normally 0)
                                // Bit 5:     LOAD  (1 = enable autoload option)
                                //      With autoload enabled the address and length registers (see below) will be unchanged after a command execution.
                                //      Otherwise the address registers will be counted up to the address off the last accessed byte of a DMA + 1,
                                //      and the length register will be changed (normally to 1).
                                // Bit 4:     FF00
                                // If this bit is set command execution starts immediately after setting the command register.
                                // Otherwise command execution is delayed until write access to memory position $FF00
                                // Bits 3..2: reserved  (normally 0)
                                // Bits 1..0: TRANSFER TYPE
                                // 00 = transfer C64 -> REU
                                // 01 = transfer REU -> C64
                                // 10 = swap C64 <-> REU
                                // 11 = compare C64 - REU

.label c64_base     = $df02     // 16 bit address
.label reu_base     = $df04     // 16 bit address
.label bank         = $df06     // bank bit 0..2 -> up to 512kB
.label xfer_size    = $df07     // 16 bit length
.label isr_reg      = $df09     // Bit 7:     INTERRUPT ENABLE  (1 = interrupt enabled)
                                // Bit 6:     END OF BLOCK MASK  (1 = interrupt on end)
                                // Bit 5:     VERIFY ERROR  (1 = interrupt on verify error), Bits 4..0: unused (normally all set)
.label addr_ctrl    = $df0a     // $DF0A: ADDRESS CONTROL REGISTER
                                // Controlls the address counting during DMA. If an address is fixed, not a memory block but always the same
                                // byte addressed by the base address register is used for DMA.
                                // Bit 7:     C64 ADDRESS CONTROL  (1 = fix C64 address)
                                // Bit 6:     REU ADDRESS CONTROL  (1 = fix REU address), Bits 5..0: unused (normally all set)
_tmp:   .byte $00

check:
    lda #$42
    sta c64_base
    lda c64_base
    cmp #$42
    bne !+
    lda #0
!:
    rts

test:
    jsr check
    beq !+
    rts     // no REU
!:
    inc VIC.BoC
    reu_fill(gl.vic_base, VIC.BoC, 8000)
    rts
}   

.macro reu_prep(bank, dst, src, len)
{
    poke8_(reu.bank, bank)
    poke16_(reu.reu_base, dst)
    poke16_(reu.c64_base, src)
    poke16_(reu.xfer_size, len)
}

.macro reu_out_(bank, dst, src, len)
{
    reu_prep(bank, dst, src, len)
    poke8_(reu.addr_ctrl, 0)
    lda #%10000000;  // c64 -> REU with delayed execution
    sta reu.cmd
}

.macro reu_in_(bank, dst, src, len)
{
    reu_prep(bank, src, dst, len)
    poke8_(reu.addr_ctrl, 0)
    lda #%10000001;  // REU -> c64 with delayed execution
    sta reu.cmd
}

.macro reu_fill(dst, val, len) 
{   
    poke8_(reu.bank, 0)
    poke8(reu._tmp, val)
    poke16_(reu.c64_base, reu._tmp)
    poke16_(reu.reu_base, 0)
    poke16_(reu.xfer_size, 1)
    lda #%10110000;  // c64 -> REU with immediate execution
    sta reu.cmd
    poke16_(reu.xfer_size, len)
    poke16_(reu.c64_base, dst)
    poke8_(reu.addr_ctrl, %01000000)    // hold address in REU
    lda #%10000001;  // REU -> c64 with delayed execution
    sta reu.cmd
}

.macro reu_kick()
{
    lda $ff00
    sta $ff00
}
