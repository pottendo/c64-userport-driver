#import "userport-drv.asm"

BasicUpstart2(main)

main:
    start_isr($0400, $0200)
    rts
chain_main: 
    nop