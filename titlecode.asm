;--------------------------------------
;RACE 'N SMASH
;(C)2023 Richard/TND
;For Lemon64 game tutorial
;
;TITLE SCREEN CODE
;Assembler: Turbo Ass. V7.44/ANGELS
;October 2023:         System: PAL Only

;CONVERTED TO WORK IN C64STUDIO/ACME

;--------------------------------------
;
;When pack/crunch to an executable use
;the following:
;
;$01 value = $37
;Jump address = $5000

;--------------------------------------
;Memory info:
;------------
;GAME

;$0C00-$0FE7 - Game screen data
;$1000-$20FF - In game music
;$2100-$27FF - Game sprites
;$2800-$2FFF - Graphics charset
;$4000-$4xxx - Game code

;TITLE:

;$3000-$3900 - Scrolltext
;$3900-$3fff - Spare memory
;$5000-$57FF - Title code
;$5800-$5BE7 - Logo colour memory
;$5C00-$5FE7 - Logo video memory
;$6000-$7F3F - Logo bitmap
;$7f40-$8fff - Spare memory
;$9000-$9FFF - Title screen music
;--------------------------------------



;Variables

game = $4000 ;JMP addr to game code

scrolltext = $3000 ;Scroll text memory

logocol  = $5800 ;Logo colour memory
                 ;stored location

logovid  = $5c00 ;Logo video memory
                 ;stored location

row      = $0400 ;Screen row position
                 ;for placing text.

colrow   = $d800 ;Colour RAM row
                 ;position

tsplit1  = $2e
tsplit2  = $82
tsplit3  = $e8
tsplit4  = $fa

;Music parameters for title screen.
;Change to $9000,$9003 before final
;compiling.

music2init = $9000
music2play = $9003

;--------------------------------------

         sei
         lda #$37
         sta $01

;--------------------------------------

;Disable runstop / restore

         lda #251
         sta $0328

;--------------------------------------

;Disable all IRQ interrupts like with
;the game.

         ldx #<$ea31
         ldy #>$ea31
         stx $0314
         sty $0315
         lda #$81
         sta $dc0d
         sta $dd0d
         lda #$00
         sta $d015
         sta $d01a
         sta $d019
         sta $d011
         sta $d020
         sta $d021

;Initialize sid chip as before in game

         ldx #$00
initsid  lda #$00
         sta $d400,x
         inx
         cpx #$18
         bne initsid

;Quick delay as before

         ldx #$00
delay    ldy #$00
delay2   iny
         bne delay2
         inx
         bne delay

;--------------------------------------

;Completely clear the screen and black
;out everything

         ldx #$00
clearscr lda #$20
         sta $0400,x
         sta $0500,x
         sta $0600,x
         sta $06e8,x
         lda #$00
         sta $d800,x
         sta $d900,x
         sta $da00,x
         sta $dae8,x
         inx
         bne clearscr

;Draw the logo bitmap colours to the
;screen.
         ldx #$00
drawpic  lda logocol,x
         sta colrow,x
         lda logocol+(1*40),x
         sta colrow+(1*40),x
         lda logocol+(2*40),x
         sta colrow+(2*40),x
         lda logocol+(3*40),x
         sta colrow+(3*40),x
         lda logocol+(4*40),x
         sta colrow+(4*40),x
         lda logocol+(5*40),x
         sta colrow+(5*40),x
         lda logocol+(6*40),x
         sta colrow+(6*40),x
         lda logocol+(7*40),x
         sta colrow+(7*40),x
         lda logocol+(8*40),x
         sta colrow+(8*40),x
         lda logocol+(9*40),x
         sta colrow+(9*40),x
         inx
         cpx #40
         bne drawpic

;Copy title screen text lines to screen
;RAM memory

         ldx #$00
copytext lda line1,x
         sta row+(12*40),x
         lda line2,x
         sta row+(15*40),x
         lda line3,x
         sta row+(17*40),x
         lda line4,x
         sta row+(20*40),x
         inx
         cpx #40
         bne copytext

         ;Initialize  scrolltext

         lda #<scrolltext
         sta messread+1
         lda #>scrolltext
         sta messread+2

         ;Initialize flash pointers

         lda #$00
         sta fdelay
         sta fptr

         jmp setupirq

