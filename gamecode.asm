;**************************************
;Race 'n' Smash - Final game build
;for Lemon64  by Richard/TND
;September 2023

;For turbo assembler
;**************************************

;ADAPTED TO WORK IN C64STUDIO/ACME
;CROSS ASSEMBLER

;Build 2 - full game with smooth
;scrolling and levels.

;--------------------------------------

;Set jump address to assembler:

;$9000 if Turbo Assembler, $8000 if
;using Turbo Macro Pro

assembler = $9000

;Set jump address to title screen code
;(set to $5000 when building the
;finished game).

titlescreen = $5000

;Memory notes exclusive to this game

;-----------------------------------
;GAME:
;$0c00-$0fe8 = track screen memory
;$1000-$20ff = music
;$2100-$27ff = sprites (first spr $84)
;$2800-$24ff = game charset (mode $1a)
;$4000-$4xxx = game code
;-----------------------------------
;When packing/crunching:
;
;$0001 = $37
;JMP   = $5000 ;Title screen code
;SEI/CLI = SEI
;--------------------------------------

;Variables/addresses
;-------------------

;Test track screen memory

trackmem = $0c00

;Screen row memory for scrolling

row      = $0400 ;Actual screen ram adr
rowtemp1 = $3d00 ;temp store address
rowtemp2 = $3d28 ;temp store address 2
scrollspeed = $03 ;Speed of hardscroll

;Music parameters

musicinit = $1000 ;Music init address
musicplay = $1003 ;Music play address

;Raster split positions in IRQ

split1   = $2e ;IRQ1
split2   = $de ;IRQ2
split3   = $ee ;IRQ3
split4   = $fa ;IRQ4

;Random sequence table

seqtable = $4c00


;--------------------------------------

;Stop RUN/RESTORE from breaking game

         lda #251
         sta $0328
;--------------------------------------

         lda #$fb ;Set this for more
         txs      ;than 4 jsrs when
                  ;using interrupts

;--------------------------------------

gamecode
         sei
         lda #$37 ;Set $01 to $37 to
         sta $01  ;enable kernal

;Clear out IRQ raster interrupt

         ldx #<$ea31
         ldy #>$ea31
         stx $0314
         sty $0315
         lda #$81
         sta $dc0d
         sta $dd0d
         lda #$00
         sta $d01a
         sta $d019
         sta $d020
         sta $d021

         lda #$0b  ;Switch off screen
         sta $d011

         ;Stop SID from playing

         ldx #$00
clearsid lda #$00
         sta $d400,x
         inx
         cpx #$18
         bne clearsid


;Copy 256 byte data to sequence table
;placed at $4c00.

         ldx #$00
copyran  lda rantable,x
         sta seqtable,x
         inx
         bne copyran

 ;Make a short delay to avoid sensitive
 ;joystick press from title screen.

         ldx #$00
wait1    ldy #$00
wait2    iny
         bne wait2
         inx
         bne wait1

;Draw a test track from the screen
;memory location.

         ldx #$00
drawtrk  lda trackmem,x
         sta $0400,x ;screen ram
         lda trackmem+$0100,x
         sta $0500,x
         lda trackmem+$0200,x
         sta $0600,x
         lda trackmem+$02e8,x
         sta $06e8,x

         ;Fill colour multi-green

         lda #13
         sta $d800,x ;colour ram
         sta $d900,x
         sta $da00,x
         sta $dae8,x
         inx
         bne drawtrk


         ;Setup VIC2 graphics

         ;Set horizontal screen mode as
         ;default multicolour

         lda #$18
         sta $d016

         ;Set char mode to custom gfx
         ;charset at $2800

         lda #$1a
         sta $d018

         ;Set game colour settings

         lda #$00
         sta $d020
         sta $d021
         lda #$09
         sta $d022
         lda #$01
         sta $d023

;Fill out the score panel ready for
;colour washing. (Colour mirroring)

         ldx #$00
washall  lda coltable,x
         sta $d800+(23*40),x
         sta $d800+(23*40)+8,x
         sta $d800+(23*40)+16,x
         sta $d800+(23*40)+24,x
         sta $d800+(23*40)+32,x
         inx
         cpx #8
         bne washall

;Erase last 2 rows on screen


         ldx #$00

erase    lda #$20
         sta $0400+(23*40),x
         sta $0400+(24*40),x


