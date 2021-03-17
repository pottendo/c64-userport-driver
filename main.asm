#import "userport-drv.asm"
#import "screen.asm"

BasicUpstart2(main)

main:
    init_screen(49, 153, screen.mode, screen.rest)
    rts
    //uport_read($c000, $1000)
test_send:
    uport_write(text, 20)
    rts
test_rcv:
    uport_read($c000, 20)
    rts
text: .text "12345678900987654321"