;--------------------------------------

;Setup IRQ raster interrupt for title
;screen.

setupirq ldx #<tirq1
         ldy #>tirq1
         lda #$7f
         stx $0314
         sty $0315
         sta $dc0d
         lda #$22
         sta $d012
         lda #$1b
         sta $d011
         lda #$01
         sta $d01a
         lda #$00
         jsr music2init
         cli
         jmp tloop

;IRQ 1 - Smooth scrolling text

tirq1    asl $d019
         lda $dc0d
         sta $dd0d

         ;Set raster position
         lda #tsplit1
         sta $d012

         ;Set flashing raster line

fline1   lda #1
         sta $d020

         ldx #$0b
         dex
         bne *-1

         ;Set to purple border split
         lda #4
         sta $d020

         ;Standard screen mode
         lda #$1b
         sta $d011

         ;Game/text charset
         lda #$1a
         sta $d018

         ;Default VIC2 bank #$03
         lda #$03
         sta $dd00

         ;Trigger synctimer
         lda #1
         sta rt2

         ;Play title music
         jsr music2play


         ;Call next IRQ interrupt
         ldx #<tirq2
         ldy #>tirq2
         stx $0314
         sty $0315
         jmp $ea7e

;IRQ 2 - Title screen logo

tirq2    asl $d019

         ;Set raster position
         lda #tsplit2
         sta $d012

         ;Prepare thin flashing line
         ;and black border (use timing
         ;of raster first)

         ldx #$02
         dex
         bne *-1

         ;Flashing line
fline2   lda #1
         sta $d020

         ;A bit more timing
         ldx #$0b
         dex
         bne *-1

         ;Black main border
         lda #$00
         sta $d020

         ;Bitmap mode active
         lda #$3b
         sta $d011

         ;Screen multicolour mode
         lda #$18
         sta $d016

         ;Vidcom paint charset mode
         lda #$78
         sta $d018

         ;Swith to VIC bank #$02
         lda #$02
         sta $dd00

         ;Setup to next IRQ interrupt
         ldx #<tirq3
         ldy #>tirq3
         stx $0314
         sty $0315
         jmp $ea7e

;IRQ 3 - Title screen credits page

tirq3    asl $d019

         ;Set raster position
         lda #tsplit3
         sta $d012

         ;Screen default on
         lda #$1b
         sta $d011

         ;Charset multicolour mode off
         lda #$08
         sta $d016

         ;Game/text charset
         lda #$1a
         sta $d018

         ;Default BANK #$03
         lda #$03
         sta $dd00

         ;Call next IRQ interrupt
         ldx #<tirq4
         ldy #>tirq4
         stx $0314
         sty $0315
         jmp $ea7e

tirq4    asl $d019

         ;Set final raster position
         lda #tsplit4
         sta $d012

         ;Call smooth scroll mode
         lda xpos
         sta $d016

         ;Call first IRQ interrupt
         ldx #<tirq1
         ldy #>tirq1
         stx $0314
         sty $0315
         jmp $ea7e


;Main title screen loop

tloop    lda #0
         sta rt2
         cmp rt2
         beq *-3

         ;Renamed scroller to txtscroll due to existing label
         ;available in gamecode.asm
         
         jsr txtscroll 
         jsr flash

         ;Wait for fire to be
         ;pressed

normal   lda #16    ;joystick port 2 fire button
         bit $dc00
         bne fast
         lda #$01
         sta difficulty
         jmp chkMode      ;checks if one or two player mode
         
fast     lda #01       ;up input
         bit $dc00
         bne faster
         lda #$02
         sta difficulty
         jmp chkMode
         
faster   lda #02         ;down input
         bit $dc00
         bne fastest
         lda #$03
         sta difficulty
         jmp chkMode
         
fastest  lda #04           ;left input
         bit $dc00
         bne extreme
         lda #$04
         sta difficulty
         jmp chkMode
         
extreme  lda #08            ;right input
         bit $dc00         
         bne tloop          ;restarts input check
         lda #$05
         sta difficulty
      