;Also backup the last track row from
;the edited screen and store to
;rowtemp1

         lda trackmem+(23*40),x
         sta rowtemp1,x
         inx
         cpx #$28
         bne erase

         ;Also init flash pointers

         lda #$00
         sta fldelay
         sta flpointer
         sta flstore

         ;Reset scroll position

         lda #$00
         sta ypos

         ;Reset level scroll speed

         lda #$02
         sta levspd+1

         ;Reset baddies speed

         lda #$01
         sta badspd+1

         ;Reset level timer (ms)

         lda #$00
         sta timems
         sta times

         ;Finally reset level to 1

         lda #$01
         sta level

;Create an empty sprite at $3fc0

         ldx #$00
empty    lda #$00
         sta $3fc0,x
         inx
         cpx #$40
         bne empty

;Setup sprite objects

         lda #%00000000 ;No sprites
         sta $d017      ;expanded X
         sta $d01b      ;behind bg
         sta $d01d      ;expanded Y

         lda #%11111111
         sta $d015 ;All sprites on
         sta $d01c ;with multicolour
         lda #1    ;Set WHITE as
         sta $d025 ;spr mcol 1
         lda #11   ;Set DARK GREY as
         sta $d026 ;spr mcol 2

         lda #$00
         sta $d01e ;Init collision

         lda #5   ;Fairer collision
                  ;timer initialised

         sta colltimer



;Make all sprites the car sprite.

         ldx #$00
docars   lda #$84 ;Read at $2000
         sta cartyp,x
         lda carcolor,x
         sta carcol,x
         inx
         cpx #$08 ;8 sprites max
         bne docars

;Setup starting position of game
;sprites, by reading the startpos table
;and store to carpos table.

         ldx #$00
makepos  lda startpos,x
         sta carpos,x
         inx
         cpx #16 ;16 bytes position
         bne makepos

;--------------------------------------

;Initialize score to 000000

         ldx #$00
initsc   lda #$30        ;digit 0
         sta score,x
         inx
         cpx #6          ;Max digits=6
         bne initsc

;Place in the score panel (at the
;bottom of the screen)

         jsr maskpanel

;Prepare IRQ raster interrupt

         ldx #<irq1 ;IRQ flag pos lo
         ldy #>irq1 ;IRQ flag pos hi
         lda #$7f
         stx $0314 ;Store IRQ flag lo
         sty $0315 ;Store IRQ flag hi
         sta $dc0d
         sta $dd0d
         lda #$32;Raster pos
         sta $d012
         lda #$1b  ;VScreen default
         sta $d011
         lda #$01  ;IRQ speeder
         sta $d01a

         lda #$00  ;Initialize music
         jsr musicinit

         cli       ;Clear IRQ

         ;After calling IRQ jump
         ;directly to the main
         ;game loop

         jmp setLives

;--------------------------------------

 ;NOTE:  Uncomment the border
 ;       colours to test raster
 ;       position.

;Make a multi-IRQ raster interrupt for
;the main game engine.

;IRQ 1: Synchronizes the raster timer
;       and also play music.


irq1     asl $d019 ; IRQ speeder again
         lda $dc0d
         sta $dd0d ; Stabilize CIA
         lda #split1 ; Set end raster
         sta $d012 ; Position

         lda #1
         sta rt

      ;  lda #1
      ;  sta $d020

         ldx #<irq2 ;Move to next irq
         ldy #>irq2
         stx $0314
         sty $0315
         jmp $ea7e ;Loop IRQ

;IRQ2 - The vertical wrap-around soft
;       scroller.

irq2     asl $d019

         lda #split2 ;Raster position
         sta $d012

         lda ypos+1 ;Read scroll Y
         sta $d011;store to screen

         ;Mask car sprite to sprite
         ;type

         jsr maskcars

      ;  lda #2   ;Test split colour
      ;  sta $d020;border

         ldx #<irq3
         ldy #>irq3
         stx $0314
         sty $0315
         jmp $ea7e

;IRQ3 - Black raster line which hides
;       graphics.

irq3     asl $d019

         nop
         nop
         nop
         nop

         lda #split3 ;End raster pos
         sta $d012

         lda #$7f  ;Cover all graphics
         sta $d011 ;in that row

         jsr maskblank



      ;  lda #3   ;Test split border
                   ;colour
      ;  sta $d020


         ldx #<irq4
         ldy #>irq4
         stx $0314
         sty $0315
         jmp $ea7e

