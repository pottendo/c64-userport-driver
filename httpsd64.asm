if .p
	t	"TopSym"
	t	"TopMac"

:scrnbase = $0400
:scrnbuf1 = $0500
:scrnbuf2 = $0600

; BUILD_MODES:

:BUILD_HTTP  = %00010000
:BUILD_HTTPS = %00100000

:BUILD_MODE  = BUILD_HTTPS
endif

if BUILD_MODE = BUILD_HTTP
	n	"VIEWD64-25H"
endif
if BUILD_MODE = BUILD_HTTPS
	n	"VIEWD64-25S"
endif

	c	"VIEWKOALA   V1.0",NULL
	o	$0801 -2
	f	BASIC


:basic	w $0801
	w $080c
	w $000a
	b $9e,$20,$32,$30,$36,$34,$00
	w $0000
	w $0000

; Bildschirm löschen
:MAININIT	lda	#$0e	; Screen colors
	sta	$d020
	sta	$02
	lda	#$06
	sta	$d021

	lda	#$0e	; Text color
	sta	$0286 

	jsr	$e544	; Clr screen

:startfile00	lda	#"0"	; Auf erstes Bild zurücksetzen
	sta	scrnbase +0
	sta	scrnbase +1
	sta	scrnbase +2

:loader	jsr	LoadHTTP
	cmp	#$00
	beq	loaded	; Server meldet keinen Ladefehler 
      
	ldy	#$80
:whirl1	ldx	#$ff
:whirl2	inc	$d020	; Ladefehler optisch anzeigen
	dex
	bne	whirl2
	dey
	bne	whirl1

	lda	$02
	sta	$d020

:loaded	jmp	$a474

:LoadHTTP	lda	#$ff	; Datenrichtung Port B Ausgang
	sta	$dd03
	lda	$dd00
	ora	#$04	; PA2 auf HIGH = ESP im Empfangsmodus
	sta	$dd00
    
	jsr	send_string	; http://irgendwas an den ESP Senden
    
	lda	#$00	; Datenrichtung Port B Eingang
	sta	$dd03 
	lda	$dd00
	and	#251	; PA2 auf LOW = ESP im Sendemodus
	sta	$dd00


    
	jsr	read_byte	; Dummy Byte
			; um IRQ im ESP anzuschubsen


; $25 = LARGE/GET: 4 Bytes
	jsr	read_byte
	sta	1020
	sta	$fa
	jsr	read_byte
	sta	1021
	sta	$fb	; Laenge Datenuebertragung Byte 1 und 2

	jsr	read_byte
	sta	1022
	sta	$68
	jsr	read_byte
	sta	1023
	sta	$69	; Laenge Datenuebertragung Byte 3 und 4

 
:loaderrorcheck	lda	$fa
	cmp	#$00
	bne	noloaderror
	lda	$fb
	cmp	#$02
	bne	noloaderror

	lda	$69
	cmp	#"0"
	bne	noloaderror
	lda	$68
	cmp	#"!"
	bne	noloaderror

; LoadHTTP/Ende
	lda	#$01	; Ladefehler
	rts

:noloaderror


:setloadadress	lda	#< scrnbuf1
	sta	$fc
	lda	#> scrnbuf1
	sta	$fd
	lda	#< scrnbuf2
	sta	$fe
	lda	#> scrnbuf2
	sta	$ff

:startload	ldy	#$00
:goread	jsr	read_byte
	sta	($fc),y
	eor	scrnbase +2
	sta	($fe),y
	iny
	bne	goread

	inc	scrnbase +2	; Blockzaehler im Bildschirm +1
	lda	scrnbase +2
	cmp	#"9" +1
	bne	:1
	lda	#"0"
	sta	scrnbase +2
	inc	scrnbase +1
	lda	scrnbase +1
	cmp	#"9" +1
	bne	:1
	lda	#"0"
	sta	scrnbase +1
	inc	scrnbase +0

::1	dec	$68	; Anzahl Bloecke -1
	lda	$68
	cmp	#$ff
	bne	next

	dec	$fb
	lda	$fb
	cmp	#$ff
	bne	next

	dec	$fa

:next	lda	$fa	; Alle Blocks empfangen?
	ora	$fb
	ora	$68
;	ora	$69	; Low-Byte ignorieren, nur 256B-Blocks
	bne	goread	; => Weiterlesen...

	ldx	#0
	ldy	#0
::0	dey
	bne	:0
	dex
	bne	:0

:cleanup	lda	#$ff	; ESP in Lesemodus schalten    
	sta	$dd03	; Datenrichtung Port B Ausgang
	lda	$dd00
	ora	#$04	; PA2 auf HIGH = ESP im Empfangsmodus
	sta	$dd00

; LoadHTTP/Ende
	lda	#$00	; Kein Ladefehler
	rts
    


:send_string	ldy	#$00
:string_next	iny
	lda	httpcommand-1,y
	jsr	write_byte
	cpy	httpcommand+1
	bne	string_next

	rts
    
    
:write_byte	sta	$dd01	; Bit 0..7: Userport Daten PB 0-7 schreiben
:dowrite	lda	$dd0d
	and	#$10	; Warten auf NMI FLAG2 = Byte wurde gelesen vom ESP
	beq	dowrite
	rts

:read_byte
:doread	lda	$dd0d
	and	#$10	; Warten auf NMI FLAG2 = Byte wurde gelesen vom ESP
	beq	doread
    
	lda	$dd01 
	rts

; HTTP/HTTPS
:httpcommand	b "W"
	b < httpnamelen
	b > httpnamelen
	b $25 ; HTTP/LARGE


:httpname

; HTTP
if BUILD_MODE = BUILD_HTTP
	b "http://www.zimmers.net/anonftp/pub/cbm/demodisks/cmd/cmd-hard.d64"
endif


; HTTPS
if BUILD_MODE = BUILD_HTTPS
	b "https://www.lyonlabs.org/commodore/onrequest/geos/geos-plain.d64"
endif


:httpnameend
:httpnamelen	= httpnameend - httpcommand