chkMode  lda #16         ;player mode check: joystick port 1 fire button
         bit $dc01
         bne onePlyr
twoPlyr  lda #$01 
         sta playerMode
         jmp gameStrt

onePlyr  lda #$00
         sta playerMode 

gameStrt jmp game

;Scroll text routine

txtscroll lda xpos
         sec
         sbc #1 ;Speed of scroll
         and #7
         sta xpos
         bcs exitscr

    ;Shift text columns to act as
    ;a scroll

         ldx #$00
movtxt   lda row+(23*40)+1,x
         sta row+(23*40),x

         inx
         cpx #39
         bne movtxt

messread lda scrolltext
         cmp #0
         bne storchr

         ;Init scroll

         lda #<scrolltext
         sta messread+1
         lda #>scrolltext
         sta messread+2
         jmp messread

         ;Store last character on
         ;message to last column on
         ;bottom row

storchr  sta row+(23*40)+39

         ;Move to next character in the
         ;scroll text

         inc messread+1 ;INC LO-BYTE
         bne exitscr    ;else skip
         inc messread+2 ;INC HI-BYTE

exitscr  rts            ;else skip

;--------------------------------------

;Text and bar flash routine

flash    lda fdelay
         cmp #1 ;Give time for flash
                ;delay before reading
                ;flash table and
                ;storing to text

         beq flashok
         inc fdelay
         rts

         ;Flash delay ok, so read
         ;flash pointer

flashok  lda #$00   ;Reset flash delay
         sta fdelay

         ldx fptr
         lda fcolour,x

         ;Store byte from table to
         ;columns

         sta colrow+(12*40)+39 ;Last
         sta colrow+(15*40)    ;First
         sta colrow+(17*40)+39 ;Last
         sta colrow+(20*40)    ;First
         sta colrow+(23*40)+39 ;Last

         ;Store byte from table2 to
         ;selfmod raster lines

         lda rtable1,x
         sta fline1+1
         lda rtable2,x
         sta fline2+1

         inx
         cpx #10 ;10 bytes to read
         beq resetf
         inc fptr
         jmp fmain ;Flash main

         ;Reset flash pointer
resetf   ldx #$00
         stx fptr

         ;Main colour wash routine

         ;Right - to left

fmain    ldx #$00
flaloop  lda colrow+(12*40)+1,x
         sta colrow+(12*40),x
         lda colrow+(17*40)+1,x
         sta colrow+(17*40),x
         lda colrow+(23*40)+1,x
         sta colrow+(23*40),x
         inx
         cpx #40 ;40 chars
         bne flaloop

         ;Left to right

         ldx #39  ;Reverse-loop
flaloop2 lda colrow+(15*40),x
         sta colrow+(15*40)+1,x
         lda colrow+(20*40),x
         sta colrow+(20*40)+1,x
         dex
         bpl flaloop2

         rts


;--------------------------------------

;Title screen pointers

rt2      !byte $00 ;Synctimer
xpos     !byte $00 ;Smooth scroll
                   ;control pointer

fdelay   !byte $00 ;Flash delay
fptr     !byte $00 ;Flash pointer

;Flash colour table (10  bytes)
;for text

fcolour  !byte $06,$04,$0a,$07,$01
         !byte $07,$0a,$04,$06,$00

;Flash colour table (10 bytes)
;for raster lines

rtable1  !byte $00,$06,$04,$0a,$07
         !byte $01,$07,$0a,$04,$06

rtable2  !byte $04,$0a,$07,$01,$07
         !byte $0a,$04,$06,$00,$06


;--------------------------------------

;Title screen standard text

         !ct scr ;Convert ASCII to 
                 ;C64 screen data
                 
               ;00000000001111111111"
line1   ;.text "01234567890123456789"

         !text "    @ 2023 t.n.d gam"
         !text "es for lemon 64!    "

line2    !text "   programming, grap"
         !text "hics and music by   "

line3    !text "              richar"
         !text "d / tnd             "

line4    !text "           press fir"
         !text "e to play           "

;--------------------------------------

;Difficulty and two-player mode bytes

difficulty !byte 0
playerMode !byte 0

;*** END ***

