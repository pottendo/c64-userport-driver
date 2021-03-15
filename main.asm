#import "userport-drv.asm"

BasicUpstart2(main)

main:
    start_isr($0400, 1000)
    rts
chain_main: 
    nop