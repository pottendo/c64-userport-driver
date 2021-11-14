; ccgms term 2021 source based on 5.5 source
; by craig smith 01/1988. 2017/2018/2019/2020/2021 mods by alwyz
; 1200baud.wordpress.com
;
; as of 1/1/2021 I am no longer maintaining ccgms. thanks! - alwyz
;
; EASYFLASH VERSION IS TURNED ON BY CHANGING VALUE OF EFBYTE TO $01
;
; Easyflash version gives option of loading/saving phonebook to cart
; and removes Swiftlink options
;
; BUILD with 64tass. Example:
;
; c:\c64\64tass\64tass.exe -C -B -i c:\c64\64tass\ccgms2021source.txt -o c:\c64\64tass\output.prg %1 %2 %3 %4 %5 %6 %7 %8 %9 2>c64error.txt
; if %errorlevel% == 1 echo errors occured!>>c64error.txt
;
; Some recent changelog stuff:
;
;5-14-2020 v2020 beta 2
; first public beta. rewrite of pretty much everything.... file transfers finally incorporate flow control. they never did before.
; resetvectors removed. re-wrote and optimized all modem drivers. removed a bunch of spaghetti code of my own making...
;
;5-16-2020 v2020 beta 3 
; f3 disablexfer improvements
; multi-receive disablexfer imrovements / trying to prevent crashing on multidownloads (noted on up9600)
; added punter handshake delays from ultimate version back in. baudrates faster than 2400 are definitely having problems with handshakes so its back!
; added jsr call to rsopen to baudrate changer. see if that fixes some weirdness
;
;5-17-2020 v2020 beta 4
; found a bug on the original punter sourcecode that incorrectly references pbuf+11
; bytes as delay 1 on 0 off, but in truth it is 1 off 0 on, so ive set both to delay on now
; update... ahh fuck it, no matter what, add delays every chance we can.... i disabled every opportunity to bypass delay around pnt106.
;
;5-18-2020 v2020 beta 5
; fixing some possible issues with multi-upload. crashes between files. enablexfer not getting turned back on at the right time?
; re-did cf1 multi-upload enable/disablexfer calls... seems good now
;
;5-19-2020 v2020 beta 6
; merged easyflash version into this one. only added 2 blocks. easier for maintaining
; still have some room from $5000-$5100 for more code/routines if need be. And can always add more code at $5c00 before the end
;
;5-21-2020 v2020 beta 7
; did some tweaks to autodialer. try counter now works to 99, and dial unlisted had some weird
; issues with that so that has been sorted as well. found one bug in the bottom screen
; display routine which has probably been there since ccgms 2017, but its good now.
;
;5-23-2020 v2020 beta 8
; easyflash false positive with reu detect. since ef and reu cant work together, added
; provisions at startup to prevent easyflash mode from even looking for an reu
;
;6-30-2020 v2021 beta 1
; doing some bugfixing. dial unlisted doesnt restore bottom of screen after dial. now it does. cosmetic fix.
; abort punter crashes stack pointer because i bypassed jump table and apparently that is neccessary so its back in the
; calls from dowmen and f3 routines. 
;
;9-22-2020 v2021 pre-beta2
; bo zimmermans firmware (and maybe others) take issue with atdt, and prefer using atd instead for bbsing (uploads/downloads issue). hopefully this
; is the only issue with firmware compatibility. willing to solve this issue on the software side, though i'd prefer firmware uses a better standard.
; but fuck it, it's 2020 and who gives a shit anymore about standards on an 8 bit computer from the 1980s? so i added an atd/atdt menu option
;
;12-08-2020 v2021 final
; well it's been fun. it was my dream at 10 years old to mod this program. 
; now i make the one everyone uses. it's been an honor and a privilege.
; there might still be bugs but they're minor if anything. 
; 
;commodore color graphics
;manipulation system terminal
;by craig smith
;
;version 2021 - 12/2020 by alwyz - this is my last version. good luck to the next modder! maybe someone will add xmodem-1k and 80 columns.
;version 2020 - 2020 by alwyz
;ultimate version - 2019 by alwyz
;version 2019 - 2019 by alwyz
;version 2017 - 2017 by alwyz
;version 5.5 -- jan 1988
;version 5.0 -- jan 1988
;version 4.5 -- may 1987
;version 4.1 -- oct 1986
;version 4.0 -- date unknown
; mods by greg pfoutz,w/permission
;version 3.0 -- aug 1985
;
modreg = $dd01
datdir = $dd03
frmevl = $ad9e
outnum = $bdcd
ldv    = $fb
status = $90
dv     = $ba
lognum = $05
modem  = $02
secadr = $03
space  = $02
untalk = $ffab
unlstn = $ffae
load   = $ffd5
save   = $ffd8
setlfs = $ffba
setnam = $ffbd
open   = $ffc0
chkin  = $ffc6
chkout = $ffc9
chrin  = $ffcf
chrout = $ffd2
getin  = $ffe4
close  = $ffc3
clrchn = $ffcc
clall  = $ffe7
readst = $ffb7
plot   = $fff0
listen = $ffb1
second = $ff93
talk   = $ffb4
tksa   = $ff96
unlsn  = $ffae
untlk  = $ffab
acptr  = $ffa5
ciout  = $ffa8
rstkey = $fe56
norest = $fe72
return = $febc
oldout = $f1ca
oldchk = $f21b
ochrin = $f157
ogetin = $f13e
oldirq = $ea31
oldnmi = $fe47
findfn  = $f30f
devnum  = $f31f
nofile  = $f701
numfil = $98
locat  = $fb
nlocat = $fd
xmobuf = $fd
backgr = $d021
border = $d020
textcl = 646
clcode = $e8da
scrtop = 648
line   = 214
column = 211
llen   = 213
qmode  = 212
imode  = 216
bcolor = 0
tcolor = 15
cursor = 95    ;cursor "_"
left   = $9d
cursfl = $fe
buffst = $b2
bufptr = $b0
grasfl = $0313
duplex = $12
tempch = $05
tempcl = $06
revtabup = $0380
buftop = $cafd
bufptrreu = $cafe
buffstreu = $caff
crcz = $cb00; use mulfil since its a punter/xmodem thing
mulfil = $cb00 ; punter only
endmulfil = $cc00 ;end area for multipunter
crclo = $cc00;crc fIX;temp for runtime tables;use tempbuf and numbuf
crchi = $cd00;crc fix;temp for runtime tables
tempbuf = $cc00 ; dialer temp buf to print on screen after connect. check for busy and all that.
numbuf = $cd00 ; dialer number buffer. holds phone number and port number
pbuf = $cd00;punter buffer. can use same area as xmodem crc hi and phone buffer			
ribuf = $ce00 ; rs232 receive input buffer points to $f7. no output buffers used on any modems in this release.
inpbuf = $cf00
configarea = $5100
mulcnt = 2047
mulfln = 2046
mlsall = 2045
mulskp = 2044
max    = $02
outstat = $a9		
jiffies = $a2
begpos = $07
endpos = $ac
bufflg = $0b
buffl2 = $0c
buffoc = $10
baudof = $0299
rtail  = $029b
rhead  = $029c
rfree  = $029d ; used for swiftlink only
rflow  = $029e ; not used
enabl  = $02a1
pnt10  = inpbuf
pnt11  = $028d
pnt14  = $02a1
pbuf2  = $0400
xmoscn = pbuf2
can    = 24
ack    = 6
nak    = 21
eot    = 4
soh    = 1
crc    = 67
cpmeof = 26
ca = 193  ;cap letters!
b  = 194
c  = 195
d  = 196
e  = 197
f  = 198
g  = 199
h  = 200
i  = 201
l  = 204
o  = 207
m  = 205
n  = 206
cp = 208
q  = 209
cr = 210
cs = 211
t  = 212
u  = 213
v  = 214
w  = 215
cx = 216
cy = 217
z  = 219

*=$0801
.byte $0d,$08,$0a,00,$9e,$34,$30
.byte $39,$36,00,00,00
 jmp prestart
;
;PUNTER
;
punter ; source code $0812
;referenced by old $c000 addresses
*=$0812  ;pxxxxx
p49152  lda #$00
 .byte $2c
p49155  lda #$03
 .byte $2c
p49158  lda #$06
 .byte $2c
p49161  lda #$09
 .byte $2c
p49164  lda #$0c
 .byte $2c
p49167  lda #$0f
 nop
p49170  jmp pnt23
p49173  jmp pnt109
pnt23 sta $62
 tsx
 stx pbuf+28
 lda #<pnttab
 clc
 adc $62
 sta pntjmp+1
 lda #>pnttab
 adc #$00
 sta pntjmp+2
pntjmp jmp pnttab
pnttab 
 jmp pnt28
 jmp pnt87
 jmp pnt84
 jmp pnt95
 jmp pnt99
 jmp pnt110
pnt27 .text 'GOOBADACKS/BSYN'
;pnt27 .text "goobadacks/bsyn"
pnt28 sta pbuf+5
 lda #$00
 sta pbuf
 sta pbuf+1
 sta pbuf+2
pnt29 lda #$00
 sta pbuf+6
 sta pbuf+7
pnt30 jsr pnt114
 jsr pnt38
 lda $96
 bne pnt35
 lda pbuf+1
 sta pbuf
 lda pbuf+2
 sta pbuf+1
 lda pnt10
 sta pbuf+2
 lda #$00
 sta pbuf+4
 lda #$01
 sta pbuf+3
pnt31 lda pbuf+5
 bit pbuf+3
 beq pnt33
 ldy pbuf+4
 ldx #$00
pnt32 lda pbuf,x
 cmp pnt27,y
 bne pnt33
 iny
 inx
 cpx #$03
 bne pnt32
 jmp pnt34
pnt33 asl pbuf+3
 lda pbuf+4
 clc
 adc #$03
 sta pbuf+4
 cmp #$0f
 bne pnt31
 jmp pnt111
pnt34 lda #$ff
 sta pbuf+6
 sta pbuf+7
 jmp pnt30
pnt35 inc pbuf+6
 bne pnt36
 inc pbuf+7
pnt36 lda pbuf+7
 ora pbuf+6
 beq pnt37
 lda pbuf+6
 cmp #$07
 lda pbuf+7
 cmp #$14
 bcc pnt30
 lda #$01
 sta $96
 jmp pnt101
pnt37 lda #$00
 sta $96
 rts
 nop
pnt38
 tya
 pha
pnt39 
 jsr modget
 bcs pnt40
 sta pnt10
 lda #$00
 sta $96
 pla
 tay
 jmp pnt41
pnt40 lda #$02
 sta $96
 lda #$00
 sta pnt10
 pla
 tay
pnt41 pha
 lda #$03
 sta $ba
 pla
 rts
pnt42 
 jsr clear232
 jsr enablexfer
 ldx #$05
 jsr chkout
 ldx #$00
pnt43 lda pnt27,y
 jsr chrout
 iny
 inx
 cpx #$03
 bne pnt43
 jmp clrchn
pnt44 sta pbuf+8
 jsr puntdelay;modded this;modded this. handshaking delay
 lda #$00;delay 0 on 1 off. originally was off
 sta pbuf+11
pnt45 lda #$02
 sta $62
 ldy pbuf+8
 jsr pnt42
pnt46 lda #$04
 jsr pnt28
 lda $96
 beq pnt47
 dec $62
 bne pnt46
 jmp pnt45
pnt47 
 jsr puntdelay;modded this;modded this. handshaking delay	
 ldy #$09
 jsr pnt42
 lda pbuf+13
 beq pnt48
 lda pbuf+8
 beq pnt50
pnt48 lda pbuf2+4
 sta pbuf+9
 sta pbuf+23
 jsr pnt65
 lda $96
 cmp #$01
 beq pnt49
 cmp #$02
 beq pnt47
 cmp #$04
 beq pnt49
 cmp #$08
 beq pnt47
pnt49 rts
pnt50 lda #$10
 jsr pnt28
 lda $96
 bne pnt47
 lda #$0a
 sta pbuf+9
pnt51 ldy #$0c
 jsr pnt42
 lda #$08
 jsr pnt28
 lda $96
 beq pnt52
 dec pbuf+9
 bne pnt51
pnt52 rts
pnt53 lda #$00;add delay back in
 sta pbuf+11
pnt54 
 jsr puntdelay;modded this. handshaking delay
 lda pbuf+30
 beq pnt55
 ldy #$00
 jsr pnt42
 jsr puntdelay;modded this. handshaking delay
pnt55 lda #$0b
 jsr pnt28
 lda $96
 bne pnt54
 lda #$00
 sta pbuf+30
 lda pbuf+4
 cmp #$00
 bne pnt59
 lda pbuf+13
 bne pnt61
 inc pbuf+25
 bne pnt56
 inc pbuf+26
pnt56 jsr pnt79
 ldy #$05
 iny
 lda ($64),y
 cmp #$ff
 bne pnt57
 lda #$01
 sta pbuf+13
 lda pbuf+22
 eor #$01
 sta pbuf+22
 jsr pnt79
 jsr pnt77
 jmp pnt58
pnt57 jsr pnt74
pnt58 lda #$2d
 .byte $2c
pnt59 lda #$3a
 jsr pnt107
 ldy #$06
 jsr pnt42
 lda #$08
 jsr pnt28
 lda $96
 bne pnt58
 jsr pnt79
 ldy #$04
 lda ($64),y
 sta pbuf+9
 jsr pnt80
 jsr clear232
 jsr enablexfer
 ldx #$05
 jsr chkout
 ldy #$00
pnt60 lda ($64),y
 jsr chrout
 iny
 cpy pbuf+9
 bne pnt60
 jsr clrchn
 lda #$00
 rts
pnt61 lda #$2a
 jsr pnt107
 ldy #$06
 jsr pnt42
 lda #$08
 jsr pnt28
 lda $96
 bne pnt61
 lda #$0a
 sta pbuf+9
pnt62 ldy #$0c
 jsr pnt42
 lda #$10
 jsr pnt28
 lda $96
 beq pnt63
 dec pbuf+9
 bne pnt62
pnt63 lda #$03
 sta pbuf+9
pnt64 ldy #$09
 jsr pnt42
 lda #$00
 jsr pnt28
 dec pbuf+9
 bne pnt64
 lda #$01
 rts
pnt65 ldy #$00
pnt66 lda #$00
 sta pbuf+6
 sta pbuf+7
pnt67 jsr pnt114
 jsr pnt38
 lda $96
 bne pnt70
 lda pnt10
 sta pbuf2,y
 cpy #$03
 bcs pnt68
 sta pbuf,y
 cpy #$02
 bne pnt68
 lda pbuf
 cmp #$41
 bne pnt68
 lda pbuf+1
 cmp #$43
 bne pnt68
 lda pbuf+2
 cmp #$4b
 beq pnt69
pnt68 iny
 cpy pbuf+9
 bne pnt66
 lda #$01
 sta $96
 rts
pnt69 lda #$ff
 sta pbuf+6
 sta pbuf+7
 jmp pnt67
pnt70 inc pbuf+6
 bne pnt71
 inc pbuf+7
pnt71 lda pbuf+6
 ora pbuf+7
 beq pnt73
 lda pbuf+6
 cmp #$06
 lda pbuf+7
 cmp #$10
 bne pnt67
 lda #$02
 sta $96
 cpy #$00
 beq pnt72
 lda #$04
 sta $96
pnt72 jmp pnt101
pnt73 lda #$08
 sta $96
 rts
pnt74 lda pbuf+22
 eor #$01
 sta pbuf+22
 jsr pnt79
 ldy #$05
 lda pbuf+25
 clc
 adc #$01
 sta ($64),y
 iny
 lda pbuf+26
 adc #$00
 sta ($64),y
 jsr disablexfer
 ldx #$02
 jsr chkin
 ldy #$07
pnt75 jsr chrin
 sta ($64),y
 iny
 jsr readst
 bne pnt76
 cpy pbuf+24
 bne pnt75
 tya
 pha
 jmp pnt78
pnt76 tya
 pha
 ldy #$05
 iny
 lda #$ff
 sta ($64),y
 jmp pnt78
pnt77 pha
pnt78 jsr clrchn
 jsr pnt109
 jsr pnt103
 jsr pnt109
 ldy #$04
 lda ($64),y
 sta pbuf+9
 jsr pnt80
 pla
 ldy #$04
 sta ($64),y
 jsr pnt81
 rts
pnt79 lda #<pbuf2
 sta $64
 lda pbuf+22
 clc
 adc #>pbuf2
 sta $65
 rts
pnt80 lda #<pbuf2
 sta $64
 lda pbuf+22
 eor #$01
 clc
 adc #>pbuf2
 sta $65
 rts
pnt81 lda #$00
 sta pbuf+18
 sta pbuf+19
 sta pbuf+20
 sta pbuf+21
 ldy #$04
pnt82 lda pbuf+18
 clc
 adc ($64),y
 sta pbuf+18
 bcc pnt83
 inc pbuf+19
pnt83 lda pbuf+20
 eor ($64),y
 sta pbuf+20
 lda pbuf+21
 rol a
 rol pbuf+20
 rol pbuf+21
 iny
 cpy pbuf+9
 bne pnt82
 ldy #$00
 lda pbuf+18
 sta ($64),y
 iny
 lda pbuf+19
 sta ($64),y
 iny
 lda pbuf+20
 sta ($64),y
 iny
 lda pbuf+21
 sta ($64),y
 rts
pnt84 lda #$00
 sta pbuf+13
 sta pbuf+12
 sta pbuf+29
 lda #$01
 sta pbuf+22
 lda #$ff
 sta pbuf+25
 sta pbuf+26
 jsr pnt80
 ldy #$04
 lda #$07
 sta ($64),y
 jsr pnt79
 ldy #$05
 lda #$00
 sta ($64),y
 iny
 sta ($64),y
pnt85 jsr pnt53
 beq pnt85
pnt86 lda #$00
 sta pnt10
 rts
pnt87 lda #$01
 sta pbuf+25
 lda #$00
 sta pbuf+26
 sta pbuf+13
 sta pbuf+22
 sta pbuf2+5
 sta pbuf2+6
 sta pbuf+12
 lda #$07
 sta pbuf2+4
 lda #$00
pnt88 jsr pnt44
 lda pbuf+13
 bne pnt86
 jsr pnt93
 bne pnt92
 jsr clrchn
 lda pbuf+9
 cmp #$07
 beq pnt90
 jsr disablexfer
 ldx #$02
 jsr chkout
 ldy #$07
pnt89 lda pbuf2,y
 jsr chrout
 iny
 cpy pbuf+9
 bne pnt89
 jsr clrchn
pnt90 lda pbuf2+6
 cmp #$ff
 bne pnt91
 lda #$01
 sta pbuf+13
 lda #$2a
 .byte $2c
pnt91 lda #$2d
 jsr goobad
 jsr pnt109
 lda #$00
 jmp pnt88
pnt92 jsr clrchn
 lda #$3a
 jsr goobad
 lda pbuf+23
 sta pbuf2+4
 lda #$03
 jmp pnt88
pnt93 lda pbuf2
 sta pbuf+14
 lda pbuf2+1
 sta pbuf+15
 lda pbuf2+2
 sta pbuf+16
 lda pbuf2+3
 sta pbuf+17
 jsr pnt79
 lda pbuf+23
 sta pbuf+9
 jsr pnt81
 lda pbuf2
 cmp pbuf+14
 bne pnt94
 lda pbuf2+1
 cmp pbuf+15
 bne pnt94
 lda pbuf2+2
 cmp pbuf+16
 bne pnt94
 lda pbuf2+3
 cmp pbuf+17
 bne pnt94
 lda #$00
 rts
pnt94 lda #$01
 rts
pnt95 lda #$00
 sta pbuf+25
 sta pbuf+26
 sta pbuf+13
 sta pbuf+22
 sta pbuf+12
 lda #$07
 clc
 adc #$01
 sta pbuf2+4
 lda #$00
pnt96 jsr pnt44
 lda pbuf+13
 bne pnt98
 jsr pnt93
 bne pnt97
 lda pbuf2+7
 sta pbuf+27
 lda #$01
 sta pbuf+13
 lda #$00
 jmp pnt96
pnt97 lda pbuf+23
 sta pbuf2+4
 lda #$03
 jmp pnt96
pnt98 lda #$00
 sta pnt10
 rts
pnt99 lda #$00
 sta pbuf+13
 sta pbuf+12
 lda #$01
 sta pbuf+22
 sta pbuf+29
 lda #$ff
 sta pbuf+25
 sta pbuf+26
 jsr pnt80
 ldy #$04
 lda #$07
 clc
 adc #$01
 sta ($64),y
 jsr pnt79
 ldy #$05
 lda #$ff
 sta ($64),y
 iny
 sta ($64),y
 ldy #$07
 lda pbuf+27
 sta ($64),y
 lda #$01
 sta pbuf+30
pnt100 jsr pnt53;transhand
 beq pnt100
 lda #$00
 sta pnt10
 rts
pnt101 inc pbuf+12
 lda pbuf+12
 cmp #$03
 bcc pnt102
 lda #$00
 sta pbuf+12
 ;lda pbuf+11;delay is always forced on no matter what now
 ;beq pnt103
 ;bne pnt106
pnt102 nop
pnt103 ldx #$00
pnt104 ldy #$00
pnt105 iny
 bne pnt105
 inx
 ;cpx #$78
 bne pnt104
pnt106 rts
pnt107 pha
 lda pbuf+25
 ora pbuf+26
 beq pnt108
 lda pbuf+29
 bne pnt108
 pla
 jsr goobad
 pha
pnt108 pla
 rts
pnt109  
 jsr enablexfer
pnt110 rts
pnt111 ldx #$00
pnt112 lda pbuf2,x
 cmp #$0d
 bne pnt113
 inx
 cpx #$03
 bcc pnt112
 jmp pnt120
pnt113 jmp pnt29
pnt114 
 lda $028d;$028d - check c= key;getnum routine
 cmp #$02
 bne pnt116
pnt115 pla
 tsx
 cpx pbuf+28
 bne pnt115
pnt116 
 lda #$01
 sta pnt10
pnt117 rts
pnt120 tsx
 cpx pbuf+28
 beq pnt121
 pla
 sec
 bcs pnt120
pnt121 lda #$80
 sta pnt10
 jsr clrchn
 rts
 brk
 brk
ptrtxt .text 13,13,5,'new pUNTER ',00
upltxt .text 'uP',00
dowtxt .text 'dOWN',00
lodtxt .text 'LOAD.',13,00
flntxt .text 'eNTER fILENAME: ',00
xfrmed .text 13,158,32,32,0
xfrtxt .text 'LOADING: ',159,0
xf2txt .text 13,5,'  (pRESS c= TO ABORT.)',13,13,00
abrtxt .text 'aBORTED.',13,00
mrgtxt .text 153,32,'gOOD bLOCKS: ',5,'000',5,'   -   '
 .text 153,'bAD bLOCKS: ',5,'000',13,0
gfxtxt .text 153,'gRAPHICS',00
gfxtxt2 .text 18,31,'c',154,'/',159,'g',146,158,0
asctxt .text 159,'aNSCII',00
rdytxt .text ' tERMINAL rEADY.',155,13,13,00
rdytxt2 .text ' tERM aCTIVATED.',155,13,13,00
dsctxt .text 13,13,5,'dISCONNECTING...',155,13,13,0
drtype .text 'D','S','P','U','R'
drtyp2 .text 'E','E','R','S','E'
drtyp3 .text 'L','Q','G','S','L'
drform .text 158,2,157,157,5,6,32,159,14,153,32,63,32,0
proto  .byte $08   ;start with
proto1 .byte $00   ;2400 baud setng
bdoutl .byte $51
bdouth .byte $0d
protoe .byte $02 ;length of proto
dreset .text "I0"
diskdv .byte $08
drivepresent .byte $01
alrlod .byte 0
lastch .byte 0
newbuf .byte <endprg,>endprg
ntsc .byte $00   ;pal=1 - ntsc =0
supercpubyte .byte $00
supertext .text "sUPERcpu eNABLED!",13,13,0
nicktemp .byte $00
drivetemp .byte $00 
;MAKECRCTABLE
crctable
		ldx 	#$00
		txa