;IRQ 4 - Display score panel

irq4     asl $d019

         lda #split4
         sta $d012

         lda #$1f   ;Static Y position
         sta $d011  ;of vertical screen
                    ;position (VSP)

;        lda #4    ;Test split border
;        sta $d020;colour

         ldx #<irq1 ;Reach end of raster
         ldy #>irq1
         stx $0314
         sty $0315

         jmp $ea7e

;--------------------------------------

;Mask all cars to sprite type
;also mask colour to sprite colour

maskcars ldx #$07
maskcar  lda cartyp,x
         sta $07f8,x
         lda carcol,x
         sta $d027,x
         dex
         bpl maskcar
         rts

;Mask all blank sprites ($3fc0)
;to sprite.

maskblank
         ldx #$07
maskblk  lda #$ff
         sta $07f8,x
         dex
         bpl maskblk
         rts

;--------------------------------------

setLives lda #$03
         sta lives1
         sta lives2
         lda playerMode 
         cmp #$00
         bne setDiff
         lda #$00
         sta lives2

setDiff  lda difficulty

diff1    cmp #$01
         bne diff2
         lda  #59 ;60 seconds
         sta  lvlTime
         jmp gameloop

diff2    cmp #$02
         bne diff3
         lda  #29 ;30 seconds
         sta  lvlTime         
         jmp gameloop 
         
diff3    cmp #$03
         bne diff4
         lda  #$14 ;15 seconds
         sta  lvlTime   
         jmp gameloop      
         
diff4    cmp #$04
         bne diff5
         lda  #$09 ;10 seconds
         sta  lvlTime         
         jmp gameloop
         
diff5    cmp #$05
         lda  #$04 ;5 seconds
         sta  lvlTime         
         jmp gameloop
         
;The main game loop (Call subroutines)

gameloop

         jsr syncall;Synchronize game

         jsr obj2spr ;Store objects pos
                     ;to sprite pos
         jsr scroller

         jsr animate ;Animate player
                     ;and baddies

         jsr movement ;Move player and
                      ;baddies

         jsr spr2spr;Sprite/sprite
                    ;collision.

         jsr scoring ;Scoring points

         jsr flashpanel ;Flash score
panel
         jsr levels  ;Level control

         jsr musicplay ;Play music
                       ;outside irq to
                       ;save rastertime

         jmp gameloop ;Infinite loop
                      ;until event

;--------------------------------------
;Sprite animation loop


animate  jsr animspr;Animation routine
         jsr animplr ;Animate player
         jsr animbad ;Animate enemies
         rts

;--------------------------------------
;Sprite movement loop for both players
;and baddies.

movement
         jsr  movplr1 ;Move player car
         jsr  movplr2
         
         jsr movbad  ;Move baddies
         rts

;--------------------------------------

;Synchronize raster timer (RT) with IRQ
;outside interrupt.

syncall  lda #$00     ;Zero RT
         sta rt
         lda rt
syncloop cmp rt
         beq syncloop ;No, loop until
         rts          ;sync ready

;--------------------------------------

;Convert all virtual car positions to
;hardware sprite positions.

obj2spr  ldx #$00
objploop lda carpos+1,x ;Read Y position
         sta $d001,x  ;Store sprite Y
         lda carpos,x ;Read X position
         asl         ;Double size of
         ror $d010    ;X sprite pos
         sta $d000,x  ;Store sprite X
         inx          ;X sprite pos
         inx          ;Y sprite pos
         cpx #16      ;16 positions
         bne objploop ;Loop if not 16
         rts

;--------------------------------------

;Animate those game sprites

animspr  lda animdelay
         cmp #1
         beq animready
         inc animdelay
         rts

         ; Ready to animate racing cars
animready
         lda #$00
         sta animdelay
         ldx animpointer
         lda carframe,x
         sta car
         inx
         cpx #8
         beq resetframe
         inc animpointer
         rts

resetframe
         ldx #$00
         stx animpointer
         rts

;Animate the player

animplr  lda car   ;Read pointer car
         sta cartyp ;Store to sprite 0
         rts

;Animate the baddies using the same
;frame.

animbad

         ldx #$00
newframe lda car
         sta cartyp+1,x ;Sprites 1-7
         inx
         cpx #$07
         bne newframe
         rts

