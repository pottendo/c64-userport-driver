
// KickAssembler v5.25 
BasicUpstart2(main_entry)

.encoding "ascii"

.label default_timeout	= $11	// $02 = ~ 1 sec.; adjustable via $ab (z_timeout)
.label z_timeout        = $ab   // length of timeout (1 short, max 255 - real loooong)
.label data_pointer	    = $a7   //  $a7/$a8 adress for data
.label tmp2		        = $a5
.label tmp		        = $a6
.label bytes_send	    = $a9 	
.label z_error		    = z_timeout
.label zpp              = $fe

main_entry:
    lda #$93    // clear screen
    jsr $ffd2

    jsr u_wic64_init
    jsr u_wictest_getip
    beq !+
    jsr get_xmaspage
    rts //jmp *       // stay here
!:  wstring(err_nowic)
    rts

get_xmaspage:
    jsr u_wic64_init
    lda #<pastebin
    ldy #>pastebin
    jsr u_com_out
	ldx #$00
	cpx z_error		    // timeout = No WiC   rts
    beq !+
    lda #<data
    ldy #>data
    jsr pullthis
    lda data
    cmp #'!'
    beq !+
    wstring(data)
    rts
!:
    wstring(err_URL)
    pla                 // get back to basic
    pla
    rts

// routines from universal lib (legacy protocol)
u_wic64_init:
	lda $dd02
	ora #$01
	sta $dd02		    // WiC init
	lda #default_timeout
	sta z_timeout
	rts

u_wictest_getip:
	jsr u_wic64_init
	lda #$02		    // set short timeout
	sta z_timeout
	lda #<com_getip
	ldy #>com_getip
	jsr u_com_out		// send command "get_ip" for testing communication
	ldx #$00
	cpx z_error		    // timeout = No WiC
	beq wtend		
	lda #<data	        // pull IP
	ldy #>data		
	jsr pullthis
	ldx #$00		    // test IP 0.0.0.0?
	stx tmp			    // default "no IP"
	stx tmp2		    // init ora
!:
	lda data, x
	cmp #$2e		    // "."
	beq l1
	ora tmp2
	sta tmp2
l1:
	inx
	cpx bytes_send
	bne !-
	lda tmp2
	cmp #$30
	beq wtend
	inc tmp             // =1 : IP is not 0.0.0.0, WiFi connected
wtend:
	lda z_timeout
	beq l2
	lda #default_timeout    //set default timeout if not 0
	sta z_timeout
l2:	rts

wic64_ESP_read:         // set WiC64 ro 'read-mode'
u_wic64_exit:
	lda $dd0d		
	lda #$ff		    // direction Port B out 
	sta $dd03
	lda $dd00
	ora #$04		    // set PA2 to HIGH = WiC64 ready for reading data from C64
	sta $dd00
	rts

wait_handshake:
	lda z_timeout		// handshake always with timeout
	bne !+
	lda #$01	// if z_error/z_timeout = 0 (timeout accured), shorten the following handshakes
!:	sta c3		// looplength for timeout
	sta c2		// z_timeout * z_timeout
!:	lda $dd0d	// check handshake
	and #$10    // wait for NMI FLAG2
	bne hs_rts 	// handshake ok - return
	dec c1		// inner loop: 256 passes
	bne !-
	dec c2		// outer loops: z_timeout * z_timeout
	bne !-
	dec c3			
	bne !-
	lda #$00	// timeout occurred!
	sta z_error	// $00=timeout, $01-$ff=OK!
hs_rts:
	rts
c1:	nop			// counter 1
c2:	nop			// counter 2
c3:	nop			// counter 3

write_byte:
	sta $dd01	// bits 0..7 parallel to WiC64 (userport PB 0-7)
	jmp wait_handshake

pullthis:
    sta data_pointer
	sty data_pointer+1
u_wic64_pull:
	jsr wic64_pull_strt	    // init retrieving data from WiC64
	bne nonull		        // check for length lobyte=0
	cmp tmp			        // length highbyte=0?
	beq pull_end		    // no bytes 
nonull:
	tax			        // x: counter lowbyte
	beq loop_read		// special case lobyte=0?
	inc tmp			    // +1 for faster check with dec/bne
loop_read:			
	jsr read_byte		// read byte
	sta (data_pointer),y
	iny
	bne !+
	inc data_pointer+1
!:	dex
	bne loop_read		
	dec tmp
	bne loop_read		// all bytes?
pull_end:
    cli
    lda #0              // ATTENTION: this is specific for XMAS -> terminate screen with '0'
    sta (data_pointer), y
	rts		
		
u_com_out:
	sta data_pointer	// set datapointer to lowbyte=A, highbyte=Y
	sty data_pointer+1
u_wic64_push:
	sei
	jsr wic64_ESP_read	
	ldy #$02		
	lda (data_pointer),y	// number of bytes to send (lowbyte)
	sta bytes_send+1
	dey
	lda (data_pointer),y	// number of bytes to send (highbyte)
	tax
	beq !+			        // special case:		lowbyte=0
	inc bytes_send+1
!:	dey			            // y=0		
loop_send:
	lda (data_pointer),y
	jsr write_byte		    // send bytes to WiC64 in loop
	iny
	bne !+
	inc data_pointer+1	
!:	dex
	bne loop_send
	dec bytes_send+1
	bne loop_send				
	cli
	rts

read_byte:
	jsr wait_handshake
	lda $dd01		// read byte from WiC64 (userport)
	rts

wic64_pull_strt:
	sei			    // init reading
	ldy #$00		// set port B to input
	sty $dd03		
	lda $dd00
	and #$fb		// PA2 LOW: WiC in send-mode
	sta $dd00 	
	jsr read_byte	// dummy byte for triggering ESP IRQ
	jsr read_byte	// data length high byte
	sta bytes_send+1
	sta tmp			// counter Hhigh byte
	jsr read_byte	// data length low byte
	sta bytes_send+0	
	rts

_wstring:
    ldy #$0
!:
    lda (zpp), y
    beq done 
    jsr $ffd2
    inc zpp
    bne !-
    inc zpp + 1
    jmp !-
done: 
    rts

pastebin:   .byte 'W',_pastebin - pastebin, $00, $01
            .text "https://pastebin.com/raw/r8yeuQrU"
_pastebin:  .byte 0

err_nowic:  .text "WIC64 NOT FOUND..."
            .byte 0
err_URL:    .text "INVALID URL..."
            .byte 0
com_getip:	.byte 'W', $04 , $00, $06

data: .byte $00

.macro wstring(ptr) 
{
    lda #<ptr
    sta zpp
    lda #>ptr
    sta zpp + 1
    jsr _wstring
}