zeroloop	sta 	crclo,x
		sta 	crchi,x
		inx
		bne	zeroloop
		ldx	#$00
fetch		txa
		eor	crchi,x
		sta	crchi,x
		ldy	#$08
fetch1		asl	crclo,x
		rol	crchi,x
		bcc	fetch2
		lda	crchi,x
		eor	#$10
		sta	crchi,x
		lda	crclo,x
		eor	#$21
		sta	crclo,x
fetch2		dey
		bne	fetch1
		inx
		bne	fetch
		rts
;SuperCPU ROUTINES

turnonscpu
lda supercpubyte
beq scpuout
lda #$01
sta $d07b

scpuout rts

turnoffscpu
lda supercpubyte
beq scpuout
lda #$01
sta $d07a
rts		

;CLEAR RS232 BUFFER POINTERS
clear232
 pha
 lda #$00
 sta rtail
 sta rhead
 sta rfree
 pla
 rts
 
puntdelay; you got a better way to do this? have at it!
 pha
 txa
 pha
 tya
 pha
pd3 ldx #$00
 ldy #$00
pd4 
 inx
 bne pd4
 iny
 bne pd4
 pla
 tay
 pla
 tax
 pla
 rts
 
efbyte .byte $00 ; 0 = no easyflash 1=easyflash mode
 
	;about 40 bytes still free here to play with before $1000

*=$1000
;start of terminal program

;pal/ntsc detect
prestart
 l1 lda $d012
 l2 cmp $d012
	beq l2
	bmi l1
	cmp #$20
	bcc start;ntsc selected
	ldx #$01
	stx ntsc

start

;SuperCPU Detect; it should just tell you to turn that shit off. who needs 30MHz for 9600 baud, anyway?

supercpudetect
lda $d0bc
asl a
bcs pgminit

lda #$01
sta supercpubyte

;SETUP INIT

pgminit
 jsr $e3bf;refresh basic reset - mostly an easyflash fix
 sei
 cld
 ldx #$ff
 txs
 lda #$2f
 sta $00
 lda #$37
 sta $01
 lda #1
 sta 204
 lda #bcolor  ;settup
 sta backgr
 sta border
 lda #tcolor
 sta textcl
 lda #$80
 sta 650      ;rpt
 lda #$0e
 sta $d418
 lda #$00
 sta locat
 lda #$e0       ;clear secondary
 sta locat+1    ;screens
 lda #$20
 ldy #$00
erasl1
 sta (locat),y
 iny
 bne erasl1
 inc locat+1
 bne erasl1
 cli
initdrive 
 lda $ba        ;current dev#
 jmp stodv2
stodev inc diskdv
 lda diskdv
 cmp #16;originally #16, try #30 here for top drive #?
 beq stodv5
 jmp stodv2
stodv5
 lda #$00
 sta drivepresent;we have no drives
 lda #$08
 sta diskdv
 jmp stodv3
stodv2 sta diskdv
 jsr drvchk
 bmi stodev
 lda #$01
 sta drivepresent;we have a drive!
stodv3
 lda efbyte
 beq stodv6;no easyflash - go ahead and look to see if we have an reu
 jsr noreu
 jmp stodv7
stodv6 
 jsr detectreu
stodv7
 lda newbuf     ;init. buffer
 sta bufptr     ;& open rs232
 lda newbuf+1
 sta bufptr+1
stodv4 
 jsr rsopen 
 jsr ercopn
 jmp init
rsopen          ;open rs232 file
 jsr disabl
 jsr disableup
 jsr enablemodem
 jsr clall
 lda #lognum
 ldx #modem
 ldy #secadr
 jsr setlfs
 lda protoe
 ldx #<proto
 ldy #>proto
 jsr setnam
 jsr open;$ffc2
 lda #>ribuf ;move rs232 buffers
 sta 248       ;for the userport 300-2400 modem nmi handling
 jsr disablemodem
 rts
ercopn
 lda drivepresent
 beq ercexit
 lda #$02;file length      ;open err chan
 ldx #<dreset
 ldy #>dreset
 jsr setnam
 lda #15
 ldx diskdv
 tay
 jsr setlfs
 jsr open;$ffc0
ercexit rts
init
 lda #1
 sta cursfl     ;non-destructive
 lda #0
 sta $9d ;prg mode
 sta grasfl     ;grafix mode
 ;sta allcap     ;upper/lower
 sta buffoc     ;buff closed
 sta duplex     ;full duplex
 jsr $e544  ;clr
 lda alrlod ; already loaded config file?
 bne noload
 lda drivepresent
 beq noload;no drive exists
;-------------
 jsr disablemodem
 lda #1
 sta alrlod
 ldx #<conffn
 ldy #>conffn
 lda #11
 jsr setnam
 lda #2
 ldx diskdv
 ldy #0
 jsr setlfs
 jsr loadcf
;-------------
 jmp begin
noload
begin
 jsr enablemodem
 jsr bell
 jsr themeroutine
term
 jsr mssg       ;title screen/CCGMS!
 jsr instr		;display commands f1 etc to terminal ready
main
 lda supercpubyte;supercpu
 beq main5
 cmp #$02;already acknowleged . no need to send text to screen
 beq main5a
 lda #<supertext
 ldy #>supertext
 jsr outstr
 lda #$02
 sta supercpubyte
main5a;supercpu = turn on 20mhz mode - for after all file transfer situations. already on? turn on again. no biggie. save code.
 jsr turnonscpu
main5
 lda bustemp
 beq mainmoveon
 ldy #1
mainprint 
 lda tempbuf,y
 jsr chrout
 iny
 cpy bustemp
 bne mainprint
 ldy #0
 sty bustemp
mainmoveon 
 ldx #$ff
 txs
 lda #$48		;keyboard matrix routine
 sta 655
 lda #$eb
 sta 656
 jsr clrchn;$ffcc
 jsr curprt		;cursor placement
main2
 lda bufptr
 sta newbuf
 lda bufptr+1
 sta newbuf+1
 jsr clrchn
 jsr getin		;kernal get input
 cmp #$00
 bne specck
mainab
 jmp main3
;check special-keys here
specck
 cmp #6
 bne specc1
 ldx 653
 cpx #6
 bne specc1
 ldx #16
 stx datdir
 ldx #0
 stx modreg;datdir and modreg need to be here for user port modem to function
 jmp main2
specc1
 ;cmp #$a4;underline key
 ;bne chkscr
 ;ldx 653     ;shift _ toggles
 ;beq checkf  ;n/d cursor
 ;cpx #1
 ;beq spetog
 ;lda allcap
 ;eor #$01
 ;sta allcap
 ;jmp main2
spetog
 ;jmp crsrtg
chkscr
 ldx 653
 cpx #$05    ;shift-ctrl and 1-4
 bcc chekrs  ;toggle screen
 ldx #$03
chksc1
 cmp clcode,x ;table of color codes
 beq chksc2
 dex
 bpl chksc1
 jmp main3   ;(not in range)
chksc2
 jmp scrtog  ;x holds pos 0-3
chekrs
 cmp #131    ;shift-r/s
 bne checkf  ;to hang-up
 jmp hangup
checkf       ;f-keys
 cmp #133
 bcc notfky
 cmp #141
 bcs notfky
 ldx #0
 stx $d020
 stx $d021
 pha
 jsr curoff
 pla
 sec
 sbc #133
 sta $03
 asl $03
 clc
 adc $03
 sta fbranc+1
 clc
fbranc
 bcc fbranc+2
 jmp f1
 jmp f3
 jmp f5
 jmp f7
 jmp f2
 jmp f4
 jmp f6
 jmp f8
notfky
 ;ldx allcap
 ;beq upplow
 ;ldx 53272
 ;cpx #23
 ;bne upplow
 ;cmp #$41
 ;bcc upplow
 ;cmp #$5b  ;'z'+1
 ;bcs upplow
 ;ora #$80
upplow ;ascii/gfx check
 sta $03
 ldx grasfl
 beq mainop
 jsr catosa  ;convert to ascii
 bne mainop
mnback
 jmp main2
mainop	;main output?
 pha
 ldx #lognum
 jsr chkout
 pla
 jsr chrout
 ldx grasfl
 beq maing
 jsr satoca
 sta $03
 bne maing
 jmp main2
maing
 ldx duplex
 beq main3
 jsr clrchn  ;if half duplex
 lda $03     ;bring back char
 ldx grasfl
 beq mainb
 cmp #$a4;underline key
 bne mainb
 lda #164    ;echo underline for
 sta $03     ;_ in ascii/half dup
mainb
 jmp bufchk  ;skip modem input
main3
 jsr clrchn
 ldx 653
 cpx #4   ;ctrl pressed
 bne specc2
 ldx 197  ;fn key
 cpx #3
 bcc specc2
 cpx #7
 bcs specc2
 lda #0
 sta macmdm
 jsr prtmac
 jmp main5;instead of main;supercpu doesnt need to be turned on and called every frame.
specc2
 cpx #3 ;shift,c=
 bne specc3
 ldx 657
 bpl specc3
 ldx #23
 stx 53272
specc3
 ldx #lognum
 jsr chkin ;get the byte from the modem
 jsr getin
 cmp #$00
 beq mnback
 ldx status
 bne mnback
 pha
 jsr clrchn
 pla
nopass
 ldx grasfl
 beq main4
 jsr satoca   ;ascii to c=
 beq main3
main4
 cmp #20      ;delete from modem
 bne bufchk   ;becomes false del
 lda #$14 ; delete key working :)
bufchk
 jsr putbuf
 jmp contn
putbuf
 ldx buffoc
 beq buffot
 ldx bufptr
 cpx bufend
 bne bufok
 ldx bufptr+1
 cpx bufend+1
 beq buffot
bufok
 ldy bufreu
 beq bufok2
 jsr reuwrite
 jmp bufok3
bufok2
 ldy #$00
 sta (bufptr),y
bufok3 
 inc bufptr
 bne buffot
 inc bufptr+1
buffot rts
contn
 jsr ctrlck
 bcc contn2
 jmp main
ctrlck
 cmp #$0a   ;ctrl-j
 beq swcrsr
 cmp #$0b   ;ctrl-k
 bne nonchk
swcrsr
 ldx grasfl
 bne nonchk
 pha
 jsr curoff
 pla
 and #$01   ;form to ch flag
 eor #$01
 sta cursfl
swcext
 sec
 rts
nonchk
 cmp #14  ;ctrl-n
 bne ctrlen
 ldx #0
 stx $d020
 stx $d021
ctrlen
 cmp #$07   ;ctrl-g;bell sound from bbs side
 bne ctrleo
 jsr bell
ctrleo
 cmp #22   ;ctrl-v;end of file transfer or boomy sound
 bne ctrlev
 jsr gong
ctrlev
; cmp #$15   ;ctrl-u;uppercase from bbs side
; bne ctrle2
; ldx #21
; stx 53272
; bne ctrlex
;ctrle2
; cmp #$0c   ;ctrl-l;lowercase from bbs side
; bne ctrle3
; ldx #23
; stx 53272
; bne ctrlex
;ctrle3
; cmp #$5f   ;false del
; bne ctrle4 ;(buff and 1/2 duplx)
; lda #20
; bne ctrlex
;ctrle4
 ldx lastch
 cpx #2  ;ctrl-b
 bne ctrlex
 ldx #15
ctrlb1  cmp clcode,x
 beq ctrlb2
 dex
 bpl ctrlb1
 bmi ctrlex
ctrlb2 stx $d020
 stx $d021
 lda #16  ;ctrl-p..non printable
ctrlex
 sta lastch
 clc
 rts
contn2
 pha
 jsr curoff  ;get rid of cursor
 pla
 jsr chrout
 jsr qimoff
 jmp main
;end of term
;subroutines follow:
bell
 ldx #$09
 stx 54291
 ldx #00
 stx 54292
 ldx #$40
 stx 54287
 ldx #00
 stx 54290
 ldx #$11
 stx 54290
 rts
gongm1 .byte 24,6,13,20,4,11,18,15,8,1,5,19,12,14,7,0,4,11,18,24
gongm2 .byte 47,0,0,0,0,0,0,4,8,16,13,13,11,28,48,68,21,21,21,15
gong
 pha
 ldx #0
gong1
 lda gongm1,x
 tay
 lda gongm2,x
 sta 54272,y
 inx
 cpx #20
 bcc gong1
 pla
 rts
scrtog   ;toggle screen #1-4
 txa     ;(swap screen memory with
 pha     ; behind kernal rom)
 jsr curoff
 lda 653
 sta $04
 pla
 asl a
 asl a
 asl a
 clc
 adc #$e0
 sta locat+1
 lda #$04
 sta $03
 lda #$00
 sta locat
 sta $02
 sei
 lda $d011
 pha
 lda #$0b
 sta $d011
 lda #<ramnmi
 sta $fffa
 lda #>ramnmi
 sta $fffb
 lda #$2f
 sta $00
 lda #$35
 sta $01
scrtg1
 jsr scrnl1
 cmp #$08
 bcc scrtg1
 lda #$d8
 sta $03
scrtg2
 jsr scrnl1
 cmp #$dc
 bcc scrtg2
 pla
 sta $d011
 lda #$37
 sta $01
 cli
 jmp main
ramnmi
 sta tempch
 lda #$37
 sta $01
 plp
 php
 sta tempcl
 lda #>ramnm2
 pha
 lda #<ramnm2
 pha
 lda tempcl
 pha
 lda tempch
 jmp $fe43
ramnm2
 pha
 lda #$35
 sta $01
 pla
 rti
scrnl1
 ldx $04
 cpx #05
 beq scrnls
 ldy #0
scrnlc  lda ($02),y
 sta (locat),y
 dey
 bne scrnlc
 beq scrnl3
scrnls  ldy #$00
scrnl2  ;swap screen page
 lda ($02),y
 tax
 lda (locat),y
 sta ($02),y
 txa
 sta (locat),y
 iny
 bne scrnl2
scrnl3  lda #<ramnmi
 sta $fffa
 lda #>ramnmi
 sta $fffb
 inc locat+1
 inc $03
 lda $03
 rts
outspc
 lda #29   ;crsr right
outsp1
 jsr chrout
 dex
 bne outsp1
 rts
bufclr
 lda buffst
 sta bufptr
 lda buffst+1
 sta bufptr+1
 rts
finpos ;calculate screenpos
 ldy line
 lda $ecf0,y
 sta locat
 lda $d9,y
 and #$7f
 sta locat+1
 lda column
 cmp #40
 bcc finp2
 sbc #40
 clc
finp2
 adc locat
 sta locat
 lda locat+1
 adc #$00
 sta locat+1
 ldy #$00
 lda (locat),y
 rts
fincol   ;calculate color ptr
 jsr finpos
 lda #$d4
 clc
 adc locat+1
 sta locat+1
 lda (locat),y
 rts
qimoff   ;turn quote/insert off
 lda #$00
 sta qmode
 sta imode
 rts
mssg
 lda #<msgtxt
 ldy #>msgtxt
 jsr outstr
 lda #32
 jsr chrout
 ldx #02 ;2nd line start char
 ;lda #163
mslop1
 jsr chrout
 dex
 bne mslop1
 lda #<author
 ldy #>author
 jsr outstr
 ldx #40
mslop2
 lda #183
 jsr chrout
 dex
 bne mslop2
 rts
instr
 lda #<instxt
 ldy #>instxt
 jsr outstr
 lda #<instx2
 ldy #>instx2
 jsr outstr
trmtyp
 ldx grasfl
 bne asctrm
 lda theme
 bne trmtyp2
 lda #<gfxtxt
 ldy #>gfxtxt
 bne termtp
trmtyp2 
 lda #<gfxtxt2
 ldy #>gfxtxt2
 bne termtp
asctrm
 lda #<asctxt
 ldy #>asctxt
termtp
 jsr outstr
 lda theme
 bne ready2
 lda #<rdytxt
 ldy #>rdytxt
 jmp outstr
ready2 
 lda #<rdytxt2
 ldy #>rdytxt2
 jmp outstr
msgtxt
.byte 13,$93,8,5,14,18,32,28,32
.text "c" 
.byte 32,129,32
.text "c" 
.byte 32,158,32
.text "g"
.byte 32,30,32
.text "m"
.byte 32,31,32
.text "s"
.byte 32,156
.text " ! "
.byte 5,32
.text "    tERMINAL 2021   "
.byte 00
author  .text "BY cRAIG sMITH mODS BY aLWYZ/POTTENDO"
.byte 146,151,00
;
instxt
.text 5,'  ',18,'f1',146,32,150,'uPLOAD          '
.text 5,18,'f2',146,32,150,'sEND/rEAD FILE',13
.text 5,'  ',18,'f3',146,32,158,'dOWNLOAD        '
.text 5,18,'f4',146,32,158,'bUFFER COMMANDS',13
.text 5,'  ',18,'f5',146,32,153,'dISK COMMAND    '
.text 5,18,'f6',146,32,153,'dIRECTORY',13
.text 5,'  ',18,'f7',146,32,30,'dIALER/pARAMS   '
.text 5,18,'f8',146,32,30,'sWITCH TERMS',13,0
instx2
.text 31,'c',28,'=',5,18,'f1',146,32,159,'mULTI-sEND    '
.text 31,'c',28,'=',5,18,'f3',146,32,159,'mULTI-rECEIVE',13
.text 31,'c',28,'=',5,18,'f5',146,32,154,'sEND DIR.     '
.text 31,'c',28,'=',5,18,'f7',146,32,154,'sCREEN TO bUFF.',13,13,0
;
mlswrn .text 13,5,'bUFFER TOO BIG - sAVE OR cLEAR fIRST!',13,0
;
dirmdm .byte 0
;directory routine
dirfn   .text '$'
dir
 jsr disablexfer
 lda #$0d
 ldx diskdv
 ldy #$00
 jsr setlfs
 jsr drvchk
 bpl dirst
 jmp drexit
dirst
 jsr clrchn
 jsr cosave
 lda #$0d
 jsr chrout
 jsr open
 lda #0
 sta dirmdm
 lda 653
 cmp #2   ;c= f6
 bne dirlp0
 lda #1
 sta dirmdm
dirlp0
 ldx #$0d
 jsr chkin
 ldy #03
drlp1
 jsr getch
 dey
 bpl drlp1
 jsr getch
 sta $0b
 jsr getch
 ldx $0b
 jsr outnum
 lda #$20
 jsr chrout
drlp2
 jsr getch
 ldx dirmdm
 beq drlpm
 cmp #0
 beq drlpm2
 cmp #$20
 bcc drlp2
drlpm
 jsr chrout
 bne drlp2
drlpm2
 jsr drret
 ldy #01
 bne drlp1
getch
 jsr getin
 ldx status
 bne drlp3
 cmp #00
 rts
drlp3
 pla
 pla
drexit
 jsr clrchn
 jsr coback
 lda #$0d
 jsr chrout
 jsr close
 jmp enablexfer
drret
 lda #$0d
 jsr chrout
 jsr clrchn
 jsr getin
 beq drcont
 cmp #$03
 beq drlp3
 lda #$00
 sta $c6
drwait
 jsr getin
 beq drwait
drcont
 ldx dirmdm
 beq dircoe
 lda #145
 jsr chrout
 lda #3  ;screen
 sta 153 ;def input dev
 ldx #5
 jsr chkout
 ldy #0
drcon2
 lda #$5
 sta dget2+1
 jsr dirget;grab bytes in buffer so we dont lock up nmis
 bcs drcon4 ; no bytes
 jmp drcon2
drcon4 
 jsr disablexfer
 jsr getin
 jsr enablexfer
 jsr chrout
 tya
 pha
 lda #$15
 sta dget2+1
 jsr dirget;grab bytes in buffer so we dont lock up nmis
drcon6 
 pla
 tay
 iny
 cpy #27
 bcc drcon2
 lda #$0d
 jsr chrout
 jsr clrchn
 lda #$0d
 jsr chrout
 ldx #5
 jsr chkin
drcon3  jsr getin
 lda $029b
 cmp $029c
 bne drcon3
dircoe
 jsr clrchn
 ldx #$0d
 jmp chkin
drvchk
 lda #00
 sta status
 lda diskdv
 jsr $ed0c
 lda #$f0
 jsr $edbb
 ldx status
 bmi drc2
 jsr $f654
 lda #$00
drc2  rts
dirget;this timeout failsafe makes sure the byte is received back from modem
       ;before accessing disk for another byte otherwise we can have
	   ;all sorts of nmi related issues.... this solves everything.
	   ;uses the 'fake' rtc / jiffy counter function / same as xmmget...
dget2 lda #10;timeout failsafe
 sta xmodel
 lda #0
 sta rtca1
 sta rtca2
 sta rtca0
ddxmogt1
 jsr modget
 bcs ddxmmgt2
 jmp dirgetout
ddxmmgt2
 jsr xmmrtc
 lda rtca1
 cmp xmodel
 bcc ddxmogt1
dirgetout rts 
;ANSI STUFF HERE
ansi .byte 00
ansitemp .byte 00
ansicolor .byte 00
ansi0colors .byte 146,28,30,149,31,156,159,152,0,0,0
ansi1colors .byte 151,150,153,158,154,156,159,05,0,0,0
;convert standard ascii to c= ascii
satoca
 pha
 lda ansi
 beq satoca2;no ansi, but check for ansi