;--------------------------------------

;Move player 1 using joystick port 2
movplr1  lda lives1
         cmp #$00
         bne readUp1
         rts

readUp1  lda #1 ;Read joystick up
         bit $dc00
         bne notup1
         jsr movplrup1 ;Move car up

notup1   lda #2 ;Read joystick down
         bit $dc00
         bne notdown1
         jsr  movplrdn1 ;Move car down
         
notdown1 lda #4 ;Read joystick left
         bit $dc00
         bne notleft1
         jsr movplrlf1 ;Move car left

notleft1 lda #8 ;Read joystick right
         bit $dc00
         bne notright1
         jsr movplrgt1 ;Move car right
notright1 rts          ;Exit subroutine

;Move player car up

movplrup1 lda carpos+1 ;Read Y of car
         sec          ;subtract pos by
         sbc #3       ;3
         cmp #$3a     ;Pos below $3a
         bcs storup1   ;No, update pos
         lda #$3a     ;Force stop pos
storup1  sta carpos+1 ;Updated position
         rts

;Move player car down

movplrdn1 lda carpos+1 ;Read Y of car
         clc          ;add pos by
         adc #3       ;3
         cmp #$c2     ;Pos above $da
         bcc stordn1   ;No, update pos
         lda #$c2     ;Force stop pos
stordn1  sta carpos+1 ;Updated position
         rts

;Move player car left

movplrlf1 lda carpos   ;Read X of car
         sec          ;subtract pos by
         sbc #2       ;2
         cmp #$2e     ;Pos below $2e?
         bcs storlft1  ;No, update pos
         lda #$2e     ;Force stop pos
storlft1 sta carpos   ;Updated position
         rts

;Move player car right

movplrgt1 lda carpos   ;Read X of car
         clc          ;add pos by
         adc #2       ;2
         cmp #$7e     ;Pos above $7e?
         bcc storrgt1  ;No update pos
         lda #$7e     ;Force stop pos
storrgt1 sta carpos
         rts
         
;Move player 2 using joystick port 1
movplr2  lda lives2
         cmp #$00
         bne readUp2
         rts

readUp2  lda #1 ;Read joystick up
         bit $dc01
         bne notup2
         jsr movplrup2 ;Move car up

notup2   lda #2 ;Read joystick down
         bit $dc01
         bne notdown2
         jsr movplrdn2 ;Move car down
         
notdown2 lda #4 ;Read joystick left
         bit $dc01
         bne notleft2
         jsr movplrlf2 ;Move car left

notleft2 lda #8 ;Read joystick right
         bit $dc01
         bne notright2
         jsr movplrgt2 ;Move car right
notright2 rts          ;Exit subroutine

;Move player car up

movplrup2 lda carpos+3 ;Read Y of car
         sec          ;subtract pos by
         sbc #3       ;3
         cmp #$3a     ;Pos below $3a
         bcs storup2   ;No, update pos
         lda #$3a     ;Force stop pos
storup2  sta carpos+3 ;Updated position
         rts

;Move player car down

movplrdn2 lda carpos+3 ;Read Y of car
         clc          ;add pos by
         adc #3       ;3
         cmp #$c2     ;Pos above $da
         bcc stordn2   ;No, update pos
         lda #$c2     ;Force stop pos
stordn2  sta carpos+3 ;Updated position
         rts

;Move player car left

movplrlf2 lda carpos+2   ;Read X of car
         sec          ;subtract pos by
         sbc #2       ;2
         cmp #$2e     ;Pos below $2e?
         bcs storlft2  ;No, update pos
         lda #$2e     ;Force stop pos
storlft2 sta carpos+2   ;Updated position
         rts

;Move player car right

movplrgt2 lda carpos+2   ;Read X of car
         clc          ;add pos by
         adc #2       ;2
         cmp #$7e     ;Pos above $7e?
         bcc storrgt2  ;No update pos
         lda #$7e     ;Force stop pos
storrgt2 sta carpos+2
         rts          

;-------------------------------------

;Move the enemy cars at twice the
;speed of the player

; the ones below are for determining whether to move players 1 and 2

chkMovP1 lda lives1
         cmp #$00
          beq  movBack1
          inx
         inx
movBack1 rts

chkMovP2 lda lives2
         cmp #$00
          beq  movBack2
          inx
         inx
movBack2 rts

