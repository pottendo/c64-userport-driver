#import "pottendos_utils.asm"

.namespace RVCop64 {
    .label rvmem_addr = $de20	
    .label rvmem_data = $de24
    .label rvmem_cmd  = $de25
    .const stash = $03
    .const swap  = $43
    .const fetch = $cc

// pointers to several RAM/ROM sections in coproc.
RAM:    .dword $40000000    // 16MB up to $41000000
SRAM:   .dword $10000000    // 16kB up to $10004000
CSR:    .dword $f0000000    // 64kb up to $f0010000
ROM:    .dword $70000000    // 48kB up to $7000c000

cmd:
    inc VIC.BoC
    rts

doit:
    RVstashSRAM($4000, $2000)
}

.macro RVstashSRAM(s, len) {
    poke32(RVCop64.rvmem_addr, RVCop64.SRAM)
    jmp RVCop64.cmd
}