ansion
 cmp #$02;is ansi color code on?
 beq coloron2
 pla
 cmp #'2'
 beq clrhomeansi
 cmp #'3'
 beq coloron
 cmp #'4'
 beq coloron;code4on when we figure out rvs
 cmp #'0'
 beq turn0on
 cmp #'7'
 beq code4on;7 is rvs
 cmp #'1'
 beq turn1on
 cmp #$3b;semicolon
 beq semion
 cmp #'['
 beq leftbracketansi;[ after escape code
 cmp #'M'
 beq ansimend
 cmp #'m'
 beq ansimend
 cmp #'J'
 beq ansimend
 cmp #'j'
 beq ansimend
 cmp #'H'
 beq ansimend
 cmp #'h'
 beq ansimend
 cmp #']'
 beq outtahere
 jmp cexit;out of ideas,move on
turn0on
 lda #0
 sta ansicolor
 jmp outtahere
turn1on
 lda #1
 sta ansicolor
 jmp outtahere
code4on;rvs on for next color
  lda #$01
  sta ansi
  lda #$12;rvs on
  jmp cexit
clrhomeansi;rvs on for next color
  lda #$01;ansi stays on to see if there's another command after
  sta ansi
  lda #$93;clr/home
  jmp cexit
leftbracketansi;ansi is on and got the left bracket
  lda #$01;ansi stays on to see if there's another command after
  sta ansi
  lda #$00;display nothing and move on in ansi mode
  jmp cexit
coloron
 lda #$02
 sta ansi
outtahere 
 lda #$00
 jmp cexit
coloron2 
 lda ansicolor
 beq ansizerocolors
ansionecolors
 lda #0
 sta ansicolor
 pla
 sec
 sbc #48
 tay
 lda #$01
 sta ansi
 lda ansi1colors,y
  jmp cexit 
ansizerocolors 
 pla
 sec
 sbc #48
 tay
 lda #$01
 sta ansi
 lda ansi0colors,y
 jmp cexit
semion
lda #$01
sta ansi
 lda #$00
 jmp cexit 
ansimend 
 lda #$00
 sta ansi
 jmp cexit
satoca2
 pla 
 cmp #$1b;ansi escape code
 beq ansi1
 jmp satoca1
ansi1
 lda #$01
 sta ansi;turn ansi on
 lda #$00
 jmp cexit
satoca1
 cmp #$a4;underline key
 bne clab0
 lda #164  ;underline
 bne cexit
clab0
 and #127
 cmp #124
 bcs cexit
 cmp #96
 bcc clab1
 sbc #32
 bne cexit
clab1
 cmp #65
 bcc clab2
 cmp #91
 bcs cexit
 adc #128
 bne cexit
clab2
 cmp #08
 bne clab3
 lda #20
clab3
 cmp #12
 bne clab4
 lda #$93
clab4
 cmp #32     ;don't allow home,
 bcs cexit   ;cd, or cr
 cmp #07
 beq cexit
 cmp #$0d
 beq cexit
 cmp #20
 beq cexit
 bne cerrc
cexit cmp #$00
 rts
ansi0keys 
cerrc
 lda #$00
 beq cexit
;convert c= ascii to standard ascii
catosa
 cmp #20
 bne alab0
 lda #08    ;delete
 bne aexit
alab0 cmp #164 ;underline
 bne alab1
 lda #$a4;underline key
alab1  cmp #65
 bcc cexit  ;if<then no conv
 cmp #91
 bcs alab2
 adc #32    ;lower a...z..._
 bne aexit
alab2  cmp #160
 bne alab3
 lda #32    ;shift to space
 bne aexit
alab3  and #127
 cmp #65
 bcc cerrc
 cmp #96    ;upper a...z
 bcs cerrc
aexit   cmp #$00
 rts
savech
 jsr finpos
 sta tempch
 eor #$80
 sta (locat),y
 jsr fincol
 sta tempcl
 lda textcl
 sta (locat),y
 rts
restch  ;restore char und non-crsr
 jsr finpos
 lda tempch
 sta (locat),y
 jsr fincol
 lda tempcl
 sta (locat),y
 rts
spleft  ;output space, crsrleft
 lda #$20
 jsr chrout
 lda #left
 jmp chrout
curoff
 ldx cursfl
 bne restch
 jsr qimoff
 jmp spleft
curprt
 lda cursfl
 bne nondst
 lda #cursor
 jsr chrout
 lda #left
 jmp chrout
nondst
 jmp savech
input
 jsr inpset
 jmp inputl
inpset
 stx max
 cpy #$00
 beq inpcon
 jsr outstr
inpcon
 jsr clrchn
 sec
 jsr plot
 stx $9e
 sty $9f
 jsr finpos    ;set up begin &
 lda locat+1   ;end of input
 sta begpos+1  ;ptrs
 sta endpos+1
 lda locat
 sta begpos
 clc
 adc max
 sta endpos
 lda endpos+1
 adc #$00
 sta endpos+1
 rts
inputl
 lda #0
 sta 204
 jsr savech
inpwat
 jsr getin
 beq inpwat
 sta $03
 and #127
 cmp #17
 beq inpcud
 cmp #34
 beq inpwat
 cmp #13
 bne inpwt1
 jmp inpret
inpwt1
 lda $03
 cmp #20
 beq inpdel
 cmp #157
 beq inpdel
 and #$7f
 cmp #19
 beq inpcls
 bne inpprc
inpcud
 jsr restch
 lda $03
 cmp #145
 beq inphom
 jsr inpcu1
 jmp inpmov
inpcu1 ldy max
inpcu2
 dey
 bmi inpcu3
 lda (begpos),y
 cmp #$20
 beq inpcu2
inpcu3
 iny
 tya
 clc
 adc $9f
 tay
 rts
inpcls
 jsr restch
 lda $03
 cmp #$93
 bne inphom
 ldy max
 lda #$20
inpcl2 sta (begpos),y
 dey
 bpl inpcl2
inphom
 ldy $9f
inpmov
 ldx $9e
 clc
 jsr plot
 jmp inputl
inpdel
 jsr finpos
 lda locat
 cmp begpos
 bne inprst
 lda locat+1
 cmp begpos+1
 beq inpwat
 bne inprst
inpprc
 jsr finpos
 lda locat
 cmp endpos
 bne inpins
 lda locat+1
 cmp endpos+1
 bne inpins
 jmp inpwat
inpins
 lda $03
 cmp #148
 bne inprst
 dec endpos+1
 ldy #$ff
 lda (endpos),y
 inc endpos+1
 cmp #$20
 beq inprst
 jmp inpwat
inprst
 ldx #$03
 stx 651
 jsr restch
 lda $03
 jsr chrout
 jsr qimoff
 jmp inputl
inpret
 jsr restch
 jsr inpcu1
 cmp 211
 bcc inpre2
 ldx $9e
 clc
 jsr plot
inpre2
 jsr finpos
 lda locat
 sec
 sbc begpos
 pha
 tay
 lda #$20
inpspc
 sta (begpos),y
 cpy max
 beq inpinp
 iny
 bne inpspc
inpinp
 pla
 sta max
 ldx $9e
 ldy $9f
 clc
 jsr plot
 lda #1
 sta 204
 lda #$03
 ldy #$00
 tax
 jsr setlfs
 lda #$00
 jsr setnam
 jsr open
 ldx #$03
 jsr chkin
 ldy #$00
inpsto
 cpy max
 beq inpend
 jsr chrin
 sta inpbuf,y
 iny
 bne inpsto
inpend
 lda #$00
 sta inpbuf,y
 jsr clrchn
 lda #$03
 jsr close
 ldx max
 rts
cosave
 ldx textcl
 stx $04
cochng
 ldx #tcolor
 stx textcl
 rts
coback
 ldx $04
 stx textcl
 rts
f6      ;directory
 lda #$01
 ldx #<dirfn
 ldy #>dirfn
dodir
 jsr setnam
 jsr dir
 jsr enablexfer
 jmp main
f8      ;term toggle
 ldx 653
 cpx #2
 bne termtg
 jmp cf7
termtg
 lda grasfl
 eor #$01
 sta grasfl
 jsr bell
 jmp term
crsrtg     ;ascii crsr toggle
 jsr curoff
 lda cursfl
 eor #$01
 sta cursfl
 jmp main
hangup     ;hang up phone
 ldx 653
 cpx #2
 bne hangup6;not C= Stop
 jsr curoff
 lda #<dsctxt
 ldy #>dsctxt
 jsr outstr
 lda motype
 beq droprs
 cmp #$01
 beq dropup
 jmp dropswift
hangup6 jmp main
 
droprs lda #%00000100
        sta $dd03
        lda #0
        sta $dd01
        ldx #226
		stx $a2
	-	bit $a2
		bmi -
        lda #4
        sta $dd01
	jmp main

dropup  lda #$04
        sta $dd03    ;cia2: data direction register b
        lda #$02
        sta $dd01    ;cia2: data port register b
        ldx #$e2
		stx $a2
a7ef3    bit $a2
        bmi a7ef3
        lda #$02
        sta $dd03    ;cia2: data direction register b
        jmp main
		
dropswift
 jsr dropdtr
 jmp main
dsktxt .byte 5,13
.text "#"
dsktx2 .text "**>      "
.byte 157,157,157,157,157,157,00
dskdtx .text '8 9 101112131415161718192021222324252627282930'
f5      ;disk command
 jsr disablexfer
 jsr ercopn
 jsr cosave
dskcmd
 lda diskdv
 sec
 sbc #$08
 asl a
 tay
 lda dskdtx,y
 sta dsktx2
 lda dskdtx+1,y
 sta dsktx2+1
 lda #<dsktxt
 ldy #>dsktxt
 ldx #36;1 - what does this do? limit length of command?
 jsr input
 beq drverr;nothing entered, drive error code?
 lda inpbuf
 cmp #$23;# drive
 beq chgdev
 jsr drvchk
 bmi drvext
 lda #$0d;return - exit
 jsr chrout
 lda inpbuf
 cmp #$24;$ directory
 bne drvsnd
 lda max
 ldx #<inpbuf
 ldy #>inpbuf
 jmp dodir
drvsnd
 ldx diskdv
 stx 612  ;dev# table, log#15
 ldx #$0f
 jsr chkout
 ldx #$00
drvlop
 lda inpbuf,x
 jsr chrout
 inx
 cpx max
 bne drvlop
 lda #$0d
 jsr chrout
drvext
 jsr clrchn
 jsr coback
 lda #$0d
 jsr chrout
 jsr enablexfer
 jmp main
drverr
 jsr drvchk
 bmi drvext
 jsr clrchn
 ldx #$0f
 jsr chkin
drver2
 jsr getin
drver3
 jsr chrout
 cmp #$0d
 bne drver2
 beq drvext
chgdev;modded this for drives over #15
 ldy #$01
 ldx inpbuf,y
 txa
 sec
 sbc #$30
 beq chgdv2;if first char is 0 as in 08 or 09 
 cmp #$03;devices 10-29 "1x or 2x"
 bpl chgdv8;might be 8 or 9.. anything over 3 doesnt count here so lets try and see if it matches 8 or 9.
 clc;definitely starts with 1 or 2 if it makes it this far
 adc #$09 ;$0a-$0b for device starting with 1x or 2x, convert to hex
 jmp chgdv2
chgdv8 
 cmp #$07
 bpl chgdv9;assume its 8 or 9, which is the only options when it starts with 8 or 9
 jmp drvext;nope there was nothing in the 00-29 range
chgdv2   iny;get the second character
 sta drivetemp
 lda inpbuf,y
 sec
 sbc #$30;decimal petscii to hex, again...
 clc
 adc drivetemp
chgdv9
 cmp #$08;lowest drive # (8)
 bcc drvext
 cmp #$1e;highest drive # (30)
 bcs drvext
 tay;y now holds complete hex of drive #
 lda diskdv
 pha
 sty diskdv
 sty 612
 jsr drvchk
bmi chgdv3
 pla
 lda #145
 jsr chrout
 jmp dskcmd
chgdv3
 pla
 sta diskdv
 sta 612
chgdv4
 lda #$20
 jsr chrout
 lda #$2d
 jsr chrout
 lda #$20
 jsr chrout
 ldy #$00
chgdv5
 lda $a1d0,y  ;device not present
 php
 and #$7f
 jsr chrout
 plp
 bmi chgdv6
 iny
 bne chgdv5
chgdv6
 jmp drvext

;xfer id and pw to macros F5 and F7
xferidpw 
 ldy #59
xferid
 lda (nlocat),y
 sta macmem+69,y
 iny
 lda (nlocat),y
 beq xferpw
 jmp xferid
xferpw
 sta macmem+69,y
 ldy #71
xferpw2
 lda (nlocat),y
 sta macmem+121,y
 iny
 lda (nlocat),y
 beq xferp3
 jmp xferpw2
xferp3
 sta macmem+121,y
 rts

;MACROS
macmdm .byte 0
macxrg .byte 0
prmacx ;find index for macro
 cpx #3   ;from 197 f-key value
 bne prmax2
 ldx #7
prmax2 txa
 sec
 sbc #4  ;now a=0..3 for f1,3,5,7
 ldx #5
prmax3 asl a
 dex
 bpl prmax3  ;a=0,64,128,192
 sta macxrg
 rts
prtmac
 lda 197
 cmp #7
 bcc prtmac
 jsr prmacx
prtmc0
 ldx macxrg
 lda macmem,x
 beq prtmc4
 pha
 ldx macmdm
 bne prtmc2
 ldx #5
 jsr chkout
 pla
 pha
 ldx grasfl
 beq prtmc1
 jsr catosa
prtmc1
 jsr chrout
 jsr clrchn
 lda #$fd
 sta $a2
prtmcd lda $a2
 bne prtmcd
 lda #$fd
 sta $a2
prtmcd2 lda $a2
 bne prtmcd2
 ldx #5
 jsr chkin
 jsr getin
 cmp #$00
 bne prtmci
 ldx duplex
 beq prtmca
 ldx grasfl
 beq prtmc2
 pla
 jsr catosa
 bne prtmck
 beq prtmc3
prtmca  pla
 bne prtmc3
prtmci  tax
 pla
 txa
prtmck  ldx grasfl
 beq prtmcj
 jsr satoca
prtmcj
 pha
prtmc2
 jsr curoff
 pla
 ldx macmdm
 bne prtmcs
 jsr putbuf
prtmcs
 jsr ctrlck
 bcs prtmc3
 jsr chrout
 jsr qimoff
 jsr curprt
prtmc3  inc macxrg
 cmp #255
 bne prtmc0
prtmc4 jmp curoff
;
stbrvs .byte 0
stbcol .byte 0
stbxps .byte 0
stbyps .byte 0
stbmax .byte 0
stbmay .byte 0
cf7  ;screen to buffer
 lda #0
 sta 198
 lda #$f1
 sta $a2
scnbf0  lda $a2
 bne scnbf0
 jsr getin
 cmp #140
 bne scnbfs
 jsr bufclr
scnbfs
 lda buffoc
 pha
 lda #1
 sta buffoc
 lda #0
 sta stbrvs
 lda #255
 sta stbcol
 ldy #24
 sty stbyps
scnbf1  ldx #39
 stx stbxps
scnbf2  jsr finscp
 cmp #$20
 bne scnbf3
 dec stbxps
 bpl scnbf2
 dec stbyps
 bpl scnbf1
 jmp scnbr4
scnbf3
 lda #$0d
 jsr putbuf
 lda #$93
 jsr putbuf
 lda 53272
 and #2
 lsr a
 lsr a
 ror a
 eor #$8e
 jsr putbuf
 lda $d021
 and #15
 beq scnbnc
 tax
 lda clcode,x
 pha
 lda #2
 jsr putbuf
 pla
 jsr putbuf
scnbnc
 lda #10
 jsr putbuf
 lda stbyps
 sta stbmay
 lda #0
 sta stbyps
scnbnl
 lda #39
 sta stbxps
scnbf4
 jsr finscp
 cmp #$20
 bne scnbf5
 dec stbxps
 bpl scnbf4
 inc stbxps
 jmp scnbrt
scnbf5
 lda stbxps
 sta stbmax
 lda #0
 sta stbxps
scnbf6
 jsr finscp
 sta $02
 jsr finscc
 sta $03
 lda $02
 and #$80
 cmp stbrvs
 beq scnbf7
 lda stbrvs
 eor #$80
 sta stbrvs
 ora #18
 eor #$80
 jsr putbuf
scnbf7
 lda $02
 cmp #$20
 beq scnbf8
 lda $03
 cmp stbcol
 beq scnbf8
 tax
 lda clcode,x
 jsr putbuf
scnbf8
 lda $02
 and #$7f
 cmp #$7f
 beq scnbf9
 cmp #$20
 bcs scnb10
scnbf9
 clc
 adc #$40
 bne scnb11
scnb10
 cmp #64
 bcc scnb11
 ora #$80
scnb11
 jsr putbuf
 inc stbxps
 lda stbxps
 cmp stbmax
 bcc scnbf6
 beq scnbf6
scnbrt
 lda stbxps
 cmp #40
 bcs scnbr2
 lda #$0d
 jsr putbuf
 lda #0
 sta stbrvs
scnbr2
 inc stbyps
 lda stbyps
 cmp stbmay
 beq scnbr3
 bcs scnbre
scnbr3  jmp scnbnl
scnbre
 ldx 646
 lda clcode,x
 jsr putbuf
scnbr4
 pla
 sta buffoc
 jmp main
;
finscp
 ldy stbyps
 lda $ecf0,y
 sta locat
 lda $d9,y
 and #$7f
 sta locat+1
 ldy stbxps
 lda (locat),y
 rts
finscc
 jsr finscp
 lda locat+1
 clc
 adc #$d4
 sta locat+1
 lda (locat),y
 and #15
 rts
;XMODEM
;xmodem routines
xmstat .byte 0
xmoblk .byte 0
xmochk .byte 0
xmobad .byte 0
xmowbf .byte 0
xmodel .byte 0
xmoend .byte 0
xmostk .byte $ff
;
xmosnd;crc mods here
 tsx
 stx xmostk
 jsr xmoset
 jsr pnt109
 lda protoc
 cmp #$01
 beq pronak
 lda #crc
 ldx #133
 jmp promoveon
pronak lda #nak
 ldx #132
promoveon 
 sta promod+1
 stx promod2+1
xmupl1
 lda #6 ;60 secs
 jsr xmmget
 beq xmupl2
xmupab jmp xmabrt
xmupl2
 cmp #can
 beq xmupab
promod cmp #nak 
 bne xmupl1
xmupll
 jsr xmocbf
 sty xmobad
 lda #soh
 sta (xmobuf),y
 iny
 lda xmoblk
 sta (xmobuf),y
 iny
 eor #$ff
 sta (xmobuf),y
 iny
xmsnd1
 jsr disablexfer
 ldx #2
 jsr chkin
xmsnd2
 jsr getin
 ldx $90  ;status
 stx xmoend
xmsnd3
xmsnd4
 sta (xmobuf),y
 clc
 adc xmochk
 sta xmochk
 iny
 cpy #131
 bcs xmsnd5
 ldx xmoend
 beq xmsnd2
 lda #cpmeof
 bne xmsnd3
xmsnd5
 sta (xmobuf),y
 jsr clrchn
xmsnd6
 jsr xmrclr
 jsr enablexfer
 ldx #5
 jsr chkout
 lda protoc;crc fix
 cmp #$02
 beq xmosndcrc
xmsnd77
 ldy #0
xmsnd7;crc mod
 lda (xmobuf),y
 jsr chrout
 iny
promod2 cpy #132
 bcc xmsnd7
xmmcontinue
 jsr clrchn
 jsr xmricl
 lda #3
 jsr xmmget
 bne xmsnbd
 cmp #can
 bne xmsnd8
 jmp xmabrt
xmosndcrc
jsr 	calccrc
		ldy #131
		lda	crcz+1		; save hi byte of crc to buffer
		sta	(xmobuf),y		;
		iny			;
		lda	crcz		; save lo byte of crc to buffer
		sta	(xmobuf),y	
jmp xmsnd77
;crc mod

calccrc		lda	#$00		; yes, calculate the crc for the 128 bytes
		sta	crcz		;
		sta	crcz+1		;
		ldy	#3		;
calccrc1	lda	(xmobuf),y		;
		eor 	crcz+1 		; quick crc computation with lookup tables
       		tax		 	; updates the two bytes at crc & crc+1
       		lda 	crcz		; with the byte send in the "a" register
       		eor 	crchi,x
       		sta 	crcz+1
      	 	lda 	crclo,x
       		sta 	crcz
		iny			;
		cpy	#131		; done yet?
		bne	calccrc1	; no, get next
		rts			; 128 bytes achieved, 4-131 (#03-#130)
;end crc mods
xmsnd8 cmp #nak
 bne xmsnd9
xmsnbd
 jsr chrout
 jmp xmsnd6
xmsnd9 cmp #ack
 bne xmsnbd
xmsnnx
 lda #'-'
 jsr goobad
 ldx xmoend
 bne xmsnen
 inc xmoblk
 inc xmowbf
 jmp xmupll
xmsnen
 lda #0
 sta xmoend
xmsne1
 jsr enablexfer
 ldx #5
 jsr chkout
 lda #eot
 jsr chrout
 lda #3
 jsr xmmget
 bne xmsne2
 cmp #ack
 bne xmsne2
 jmp xmfnok
xmsne2
 inc xmoend
 lda xmoend
 cmp #10
 bcc xmsne1
 jmp xmneot
;
;
xmoset
 lda #1
 sta xmoblk
 lda #0
 sta xmowbf
 sta xmobad
xmocbf
 lda xmowbf
 and #3
 sta xmowbf
 lda #<xmoscn
 sta xmobuf
 lda #>xmoscn
 sta xmobuf+1
 ldx xmowbf
 beq xmocb2
xmocb1
 lda xmobuf
 clc
 adc #$85
 sta xmobuf
 lda xmobuf+1
 adc #0
 sta xmobuf+1
 dex
 bne xmocb1
xmocb2  ldy #0
 sty xmochk
 sty xmoend
 rts
xmrclr
 lda $029d ;clear rs232 output
 sta $029e
xmricl
 lda $029b ;and input buffers
 sta $029c
 rts
xmmget
 sta xmodel
 lda #0
 sta rtca1
 sta rtca2
 sta rtca0
xmogt1
 jsr modget
 bcs xmmgt2
 ldx #0
 rts
xmmgt2
 jsr xchkcm
 jsr xmmrtc
 lda rtca0
 cmp xmodel
 bcc xmogt1
 jsr clrchn
 and #0
 ldx #1
 rts
xmmrtc
f69b ldx #$00
f69d inc rtca2
f69f bne f6a7
f6a1 inc rtca1
f6a3 bne f6a7
f6a5 inc rtca0
f6a7 sec
f6a8 lda rtca2
f6aa sbc #$01
f6ac lda rtca1
f6ae sbc #$1a
f6b0 lda rtca0
f6b2 sbc #$4f
f6b4 bcc f6bc
f6b6 stx rtca0
f6b8 stx rtca1
f6ba stx rtca2
f6bc rts
rtca1 .byte $00
rtca2 .byte $00
rtca0 .byte $00
xincbd
 lda #':'
 jsr goobad
 inc xmobad
 lda xmobad
 cmp #10
 bcs xmtrys
 rts
xchkcm
 ldx 653
 cpx #2
 beq xmcmab
 rts
xmfnok lda #'*'
 jsr goobad
 lda #0
.byte $2c
xmabrt lda #1
.byte $2c
xmneot lda #2
.byte $2c
xmtrys lda #3
.byte $2c
xmsync lda #4
.byte $2c
xmcmab lda #5
 sta xmstat
xmoext  
tsx
 cpx xmostk
 beq xmoex2
 pla
 clc
 bcc xmoext
xmoex2
 jsr xmrclr
 lda xmstat
 cmp #4
 bcc xmoex4
 jsr pnt109
 ldx #5
 jsr chkout
 ldy #8
 lda #can
xmoex3
 jsr chrout
 dey
 bpl xmoex3
xmoex4
 jsr clrchn
 jsr disablexfer
 lda #2
 jmp close
;
xmorcv
 tsx
 stx xmostk
 jsr pnt109;clear and disable/enablexfer
 jsr xmoset
 beq xmorcp
xmorc0
 jsr xincbd
xmorcp
 lda #0
 sta xmoend
xmorc1;crc fix
 jsr clear232
 jsr enablexfer
 ldx #5
 jsr chkout
 lda protoc
 cmp #$01
 beq oldxmodemout
 lda #crc
 ldx #133
 jmp newcrcout
oldxmodemout
lda #nak
ldx #132
newcrcout
sta crcrcvfix1+1
stx crcrcvfix2+1
crcrcvfix1 lda #nak
 jsr chrout
 jsr clrchn
xmorcl
 lda #1
 jsr xmmget
 beq xmorc2
xmorci
 inc xmoend
 lda xmoend
 cmp #10
 bcc xmorc1
xmrcab jmp xmabrt
xmorc2
 cmp #can
 beq xmrcab
 cmp #eot
 bne xmorcs
 lda #1
 sta xmoend
 jmp xmorak
xmorcs
 cmp #soh
 bne xmorci
 jsr xmocbf
 beq xmorc4
xmorc3
 lda #1
 jsr xmmget
 bne xmorc0
xmorc4
 sta (xmobuf),y
 iny
crcrcvfix2 cpy #132
 bcc xmorc3
 ;doing the old checksum check
 ldy #1
 lda (xmobuf),y;byte 2
 iny
 eor (xmobuf),y;byte 3 (packet #/ff check)
 cmp #$ff
 bne xmorc0
 jsr disablexfer
lda protoc
cmp #$02
beq receivecheck;bypass the checksum and go to the crc check for xmodem-crc
 lda #0
xmorc5
 iny
 cpy #131
 bcs xmorc6
 adc (xmobuf),y
 clc
 bcc xmorc5
xmorc6
 sta xmochk
 cmp (xmobuf),y;132(#131-checksum byte)
 bne xmorc0
;old checksum is done
backcrc
 ldy #1
 lda (xmobuf),y
 cmp xmoblk
 beq xmorc7
 ldx xmoblk
 dex
 txa
 cmp (xmobuf),y
 bne xmorsa
 lda #'/'
 jsr goobad
 jmp xmorc9
xmorsa  jmp xmsync
xmorc7
 jsr clrchn
 jsr disablexfer
 ldx #2
 jsr chkout
 ldy #3
xmorc8
 lda (xmobuf),y
 jsr chrout
 iny
 cpy #131
 bcc xmorc8
xmorc9
 lda #0
 sta xmoend
 inc xmoblk
 jsr clrchn
 lda #'-';good block
 jsr goobad
xmorak
 inc xmowbf
 jsr clear232
 jsr enablexfer
 ldx #5
 jsr chkout
 lda #ack
 jsr chrout
 jsr clrchn
 lda #0
 sta xmobad
 lda xmoend
 bne xmor10
 jmp xmorcl;next block
xmor10
 jmp xmfnok;end of file, send * key
;
;crc check for xmodem-crc receive
receivecheck
jsr 	calccrc
		ldy #131
		lda	crcz+1		; save hi byte of crc to buffer
		cmp	(xmobuf),y		;
		bne badcrc
		iny			;
		lda	crcz		; save lo byte of crc to buffer
		cmp	(xmobuf),y	
		bne badcrc
jmp backcrc
badcrc jmp xmorc0
;
xmopsu .text 2,'PRG, ',2,'SEQ, or ',2,'USR? ',0
xmotyp
 lda #<xmopsu
 ldy #>xmopsu
 jsr outstr
 jsr savech
xmoty2
 jsr getin
 beq xmoty2
 and #$7f
 ldx #3
xmoty3
 cmp upltyp,x
 beq xmoty4
 dex
 bne xmoty3
 beq xmoty2
xmoty4
 stx pbuf+27
 rts
;
;crc mods here
xmo1er .text 13,'tRANSFER cANCELLED.',0
xmo2er .text 13,'eot nOT aCKNOWLEGED.',0
xmo3er .text 13,'tOO mANY bAD bLOCKS!',0
xmo4er .text 13,c,'sYNC lOST!',0
xmoupl
 jsr xmosnd
 jmp xmodon
xmodow
 jsr xmorcv
xmodon
 lda #$0d
 jsr chrout
 lda xmstat
 bne xmodn2
 jmp xfrdun
xmodn2
 cmp #5
 beq xmodna
 cmp #1
 bne xmodn3
 lda #<xmo1er
 ldy #>xmo1er
 bne xmodnp
xmodn3
 cmp #2
 bne xmodn4
 lda #<xmo2er
 ldy #>xmo2er
 bne xmodnp
xmodn4 cmp #3
 bne xmodn5
 lda #<xmo3er
 ldy #>xmo3er
 bne xmodnp
xmodn5
 lda #<xmo4er
 ldy #>xmo4er
xmodnp
 jsr outstr
 jsr gong
 lda #$0d
 jsr chrout
xmodna
 jmp abortx
;xmodem-crc fix here til xferpt
xmdtxt .text 13,13,5,cx,m,'ODEM ',0
xmctxt .text 13,13,5,cx,m,'ODEM-crc ',0
xferfn
 pha
 lda protoc
 beq xferpt
 cmp #$02
 beq crctxt
 lda #<xmdtxt
 ldy #>xmdtxt
 jsr outstr
 jmp xferwc
crctxt
 lda #<xmctxt
 ldy #>xmctxt
 jsr outstr
 jmp xferwc
xferpt
 lda #<ptrtxt
 ldy #>ptrtxt
 jsr outstr
xferwc
 pla
 bne xferdw
 lda #<upltxt
 ldy #>upltxt
 clc
 bcc entfnt
xferdw
 lda #<dowtxt
 ldy #>dowtxt
entfnt
 jsr outstr
 lda #<lodtxt
 ldy #>lodtxt
 jsr outstr
entfil
 ldx #0
entfil2 
 lda #0
 sta inpbuf,x
 inx
 cpx #20
 bne entfil2
 lda #<flntxt
 ldy #>flntxt
 ldx #16
 jsr input
 php
 lda #$0d
 jsr chrout
 plp
 rts
abortx
 jsr clrchn
 lda #<abrtxt
 ldy #>abrtxt
 jsr outstr
 jsr coback
 jsr disablexfer
 lda #$02
 jsr close
 jsr enablexfer
 jmp main
xfermd  pha
 jmp xferm0
xfrmsg
 pha
 lda #15
 sta textcl
 sta backgr
 lda #$93
 jsr chrout
 lda #bcolor
 sta backgr
xferm0  lda #13
 sta 214
 lda #$0d
 jsr chrout
 lda #06
 sta textcl
 ldx #40
 lda #192
xferm1  jsr chrout
 dex
 bne xferm1
 lda #<xfrmed
 ldy #>xfrmed
 jsr outstr
 pla
 bne xferm2
 lda #<upltxt
 ldy #>upltxt
 clc
 bcc xferm3
xferm2
 lda #<dowtxt
 ldy #>dowtxt
xferm3
 jsr outstr
 lda #<xfrtxt
 ldy #>xfrtxt
 jsr outstr
 ldy #0
xferm4  lda inpbuf,y
 jsr chrout
 iny
 cpy max
 bne xferm4
 lda inpbuf,y
 jsr chrout
 lda inpbuf+1,y
 jsr chrout
 lda #$0d
 jsr chrout
 lda #<xf2txt
 ldy #>xf2txt
 jmp outstr
margin
 lda #<mrgtxt
 ldy #>mrgtxt
 jmp outstr
upltyp .byte 0,'P','S','U'
f1    ;upload
 jsr turnoffscpu
 jsr disablexfer
 jsr cosave
 lda #0
 sta mulcnt
 jsr xferfn
 bne uplfff
 jmp abortx
uplfff
 jsr ercopn
 ldy max
 lda #','
 sta inpbuf,y
 lda #$50;'P'
 sta inpbuf+1,y
 jsr filtes
 beq uplfil
 ldy max
 lda #$53;'S'
 sta inpbuf+1,y
 jsr filtes
 beq uplfil
 ldy max
 lda #$55;'U'
 sta inpbuf+1,y
uplmen
 jsr filtes
 beq uplfil
 pha
 ldx #$0f
 jsr chkin
 pla
 jmp drver3
uplfil
 ldy max
 ldx #03
fltpsr  lda upltyp,x
 cmp inpbuf+1,y
 beq fltpfo
 dex
 bne fltpsr
fltpfo  stx pbuf+27
 jmp uplok
filtes
 ldy max
 iny
 iny
 tya
 ldx #<inpbuf
 ldy #>inpbuf
 jsr setnam
 lda #02
 ldx diskdv
 ldy #00
 jsr setlfs
filopn  jsr open
 ldx #15
 jsr chkin
 jsr getin
 cmp #'0'
 beq filtso
 php
 pha
 lda #$02
 jsr close
 pla
 plp
filtso  rts
uplok
 lda #0
 jsr xfrmsg
 jsr clrchn
 lda protoc
 beq uplok2;punter
;crc fix - create tables
jsr crctable
;end crc fix
 jsr margin
 jmp xmoupl
uplok2
 jsr clear232
 jsr p49173
 jsr p49164
 lda inpbuf
 cmp #01
 bne uplcon
 jsr bell
 jmp abortx
uplcon
 jsr margin
 jsr p49173
 lda #$ff
 sta pbuf+24
 jsr p49158
xfrend
 jsr disablexfer
 lda #02
 jsr close
 jsr clrchn
 lda #$0d
 jsr chrout
 lda mulcnt
 beq xfrnrm
 rts
xfrnrm
 lda inpbuf
 cmp #$01
 bne xfrdun
 jmp abortx
xfrdun
 jsr pnt109;clear and reenable
 jsr gong
 jmp main
f3    ;download
 jsr disablexfer
 lda #0
 sta mulcnt
 jsr cosave
 jsr turnoffscpu
 lda #$01
 jsr xferfn;display "punter protocol, enter name" and input string
 bne dowfok
 jmp abortx
dowfok
 lda protoc
 beq dowfo2
 jsr xmotyp
 jmp dowmen
dowfo2
 ldy max
 lda #160
 sta inpbuf,y
 sta inpbuf+1,y
dowmen  
 lda #01
 jsr xfrmsg;set up screen
 ldx protoc
 bne dowcon
 lda inpbuf
 pha
 jsr clrchn
dowmen2 
 jsr p49173;enable rs232 to receive;pnt109
 jsr p49161;zero out punter buffers for new download and get file info from sender
 ldx inpbuf
 pla
 sta inpbuf
 lda mulcnt
 bne dowcon
 cpx #01
 bne dowcon
dowabt
 jsr bell
 jmp abortx
dowcon
 ldx #$ff
 stx pbuf+24
 jsr disablexfer
 jsr ercopn
 ldx #$0f
 jsr chkout
 lda #'I'
 jsr chrout
 lda #'0'
 jsr chrout
 lda #$0d
 jsr chrout
 jsr clrchn
 ldx #$0f
 jsr chkout
 lda #'S'
 jsr chrout
 lda #'0'
 jsr chrout
 lda #':'
 jsr chrout
 ldx #0
scrlop
 lda inpbuf,x
 jsr chrout
 inx
 cpx max
 bne scrlop
 lda #$0d
 jsr chrout
 jsr dowsfn
 lda #1
 jsr xfermd
 jsr margin
 jmp dowopn
dowsfn
 jsr clrchn
 ldx max
 lda #','
 sta inpbuf,x
 sta inpbuf+2,x
 inx
 lda #'W'
 sta inpbuf+2,x
 lda mulcnt
 bne dowksp
 ldy pbuf+27
 lda upltyp,y
 sta inpbuf,x
dowksp 
 lda max
 clc
 adc #$04
 ldx #<inpbuf
 ldy #>inpbuf
 jsr setnam
 lda #02
 ldx diskdv
 tay
 jmp setlfs
dowopn
 jsr filopn
 beq dowop2
 pha
 ldx #$0f
 jsr chkin
 pla
 jmp drver3
dowop2
 lda protoc
 beq dowop3
 jsr crctable;create crc tables;crc fix
 jmp xmodow;pick punter or xmodem here to really start downloading
dowop3 
 jsr p49173;pnt109
 jsr p49155;get data;pnt87
 jsr clear232
 jmp xfrend;close file
;
sndtxt  .text 13,13,5,2,'READ OR',2,'SEND FILE? ',00
sndtxttwo .text 'sPACE TO PAUSE - r/s TO ABORT',13,13,00
f2
 ldx 653
 cpx #02
 bne send
 jmp cf1
;send textfile
send
 jsr disablexfer
 jsr cosave
 lda #<sndtxt
 ldy #>sndtxt
 jsr outstr
 jsr savech
sndlop
 jsr getin
 cmp #'S'
 bne sndc1
 ldx #$40
 bne sndfil
sndc1
 cmp #'R'
 bne sndc2
 ldx #0
 beq sndfil
sndc2
 cmp #$0d
 bne sndlop
 jsr restch
 lda #$0d
 jsr chrout
sndabt
 jmp abortx
sndfil
 ora #$80
 jsr outcap
 lda #$0d
 jsr chrout
 stx bufflg
 stx buffl2
 jsr entfil
 beq sndabt
 lda #$0d
 jsr chrout
 lda max
 ldx #<inpbuf
 ldy #>inpbuf
 jsr setnam
 lda #<sndtxttwo
 ldy #>sndtxttwo
 jsr outstr
 lda #02
 ldx diskdv
 tay
 jsr setlfs
 jsr open
 ldx #$05
 jsr chkout
 ;lda #15
 ;jsr chrout
 jsr dskout
 lda #02
 jsr close
 lda #0
 jsr enablexfer
 jsr cochng
 lda #$0d
 jsr chrout
 jmp main
 
nickdelaybyte .byte $00

tmsetl
 ldx #0
 stx $a2
tmloop
 ldx $a2
 cpx #$03 ;***time del
 bcc tmloop
tmlop3
 ldx #255
tmlop2 dex
 bne tmlop2
 rts
 
;
;disk output routine
dskout
 jsr clrchn
 jsr curprt
 lda bufflg  ;bufflg 00=disk
 bpl dskmo   ;$40=disk w. delay
 jsr memget  ;$80=memory get
 bit bufflg  ;$ff=mem w. delay
 bvs timdel
 ldx #$ff
mrloop
 dex
 bne mrloop
 beq chstat
dskmo
 jsr disablexfer
 ldx #02
 jsr chkin
 jsr getin
 pha
 pla 
timdel
 bit bufflg
 bvc chstat
 jsr tmsetl
chstat
 pha
 lda status
 and #$40
 bne dskext
 jsr clrchn
 jsr curoff
 pla
 pha
 jsr ctrlck
 jsr chrout
 jsr qimoff
 ldx buffl2 ;non zero=to modem
 bne dskmo1
 pla
 jmp chkkey
dskmo1
 jsr clear232
 jsr enablexfer
 jsr clear232
 ldx #05
 jsr chkout
 pla
 ldx grasfl
 beq dskmo2
 jsr catosa
dskmo2
 jsr chrout
dxmmget;this timeout failsafe makes sure the byte is received back from modem
       ;before accessing disk for another byte otherwise we can have
	   ;all sorts of nmi related issues.... this solves everything.
	   ;uses the 'fake' rtc / jiffy counter function / same as xmmget...
 lda #70;timeout failsafe
 sta xmodel
 lda #0
 sta rtca1
 sta rtca2
 sta rtca0
dxmogt1
 jsr modget
 bcs dxmmgt2
 jmp chkkey
dxmmgt2
 jsr xmmrtc
 lda rtca1
 cmp xmodel
 bcc dxmogt1
chkkey
 jsr keyprs
 beq dskout
 cmp #3;run stop
 beq dskex2
 jsr enablexfer
 cmp #'S'
 bne dskwat
 lda bufflg
 bpl dskwat
 jsr skpbuf
 ldx status
 bne dskex2
 jsr enablexfer
 jmp dskout
dskwat
 jsr keyprs
 beq dskwat
 jsr enablexfer
 jmp dskout
dskext
 jsr enablexfer
 pla
dskex2
 jsr clrchn
 jmp curoff
keyprs
 jsr clrchn
 jsr getin
 cmp #0
 rts
outstr
 sty $23
 sta $22
 ldy #0
outst1 lda ($22),y
 beq outste
 cmp #2
 beq hilite
 cmp #03
 bne outst2
 iny
 lda ($22),y
 sta 214
 lda #$0d
 jsr chrout
 lda #145
 jsr chrout
 iny
 lda ($22),y
 sta 211
 bne outst4
outst2
 cmp #$c1
 bcc outst3
 cmp #$db
 bcs outst3
 lda 53272
 and #$02
 php
 lda ($22),y
 plp
 bne outst3
 and #$7f
outst3
 jsr chrout
outst4 iny
 bne outst1
 inc $23
 bne outst1
outste rts
hilite
 lda textcl
 pha
 lda #1
 sta textcl
 lda #18  ;rvs-on
 jsr chrout
 lda #161
 jsr chrout
 lda 53272
 and #2
 php
 iny
 lda ($22),y
 plp
 beq hilit2
 ora #$80
hilit2  jsr chrout
 lda #182
 jsr chrout
 pla
 sta textcl
 lda #146
 bne outst3
;
outcap
 cmp #$c1    ;cap 'a'
 bcc outcp3
 cmp #$db    ;cap 'z'
 bcs outcp3
 pha
 lda 53272
 and #2
 beq outcp2
 pla
 bne outcp3
outcp2  pla
 and #$7f
outcp3  jmp chrout
;
xmpoly .text 13,5,'mULTI-TRANSFER - pUNTER ONLY.',13,0
cf1  ;multi-send
 jsr cosave
 lda protoc
 beq mulsav
mulnop
 lda #<xmpoly
 ldy #>xmpoly
 jsr outstr
 jmp abortx
mulsav
 jsr turnoffscpu
 lda #$93
 jsr chrout
 ;lda bufptr+1;old references comparing buffer area and making sure theres enough
 ;cmp #>mulfil;room for punter files to be stored, but since we're now
 ;bcc mulsok;reserving #$ff space for punter, its not neccessary
 ;lda bufptr
 ;cmp #<mulfil
 ;bcc mulsok
 ;lda #<mlswrn
 ;ldy #>mlswrn
 ;jsr outstr
 ;jmp abortx
mulsok  lda #<msntxt
 ldy #>msntxt
 jsr outstr
 lda #<moptxt
 ldy #>moptxt
 jsr outstr
 jsr mltdir;grab files from directory listing
 lda mulcnt;some files to send?
 bne mlss1;yes
mlss0  jmp mlssab;nope, we are done
mlss1
 lda mulfln
 sta mulcnt;how many files to send. decrement until none left
 beq mlss0
 lda #0
 sta mulfln
 lda #<mulfil
 sta $fd
 lda #>mulfil
 sta $fe
mlslop
 ldy #19
 lda ($fd),y
 bne mlssen
mlsinc  
 lda $fd
 clc
 adc #20
 sta $fd
 lda $fe
 adc #0
 sta $fe
 lda $fe
 cmp #>endmulfil
 bcc mlslop
 jmp mulab2
mlssen
 ldy #17
mlss2  lda ($fd),y
 cmp #160
 bne mlss3
 dey
 cpy #01
 bne mlss2
 jmp mulab2
mlss3  dey
 sty max
 iny
mlss4  lda ($fd),y
 sta inpbuf-2,y
 dey
 cpy #01
 bne mlss4
 ldx max
 lda #','
 sta inpbuf,x
 ldy #18
 lda ($fd),y
 and #07
 cmp #04
 bne mlsg
 jmp mulabt
mlsg
 tay
 lda drtype,y
 sta inpbuf+1,x
mlsgo
 jsr mlshdr
 ldy #0
mlsgo1  lda inpbuf,y
 jsr chrout
 iny
 cpy max
 bne mlsgo1
 lda inpbuf,y
 jsr chrout
 lda inpbuf+1,y
 jsr chrout
 lda #$0d
 jsr chrout
 jsr clrchn
 jsr uplmen;disk setup
 ldx 653
 cpx #02
 beq mulab2
 lda inpbuf
 bne mulab2
 inc mulfln
 lda mulfln
 cmp mulcnt
 beq mlss5
 ldx #00
 stx $a2
mlstim  lda $a2
 cmp #110
 bcc mlstim
 jmp mlsinc
mlss5
 jsr mlshdr
 ldx #16
 lda #04  ;ctrl-d
mlss6  jsr chrout
 dex
 bne mlss6
 lda #$0d
 jsr chrout
mlssab jsr clrchn
 jsr coback
 jsr gong
 jmp term
mlshdr  
 jsr clear232
 jsr enablexfer
 ldx #5
 jsr chkout
 ldx #16
 lda #09  ;ctrl-i
mlscri  jsr chrout
 dex
 bne mlscri
 rts
mulabt
 jsr gong
mulab2
 jsr clrchn
 lda #$0d
 jsr chrout
 lda #02
 jsr close
 lda motype
 cmp #$02
 bmi mulab3
mulab3 
 jsr enablexfer
 jmp term
;
cf3  ;multi-receive
 jsr disablexfer
 jsr cosave
 lda protoc
 beq mulrav
 jmp mulnop
mulrav
jsr turnoffscpu
lda #$01
 sta mulcnt
 lda #$93
 jsr chrout
 lda #<mrctxt
 ldy #>mrctxt
 jsr outstr
mrllgc
 ldx 653
 bne mrllgc
mlrnew
 jsr enablexfer
 ldy #0
 sty max
mlrwat
 ldx 653
 cpx #02
 beq mulab2
 ldx #05
 jsr chkin
 jsr getin
 cmp #09
 bne mlrwat
mlrwt2
 ldx 653
 cpx #02
 beq mulab2
 jsr getin
 cmp #0
 beq mlrwt2
 cmp #9  ;ctrl-i
 beq mlrwt2
 bne mlrfl1
mlrflp
 ldx 653
 cpx #02
 beq mulab2
 ldx #5
 jsr chkin
 jsr getin
 cmp #0
 beq mlrflp
mlrfl1   
 cmp #$0d
 beq mlrfl2
 ldy max
 sta inpbuf,y
 inc max
 lda max
 cmp #18
 bcc mlrflp
mlrfl2
 ldy max
 cpy #03
 bcc mlfext
 dey
 dey
 lda inpbuf,y
 cmp #','
 bne mlfext
 sty max
 lda inpbuf
 cmp #04   ;ctrl-d
 bne mlffl2
mlfext  jmp mulabt
mlffl2
 jsr dowmen
 lda inpbuf
 beq mlrnew
 bne mlfext
;
goobad
 sta 1844
 cmp #'/'
 beq goober
 cmp #'*'
 bne goob2
goober  rts
goob2 cmp #':'
 beq goob3
 ldx #3
 bne goob4
goob3  ldx #25
goob4  inc 1837,x
 lda 1837,x
 cmp #':'
 bcc goober
 lda #'0'
 sta 1837,x
 dex
 bpl goob4
 rts
;
msntxt .text 13,14,5,18,32,'mULTI-sEND ',146,32,45,32
 .text 'sELECT FILES:',13,13,0
moptxt .text 154,32,'yES/nO/qUIT/sKIP8/dONE/'
 .text 'aLL',13,0
mrctxt .text 13,14,5,18,32,'mULTI-rECEIVE ',13,13
 .text 159,'wAITING FOR HEADER...c= ABORTS.',13,0
;multi - choose files
mltdir
 jsr disablexfer
 lda diskdv
 jsr listen
 lda #$f0
 jsr second
 lda #'$'
 jsr ciout
 lda #'0'
 jsr ciout
 lda #':'
 jsr ciout
 lda #'*'
 jsr ciout
 jsr unlsn
 lda #<mulfil
 sta $fd
 lda #>mulfil
 sta $fe
 lda diskdv
 jsr talk
 lda #$60
 jsr tksa
 ldy #0
 sty mulcnt ;count entries
 sty mulfln
 sty mlsall
 sty mulskp
 ldy #31
mdrlp0
 jsr mgetch
 dey
 bpl mdrlp0
 ldy #$01
mdrlp1  jsr mgetch
 dey
 bpl mdrlp1
 ldy #0
 jsr mgetch
 sta ($fd),y
 sta $07e8,y
 iny
 jsr mgetch
 sta ($fd),y
 sta $07e8,y
 lda #0
 sta $06
mdrlp2  jsr mgetch
 inc $06
 cmp #'"'
 bne mdrlp2
mdrlpf
 iny
 cpy #18
 beq drlpfn
 jsr mgetch
 cmp #'"'
 bne drlpnq
 lda #160
drlpnq
 sta ($fd),y
 sta $07e8,y
 jmp mdrlpf
drlpfn
 dey
 cpy #01
 beq drlptc
 lda $07e8,y
 cmp #' '
 bne drlptc
 lda #160
 sta ($fd),y
 sta $07e8,y
 bne drlpfn
drlptc
 jsr mgetch
 lda #00
 sta $05
 jsr mgetch
 cmp #'*'
 bne drlpsp
 lda #$80
 sta $05
drlpsp
 jsr mgetch
 ldx #04
drlptl
 cmp drtype,x
 beq drlptp
 dex
 bne drlptl
drlptp
 txa
 ora $05
 sta $05
 jsr mgetch
 jsr mgetch
 jsr mgetch
 cmp #'<'
 bne drlpte
 lda $05
 ora #$40
 sta $05
drlpte  lda $05
 ldy #18
 sta ($fd),y
 sta $07e8,y
 lda #00
 iny
 sta ($fd),y
dirgrb
 jsr mgetch
 bne dirgrb
 inc mulcnt
 lda mulskp
 bne mulpmt
 jsr mdrret
 bne mulnen
mulpmt dec mulskp
 jsr drpol7
mulnen
 lda diskdv
 jsr talk
 lda #$60
 jsr tksa
 ldy #01
 jmp mdrlp1
mgetch  jsr acptr
 ldx status
 bne mdrlp3
 cmp #00
 rts
mdrlp3  pla
 pla
mdrext  lda diskdv
 jsr listen
 lda #$e0
 jsr second
 jsr untlk
 jsr unlsn
 jsr clrchn
 jsr ercopn ; possible fix for multi upload crash on up9600 - 2018 fix
 jmp enablexfer
mdrret
 ldy #0
drpol0
 sty $02
 lda drform,y
 cmp #02   ;ctrl-b
 bne drpol1
 ldy #00
 lda $07e8,y
 tax
 iny
 lda $07e8,y
 jsr $bdcd
 ldy $06
drprbl
 lda #' '
 jsr chrout
 dey
 bne drprbl
 beq drpol4
drpol1
 cmp #$0e  ;ctrl-n
 bne drpol2
 ldy #02
drprnm
 lda $07e8,y
 jsr chrout
 iny
 cpy #18
 bne drprnm
 beq drpol4
drpol2
 cmp #$06  ;ctrl-f
 bne drpol3
 ldy #18
 lda $07e8,y
 tay
 and #07
 tax
 tya
 and #$80
 bne drprf1
 lda #' '
 bne drprf2
drprf1  lda #'*'
drprf2  jsr chrout
 lda drtype,x
 jsr chrout
 lda drtyp2,x
 jsr chrout
 lda drtyp3,x
 jsr chrout
 tya
 and #$40
 bne drprf3
 lda #' '
 bne drprf4
drprf3  lda #'<'
drprf4  jsr chrout
 bne drpol4
drpol3
 jsr chrout
drpol4
 ldy $02
 iny
 cpy #14
 beq drpol5
 jmp drpol0
drpol5
 lda mlsall
 beq mlsf0
 lda #'Y'
 jsr chrout
 bne mlsyes
mlsf0
 lda #' '
 jsr chrout
 lda #$9d
 jsr chrout
 jsr curprt
mlswlp  jsr getin
 beq mlswlp
 and #127
 cmp #'A'
 bcc mlswlp
 cmp #'['
 bcs mlswlp
 pha
 jsr curoff
 pla
 pha
 jsr chrout
 lda #$9d
 jsr chrout
 pla
 cmp #'Y'
 bne mlsf1
mlsyes  ldy #19
 inc mulfln
 lda #$80
 sta ($fd),y
 bne mlsnpr2
mlsf1  cmp #'N'
 beq mlsnpr
 cmp #'A'
 bne mlsf2
 lda #01
 sta mlsall
 bne mlsyes
mlsf2
 cmp #'D'
 bne mlsf3
 lda #$0d
 jsr chrout
 jmp mdrlp3
mlsf3
 cmp #'Q'
 bne mlsf4
 jsr mdrext
 pla
 pla
 pla
 pla
 jsr clrchn
 jmp term
mlsf4
 cmp #'S'
 bne mlsf0
 lda #07
 sta mulskp
mlsnpr  lda #$0d
 jsr chrout
drpol7
 lda $fd
 clc
 adc #0
 sta $fd
 lda $fe
 adc #0
 sta $fe
 rts
mlsnpr2  lda #$0d
 jsr chrout
drpol72
 lda $fd
 clc
 adc #20
 sta $fd
 lda $fe
 adc #0
 sta $fe
 rts
;
buftxt .byte 5
.text "bUFFER "
.byte 00
buftx2 .text " BYTES FREE.  "
.byte 13,2
.text "OPEN  "
.byte 2
.text "CLOSE  "
.byte 2
.text "ERASE  "
.byte 2
.text "TRANSFER"
.byte 13,2
.text "LOAD  "
.byte 2
.text "SAVE   "
.byte 2
.text "PRINT  "
.byte 2
.text "VIEW: "
.byte 0
opntxt .text "oPEN"
.byte 00
clotxt .text "cLOSED"
.byte 00
erstxt .text  "eRASE bUFFER! - "
.byte 2
.text "YES OR "
.byte 2
.text "NO?       "
.byte 157,157,157,15,157,157,157,0
snbtxt .byte 13,13
.text "sENDING BUFFER..."
.byte 13,13,00
dontxt .byte 13,13,5
.text "dONE."
.byte 13,0
bufreuenabledtxt .byte 5
.text "reu ",0
bufmsg
 lda bufreu
 beq bufmoveon
 lda #<bufreuenabledtxt
 ldy #>bufreuenabledtxt
 jsr outstr 
bufmoveon 
 lda #<buftxt
 ldy #>buftxt
 jsr outstr
 lda buffoc
 beq bufms1
 lda #<opntxt
 ldy #>opntxt
 clc
 bcc bufms2
bufms1
 lda #<clotxt
 ldy #>clotxt
bufms2
 jmp outstr
bufprm
 lda #$0d
 jsr chrout
 jsr bufmsg
 lda #' '
 jsr chrout
 lda #'-'
 jsr chrout
 lda #' '
 jsr chrout
 lda bufend
 sec
 sbc bufptr
 tax
 lda bufend+1
 sbc bufptr+1
 jsr outnum
 lda #<buftx2
 ldy #>buftx2
 jmp outstr
f4
 ldx 653
 cpx #02
 bne buffrc
 jmp cf3
buffrc  ;buffer cmds
 jsr cosave
bufask
 lda #$0d
 jsr chrout
 jsr bufprm
bufwat
 jsr savech
buflop
 jsr getin
 beq buflop
 and #127
 pha
 jsr restch
 pla
 cmp #$0d
 bne bufcmd
bufext
 lda #' '
 jsr chrout
 lda #$0d
 jsr chrout
 jsr chrout
 jsr coback
 jsr enablexfer
 jmp main
bufcmd
 cmp #'O'
 bne bufcm2
 ldx #$01
 stx buffoc
 bne bufex1
bufcm2
 cmp #'C'
 bne bufcm3
 ldx #0
 stx buffoc
bufex1
 ora #$80
bufexa
 jsr outcap
 lda #$0d
 jsr chrout
 lda #145 ;crsr up
 ldx #04
bufex2
 jsr chrout
 dex
 bpl bufex2
 jmp bufask
bufcm3
 cmp #'E'
 bne bufcm4
 ora #$80
 jsr outcap
 lda #$0d
 jsr chrout
 lda #145
 ldx #02
bufer1
 jsr chrout
 dex
 bpl bufer1
 lda #<erstxt
 ldy #>erstxt
 jsr outstr
 jsr savech
bufer2
 jsr getin
 beq bufer2
 and #127
 cmp #'N'
 beq bufer3
 cmp #'Y'
 bne bufer2
 jsr bufclr
bufer3
 jsr restch
 lda #145
 jsr chrout
 jsr chrout
 jmp bufask
bufcm4
 cmp #'P'
 bne bufvew
 ora #$80
 jsr outcap
 jmp bufpro
bufvew
 cmp #'V'
 bne bufcm5
 lda #$93
 jsr chrout
 lda #$80
 sta bufflg
 and #0
 sta buffl2
 jsr prtbuf
 jmp main
prtbuf ;buf.to screen
 lda buffst
 pha
 lda buffst+1
 pha
 lda #$2f
 sta $00
 lda #$36
 sta $01
 jsr dskout
 lda #$37
 sta $01
 pla
 sta buffst+1
 pla
 sta buffst
 rts
memget
 ldx buffst
 cpx bufptr
 bcc memok
 ldx buffst+1
 cpx bufptr+1
 bcc memok
memgab ldx #$40
 stx status
 rts
memok
 ldy bufreu
 beq memok2
 jsr reuread
 jmp memok3
memok2
 ldy #0
 lda (buffst),y
memok3
 inc buffst
 bne memext
 inc buffst+1
memext
 ldx #0
 stx status
 rts
skpbuf
 lda buffst+1
 cmp bufptr+1
 bcs memgab
 inc buffst+1
skpbf2
 lda buffst+1
 cmp bufptr+1
 bcc memext
 lda buffst
 cmp bufptr
 bcs memgab
 bcc memext
;
bufcm5
 cmp #'S'
 bne bufcm6
 jsr solfil
 jmp savbuf
solfil
 ora #$80
 jsr outcap
 lda #$0d
 jsr chrout
 jsr chrout
 jsr entfil
 bne solfok
 jmp abortx
solfok  rts
savbuf
 jsr disablexfer;to be save 5-13 fix?? worked without it, but this should be here
 lda #0
 sta mulcnt
 lda #$02
 sta pbuf+27
 jsr dowsfn
 lda #$36
 sta $01
 lda buffst;start of buffer
 sta $c1;I/O Start Address ($c1 $c2)
 lda buffst+1
 sta $c2
 lda bufptr;end of buffer
 clc
 adc #$01
 sta $ae;Tape End Addresses/End of Program ($ae / $af)
 lda bufptr+1
 adc #0
 sta $af
 lda #$61
 sta $b9
 jsr $f3d5;open file on serial bus
 jsr $f68f;print saving and filename
 lda $ba
 jsr $ed0c;send listen to serial bus
 lda $b9
 jsr $edb9;LSTNSA. Send LISTEN secondary address to serial bus
 ldy #0
 jsr $fb8e;Move the Tape SAVE/LOAD Address into the Pointer at 172 ($ac)
 lda bufreu
 beq afuckit
 jsr af624
 lda #$00
 sta buffst
 sta buffst+1
 jmp amoveon
afuckit jsr $f624
amoveon 
 php
 lda #$37
 sta $01
 plp
 bcc bsaved
 lda #$0d
 jsr chrout
 jsr bell
 lda #$00
 sta buffst
 sta buffst+1
 jmp abortx
;reu needs a special save routine cause craig decided to be all fancy with this one :) 
af624   jsr $fcd1;check the tape read/write pointer
af627   bcs af63f;
af629   ;lda ($ac),y
        jsr reuread
af62b   jsr $eddd;send a byte to an i/o device over the serial bus
af62e   jsr $ffe1;stop. query stop key indicator, at memory address $0091; if pressed, call clrchn and clear keyboard buffer.
af631   bne af63a
af633   jsr $f642
af636   lda #$00
af638   sec
af639   rts
af63a   
inc buffst
 lda buffst
beq anext
 jsr $fcdb
bne af624
anext inc buffst+1
  jsr $fcdb;advance tape pointer
af63d   bne af624
af63f   jsr $edfe;UNLSTN.
afnext        jmp $f642
;done
bsaved
 jsr enablexfer
 jmp bufext
bufcm6
 cmp #'L'
 bne bufcm7
 jsr solfil
lodbuf
 jsr disablexfer;5-13 put in, didnt seem to need it, need to test with it. might crash with it cause the program does that sometimes....
 lda #$02
 ldx diskdv
 tay
 jsr setlfs
 lda max
 ldx #<inpbuf
 ldy #>inpbuf
 jsr setnam
 jsr open
 ldx #$02
 jsr chkin
lodbfl
 jsr getin
 ldx status
 bne lodbex
 ldx bufptr
 cpx bufend
 bne lodbok
 ldx bufptr+1
 cpx bufend+1
 beq lodbex
lodbok
 ldy bufreu
 beq lodbokram
 jsr reuwrite
 jmp lodbokreu
lodbokram
 ldy #0
 sta (bufptr),y
lodbokreu
 inc bufptr
 bne lodbfl
 inc bufptr+1
 bne lodbfl
lodbex
 jsr clrchn
 lda #$02
 jsr close
 jsr enablexfer
 jmp bufext
bufcm7
 cmp #'T'
 beq sndbuf
 cmp #'<'
 beq bufchg
 cmp #'>'
 bne bufbak
bufchg
 jsr chgbpr
 jmp bufexa
bufbak
 jmp bufwat
sndbuf
 ora #$80
 jsr outcap
 lda #<snbtxt
 ldy #>snbtxt
 jsr outstr
 lda #$ff
 sta bufflg
 sta buffl2
 jsr prtbuf
 jsr cosave
 jsr clear232
 lda #<dontxt
 ldy #>dontxt
 jsr outstr
 jsr coback
 jsr enablexfer
 jmp main
chgbpr
 pha
 cmp #'>'
 beq chgbp3
 lda bufptr+1
 cmp #>endprg
 bne chgbp1
 lda bufptr
 cmp #<endprg
 beq chgben
chgbp1
 lda bufptr
 bne chgbp2
 dec bufptr+1
chgbp2  dec bufptr
 jmp chgben
chgbp3
 lda bufptr+1
 cmp bufend
 bne chgbp4
 lda bufptr
 cmp bufend+1
 beq chgben
chgbp4
 inc bufptr
 bne chgben
 inc bufptr+1
chgben
 ldx #1
 stx 651
 pla
 rts
;
bufpdt .text 13,13,"dEVICE",0
bufpda .text 13,cs,'ec.',ca,'.: ',0
bufpdp .text $93,13,cp,'rinting...',13,0
bufpro
 lda #<bufpdt
 ldy #>bufpdt
 ldx #1
 jsr inpset
 lda #'4'
 jsr chrout
 jsr inputl
 bne bufpr2
bufpra lda #$0d
 jsr chrout
 jmp abortx
bufpr2 lda inpbuf
 cmp #'3'
 bcc bufpra
 cmp #'6'
 bcs bufpra
 and #$0f
 pha
 lda #<bufpda
 ldy #>bufpda
 ldx #1
 jsr inpset
 lda #'7'
 jsr chrout
 jsr inputl
 beq bufpra
 lda inpbuf
 cmp #'0'
 bcc bufpra
 cmp #':'
 bcs bufpra
 and #$0f
 tay
 pla
 tax
 lda #4
 jsr setlfs
 lda #0
 jsr setnam
 lda #<bufpdp
 ldy #>bufpdp
 jsr outstr
 jsr open
 ldx status
 bne bufpr3
 lda buffst
 pha
 lda buffst+1
 pha
 lda #$2f
 sta $00
 lda #$36
 sta $01
 jsr mempro
 lda #$37
 sta $01
 pla
 sta buffst+1
 pla
 sta buffst
bufpr3
 lda #4
 jsr close
 lda #<dontxt
 ldy #>dontxt
 jsr outstr
 jsr coback
 jsr enablexfer
 jmp main
mempro
mempr2
 jsr memget
 bne mempr3
 pha
 and #$7f
 cmp #$0d
 beq memprp
 cmp #$20
 bcc mempab
memprp
 ldx #4
 jsr chkout
 pla
 jsr chrout
 ldx status
 bne mempr3
 jmp mempr2
mempab pla
 jmp mempr2
mempr3
 jmp clrchn
;
;phone book stuff begins here
entcol .byte 5
hilcol .byte 158
phhtxt
.byte 19,13
.byte 5,18,161
.text "crsr kEYS"
.byte 182,146,154
.text " - mOVE"
.byte 5,18,161
.text "rETURN"
.byte 182,146,154
.text " - sELECT"
.byte 13
.byte 159,2
.text "DIAL uNLISTED #  "
.byte 2
.text "EDIT cURRENT #"
.byte 13
.byte 2
.text "CALL cURRENT #   "
.byte 2
.text "A-dIAL sELECTED"
.byte 13,2
.text "REVERSE cALL     "
.byte 2
.text "X-rETURN tO mENU"
.byte 13
.byte 152,3,5,0,18
.text "           >>>pHONE bOOK<<<           "
.byte 29,20,32,157,148,32,13,0
stattx .byte 152,3,21,0,18
.text "                                      "
.byte 29,20
.byte 32,157,148,32,13,145,18,0
staptx .byte 152,3,21,0,18,32,0
.byte 0
toetxt .byte 3,6,0,0
curbtx .byte 3,22,1,159
.text "nAME:"
.byte 13
.text "   ip:"
.byte 13,32
.text "pORT: "
.byte 29,29,29,29,29
.text " id: "
.byte 29,29,29,29,29,29,29,29,29,29,29
.text " tRY: "
.byte 29,29,29,29,20,145,13,0
curbt3 .byte 3,22,1,159
.text "nAME:"
.byte 13
.text " dIAL:"
.byte 13,32
.text "      "
.byte 29,29,29,29,29
.text "     "
.byte 29,29,29,29,29,29,29,29,29,29,29
.text " tRY: "
.byte 29,29,29,29,20,145,13,0
curbt2 .text 159," pw:             ",0
curbt4 .text 159," id: ",0
nontxt .byte 5
.text "(nONE)             "
.byte 13,0
clrlnt .byte 3,22,7
.text "                  "
.byte 3,22,7,5,0
empbbs .byte 151,164,164,164,164,164,164,164,164,164,164,164,164
 .byte 164,164,164,164,164,164
curbbs .byte 146
colbbs .byte 153
nambbs .text "                "
.byte 146,5,0
curpik .byte 0
tmppik .byte 0
bautmp .byte 6
gratmp .byte 0
prtstt
 pha
 tya
 pha
 lda #<staptx
 ldy #>staptx
 jsr outstr
 pla
 tay
 pla
 jsr outstr
 lda #$20
prtst2  ldx 211
 cpx #39
 bcs prtst3
 jsr chrout
 bne prtst2
prtst3  rts
phnptr
 lda curpik
 sta nlocat
 lda #83      ;len of one entry
 sta nlocat+1
 jsr multpy
 jmp phnpt4
multpy  clc
 lda #$00
 ldx #$08
phnpt2  ror a
 ror nlocat
 bcc phnpt3
 clc
 adc nlocat+1
phnpt3  dex
 bpl phnpt2
 sta nlocat+1
 rts
phnpt4
 lda nlocat
 clc
 adc #<phbmem
 sta nlocat
 lda nlocat+1
 adc #>phbmem
 sta nlocat+1
 ldy #$00
 rts
onpent
 lda hilcol
 bne prten0
prtent
 lda entcol
prten0  sta colbbs
prten1  lda #146
 sta curbbs
 ldy #0
 lda (nlocat),y
 beq prtcur
 lda #18
 sta curbbs
prtcur   ldy #2
prten2   lda (nlocat),y;print bbs name in list
 sta nambbs-2,y
 iny
 cpy #20;length of bbs name
 bcc prten2
 lda nambbs
 bne prten4
 ldy #1
prten3  lda empbbs,y;print lines in place of empty bbs names
 sta colbbs,y
 iny
 cpy #19
 bcc prten3
 lda colbbs
 cmp hilcol
 beq prten4
 lda empbbs
 sta colbbs
prten4
 ldy #$00
prten5  lda curbbs,y
 beq prten6
 jsr chrout
 iny
 bne prten5
prten6  lda #$0d
 jmp chrout
;
clrent
 lda #0
 sta curpik
clren1
 jsr phnptr
 lda #0
 sta (nlocat),y
 inc curpik
 lda curpik
 cmp #30
 bcc clren1
 jmp phinit
;
phinit
 lda #$30
 sta trycnt
 sta trycnt+1
 lda #$00
 sta curpik
 jsr clrchn
 lda #<phhtxt
 ldy #>phhtxt
 jsr outstr
 lda #<toetxt
 ldy #>toetxt
 jsr outstr
phini2
 lda #29
 jsr chrout
 jsr phnptr
 jsr prtent
 inc curpik
 lda curpik
 cmp #15
 bcc phini2
 lda #<toetxt
 ldy #>toetxt
 jsr outstr
phini3  lda #21  ;col 21
 sta 211
 jsr phnptr
 jsr prtent
 inc curpik
 lda curpik
 cmp #30
 bcc phini3
 lda #<stattx
 ldy #>stattx
 jsr outstr
 lda #0
 sta curpik
 lda #<curbtx
 ldy #>curbtx
 jsr outstr
 rts
phnroc .byte 3,0,0,0
arrowt .byte 32,93,93,32,60,125,109,62,32,32,0
hilcur
 ldx curpik
 inx
 txa
 and #$0f
 clc
 adc #5
 sta phnroc+1  ;row
 lda #1
 sta phnroc+2  ;col
 lda curpik
 cmp #15
 bcc hilcu2
 inc phnroc+1
 lda #21
 sta phnroc+2
hilcu2
 lda colbbs
 cmp hilcol
 bne hilcu7
 ldx toetxt+1
hilcu3
 lda $ecf0,x
 sta nlocat
 lda $d9,x
 and #$7f
 sta nlocat+1
 ldy #0
 cpx phnroc+1
 bne hilcu4
 ldy #4
 bne hilcu5
hilcu4
 bcc hilcu5
 ldy #8
 bne hilcu6
hilcu5
 lda phnroc+2
 cmp #20
 bcc hilcu6
 iny
 iny
hilcu6
 lda arrowt,y
 pha
 lda arrowt+1,y
 ldy #20
 sta (nlocat),y
 pla
 dey
 sta (nlocat),y
 lda nlocat+1
 clc
 adc #212
 sta nlocat+1
 lda #5  ;green
 sta (nlocat),y
 iny
 sta (nlocat),y
 inx
 cpx #21
 bcc hilcu3
hilcu7
 lda #<phnroc
 ldy #>phnroc
 jsr outstr
 jsr phnptr
 jmp prten1
posnam
 ldx curbtx+1
 dex
 stx 214
 lda #$0d
 jsr chrout
 lda #7  ;start at col 7
 sta 211
 rts
;
shocol .byte 1,1
shocur
 jsr posnam
 lda #5
 sta colbbs
 lda #146
 sta curbbs
 ldy #2
 lda (nlocat),y
 bne shocrp
 lda #<nontxt
 ldy #>nontxt
 jsr outstr
 jmp shocr0
shocrp jsr prtcur;print current on top list
shocr0 lda #7
 sta 211
 ldy #20
shocr1 lda (nlocat),y
 beq shocr2
 jsr chrout
 iny
 cpy #52;length of ip address
 bcc shocr1
shocr2  lda #$20
 ldx 211
 cpx #39;clear line for next one
 bcs shocr3
 jsr chrout
 bne shocr2
shocr3
 ;lda unlisted
 ;bne shotty
shobau;start display of bottom line
 lda #23
 sta 214
 lda #$0d
 jsr chrout
 lda #7
 sta 211
 lda shocol
 sta 646
 lda unlisted
 bne shocr5
 ldy #53
shocr4 lda (nlocat),y
 beq shocr5
 jsr chrout
 iny
 cpy #58;end of port
 bcc shocr4
shocr5  lda #$20
 ldx 211
 cpx #12;clear line for next one
 bcs shocr66
 jsr chrout
 bne shocr5
shocr66  lda #17
 sta 211
 lda unlisted
 bne shocr7
 ldy #59;start of user id
shocr6 lda (nlocat),y
 beq shocr7
 jsr chrout
 iny
 cpy #70;end of user id
 bcc shocr6
shocr7  lda #$20
 ldx 211
 cpx #29;clear line for next one
 bcs shocr8
 jsr chrout
 bne shocr7
shocr8
shotty
 lda #34
 sta 211
 lda #7
 sta 646
 lda #<trycnt
 ldy #>trycnt
 jsr outstr
 lda unlisted
 bne shotty3
shotty2 
 lda #<curbtx
 ldy #>curbtx
 jsr outstr
 lda #19
 jmp chrout
shotty3 
 lda #<curbt3
 ldy #>curbt3
 jsr outstr
 ;lda #$00
 ;sta unlisted
 lda #19
 jmp chrout
;

xorall
 lda #0
 sta curpik
xoral2
 jsr xorent
 inc curpik
 lda curpik
 cmp #30
 bcc xoral2
 rts
xorent
 jsr phnptr
 ldy #2
 lda (nlocat),y
 bne xortog
xorabt rts
xortog
 ldy #0
 lda (nlocat),y
 eor #$01
 sta (nlocat),y
 rts
;
newent
 jsr posnam
 ldx #18
 ldy #0
 jsr inpset
 ldy #2
 lda (nlocat),y
 bne newen2
 dey
 lda bautmp
 sta (nlocat),y
 lda gratmp
 lsr a
 ror a
 ora (nlocat),y
 sta (nlocat),y
 lda #<clrlnt
 ldy #>clrlnt
 jsr outstr
 jmp newen4
newen2
 ldy #17
newenl lda nambbs,y
 cmp #$20
 bne newen3
 dey
 bpl newenl
newen3 iny
 tya
 clc
 adc 211
 sta 211
newen4
 lda #1
 sta 646
 jsr inputl
 lda #0
 sta inpbuf,x
 cpx #0
 bne neweok
newugh jmp zerent
neweok
 lda inpbuf
 cmp #$20
 beq newugh
 ldy #19
 lda #$20
newen5  sta (nlocat),y
 dey
 cpy #1
 bne newen5
 iny
 lda inpbuf
 sta (nlocat),y
 ldx #0
 ldy #2
newen6 lda inpbuf,x
 beq newen7
 sta (nlocat),y
 iny
 inx
 cpx #18
 bcc newen6
newen7;start of ip address
 lda #$0d
 jsr chrout
 lda #7
 sta 211
 ldy #0
 ldx #32;max length of entry
 jsr inpset
 ldy #20;top of entry
newen8 lda (nlocat),y
 beq newen9
 iny
 cpy #52;end of entry
 bcc newen8
newen9 tya
 sec
 sbc #20;start of entry
 clc
 adc 211
 sta 211
 jsr inputl
 lda #0
 sta inpbuf,x
 cpx #0
 bne newpok
 ldy #2
 sta (nlocat),y
 jmp newent
newpok
 tax
 ldy #20;start of entry
newena  lda inpbuf,x
 sta (nlocat),y
 beq newenb
 iny
 inx
 cpy #52;end of entry plus 1
 bcc newena
newenb
 ldy #23
 lda #$20
dalun2p sta 1996,y;$079f
 dey
 bpl dalun2p
newen7a
 lda #$0d
 jsr chrout
 lda #7;start spot
 sta 211
 ldy #0
 ldx #5;max length of entry
 jsr inpset
 ldy #53;top of entry
newen8a lda (nlocat),y
 beq newen9a
 iny
 cpy #58;end marker of entry
 bcc newen8a
newen9a tya
 sec
 sbc #53;top marker of entry
 clc
 adc 211
 sta 211
 jsr inputl
 lda #0
 sta inpbuf,x
 cpx #0
 bne newpoka
 ldy #53
 sta (nlocat),y
 lda #$91
 jsr chrout
 jmp newenb
newpoka
 tax
 ldy #53;top of entry
newenaa  lda inpbuf,x
 sta (nlocat),y
 beq newenba
 iny
 inx
 cpy #58;end marker of entry plus one
 bcc newenaa
newenba
;display ID:
newen7id
 lda #12
 sta 211
 lda #<curbt4
 ldy #>curbt4
 jsr outstr
 lda #5
 jsr chrout
;display current id
 lda #17
 sta 211
 ldy #59;start of password
shocr6id lda (nlocat),y
 beq newen7b
 jsr chrout
 iny
 cpy #70;end of id
 bcc shocr6id 
;enter id
newen7b
 lda #17;start spot
 sta 211
 ldy #0
 ldx #11;max length of entry
 jsr inpset
 ldy #59;top of entry
newen8b lda (nlocat),y
 beq newen9b
 iny
 cpy #70;end marker of entry
 bcc newen8b
newen9b tya
 sec
 sbc #59;top marker of entry
 clc
 adc 211
 sta 211
 jsr inputl
 lda #0
 sta inpbuf,x
 cpx #0
 bne newpokb
 ldy #59
 sta (nlocat),y
 jmp newen7c
newpokb
 tax
 ldy #59;top of entry
newenab  lda inpbuf,x
 sta (nlocat),y
 beq newenbb
 iny
 inx
 cpy #70;end marker of entry plus one
 bcc newenab
newenbb
;enter password
newen7c
 lda #12
 sta 211
 lda #<curbt2
 ldy #>curbt2
 jsr outstr
 lda #5
 jsr chrout
;display current pw
shocr66a  lda #17
 sta 211
 ldy #71;start of password
shocr6a lda (nlocat),y
 beq shocr7a
 jsr chrout
 iny
 cpy #82;end of password
 bcc shocr6a
shocr7a 
 lda #17;start spot
 sta 211
 ldy #0
 ldx #11;max length of entry
 jsr inpset
 ldy #71;top of entry
newen8c lda (nlocat),y
 beq newen9c
 iny
 cpy #82;end marker of entry
 bcc newen8c
newen9c tya
 sec
 sbc #71;top marker of entry
 clc
 adc 211
 sta 211
 jsr inputl
 lda #0
 sta inpbuf,x
 cpx #0
 bne newpokc
 ldy #71
 sta (nlocat),y
 jmp newenbc
newpokc
 tax
 ldy #71;top of entry
newenac  lda inpbuf,x
 sta (nlocat),y
 beq newenbc
 iny
 inx
 cpy #82;end marker of entry plus one
 bcc newenac
newenbc
 lda #<stattx
 ldy #>stattx
 jmp outstr
zerent
 ldy #83
 lda #0
zeren2  sta (nlocat),y
 dey
 bpl zeren2
 rts
;
tmpopt .byte 00
tmpmax .byte 00
tmptmp .byte 00
newsel
 jsr getin
 cmp #$2b;+
 bne newsl2
 inc tmpopt
 lda tmpopt
 cmp tmpmax
 bcc newsl1
 lda #0
 sta tmpmax
newsl1 sec
 rts
newsl2 cmp #$2d
 bne newsl3
 dec tmpopt
 bpl newsl1
 ldx tmpmax
 dex
 stx tmpopt
 sec
 rts
newsl3 cmp #$0d
 bne newsel
 clc
 rts
;
phbook
 lda #$93
 jsr chrout
 jsr phinit
phloop
 lda #$30
 sta trycnt
 sta trycnt+1
 lda hilcol
 sta colbbs
 jsr hilcur
 jsr shocur
phbget
 jsr getin
 cmp #$00
 beq phbget
 cmp #157  ;left
 bne phb2
 lda curpik
 sbc #15
 bcs phnupd
 adc #30
 jmp phnupd
phb2  cmp #29 ;right
 bne phb3
 lda curpik
 clc
 adc #15
 cmp #30
 bcc phnupd
 sbc #30
 jmp phnupd
phb3  cmp #145 ;up
 bne phb4
 lda curpik
 sbc #1
 bcs phnupd
 adc #30
 jmp phnupd
phb4  cmp #17  ;down
 bne phb5
 lda curpik
 clc
 adc #1
 cmp #30
 bcc phnupd
 sbc #30
phnupd
 pha
 lda entcol
 sta colbbs
 jsr hilcur
 pla
 sta curpik
 jmp phloop
phb5
 cmp #19
 bne phb6
phbhom  lda #0
 beq phnupd
phb6
 cmp #$93
 bne phb7
 jsr clrent
 jsr phinit
 jmp phloop
phb7
 and #$7f
 cmp #$58;x
 bne phb8
 jmp f7
phb8
 cmp #$20
 beq phnsel
 cmp #$0d
 bne phb9
phnsel  ldy #2
 lda (nlocat),y
 bne phntog
phabrt jmp phbget
phntog
 ldy #0
 lda (nlocat),y
 eor #$01
 sta (nlocat),y
 jmp phloop
phb9  cmp #$52;r
 bne phb10
 jsr xorall
 jsr phinit
 jmp phloop
phb10
 cmp #$45
 bne phb11
 jsr newent
 jmp phloop
phb11
 cmp #$43
 bne phb12
 jmp dialts
phb12
 cmp #$41
 bne phb13
 jmp dalsel
phb13
 cmp #$44
 bne phb14
 jmp dalunl
phb14
 jmp phbget
;
dialts
 lda #0
 sta daltyp
 lda #<calctx
 ldy #>calctx
 jsr prtstt
;
dialcr
jsr xferidpw
 jsr phnptr
 ldy #20
dialc1 lda (nlocat),y
 beq dialc2
 sta numbuf-20,y
 iny
 cpy #52
 bcc dialc1
dialc2
 lda #$3a
 sta numbuf-20,y
dialc5
 tya
 tax
 inx
 ldy #53
dialc4 lda (nlocat),y
 beq dialc6
 sta numbuf-20,x
 iny
 inx
 cpy #58
 bcc dialc4
dialc6
 lda #$0d
 sta numbuf-20,x
 lda numbuf
 cmp #$0d
 bne dialc3
 lda #0
 sta whahap
 jmp dalfin
dialc3;to be deleted - routine to use baud rate and c/g from phonebook entry
 lda #$00
 sta unlisted
 jmp dial
;
dalfin
 lda #$00
 sta unlisted
 lda whahap
 cmp #1
 bne dalf2    ;connected
 lda #<conntx
 ldy #>conntx
dalnv
 jsr prtstt
 lda #$e0
 sta $a2
dalfcl  lda $a2
 bne dalfcl
 lda #$0f
 sta $d418
 ;lda trycnt; this was just to be cute but not neccessary anymore
 ;cmp #4
 ;bcc dalfc1
 ;jsr gong
 ;jmp dalfc2
dalfc1 jsr bell
dalfc2
dalterm
 jmp term
dalf2
 cmp #2      ;aborted
 bne dalf3
 jmp dalfab
dalf3
 cmp #0
 bne dalf4
 lda daltyp  ;no connect
 cmp #2
 bcs dalslc
 lda numbuf
 cmp #$0d
 bne dalag
 jmp dlabrt
dalag
 jmp adnum   ;redial for curr/unl
dalslc
 lda #<stattx
 ldy #>stattx
 jsr outstr
 jmp dalsl0
dalsel  ;dial selected
 lda #$30
 sta trycnt
 sta trycnt+1
 lda #<dalstx
 ldy #>dalstx
 jsr prtstt
dalsl0
 lda #2
 sta daltyp
 lda curpik
 sta tmppik
 lda entcol
 sta colbbs
 jsr hilcur
 lda trycnt+1
 cmp #$30
 beq dalsl3
dalsl1
 inc curpik
 lda curpik
 cmp #30
 bcc dalsl2
 lda #0
 sta curpik
dalsl2
 cmp tmppik
 bne dalsl3
 jmp dlabrt
dalsl3
 jsr phnptr
 ldy #0
 lda (nlocat),y
 beq dalsl1
 lda hilcol
 sta colbbs
 jsr hilcur
 jsr shocur
 jmp dialcr
dalf4
dalfab
 lda #<stattx
 ldy #>stattx
 jsr outstr
 jmp phloop
;
curunl
.byte 145,13,32,159
.text "pORT: "
.byte 05,0
prtunl
.byte 145,13,32,159
.text "dIAL: "
.byte 05,0
unlisted .byte $00
unltemp .byte $00
dalunl
 lda #1
 sta daltyp
 lda entcol
 sta colbbs
 jsr hilcur
 lda #<dulstx
 ldy #>dulstx
 jsr prtstt
 lda grasfl
 beq dalun1
 lda #$80
dalun1  
 jsr shocr3
 lda #<clrlnt
 ldy #>clrlnt
 jsr outstr
 lda #<unlstx
 ldy #>unlstx
 jsr outstr
 ldy #80
 lda #$20
dalun2 sta 1951,y;$079f
 dey
 bpl dalun2
 lda #7
 sta 211
 ldy #0
 ldx #32
 jsr input
 bne dalun3
 jmp dlabrt
dalun3
 ldx #$00
dalun6
 lda inpbuf,x
 sta numbuf,x
inx
lda inpbuf,x
bne dalun6
lda #$3a
sta numbuf,x
inx
 stx unltemp
dalun7
 ldy #80
 lda #$20
dalun9 sta 1951,y;$079f
 dey
 bpl dalun9
 lda #<curunl
 ldy #>curunl
 jsr outstr
 lda #7
 sta 211
 ldy #0
 ldx #5
 jsr input
bne dalun8
jmp dlabrt 
dalun8
ldx #$00
ldy unltemp
dalun4  lda inpbuf,x
 sta numbuf,y
 inx
 iny
 lda inpbuf,x
 bne dalun4 
 lda #$0d
 sta numbuf,y
 iny
 lda #$00
 sta numbuf,y
 ldy #$00
 lda #<prtunl
 ldy #>prtunl
 jsr outstr
 lda #<numbuf
 ldy #>numbuf
 jsr outstr
 lda #$91
 jsr chrout
 lda #$01
 sta unlisted
 jmp dial
;
calctx .text 'cALL cURRENT nUMBER...',0
dalstx .text 'dIAL sELECTED nUMBERS...',0
dulstx .text 'dIAL uNLISTED nUMBER.',0
unlstx .text 'uNLISTED.',13,0
wcrtxt .text 'wAITING fOR cARRIER...',0
pabtxt .text 'dIALING...  ',cp,'RESS ',cs,t,o,cp,' TO ABORT.',0
numptr .byte 0
trycnt .byte 0,0,0 ;how many tries?
daltyp .byte 0 ;0=curr, 1=unlisted
              ;2=selected
whahap .byte 0 ;status after call
;0=busy/no carrier, 1=connect
;2=aborted w/stop , 3=dunno(1660)
;
;main body of dialer
dial
adnum
 lda #$0d
 jsr chrout
await0
 lda unlisted;unlisted gets a pass on the empty entry check;new mods for beta 7
 bne await01
 ldy #2;empty entry? don't dial!
 lda (nlocat),y
 bne await01
 jmp dlabrt
await01
 lda #$96      ;1.75 sec delay
 sta $a2
await1
 jsr getin    ;check r/s
 cmp #$03
 bne awaitl
 jmp dlabrt
awaitl
 lda $a2
 bne await1
adbegn
 lda #$88       ;2 sec delay
 sta $a2        ;for dial tone
await2
 lda $a2
 bne await2
 inc trycnt+1
 lda trycnt+1
 cmp #$3a
 bcc dialnoinc
 inc trycnt
 lda trycnt
 cmp #$3a
 beq dlabrt
 lda #$30
 sta trycnt+1
dialnoinc
 jsr shocr3
dialin
 ldy #31
 lda #1
dlwhtl sta 56223,y
 dey
 bpl dlwhtl
dlinit
 lda #<pabtxt  ;print stop aborts
 ldy #>pabtxt  ;
 jsr prtstt
smrtdl      ;hayes/paradyne dial
 jsr clear232
 jsr enablemodem
 ldx #$05
 jsr chkout
 lda #<pr3txt
 ldy #>pr3txt
 jsr outmod
 lda mopo1
 bne haydat
 lda #<atdtxt;atdt
 ldy #>atdtxt
 jmp haydatcont
haydat
 lda #<atdtxt2;atd
 ldy #>atdtxt2
haydatcont 
 jsr outstr
 ldx #$00
hayda4  stx numptr
 ldx numptr
 lda #14
 sta 56223,x
 ldx numptr
 lda numbuf,x
 jsr chrout
 ldx numptr
 inx
 cmp #$0d
 bne hayda4 
 jsr clrchn
hayda6
 jmp haybus
haynan
 lda #<nantxt
 ldy #>nantxt
 jsr prtstt
 jmp haybk2
haybak
 lda #<bustxt
 ldy #>bustxt
 jsr prtstt
haybk2
 lda #$c8
 sta $a2
haybk3  lda $a2
 bne haybk3
 jsr haydel
 jmp redial
haycon  
 jsr haydel
 lda #1     ;set connect flag
 sta whahap
 jmp dalfin
haydel
 lda #$e8
 sta $a2
 ldx #$05
 jsr chkin
haydll  jsr getin
 cmp #$0d
 beq haydlo
 lda $a2
 bne haydll
haydlo  
 jsr clrchn
 rts
dlabrt
 lda #$d0
 sta $a2        ;short delay
dlablp
 lda $a2
 bne dlablp     ;back to phbook
dgobak
 lda #2
 sta whahap
 jmp dalfin
redial
 lda #$80
 sta $a2
rddel1          ;2 second delay
 lda $a2        ;before restart
 bne rddel1
rgobak
 lda #0
 sta whahap     ;set redial flag
 jmp dalfin     ;back to phbook
outmod
 jsr outstr
outmo1  lda #$e0
 sta $a2
outmo2  lda $a2
 bne outmo2
 rts
;
nicktime .byte $00 
atdtxt .text 'ATDT',0
atdtxt2 .text 'ATD',34,0;adds a " before dialing the bbs cause zimmers firmware needs this
athtxt .text 'ATH',13,0
atplus .text '+++',0
pr3txt .text 'ATV1',13,0
bustxt .text "bUSY",0
nantxt .text "nO cARRIER",0
conntx .text "cONNECT!",0
tdelay .byte 00

;CARRIER / BUSY / NO ANSWER DETECT

bustemp .byte $00

haybus
ldy #$00
sty bustemp
haybus2
jsr newgethayes
haybus3
jsr puthayes
cpy #$ff
beq hayout;get out of routine. send data to terminal, and set connect!
jsr newgethayes
cmp #$62 ;b
bne haynocarr;move to check for no carrier
jsr puthayes
jsr newgethayes
cmp #$75 ;u
bne haybus3
jsr puthayes
jsr newgethayes
cmp #$73 ;s
bne haybus3
jsr puthayes
jsr newgethayes
cmp #$79 ;y
bne haybus3
ldy #$00
sty bustemp
jmp haybak ; busy!
;
haynocarr
cmp #$6e ;n
bne haybusand;move to next char
jsr puthayes
jsr newgethayes
cmp #$6f ;o
bne haybus3
jsr puthayes
jsr newgethayes
cmp #$20 ;' '
bne haybus3
jsr puthayes
jsr newgethayes
cmp #$63 ;c
bne haynoanswer
jsr puthayes
jsr newgethayes
cmp #$61 ;a
bne haybus3
jsr puthayes
jsr newgethayes
cmp #$72 ;r
bne haybus3
jsr puthayes
jsr newgethayes
cmp #$72 ;r
bne haybus3
ldy #$00
sty bustemp
jmp haynan ; no carrier!
;
haybusand
cmp #$42 ;b
bne haynocarrand;move to check for no carrier
jsr puthayes
jsr newgethayes
cmp #$55 ;u
bne haybus3
jsr puthayes
jsr newgethayes
cmp #$53 ;s
bne haybus3
jsr puthayes
jsr newgethayes
cmp #$59 ;y
bne haybus3
ldy #$00
sty bustemp
jmp haybak ; busy!
;
haynocarrand
cmp #$4e ;n
bne haybus3;move to next char
jsr puthayes
jsr newgethayes
cmp #$4f ;o
bne haybus3
jsr puthayes
jsr newgethayes
cmp #$20 ;' '
bne haybus3
jsr puthayes
jsr newgethayes
cmp #$43 ;c
bne haynoanswerand
jsr puthayes
jsr newgethayes
cmp #$41 ;a
bne haybus3
jsr puthayes
jsr newgethayes
cmp #$52 ;r
bne haybus3
jsr puthayes
jsr newgethayes
cmp #$52 ;r
bne haybus3
ldy #$00
sty bustemp
jmp haynan ; no carrier!

haynoanswerand
cmp #$41 ;a
bne haybus3
jsr puthayes
jsr newgethayes
cmp #$4e ;n
bne haybus3
jsr puthayes
jsr newgethayes
cmp #$53 ;s
bne haybus3
jsr puthayes
jsr newgethayes
cmp #$57 ;w
bne haybus3
ldy #$00
sty bustemp
jmp haynan ; no carrier!

haynoanswer
cmp #$61 ;a
bne haybus3
jsr puthayes
jsr newgethayes
cmp #$6e ;n
bne haybus3
jsr puthayes
jsr newgethayes
cmp #$73 ;s
bne haybus3
jsr puthayes
jsr newgethayes
cmp #$77 ;w
bne haybus3
ldy #$00
sty bustemp
jmp haynan ; no carrier!

;
hayout 
sty bustemp
jmp haycon
;
newgethayes
inc waittemp;timeout for no character loop so
ldx waittemp;so it doesn't lock up
cpx #$90;maybe change for various baud rates
beq newget2
ldx #$05
jsr chkin
jsr getin
beq newgethayes

newget2
ldx #$00
stx waittemp 
 rts

puthayes
ldy bustemp
iny 
sty bustemp
sta tempbuf,y 
rts

waittemp .byte $00
;
losvco
 jsr disablexfer
 jsr ercopn
 lda #<svctxt
 ldy #>svctxt
 ldx #16
 jsr inpset
 lda #<conffn
 ldy #>conffn
 jsr outstr
 jsr inputl
 beq losvex
 txa
 ldx #<inpbuf
 ldy #>inpbuf
 jsr setnam
 lda #2
 ldx diskdv
 ldy #0
 jsr setlfs
 ldx $b7
losvex
 rts
svconf
 lda efbyte;are we in easyflash mode?
 beq svcon44;no? then just go to disk mode
 lda diskoref;is config in easyflash or disk mode?
 beq savecfef
svcon44 
 jsr losvco
 bne svcon2
svcon2
 ldx #15
 jsr chkout
 ldx #0
svcon3 lda scracf,x
 beq svcon4
 jsr chrout
 inx
 bne svcon3
svcon4
 ldx #0
svcon5  lda inpbuf,x
 jsr chrout
 inx
 cpx max
 bcc svcon5
 lda #$0d
 jsr chrout
 jsr clrchn
 lda #<config
 sta nlocat
 lda #>config
 sta nlocat+1
 lda #nlocat
 ldx #<endsav
 ldy #>endsav
 jsr $ffd8
 jsr losver
losvab rts
savecfef
 jmp writeconfigef
loconf
 lda efbyte;do we have an easyflash?
 beq loadcf2;nope, we are using the non-easyflash version
 lda diskoref
 beq loadcfef
loadcf2 
 jsr losvco
 beq losvab
loadcf 
 ldx #<config
 ldy #>config
 lda #0  ;load
 jsr $ffd5
 jsr losver
loadcfpart2
 jsr themeroutine
 jsr rsopen
 rts
loadcfef
 jsr readconfigef
 jmp loadcfpart2
losver
jsr disablemodem
 ldx #15
 jsr chkin
losve2  jsr getin
 cmp #$0d
 bne losve2
 jmp clrchn

 
decoen
viewmg
 lda #<ampag1
 ldy #>ampag1
 jsr outstr
 lda #0
 sta 198
viewm1
 lda 198
 beq viewm1
 lda #<ampag2
 ldy #>ampag2
 jsr outstr
 lda #0
 sta 198
viewm2
 lda 198
 beq viewm2
 rts
;
prwcmc
 lda macxrg
 and #$c0
 asl a
 rol a
 rol a
 asl a
 clc
 adc #$31;1
 sta edfktx
 rts
edtmtx .text $93,5,13,13,e,'DIT WHICH MACRO?',13
.text 158,'(ctrl f1 / f3 OR return ' 
.text 'TO ABORT.) ',5,3,2,18,0
edtrtx .text 19,13,5,e,'DIT ',f
edfktx .text '1 mACRO...<',c,t,cr,l,'-',cx,'> TO END:',13,13,13,13,0
wchmac .byte 0
macfull .byte 0
edtmac
 lda #<edtmtx
 ldy #>edtmtx
 jsr outstr
 jsr savech
edtmlp  lda 197
 cmp #1  ;return
 bne edtmc2
edtmab  rts
edtmc2 cmp #4
 bcc edtmlp
 cmp #6
 bcs edtmlp
 pha
 jsr restch
 pla
 tax
edtmc3
 lda 197
 cmp #7
 bcc edtmc3
 jsr prmacx
 sta wchmac
edtmen
 lda #0
 sta 198
 lda #$93
 jsr chrout
 lda #0
 sta $d020
 sta $d021
edtstr
 jsr prwcmc
 lda #<edtrtx
 ldy #>edtrtx
 jsr outstr
 lda #1
 sta macmdm
 sta cursfl
 lda wchmac
 sta macxrg
 clc
 adc #62
 sta macfull
 jsr restch
 lda #$20
 jsr chrout
 lda #157
 jsr chrout
 jsr prtmc0
edtinp jsr curprt
edtkey
 jsr getin
 beq edtkey
 cmp #16 ;ctrl-p
 beq edtmen
 cmp #19    ;no home or clr
 beq edtkey
 cmp #$93
 bne edtky1
 ldx macxrg
edtclr
 lda #0
 sta macmem,x
 cpx wchmac
 beq edtky0
 dex
 jmp edtclr
edtky0 ldx wchmac
 stx macxrg
 jmp edtmen
edtky1
 cmp #24 ;ctrl-x
 beq edtbye
 cmp #20 ;del
 bne edtky2
 lda macxrg
 cmp wchmac
 beq edtkey
 tax
 jsr edtdel
 bcs edtmen
 lda macxrg
 and #$3f
 cmp #$3f
 bne edtkey
 jmp edtmen
edtky2
 ldx 214
 cpx #23
 bcs edtkey
 cpx #3
 bcc edtkey
edtky3
 ldx macxrg
 cpx macfull;64 bytes of memory per macro
 bcs edtkey
 sta macmem,x
 pha
 txa
 cmp wchmac
 beq edtky4
 and #$3f
 bne edtky4
 pla
 jsr bell
 jmp edtmen
edtky4
 inc macxrg
 jsr curoff
 pla
 jsr ctrlck
 bcc edtky5
 jmp edtinp
edtky5
 jsr chrout
 jsr qimoff
 jmp edtinp
edtbye  ldx macxrg
 lda #0
 sta macmem,x
 rts
macrvs .byte 146
maccty .byte 10
maccol .byte 5
maccas .byte 14
macbkg .byte 0
edtdel
 lda #146
 sta macrvs
 lda #10
 sta maccty
 lda #5
 sta maccol
 lda #14
 sta maccas
 lda #0
 sta macbkg
 lda macmem-1,x
 cmp #$a4;underline key
 beq edtde2
 and #$7f
 cmp #$20
 bcc edtde0
 jmp edtdle
edtde0
 cmp #17
 beq edtde1
 cmp #29
 bne edtde3
edtde1  lda macmem-1,x
edtdeo  eor #$80
 jmp edtdln
edtde2
 lda #148
 jsr edprrv
 lda #29
 jmp edtdln
edtde3 lda macmem-1,x
 cmp #148
 bne edtde4
 lda #29
 jsr edprrv
 lda #148
 bne edtdeo
edtde4  jsr edtcok
 bmi edtde7
 ldx macxrg
 lda macmem-2,x
 sta macbkg
edtde5  dex
 cpx wchmac
 beq edtde6
 lda macmem-1,x
 jsr edtcok
 bmi edtde5
 ldy macmem-2,x
 cpy macbkg
 beq edtdcl
 cpy #2
 beq edtde5
 ldy macbkg
 cpy #2
 beq edtde5
edtdcl
 sta maccol
edtde6
 lda macbkg
 cmp #2
 bne edtclh
 sta lastch
 cpx wchmac
 beq edtclb
 lda maccol
 jsr edtcok
 bmi edtclb
 tya
 tax
edtclb
 stx $d020
 stx $d021
 jmp edtdla
edtclh
 lda #0
 sta lastch
 lda maccol
 jmp edtdln
edtde7
 cmp #10
 beq edtde8
 cmp #11
 bne edtd12
edtde8 ldx macxrg
edtde9 dex
 cpx wchmac
 beq edtd11
 lda macmem-1,x
 cmp #10
 beq edtd10
 cmp #11
 bne edtde9
edtd10  sta maccty
edtd11  lda maccty
 jmp edtdln
edtd12  and #$7f
 cmp #18
 bne edtd15
 ldx macxrg
edtd13  dex
 cpx wchmac
 beq edtd14
 lda macmem-1,x
 and #$7f
 cmp #18
 bne edtd13
 lda macmem-1,x
 sta macrvs
edtd14  lda macrvs
 and #$80
 eor #$80
 sta 199
 lda macrvs
 jmp edtdln
edtd15
 cmp #12
 beq edtd16
 cmp #14
 beq edtd16
 cmp #21
 bne edtd19
edtd16 ldx macxrg
edtdlc dex
 cpx wchmac
 beq edtd18
 lda macmem-1,x
 cmp #12
 beq edtd17
 cmp #14
 beq edtd17
 cmp #21
 bne edtdlc
edtd17 sta maccas
edtd18 lda maccas
 jmp edtdln
edtd19
 cmp #$0d
 bne edtdla
 lda #0
 sta 199
 lda #146
 jsr edprrv
 dec macxrg
 ldx macxrg
 lda #0
 sta macmem,x
 sec
 rts
edtdle
 lda #20
 jsr edprrv
 lda #148
edtdln
 jsr edprrv
edtdla
 dec macxrg
 ldx macxrg
 lda #0
 sta macmem,x
 clc
 rts
edprrv
 sta $02
 lda 199
 pha
 lda #0
 sta 199
 jsr curoff
 lda $02
 jsr ctrlck
 bcs edprr2
 jsr chrout
 jsr qimoff
edprr2 pla
 sta 199
 jmp curprt
edtcok
 ldy #15
edtco2  cmp clcode,y
 beq edtco3
 dey
 bpl edtco2
edtco3 rts
;
f7    ;terminal params/dial
 jsr disablemodem
 lda #0
 sta $d020
 sta $d021
 lda #<f7mtxt   ;print f7 menu
 ldy #>f7mtxt
 jsr outstr
 lda efbyte
 beq f7noef
f7ef 
 lda #<f7mtx3ef
 ldy #>f7mtx3ef
 jsr outstr
 jmp f7continue
f7noef 
 lda #<f7mtx3noef
 ldy #>f7mtx3noef
 jsr outstr
f7continue 
 lda #<f7mtxcont
 ldy #>f7mtxcont
 jsr outstr
 lda #<f7mtx2
 ldy #>f7mtx2
 jsr outstr
f7opts
 lda #$00
 sta $c6
 jsr f7parm
f7chos
 lda $a2
 and #$0f
 bne f7chgk
 lda $a2
 and #$10
 beq f7oprt
 lda #<prret
 ldy #>prret
 jsr outstr
 jmp f7chgk
f7oprt
 lda #<prret2
 ldy #>prret2
 jsr outstr
f7chgk
 jsr getin
 cmp #$00
 beq f7chos
f7chs0
 and #$7f
 cmp #$41   ;A-auto-dial opt
 bne f7chs1
 lda baudrt
 sta bautmp
 lda grasfl
 sta gratmp
 jmp phbook
f7chs1
 cmp #$42 	;B-Baud Rate
 bne f7chs2
;baud rate change
 ldy motype
 beq move24tp
 cpy #$01
 beq move96tp
 cpy #$03;check for swift df - we'll do the no reu check if selected
 bne brinc
 jsr noreu
 jmp brinc
move24tp 
 lda baudrt
 cmp #$02
 bmi brinc
 jmp brrst
move96tp
 lda baudrt
 cmp #$04
 bmi brinc
 jmp brrst 
brinc inc baudrt
 lda baudrt
 cmp #$07
 bne mobaud
brrst
 lda #$00
 sta baudrt
mobaud
 jsr rsopen;5-16 add failsafe....
 jmp f7opts
f7chs2
 cmp #$44 	;D-Duplex
 bne f7chs5
;duplex change
 lda duplex
 eor #$01
 sta duplex
 jmp f7opts
f7chs5
 cmp #$46;F-Firmware
 bne f7chstheme
 lda mopo1
 eor #$01
 sta mopo1
 jmp f7opts
f7chstheme
 cmp #$54;theme
 bne f7chsconfig
 inc theme
 lda theme
 cmp #$06
 bne f7theme2
 lda #$00
 sta theme
f7theme2 
 jsr themeroutine
 jmp f7opts
f7chsconfig;easyflash only
 cmp #$43 	;C-Config EF/Disk
 bne f7chs3
 lda efbyte;do we have an easyflash? no? then go on then and forget about this option
 beq f7chs3
 lda diskoref
 eor #$01
 sta diskoref
 jmp f7opts
f7chs3		
 cmp #$4d	;M-modem type
 bne f7chsp
;change modem type
 inc motype
 lda motype
 pha
 lda efbyte
 beq modems5
 pla
 cmp #$02;only 2 modems in easyflash mode
 bcc incmod
 jmp modems6
modems5
 pla 
 ;XXXXXXX
 cmp #$06;max # of modems
 bcc incmod
modems6 
 lda #$00
 sta motype
 lda #$02
 sta baudrt
incmod
 jsr rsopen
 jmp f7opts
f7chsp;x-modem crc fix
 cmp #$50	;P-Protocol
 bne f7chs6
 inc protoc
 lda protoc
 cmp #$03
 bcc f7chspmoveon
 lda #$00
 sta protoc
f7chspmoveon
 jmp f7opts
f7chs6
 cmp #$53;S-save
 bne f7chs7
 jsr svconf
 jmp f7
f7chs7
 cmp #$4c
 bne f7chs8
 jsr loconf
 jmp f7
f7chs8
 cmp #$45
 bne f7chs9
 jsr edtmac
 jmp f7
f7chs9
 cmp #$56
 bne f7chsa
 jsr viewmg
 jmp f7
f7chsa
 cmp #$0d
 beq f7chsb
f7gbkk jmp f7chos
f7chsb
lda nicktemp
beq moveonterm
moveonterm
jsr enablemodem
 jmp term

prmopt .text <op1txt,>op1txt,<op2txt,>op2txt,<op6txt,>op6txt,<op3txt,>op3txt,<op4txt,>op4txt,<op5txt,>op5txt
prmlen .text 4,18,8,10,20,19
op1txt .text "fULLhALF"
op2txt .text 'uSER pORT 300-2400'
.text 'up9600 / ez232    '
.text 'sWIFT / tURBO de  '
.text 'sWIFT / tURBO df  '
.text 'sWIFT / tURBO d7  '
.text 'pottendos parallel'
op6txt .text "sTANDARDzIMODEM "
op3txt .text "pUNTER    ","xMODEM    ","xMODEM-crc"
             ;themes
             ;0-classic 
             ;1-Iman of XPB v7.1
			 ;2-v8.1 Predator/FCC
			 ;3-9.4 Ice THEME
			 ;4-17.2 Defcon/Unicess
op4txt .text "cLASSIC ccgms V5.5  "
       .text "iMAN / xpb V7.1     "
	   .text "pREDATOR / fcc V8.1 "
	   .text "iCE THEME V9.4      "
	   .text "dEFCON/uNICESS V17.2"
	   .text "aLWYZ / ccgms 2021  "
op5txt .text 29,29,29,29,29,29,29,29,29,29,29,29,29,29,29,"ef  ",29,29,29,29,29,29,29,29,29,29,29,29,29,29,29,"dISK"
prmtab
 lda #$0d
 jsr chrout
 jsr chrout
 ldx #17
 jmp outspc
prmclc;duplex/modem type/protocol display
 tya
 asl a
 tax
 lda prmopt,x
 sta prmadr+1
 lda prmopt+1,x
 sta prmadr+2
 rts
prmprt
 dex
 bmi prmpr2
 lda prmadr+1
 clc
 adc prmlen,y
 sta prmadr+1
 lda prmadr+2
 adc #$00
 sta prmadr+2
 bne prmprt
prmpr2
 inx
prmadr
 lda op1txt,x
 jsr chrout
 inx
 txa
 cmp prmlen,y
 bne prmadr
 jmp prmtab
;
f7parm
 lda #19
 jsr chrout
 lda #1
 sta 646
 ldy f7thob
prmlop
 jsr prmtab
 dey
 bne prmlop
 jsr prmclc
 lda baudrt
 asl a
 tax
 lda bpsspd+1,x
 pha
 lda bpsspd,x
 tax
 pla
 jsr outnum
 lda #$20
 jsr chrout
 jsr chrout
 jsr prmtab
 ldy #0;duplex
 jsr prmclc
 ldx duplex
 jsr prmprt
 iny
 jsr prmclc
 ldx motype 
 jsr prmprt
 ldy #2
 jsr prmclc
 ldx mopo1
 jsr prmprt
 ldy #3
 jsr prmclc
 ldx protoc
 jsr prmprt
 ldy #4
 jsr prmclc
 ldx theme
 jsr prmprt
 lda efbyte
 beq skipeflisting
 ldy #5
 jsr prmclc
 ldx diskoref
 jmp prmprt
 skipeflisting rts
scracf .text "S0:",0
svctxt .text $93,13,5,"fILENAME: ",0
conffn .text "CCGMS-PHONE",0
f7thob .text 2
f7mtxt .byte $93,16,14,5
.text "   dIALER/pARAMETERS",13
 .text 31,"   ",163,163,163,163,163,163,163,163,163,163,163,163,163,163
 .text 163,163,163,13,5
f7mtx1 .text 16
.text 05,32,2,"AUTO-dIALER/pHONEBOOK",13,13
.text 32,2,"BAUD rATE   -",13,13
.text 32,2,"DUPLEX      -",13,13
.text 32,2,"MODEM tYPE  -",13,13
f7mtxpre
.text 32,2,"F IRMWARE    -",13,13
.text 32,2,"PROTOCOL    -",13,13
.text 32,2,"THEME       -",13,13,0
f7mtx3noef
.text 32,2,"EDIT mACROS",13,13,0
f7mtx3ef
.text 32,2,"EDIT mACROS  ",32,2,"CFG dEVICE -",13,13,0
f7mtxcont
.text 32,2,"LOAD/",2,"SAVE pHONE bOOK AND cONFIG.",13,13
.text 32,2,"VIEW aUTHOR'S mESSAGE",13,13,0
f7mtx2 
prret .text 3,22,0,5,cp,"RESS <",158,18,"r",e,t,u,cr,n,146,5,"> TO ABORT.",13,0
prret2 .text 3,22,7,159,"return",13,0

bpsspd .byte 44,1,176,4,96,9,192,18,128,37,0,75,0,150;new rates
          ;  300  1200  2400 4800   9600   19200  38400
          ;  00   01    02    03   04     05     06 	
          ;  256  256   1024  2304 4608   9472   19200


;---- pottendo parallelport modem

pottendosetup
        jmp ($6500)

;----NEW RS232 Userport 300-2400 taken from Novaterm 9.6
;----cause everything else sucked

; user port serial drivers

rssetup 
		
		sei
		
		jsr setbaud232
				
		lda #<nmi64
        ldy #>nmi64
        sta $0318
        sty $0319
		
        lda  #<rsout
        ldx  #>rsout
        sta  $326
        stx  $327

        lda  #<rsget
        ldx  #>rsget
        sta  $32a	
        stx  $32b
		
		cli

		jmp clear232
		
bdloc
ntsc232    .word 3408,851,425    ; transmit times
        .word 4915,1090,459   ; startup bit times
        .word 3410,845,421    ; full bit times
pal232     .word 3283,820,409    ; transmit times for PAL
        .word 4735,1050,442   ; startup bit times for PAL
        .word 3285,814,406    ; full bit times for PAL

isbyte	.byte 0
lastring .byte 0

rsget 	lda $99
        cmp #2                ; see if default input is modem
        beq jbgetrs
        jmp ogetin               ; nope, go back to original

jbgetrs jsr rsgetxfer
		bcs  +                ; if no character, then return 0 in a
        rts
	+	clc
        lda #0
        rts
		
rsgetxfer
		ldx rhead
        cpx rtail
        beq +                ; skip (empty buffer, return with carry set)
        lda ribuf,x
		pha
        inc rhead
        clc
		pla
	+	rts

				
nmi64   pha             ; new nmi handler
        txa
        pha
        tya
        pha
nmi128  cld
        ldx $dd07       ; sample timer b hi byte
        lda #$7f        ; disable cia nmi's
        sta $dd0d
        lda $dd0d       ; read/clear flags
        ;bpl notcia      ; (restore key)
nmi1    cpx $dd07
        ldy $dd01
        bcs mask
        ora #$02
        ora $dd0d
mask    and $02a1
        tax
        lsr
        bcc ckflag
        lda $dd00
        and #$fb
        ora $b5
        sta $dd00
ckflag  txa
        and #$10
        beq nmion
strtlo  lda #0
        sta $dd06
strthi  lda #0
        sta $dd07
        lda #$11
        sta $dd0f
        lda #$12
        eor $02a1
        sta $02a1
        sta $dd0d
fulllo  lda #0
        sta $dd06
fullhi  lda #0
        sta $dd07
        lda #$08
        sta $a8
        jmp chktxd
notcia  ;ldy #$00
        ;jmp rstkey      ; or jmp norest
nmion   lda $02a1          ;  receive a bit/byte
        sta $dd0d
        txa
        and #$02
        beq chktxd
        tya
        lsr
        ror $aa
        dec $a8
        bne txd
	    lda $aa	
		ldx rtail         ;index to buffer
		sta ribuf,x     ;and store it
		inc rtail         ;move index to next slot
switch0 lda #$00
        sta $dd0f
        lda #$12
switch  ldy #$7f
        sty $dd0d
        sty $dd0d
        eor $02a1
        sta $02a1
        sta $dd0d
txd     txa
        lsr
chktxd  bcc nmiflow
        dec $b4
        bmi endbyte
        lda #$04
        ror $b6
        bcs store
low     lda #$00
store   sta $b5
nmiflow lda $a8
    	and #$08
		beq nmiexit
		clc
nmiexit pla
        tay
        pla
        tax
        pla
        rti
		
endbyte lda #0
        sta isbyte
txoff   ldx #$00            ;  turn transmit int off
        stx $dd0e
        lda #$01
        bne switch
		jmp disabl
		
rsout   pha             ; new bsout
        lda $9a
        cmp #02
        bne notmod
        pla
rsout5  sta $97
		stx $9e
		sty $9f
rsout2  lda $97
		sta $b6
        lda #0
        sta $b5
        lda #$09
        sta $b4
        lda #$ff
        sta isbyte
xmitlo  lda #0
        sta $dd04
xmithi  lda #0
        sta $dd05
        lda #$11
        sta $dd0e
        lda #$81
change  sta $dd0d
        php
        sei
        ldy #$7f
        sty $dd0d
        sty $dd0d
        ora $02a1
        sta $02a1
        sta $dd0d
        plp
rsout3  bit isbyte
        bmi rsout3
ret1    clc
		ldx $9e
		ldy $9f
		lda $97
		rts
notmod  pla
		jmp  oldout

disabl  pha
	-	;lda $02a1;this fucks shit up... get rid of it...
        ;and #$03
        ;bne -
        lda isbyte
        bne -
        lda #$10
        sta $dd0d
        lda #$02
        and $02a1
        bne -
        sta $02a1
        pla
        rts

inable  stx $9e         ; enable rs232 input
		sty $9f
        sta $97
		lda $02a1
        and #$12
        bne ret1
        sta $dd0f
        lda #$90
        jmp change
		
setbaud232 lda baudrt
setbd0  asl
        clc
        adc ntsc
setbd1  tay
        lda bdloc,y
        sta xmitlo+1
        lda bdloc+1,y
        sta xmithi+1
        lda bdloc+6,y
        sta strtlo+1
        lda bdloc+7,y
        sta strthi+1
        lda bdloc+12,y
        sta fulllo+1
        lda bdloc+13,y
        sta fullhi+1
        rts

;----Swiftlink - Jeff Brown Adaptation of Novaterm version

stopsw        = 1
startsw        = 0

swift = $de00               ; can be d to df00 or d700 depending

sw_data = swift                ; swiftlink registers
sw_stat = swift+1
sw_cmd  = swift+2
sw_ctrl = swift+3
sw_baud = swift+7

nmisw        	pha
				txa
				pha
				tya
				pha
sm1				lda sw_stat
				and #%00001000	; mask out all but receive interrupt reg
				bne sm2 ; get outta here if interrupts are disabled (disk access etc)
				sec		; set carry upon return
				bcs recch1
sm2        		lda         sw_cmd
				ora         #%00000010        ; disable receive interrupts
sm3        		sta         sw_cmd
sm4 			lda         sw_data
				ldx         rtail
				sta         ribuf,x
				inc         rtail
				inc         rfree
				lda rfree
				cmp         #200                ; check byte count against tolerance
				bcc         recch0            ; is it over the top?
				ldx         #stopsw
				stx paused ;x=1 for stop, by the way
				jsr         flow   
recch0
sm5        		lda         sw_cmd
				and         #%11111101        ; re-enable receive interrupt
sm6        		sta         sw_cmd
recch2        	clc
recch1        	pla
				tay
				pla
				tax
				pla
				rti

flow
sm7         	lda         sw_cmd
				and         #%11110011
				cpx         #stopsw
				beq         fl1
				ora         #%00001000
fl1
sm8        	sta         sw_cmd
				rts
		
swwait
sm9        		lda         sw_cmd
				ora         #%00001000        ; enable transmitter
sm10       		sta         sw_cmd
sm11       		lda         sw_stat
				and         #%00110000
				beq         swwait
				rts
			  
disablsw
sm12        	lda         sw_cmd
				ora #%00000010	; disable receive interrupt
sm13        	sta         sw_cmd
        		rts

inablesw        
sm14				lda         sw_cmd
					and #%11111101	; enable receive interrupt
sm15				sta         sw_cmd
					rts

swsetup
				sei
				
;             .------------------------- parity control,
;             :.------------------------ bits 5-7
;             ::.----------------------- 000 = no parity
;             :::
;             :::.------------------- echo mode, 0 = normal (no echo)
;             ::::
;             :::: .----------- transmit interrupt control, bits 2-3
;             :::: :.---------- 10 = xmit interrupt off, RTS low
;             :::: ::
;             :::: ::.------ receive interrupt control, 0 = enabled
;             :::: :::
;             :::: :::.--- DTR control, 1=DTR low
      lda   #%0000_1001
sm16      		sta   sw_cmd

;             .------------------------- 0 = one stop bit
;             :
;             :.-------------------- word length, bits 6-7
;             ::.------------------- 00 = eight-bit word
;             :::
;             :::.------------- clock source, 1 = internal generator
;             ::::
;             :::: .----- baud
;             :::: :.---- rate
;             :::: ::.--- bits   ;1010 == 4800 baud, changes later
;             :::: :::.-- 0-3
      lda   #%0001_0000
sm17     		sta sw_ctrl

        lda         baudrt               ;0=300, 1=1200, 2=2400,3=4800,4=9600, 5=19200, 6=38400
setbaud        	tax
sm18        	lda         sw_ctrl
				and         #$f0
				ora         swbaud,x
sm19        	sta         sw_ctrl
				
        lda        #<newout
        ldx        #>newout
        sta        $326
        stx        $327

        lda        #<newin
        ldx        #>newin
        sta        $32a	
        stx        $32b

        lda        #<nmisw
        ldx        #>nmisw
        sta        $0318
        stx        $0319
       
        jsr clear232
		cli
        rts

newout        	pha                        ;dupliciaton of original kernal routines
				lda         $9a                  ;test dfault output device for
				cmp         #$02                   ;screen, and...
		        beq         +
				pla                        ;if so, go back to original rom routines
				jmp         oldout
+    			pla

rsoutsw      
				sta $97
				stx $9e
				sty $9f
sm20        	lda         sw_cmd
				sta         temp
				jsr         swwait
				lda         $97
sm21        	sta         sw_data
				jsr         swwait
				lda         temp                ; restore rts state
sm22        	sta         sw_cmd
				lda $97
				ldx $9e
				ldy $9f
				clc
				rts

dropdtr 
sm23	lda sw_cmd
	and #%11111110
sm24	sta sw_cmd
	ldx #226
	stx $a2
wait30	bit $a2
	bmi wait30
	ora #%00000001
sm25	sta sw_cmd
	rts
	
newin   lda $99
        cmp #2                ; see if default input is modem
        beq jbgetsw
        jmp ogetin               ; nope, go back to original
		
jbgetsw jsr swgetxfer
		bcs  +                ; if no character, then return 0 in a
        rts
	+	clc
        lda #0
        rts
		
swgetxfer
		ldx rhead
        cpx rtail
        beq ++                ; skip (empty buffer, return with carry set)
        lda ribuf,x
		pha
        inc rhead
		dec rfree
		ldx paused                ; are we stopped?
		beq +                ; no, don't bother
		lda rfree                ; check buffer free
		cmp #50                ; against restart limit
		bcs +                ; is it larger than 50?
		ldx #startsw          ;if no, then dont start yet
		stx paused
		jsr flow
    +   clc
		pla
	+   rts

temp        .byte        0

paused .byte $00

swbaud .byte $15,$17,$18,$1a,$1c,$1e,$1f,$10,$10,$10

;--------------------------------------------------------------
UP9600

nmi_startbit:
        pha
		txa
		pha
		tya
		pha
        bit  $dd0d              ; check bit 7 (startbit ?)
        bpl  nv1                  ; no startbit received, then skip
        
        lda  #$13
        sta  $dd0f              ; start timer B (forced reload, signal at PB7)
        sta  $dd0d              ; disable timer and FLAG interrupts
        lda  #<nmi_bytrdy       ; on next NMI call nmi_bytrdy
        sta  $0318           ; (triggered by SDR full)
		lda  #>nmi_bytrdy       ; on next NMI call nmi_bytrdy
        sta  $0319           ; (triggered by SDR full)

    nv1 pla	; ignore, if NMI was triggered by RESTORE-key
        tay
		pla
		tax
		pla
		rti

nmi_bytrdy:
        pha
		txa
		pha
		tya
		pha
        bit  $dd0d              ; check bit 7 (SDR full ?)
        bpl  nv1                  ; SDR not full, then skip (eg. RESTORE-key)
        
        lda  #$92
        sta  $dd0f              ; stop timer B (keep signalling at PB7!)
        sta  $dd0d              ; enable FLAG (and timer) interrupts
        lda  #<nmi_startbit     ; on next NMI call nmi_startbit
        sta  $0318           ; (triggered by a startbit)
		lda  #>nmi_startbit     ; on next NMI call nmi_startbit
        sta  $0319           ; (triggered by a startbit)
        txa
        pha
        lda  $dd0c              ; read SDR (bit0=databit7,...,bit7=databit0)
        cmp  #128               ; move bit7 into carry-flag
        and  #127
        tax
        lda  revtabup,x           ; read databits 1-7 from lookup table
        adc  #0                 ; add databit0
        ldx  rtail            ; and write it into the receive buffer
        sta  ribuf,x
        inx
        stx  rtail
        sec
        txa
        sbc  rhead
        cmp  #200
        bcc  +
        lda  $dd01              ; more than 200 bytes in the receive buffer
        and  #$fd               ; then disbale RTS
        sta  $dd01
    +   pla
        tax
        jmp nv1
		
upsetup

        ldx  #0
    -   stx  outstat            ; outstat used as temporary variable
        ldy  #8
    -   asl  outstat
        ror  a
        dey
        bne  -
        sta  revtabup,x
        inx
        bpl  --
		
        jsr clear232
			
		jsr setbaudup

        lda  #<newoutup
        ldx  #>newoutup
        sta  $326
        stx  $327

        lda  #<newinup
        ldx  #>newinup
        sta  $32a	
        stx  $32b
		  	
        ;; enable serial interface (IRQ+NMI)
        
enableup        sei
  
        ldx  #<new_irq          ; install new IRQ-handler
        ldy  #>new_irq
        stx  $0314
        sty  $0315
        
        ldx  #<nmi_startbit     ; install new NMI-handler
        ldy  #>nmi_startbit
        stx  $0318
        sty  $0319
		
        ldx  ntsc               ; PAL or NTSC version ?
        lda  ilotab,x           ; (keyscan interrupt once every 1/64 second)
        sta  $dc06              ; (sorry this will break code, that uses
        lda  ihitab,x           ; the ti$ - variable)
        sta  $dc07              ; start value for timer B (of CIA1)
        txa
        asl  a
        
a7e0c   eor  #$00               ; ** time constant for sender **
a7e0e   ldx  #$00                 ; 51 or 55 depending on PAL/NTSC version
        sta  $dc04              ; start value for timerA (of CIA1)
        stx  $dc05              ; (time is around 1/(2*baudrate) )

a8e0c   lda  #$00
	    sta  $dd06              ; start value for timerB (of CIA2)
a8e0e   lda  #$00 
		sta  $dd07              ; (time is around 1/baudrate )
  
        lda  #$41               ; start timerA of CIA1, SP1 used as output
        sta  $dc0e              ; generates the sender's bit clock
        lda  #1
        sta  outstat
        sta  $dc0d              ; disable timerA (CIA1) interrupt
        sta  $dc0f              ; start timerB of CIA1 (generates keyscan IRQ)
        lda  #$92               ; stop timerB of CIA2 (enable signal at PB7)
        sta  $dd0f
        lda  #$98
        bit  $dd0d              ; clear pending NMIs
        sta  $dd0d              ; enable NMI (SDR and FLAG) (CIA2)
        lda  #$8a
        sta  $dc0d              ; enable IRQ (timerB and SDR) (CIA1)
        lda  #$ff
        sta  $dd01              ; PB0-7 default to 1
        sta  $dc0c              ; SP1 defaults to 1
        lda  #2                 ; enable RTS
        sta  $dd03              ; (the RTS line is the only output)
		cli
        rts

		;; IRQ part

new_irq:     
	    lda  $dc0d    ;cia1: cia interrupt control register
        lsr 
        lsr 
        and  #$02
        beq  b7d72
        ldx  $a9
        beq  b7d70
        dex 
        stx  $a9;outstat
b7d70   bcc  b7da6
b7d72   cli 
        jsr  $ffea ;$ffea - update jiffy clock
b7da3   jsr  $ea87 ;$ea87 (jmp) - scan keyboard                    
b7da6   jmp  $ea81
     
ilotab:
        .byte $95
        .byte $25
ihitab: 
        .byte $42
        .byte $40       

setbaudup  
        lda baudrt
b7e56   asl 
        ora ntsc
        tax 
        lda f7e6c,x
        sta a7e0c+1
        lda f7e76,x
        sta a7e0e+1
		lda f8e6c,x
        sta a8e0c+1
		lda f8e76,x
        sta a8e0e+1
        rts 

;recv 		
f7e6c 	.byte $b0 ;0300
f7e6d 	.byte $70
f7e6e   .byte $a8;1200
f7e6f   .byte $98
f7e70   .byte $d4;2400
f7e71   .byte $cc
f7e72   .byte $6a ;4800
f7e73   .byte $66
f7e74   .byte $35;9600 ntsc 
f7e75   .byte $33;9600 pal
f7e76   .byte $06;300
f7e77   .byte $06
f7e78   .byte $01;1200
f7e79   .byte $01
f7e7a 	.byte $00;2400
f7e7b  	.byte $00
f7e7c  	.byte $00;4800
f7e7d  	.byte $00 
f7e7e  	.byte $00;9600 ntsc
f7e7f  	.byte $00;9600 pal 

;send (x2 of receive)
f8e6c 	.byte $50 ;0300
f8e6d 	.byte $d0
f8e6e   .byte $50;1200
f8e6f   .byte $30
f8e70   .byte $a8;2400
f8e71   .byte $98
f8e72   .byte $d4 ;4800
f8e73   .byte $cc
f8e74   .byte $6a;9600 ntsc 
f8e75   .byte $66;9600 pal
f8e76   .byte $0d;300
f8e77   .byte $0c
f8e78   .byte $03;1200
f8e79   .byte $03
f8e7a 	.byte $01;2400
f8e7b  	.byte $01
f8e7c  	.byte $00;4800
f8e7d  	.byte $00 
f8e7e  	.byte $00;9600 ntsc
f8e7f  	.byte $00;9600 pal 
     
        ;; get byte from serial interface

newinup lda $99
        cmp #2                ; see if default input is modem
        beq jbgetup
        jmp ogetin               ; nope, go back to original

jbgetup jsr upgetxfer
		bcs  +                ; if no character, then return 0 in a
        rts
	+	clc
        lda #0
        rts

upgetxfer ; refer to this routine only if you wanna use it for protocols (xmodem.punter etc)
		ldx rhead
        cpx rtail
        beq ++                 ; skip (empty buffer, return with carry set)
        lda ribuf,x
        inx
        stx rhead
        pha
        txa
        sec
        sbc rtail
        cmp #50
        bcc +
        lda #2                 ; enable RTS if there are less than 50 bytes
        ora $dd01              ; in the receive buffer
        sta $dd01
    +   clc
		pla
	+	rts
		
        ;; put byte to serial interface

newoutup  pha                        ;dupliciaton of original kernal routines
          lda  $9a                  ;test dfault output device for
          cmp  #$02                   ;screen, and...
          beq  +
          pla                        ;if so, go back to original rom routines
          jmp  oldout
    +     
		pla
        sta $97
		stx $9e
		sty $9f
rsoutup pha
		cmp  #$80
		and  #$7f
        tax 
s7e80   cli
        lda #$fd
        sta $a2
b7e85   lda $a9
        beq b7e8d
        bit $a2
        bmi b7e85
b7e8d   lda  #$04
		ora  $dd00
		sta  $dd00
b7d3c   lda  $dd01    ;cia2: data port register b
        and  #$44
        eor  #$04
        beq  b7d3c
b7d45   lda  revtabup,x
        adc  #$00
        lsr  
        sta  $dc0c    ;cia1: synchronous serial i/o data buffer
        lda  #$02
        sta  $a9
        ror 
        ora  #$7f
        sta  $dc0c    ;cia1: synchronous serial i/o data buffer
		clc
        lda $97
		ldx $9e
		ldy $9f	
		pla
        rts 
		
        ;; disable serial interface

disableup  
		sei
        lda  #$7f
        sta  $dd0d              ; disable all CIA interrupts
        sta  $dc0d
        lda  #$41               ; quick (and dirty) hack to switch back
        sta  $dc05              ; to the default CIA1 configuration
        lda  #$81
        sta  $dc0d              ; enable timer1 (this is default)

        lda #<oldnmi    ; restore old NMI-handler
        sta $0318
        lda #>oldnmi
        sta $0319
        lda #<oldirq
        sta $0314     ;irq
        lda #>oldirq
        sta $0315     ;irq
        cli 
        rts 
		
;END UP9600

;reset modems here
	
enablemodem
lda motype
beq enablers1
cmp #$01;up9600
beq enableup1
cmp #$02
beq enablesw1
cmp #$03
beq enableswdf
cmp #$04
beq enableswd7
;XXXXXXXXX
cmp #$05
beq enablepottendo
rts

enableup1 
jmp upsetup
enablers1
jmp rssetup
;XXXXXXXX
enablepottendo
jmp pottendosetup 

enablesw1
lda #$de
jmp swifttemp
enableswdf
lda #$df
jmp swifttemp
enableswd7
lda #$d7

swifttemp 
sta sm1+2
sta sm2+2
sta sm3+2
sta sm4+2
sta sm5+2
sta sm6+2
sta sm7+2
sta sm8+2
sta sm9+2
sta sm10+2
sta sm11+2
sta sm12+2
sta sm13+2
sta sm14+2
sta sm15+2
sta sm16+2
sta sm17+2
sta sm18+2
sta sm19+2
sta sm20+2
sta sm21+2
sta sm22+2
sta sm23+2
sta sm24+2
sta sm25+2
jmp swsetup

enablexfer
pha
txa
pha
tya
pha
lda motype
beq enablersxfer
cmp #$01;up9600
beq enableupxfer

jsr inablesw
jmp xferout

enablersxfer 
jsr inable
jmp xferout

enableupxfer 
jsr enableup
jmp xferout

disablexfer
disablemodem
pha
txa
pha
tya
pha
lda motype
beq disablers1
cmp #$01;up9600
beq disableup1

jsr disablsw
jmp xferout

disableup1 
jsr disableup
jmp xferout

disablers1 
jsr disabl 
jmp xferout

xferout
pla
tay
pla
tax
pla
rts

modget

lda motype
beq modgetrs
cmp #$01
beq modgetup

jmp swgetxfer

modgetup jmp upgetxfer

modgetrs jmp rsgetxfer

;REU ROUTINES - 17XX REU. Only uses first bank regardless. 64k is more than enough memory

bufreu .byte $00;0-ram 1-reu

; detect REU

detectreu
		 ;jmp noreu;temp byte to default to no reu, for troubleshooting if needed
		 
         ldx #2
loop1    txa
         sta $df00,x
         inx
         cpx #6
         bne loop1

         ldx #2
loop2    txa
         cmp $df00,x
         bne noreu
         inx
         cpx #6
         bne loop2

         lda #1
		 sta bufreu
		 lda #$00   ;set buffer start
         sta newbuf
		 sta newbuf+1
		 sta buffst
		 sta buffst+1
		 sta bufptr
		 sta bufptr+1
		 lda #$ff
		 sta bufend
		 sta bufend+1
         rts

noreu    lda #0
         sta bufreu
		 lda #<endprg   ;set buffer start
         sta buffst
         lda #>endprg
         sta buffst+1
		 lda #<buftop
		 sta bufend
		 lda #>buftop
		 sta bufend+1
         rts

bufend .byte $00,$00

;read/write to from reu

length   = 0001;one byte at a time

reuwrite  
         sta bufptrreu
         pha
         lda #<bufptrreu
         sta $df02
         lda #>bufptrreu
         sta $df03
         lda bufptr
         sta $df04
         lda bufptr+1
         sta $df05
         lda #0
         sta $df06
         lda #<length
         sta $df07
         lda #>length
         sta $df08
         lda #0
         sta $df0a
c64toreu
         lda #$b0	
         sta $df01
		 pla
		 rts
	
reuread  
         lda #<buffstreu
         sta $df02
         lda #>buffstreu
         sta $df03
         lda buffst
         sta $df04
         lda buffst+1
         sta $df05
         lda #0
         sta $df06
         lda #<length
         sta $df07
         lda #>length
         sta $df08
         lda #0
         sta $df0a
reutoc64 lda #$b1
         sta $df01
		 lda buffstreu
		 rts
		 
;END REU
;THEME ROUTINES
	 
tc1  .byte 05,31,05,05,31,151;f1
tc2  .byte 150,150,31,151,151,156;Upload
tc3  .byte 05,154,05,05,156,152;f3
tc4  .byte 158,158,154,31,152,154;Download
tc5  .byte 05,159,05,05,154,155;f5
tc6  .byte 153,153,31,156,155,159;Disk
tc7  .byte 05,153,05,05,159,155;f7
tc8  .byte 30,159,154,154,155,153;Options
tc9  .byte 05,31,05,05,31,151;f2
tc10 .byte 150,150,31,31,151,156;send/rec
tc11 .byte 05,154,05,05,156,152;f4
tc12 .byte 158,158,154,156,152,154;Buffer menu
tc13 .byte 05,159,05,05,154,155;f6
tc14 .byte 153,153,31,154,155,159
tc15 .byte 05,153,05,05,159,155;f8
tc16 .byte 30,159,154,155,155,153;f8 text
tc17 .byte 31,31,159,151,151,31;C
tc18 .byte 05,158,05,05,155,152;cf1
tc19 .byte 159,154,31,155,152,158;cf1 text
tc20 .byte 05,158,05,05,155,152;f3
tc21 .byte 159,154,31,159,152,158;f3 txt
tc22 .byte 05,150,05,05,05,151;f5
tc23 .byte 154,31,154,159,151,150;f5txt
tc24 .byte 05,150,05,05,05,151;f7
tc25 .byte 154,31,154,158,151,150;f7txt
tc26 .byte 28,28,28,152,152,28;= sign
tc27 .byte 05,153,153,153,153,152;f7 menu color
tc28 .byte 159,150,150,150,150,154;phonebook color

themeroutine
ldy theme
lda tc1,y
sta instxt
lda tc2,y
sta instxt+8
lda tc9,y
sta instxt+25
lda tc10,y
sta instxt+31
lda tc3,y
sta instxt+47
lda tc4,y
sta instxt+55
lda tc11,y
sta instxt+72
lda tc12,y
sta instxt+78
lda tc5,y
sta instxt+95
lda tc6,y
sta instxt+103
lda tc13,y
sta instxt+120
lda tc14,y
sta instxt+126
lda tc7,y
sta instxt+137
lda tc8,y
sta instxt+145
lda tc15,y
sta instxt+162
lda tc16,y
sta instxt+168
lda tc17,y
sta instx2
sta instx2+25
sta instx2+50
sta instx2+75
lda tc26,y
sta instx2+2
sta instx2+27
sta instx2+52
sta instx2+77
lda tc18,y
sta instx2+4
lda tc20,y
sta instx2+29
lda tc22,y
sta instx2+54
lda tc24,y
sta instx2+79
lda tc19,y
sta instx2+10
lda tc21,y
sta instx2+35
lda tc23,y
sta instx2+60
lda tc25,y
sta instx2+85
lda tc27,y
sta f7mtx1+1
sta f7mtxpre+3
lda tc28,y
sta curbtx+3
sta curbt3+3
sta curbt2
sta curbt4
sta curunl+3
sta prtunl+3
rts

;END of THEME ROUTINE	 

;EASYFLASH

;EF WRITE CONFIG

writeconfigef

jsr eapiinit

lda #$30      ; bank $30 (this is where the config is going to be stored).  
ldy #$80      ; lorom
jsr $df83     ; erase sector (banks 30:0, 31:0, 32:0, 33:0, 34:0, 35:0, 36:0 and 37:0 are set to $ff) 
jsr eapi2     ; delay 1.5 seconds after erase to let c64 physically finish its job for compatibility.
lda #$30      ; set bank $30 for the next read/write command. 
jsr $df86
lda #$b0      ; set bank mode to llll (continue to next lo bank after current lo bank is full)
ldx #$00      ; set address to $8000,
ldy #$80      ; this is the position in the bank where the config is being stored, ie top of bank)
jsr $df8c
ldx #$00    

f1080 lda $5100,x   ; this is where the config is positioned.
jsr $df95     ; write byte to ef, $0305 to $8000, $0306 to $8001, etc.
inx
bne f1080
inc f1080+2
lda f1080+2
cmp #$5c
bne f1080
lda #$51
sta f1080+2

lda #$04      ; cart off.
sta $de02
rts

f10b0   ldy #$00
ldx #$00
eapi3  inx
bne eapi3
dey
bne eapi3
rts
eapi2 jsr f10b0    ; delay 0,5 seconds
jsr f10b0    ; delay 0,5 seconds
jsr f10b0    ; delay 0,5 seconds
rts

;EF READ CONFIG

readconfigef

jsr eapiinit

;lda #$30      ; bank $30 (this is where the config is going to be stored).  
;ldy #$80      ; lorom
;jsr $df83     ; erase sector (banks 30:0, 31:0, 32:0, 33:0, 34:0, 35:0, 36:0 and 37:0 are set to $ff) 
;jsr eapi2     ; delay 1.5 seconds after erase to let c64 physically finish its job for compatibility.
lda #$30      ; set bank $30 for the next read/write command. 
jsr $df86
lda #$b0      ; set bank mode to llll (continue to next lo bank after current lo bank is full)
ldx #$00      ; set address to $8000,
ldy #$80      ; this is the position in the bank where the config is being stored, ie top of bank)
jsr $df8c
ldx #$00    

f1080r jsr $df92; read byte to ef, $0305 to $8000, $0306 to $8001, etc.
f1080rs sta $5100,x   ; this is where the config is positioned.   
inx
bne f1080r
inc f1080rs+2
lda f1080rs+2
cmp #$5c
bne f1080r
lda #$51
sta f1080rs+2

lda #$04      ; cart off.
sta $de02
rts

eapiinit

lda #$07      ; cart on. banks visible from $8000-$bfff
sta $de02
lda #$00      ; select bank 0.
sta $de00
ldx #$00      ; copy eapi driver from bank 0 to ram at $1800. (eapi is always at $b800 in bank 0).
eapi1   lda $b800,x
sta $cb00,x
lda $b900,x
sta $cc00,x
lda $ba00,x
sta $cd00,x
inx
bne eapi1
jsr $cb14     ; init eapi driver. (routines copied to extra cart ram $df80-dfff) 
rts

;END EF

;-----------CONFIG

*=$5100
config
baudrt .byte $02 ;2400 baud def
mopo1  .byte $00 ;used to be pick up byte - unused and will now be atdt/atd byte - 00-atdt - 01-atd
mopo2  .byte $20 ;hang up
;
motype .byte $00 ;0=User Port, 1=UP9600
;^modem type^   ;2=Swiftlink DE
                ;3=Swiftlink D7
                ;4=Swiftlink DF
;
phbmem ;reserve mem for phbook
;.text 0,6,'aFTERLIFE         ','192.168.0.8     ',0,'               ',0,'6401 ',0,'myuserid   ',0,'mypassword1',0
;.text 0,6,'aFTERLIFE         ','192.168.0.8:6401                ',0,'6400 ',0,'anotheruser',0,'mypassword1',0
;.text 0,6,'aFTERLIFE         ','192.168.0.8:6401                ',0,'23   ',0,'myid       ',0,'mypassword1',0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.text 0,6,'cOMMODORESERVER   ','COMMODORESERVER.COM',0,13,0,0,0,0,0,0,0,0,0,0,0,0,'1541',0,13,'ID         ',0,'PIN        ',0,0,0

macmem
macmm1 .text 'hELLO wORLD',0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
macmm2 .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
macmm3 .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
macmm4 .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
protoc .byte 0; punter/xmodem flag
theme .byte 0;0-classic 
             ;1-Iman of XPB v7.1
			 ;2-v8.1 Predator/FCC
			 ;3-9.4 Ice THEME
			 ;4-17.2 Defcon/Unicess
diskoref .byte $00;00 = ef - 01=disk
endsav .byte 0

*=$5c00

ampag1
.text 147,10,155,15,14,'',28,'   c',129,'c',158,'g',30,'m',31,'s',156
.text '! ',5,'tERM '
.text 'V2021 MODDED BY aLWYZ',13,13,18
.text 158,'cOMMANDS:',146,13,13,31,'c',28,'=   ',5,'stop'
.text '      ',159,'dISCONNECT.',154,' (dROP dtr)',13,5,'ctrl j/k'
.text '       ',153,'dEST/nON dEST cURSOR',13
.text 31,'c',28,'=   ',5,'ctrl'
.text ' 1-4  ',158,'tAKE A ',39,'SNAPSHOT',39,' OF THE',13,'              '
.text '  SCREEN INTO STORAGE 1-4',13
.text 5,'shft ctrl'
.text ' 1-4  ',158
.text 'rECALL sNAPSHOT 1-4',13,'               (sWAPS W/CURRENT SCREEN)',13
.text 31,'c',28,'=   ',5,'f7  '
.text '      ',158,'sTORES cURRENT sNAPSHOT',13,'                IN BUFFER'
.text 13,5,'ctrl f1/f3     ',156,'mACROS.',13
.text 5,'ctrl f5/f7     ',156,'sEND uSER id/pASSWORD.',13,13
.text 159,'aT DISK PROMPT, "#x" CHANGES TO DEV#X.',13
.text 'dEVICES 8-29 ARE VALID.',13
.text 'sd2iec: "CD/X" CHANGES TO SUBDIR X',13
.text 'and "CD:',$5f,'" CHANGES TO ROOT DIR.',13
.text 154,'aT THE'
.text ' BUFFER CMD PROMPT, ',5,'< ',154,'AND ',5,'>',13,154,'MOVES THE BUF'
.text 'FER POINTER.',13,153,'oN-LINE, ',5,'ctrl-b <COLOR-CODE> '
.text 153,'CHANGES',13,'THE BACKGROUND COLOR.',5,' ctrl-n',153,' MAKES ',13,'BACKGROUND BLACK.',5
.text ' ctrl-g',153,' BELL SOUND',13,5,'ctrl-v ',153,'SFX SOUND',5,'     pRESS A KEY...',0
ampag2
.text 147,10,155,15
.text 5,'   tHIS vERSION OF ccgms IS BASED ON',13
.text 14,'        ',28,'c',129,'c',158,'g',30,'m',31,'s',5,'! tERM '
.text '(C) 2016',13
.text ' BY cRAIG sMITH, aLL rIGHTS rESERVED.',13,13
.text 153,'tHIS PROGRAM IS OPEN SOURCE.',13
.text 'REDISTRIBUTION AND USE IN SOURCE AND',13
.text 'BINARY FORMS, WITH OR WITHOUT MODIFI-',13
.text 'CATION, ARE PERMITTED UNDER THE TERMS',13
.text 'OF THE bsd 3-CLAUSE LICENSE.',13
.text 'fOR DETAILS, OR TO CONTRIBUTE, VISIT:',13
.text 158,' HTTPS://GITHUB.COM/SPATHIWA/CCGMSTERM',13,13
.text $9c,'a',$9a,'L',$9f,'W',$99,'Y',$9e,'Z',152,' WOULD LIKE TO THANK '
.text 153,'THE cbm',13,'hACKERS mAILING lIST,',158,' irc #C64FRIENDS,',13
.text 129,'PCOLLINS/EXCESS, LARRY/ROLE, XLAR54,',13
.text 129,'AND THE USERS OF afterlife bbs WHO',13,'HELPED WITH '
.text 150,'TESTING, TIPS, AND BUGFIXES.',13,13
.text 154,'iT HAS BEEN MY PLEASURE TO MAINTAIN',13,'THIS PROGRAM FROM 2017-2020 - ',$9c,'a',$9a,'L',$9f,'W',$99,'Y',$9e,'Z',152,13,13
.text 13,153,5,'pRESS A KEY...',0,0
endprg .byte 0
endall
.end