movbad   ldx  #$00           

movloop  cpx #$00
          bne  p2movCh
         jsr chkMovP1
p2movCh  cpx #$2        
         bne movEnem
         jsr chkMovP2

movEnem
         lda carpos+1,x ;Read sprite 1
                        ;Y pos (Enemy
                        ;cars)
         clc
badspd   adc #2
         sta carpos+1,x
         inx
         inx
         cpx #16 ;7 sprites for baddies
         bne movloop
         rts

;-------------------------------------
;Hardware pixel based sprite to sprite
;collision.

spr2spr  
redIf1   lda iframes1 ;makes sure that iframes reduce when not 0
         cmp #$00
         beq redIf2
         dec iframes1
redIf2   lda iframes2
         cmp #$00
         beq chkPcol
         dec iframes2
         
chkPcol   lda $d01e
          sta  collBits ;stores collision bits from d01e just in case because the previous instruction resets it
          lda  lives1  ;this makes sure that collision works with dead players
          cmp  #%00
         beq pl1Chk
          lda  lives2
          cmp  #%00
          beq  pl1Chk
          
         lda collBits 
         bit collCheck ;this should result in a 0 if players 1 and 2 collide
          beq  nocrash
         
pl1Chk   lda iframes1
         cmp #%00
          beq  pl1Sta
          lda collBits
          lsr
          sta  collBits
         jmp pl2Chk

pl1Sta   lda collBits
         lsr
         sta collBits ; this is for pl2Chk: done because value of acc might change because of crashed1
         bcc pl2Chk
         jsr crashed1 ;if player 1 crashed, that means player 2 didn't crash (might not work with certain conditions but whatever, let's work with the limitations here)
pl2Chk   lda iframes2
         cmp #$00
         bne nocrash

         lda collBits
         lsr
         bcc nocrash ;integrate pickup here later
         jmp crashed2

nocrash  rts

;-------------------------------------

;The player has crashed, but make sure
;the crash counter has reached zero
;before the player dies.



crashed  dec colltimer
         rts


crashed1 lda colltimer ;check if this causes a bug later
         cmp #$00
         bne crashed
         lda lives1
         cmp #%00
         beq chkLives
          dec  lives1
         beq chkLives ;It's verbose, but it works
         lda #30
         sta iframes1
bckcr1   rts

crashed2 lda colltimer
         cmp #%00
          bne  crashed
         lda lives2
          cmp  #$00
          beq chkLives
          dec  lives2
          beq chkLives
          lda  #30
         sta iframes2
bckcr2   rts

chkLives 
chkpl1   lda  lives1 ;for player 1
         cmp #$00
         beq chkpl2
         jmp bckcr1           ;returns if one of them is still alive
chkpl2   lda lives2
         cmp #$00
         beq destroy      ;adjust later; don't use jsr
         jmp bckcr2

;--------------------------------------

;The player car has now been destroyed
;prepare explosion routine

destroy
         lda #$00 ;Reset animation
                  ;pointers for
                  ;explosion sequence

         sta animdelay2
         sta animpointer2

         lda #$07 ;Yellow for explode
         sta carcol ;Player sprite
                    ;colour.

         ;Recall the synctimer loop
         ;sprite expansion msb and
         ;also colour washing over
         ;the score panel.

exploop  jsr syncall ;Sync timer
         jsr obj2spr ;Objects to sprite
         jsr animbad ;Animate baddies
         jsr shiftaway ;Move cars up
         jsr flashpanel ;Colour panel
         jsr musicplay ;Play music

         ;Now do explosion animation
         ;inside the loop

         lda animdelay2
         cmp #4 ;Speed of anim
         beq doexp ;do explosion
         inc animdelay2
         jmp exploop

doexp    lda #0
         sta animdelay2

         ;Main explosion animation

         ldx animpointer2
         lda expframe,x ;Explosion
                        ;frame

         sta cartyp    ;Store to
                       ;sprite 0
         inx
         cpx #8 ;Total no.of frames
         beq gameover ;Explosion exits
         inc animpointer2
         jmp exploop

;--------------------------------------
;Shift all enemy cars upwards until
;they have left the screen during
;player explosion.

shiftaway
         ldx #$00
uploop   lda carpos+3,x
         sec
         sbc #$08
         cmp #$10
         bcs updateup

         ;No car reappear in explosion
         ;so move x position to offset

         lda #$00
         sta carpos+2,x
updateup sta carpos+3,x
         inx
         inx
         cpx #14 ;(or $0e)
         bne uploop
         rts

;--------------------------------------

;The game is over so now work out if
;the player has scored a new hi score

gameover

         lda #$00;All sprites off
         sta $d015

         lda score
         sec
         lda hiscore+5
         sbc score+5
         lda hiscore+4
         sbc score+4
         lda hiscore+3
         sbc score+3
         lda hiscore+2
         sbc score+2
         lda hiscore+1
         sbc score+1
         lda hiscore
         sbc score
         beq nohiscore
         bpl nohiscore

;Player's score becomes a hi score

         ldx #$00
makenewsc
         lda score,x
         sta hiscore,x
         inx
         cpx #6
         bne makenewsc

;Display A NEW HI SCORE onto the screen

         ldx #$00

dispnewhi
         lda hitext,x
storok
         sta $054c,x
         lda #$03 ;Cyan instead of
         sta $d94c,x  ;light green
         inx
         cpx #14
         bne dispnewhi

nohiscore
         jsr maskpanel

;Display the GAME OVER text

         ldx #$00
setgo    lda gotext,x
gook     sta $05c7,x
         lda #$02 ;Red instead of pink
         sta $d9c7,x
         inx
         cpx #9;Length of text
         bne setgo

;The main game over loop, sync timer
;and flash panel while game over text
;is showing.

gameoverloop

         jsr syncall
         jsr flashpanel
         jsr musicplay

         lda #16 ;Fire press wait
         bit $dc00
         bne gameoverloop ;Loop it

         jmp titlescreen

;-------------------------------------

;Scoring points
;Enemy cars must exit the screen
;before points are scored in units of
;100s.

;*+2 ;Accuracy for levels

scoring  ldx #$00
chkloop  lda carpos+3,x
         cmp #$dc;Range $dc reached
         bcc skipnew
         lda #$00 ;Reset Y position
         sta carpos+3,x
         jmp setnextpos
skipnew  inx
         inx
         cpx #14
         bne chkloop
         rts

;Set new X position for next enemy car
;by calling

setnextpos
         ldy rseqptr    ;Read sequence
                        ;pointer to read
         lda seqtable,y ;next byte on tb
         sta rndstor    ;store rndstor

         ldy rndstor    ;read rbdstor,y
         lda randpostbl,y ;read table
         sta carpos+2,x   ;store to car
                          ;x position
         inc rseqptr    ;then increment
                        ;sequence read
                        ;pointer

;Add points in units of 100 then copy
;the updated score to screen.

scoreit

         jsr incScore
         ldx #$03
scloop   lda score,x

         cmp #$3a ;Illegal char value; ascii of 0 - 9 goes from 30 to 39 hexadecimal
         bcc scoreok

         lda #$30 ;Make as 0
         sta score,x
         inc score-1,x

scoreok  dex
         bne scloop

maskpanel
         lda level
         clc
         adc #$30 ;Convert to digits
         sta levelct

         ldx #$00
maskloop lda scorepanel,x
panelok

         sta $0400+(23*40),x

         inx
         cpx #$28
         bne maskloop

         rts
         
incScore ldx #$00
incLoop  inc score+3
         inx
         cpx difficulty
         bne incLoop
         rts

;-------------------------------------

;Flash score panel routine

flashpanel
         lda fldelay  ;Delay flashing
         cmp #1       ;for a bit
         beq flok     ;before doing
         inc fldelay  ;main flash
         rts
;Flash is okay, continue colour

flok     lda #0
         sta fldelay ;Reset delay
         ldx flpointer ;Flash pointer
         lda coltable,x

         sta $d800+(23*40)+39
             ;^store 1 row up from last
             ; row

              ;^Col RAM, Row + Column

         inx
         cpx #8 ;8 bytes to read
         beq resetfl ;Reset flash
         inc flpointer
         jmp updatefl

resetfl  ;Reset flash
         ldx #$00
         stx flpointer
updatefl
         ;Wash colour from last char
         ;column of panel to the first
         ;char in panel row.

         ldx #$00
washloop lda $d800+(23*40)+1,x
         sta $d800+(23*40),x
         inx
         cpx #39
         bne washloop
         rts

;--------------------------------------

;Game screen vertical wrap-around
;scroller

scroller lda ypos
         clc
levspd   adc #1   ;Speed based on level
         sta ypos
         lda ypos

         and #$07
         ora #$10
         sta ypos+1

         lda ypos
         cmp #$08
         bcc noscroll
         lda #$00
         sta ypos
         jmp hardscr
noscroll rts

         ;Shift upper screen rows to
         ;lower screen row. Store
         ;last row first (split
         ;hard scroll into two segments
         ;in reverse order.

hardscr

         jsr layer2;Scroll bottom layer
         jmp layer1;Scroll top layer

;Hard scroll bottom layer
;Read each column backwards

layer1

         ldx #39
hsloop1  lda row+(22*40),x
         sta rowtemp1,x
         lda row+(21*40),x
         sta row+(22*40),x
         lda row+(20*40),x ;and so on...
         sta row+(21*40),x
         lda row+(19*40),x
         sta row+(20*40),x
         lda row+(18*40),x
         sta row+(19*40),x
         lda row+(17*40),x
         sta row+(18*40),x
         lda row+(16*40),x
         sta row+(17*40),x
         lda row+(15*40),x
         sta row+(16*40),x
         lda row+(14*40),x
         sta row+(15*40),x
         lda row+(13*40),x
         sta row+(14*40),x
         lda row+(12*40),x
         sta row+(13*40),x
         lda row+(11*40),x
         sta row+(12*40),x
         lda row+(10*40),x
         sta row+(11*40),x
         lda rowtemp2,x
         sta row+(10*40),x
         dex
         bpl hsloop1
         rts

;The top layer scroll
layer2
         ldx #39
hsloop2
         lda row+(9*40),x
         sta rowtemp2,x
         lda row+(8*40),x
         sta row+(9*40),x
         lda row+(7*40),x
         sta row+(8*40),x
         lda row+(6*40),x
         sta row+(7*40),x
         lda row+(5*40),x
         sta row+(6*40),x
         lda row+(4*40),x
         sta row+(5*40),x
         lda row+(3*40),x
         sta row+(4*40),x
         lda row+(2*40),x
         sta row+(3*40),x
         lda row+(1*40),x
         sta row+(2*40),x
         lda row+(0*40),x
         sta row+(1*40),x
         lda rowtemp1,x
         sta row,x
         dex
         bpl hsloop2
         rts

;---------------------------------------

;Level control. This is based on
;playing time. The player should last
;60 seconds before the game speeds up (in normal difficulty)

levels
         lda timems
         cmp #60    ;99 seconds?
         beq secondup
         inc timems
         rts

         ;Reset milliseconds

secondup lda #$00
         sta timems
         lda times
         cmp lvlTime   ;level time interval based on difficulty
         beq levclear
         inc times

         rts

   ;Level clear, check if
   ;level is 8 if so, skip
   ;otherwise add more speed to the
   ;game.

levclear
         lda #$00
         sta times
         lda level
         cmp #8
         beq skip
         inc level
         inc levspd+1
         inc badspd+1
         jsr maskpanel
skip
         rts

;---------------------------------------

;POINTERS

; collission checker for bit instruction
collCheck !byte %11111100
collBits !byte 0

;i-frames
iframes1 !byte 0
iframes2 !byte 0

lvlTime !byte 0   ;seconds required before level transition; changes based on difficulty
lives1 !byte 0
lives2 !byte 0

;Raster sync timer

rt       !byte 0

;Scroller screen  vertical position
;control byte

ypos     !byte $00,0

;Level timer pointers

timems   !byte 0        ;milliseconds
times    !byte 0 ;seconds
level    !byte 1       ;Actual level

;Car sprite animation pointers

animdelay !byte 0
animpointer !byte 0

;Car object type and colour for
;rasters

cartyp   !byte 0,0,0,0,0,0,0,0
carcol   !byte 0,0,0,0,0,0,0,0

;Explosion sprite animation pointers

animdelay2 !byte 0
animpointer2 !byte 0
car      !byte $84 ;Car store anim

;-------------------------------------

;Fairer collision timer avoiding bugs

colltimer !byte 0

;Random sequence pointer

rseqptr  !byte  0
rndstor  !byte  0

;Colour flash delay and pointer

fldelay  !byte  0
flpointer !byte  0
flstore  !byte  0

;Car position table. Car 1 is the main
;player. Cars 2 - 8 are the baddies.

carpos   !byte  $00,$00 ;Car 1-Sprite 0
         !byte  $00,$00 ;Car 2-Sprite 1
         !byte  $00,$00 ;Car 3-Sprite 2
         !byte  $00,$00 ;Car 4-Sprite 3
         !byte  $00,$00 ;Car 5-Sprite 4
         !byte  $00,$00 ;Car 6-Sprite 5
         !byte  $00,$00 ;Car 7-Sprite 6
         !byte  $00,$00 ;Car 8-Sprite 7

;Car colour table

carcolor
         !byte  $0a,$0d,$0f,$0e
         !byte  $04,$07,$0a,$0c

;Starting position table. Car 1 is the
;main player. Cars 2-8 are the baddies.

;Reset X position for enemy cars to 0
;so that it looks as if the player is
;trying to catch up with them.

startpos !byte  $4c,$ba ;Car 1-Sprite 0 ;Car1 and 2 start on the same y pos for two-player mode
         !byte  $60,$ba ;Car 2-Sprite 1
         !byte  $00,$c0 ;Car 3-Sprite 2
         !byte  $00,$40 ;Car 4-Sprite 3
         !byte  $00,$20 ;Car 5-Sprite 4
         !byte  $00,$60 ;Car 6-Sprite 5
         !byte  $00,$a0 ;Car 7-Sprite 6
         !byte  $00,$e0 ;Car 8-Sprite 7

;Posible positions:
;$2e,$42,$56,$6a,$7e,$00 ;00 = no enemy

randpostbl
         !byte  $2e,$42,$56,$6a,$7e,$38
         !byte  $4a,$60,$74,$00

;--------------------------------------
;Sprite frames:

;Car animation table

carframe !byte  $84,$85,$86,$87
         !byte  $88,$89,$8a,$8b

;Explosion animation table

expframe !byte  $8c,$8d,$8e,$8f
         !byte  $90,$91,$92,$93

;--------------------------------------
;Text objects

;Score panel, for playing  game

         !ct scr ; Convert ASCII to C64
                 ; screen code text format
         
scorepanel
         !text "score: "
score    !text "000000"
         !text "     level: "
levelct  !text "1    "
         !text "hi: "
hiscore  !text "000000"

;Game over text

gotext   !text "game over"

;New hi score text

hitext   !text "a new hi score"

;Colour cycle table for score panel
;8 bytes = full row

coltable !byte  $04,$03,$07,$01
         !byte  $07,$03,$04,$02

;--------------------------------------

;A 256 byte set of random numbers 0-9
         ; 25*10 + 6 bytes = 256

rantable
         !byte  0,5,2,4,7,1,6,4,8,1,9
         !byte  3,1,9,0,7,3,4,8,0,1,6
         !byte  4,0,3,9,2,7,5,1,6,3,8
         !byte  5,0,2,3,5,6,8,7,9,4,1
         !byte  5,1,7,2,9,4,6,1,8,2,7

         !byte  9,4,0,7,2,6,1,8,0,6,3
         !byte  4,5,1,3,7,4,0,9,3,6,8
         !byte  6,1,9,0,5,7,2,5,2,8,1
         !byte  0,3,5,1,8,3,2,7,4,9,3
         !byte  2,5,1,2,6,1,2,9,1,3,7

         !byte  8,0,1,9,0,3,6,0,5,7,3
         !byte  4,0,2,1,9,1,4,2,7,1,5
         !byte  9,0,3,6,5,1,2,4,7,3,1
         !byte  4,1,5,9,1,2,8,5,6,2,7
         !byte  1,3,4,7,1,8,4,6,1,9,3

         !byte  4,3,0,9,0,6,2,7,4,8,1
         !byte  2,0,8,0,6,1,7,2,9,3,6
         !byte  1,6,4,0,9,2,4,9,1,7,0
         !byte  3,0,1,7,3,9,2,6,3,1,7
         !byte  8,3,1,8,3,1,9,2,6,1,4

         !byte  3,1,7,4,1,0,1,8,3,7,3
         !byte  4,1,5,6,3,1,6,4,8,9,2
         !byte  1,7,3,9,2,5,6,2,8,3,8
         !byte  3,6,0,8,3,1,2,7,3,4,1
         !byte  3,0,1,4,3,5,1,9,7,8,6

         !byte  5,4,3,2,1,0

;--------------------------------------

