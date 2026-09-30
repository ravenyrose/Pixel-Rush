;**************************************
;Race 'n' Smash - Prototype build
;for Lemon64 by Richard/TND
;September 2023
;**************************************

  !to "prototype.prg",cbm
  
  ;Import game screen
  *=$0c00
  !bin "c64/testscreen.prg",,2
  
;**************************************
;Race 'n' Smash - Prototype build
;for Lemon64 by Richard/TND
;September 2023
;**************************************  
  
;Set jump addr to assembler
;$9000 if Turbo Assembler, $8000 if
;using Turbo Macro Pro

;assembler = $9000 <- Not needed in
                     ;c64 Studio
  
;Test track screen memory
trackmem = $0c00


;C64Studio Basic startup command

        *=$0801
        !basic 16384

;--------------------------------------
    *= $4000;set start address
;--------------------------------------

;Setup jump assembler on RESTORE press
;** remove code snippet when compiling
;the final production *** (NOT NEEDED
;IN C64 STUDIO)

         ;lda #<assembler
         ;sta $0328
         ;lda #>assembler
         ;sta $0329
         
         lda #$fb ;Set this for more
         txs ;than 4 jsrs when using interrupts
         
gamecode

         sei
         lda #$37 ;Set $01 to $37 to
         sta $01 ;enable kernal
         
;Draw a test track from the screen
;memory location.

        ldx #$00
drawtrk lda trackmem,x
        sta $0400,x ;screen ram
        lda trackmem+$0100,x
        sta $0500,x
        lda trackmem+$0200,x
        sta $0600,x
        lda trackmem+$02e8,x
        sta $06e8,x  

;Fill colour grey

        lda #12
        sta $d800,x ;colour ram
        sta $d900,x
        sta $da00,x
        sta $dae8,x
        inx         
        bne drawtrk
         
;Fill first sprite with block square

        ldx #$00
fill    lda #$ff
        sta $2000,x
        inx
        cpx #$40 ;Or 64 bytes
        bne fill ;(1 full sprite)        
        
;Setup sprite objects

        lda #%00000000 ;No sprites
        sta $d017 ;expanded X
        sta $d01b ;behind bg
        sta $d01d ;expanded Y

        lda #%11111111
        sta $d015 ;All sprites on

        lda #$00
        sta $d01e ;Init collision

        lda #5 ;Fairer collision
        sta colltimer ;timer

        lda #$14 ;Default C64 charset
        sta $d018 ;mode BANK 3

        lda #$00   ;Colour black
        sta $d020  ;border colour
        sta $d021  ;background colour        
        
;Make all sprites filled blocks by
;reading the first 64 bytes of sprite
;data at $2000. And paint the cars

         ldx #$00
dosquare lda #$80 ;Read at $2000
         sta $07f8,x
         lda carcolor,x
         sta $d027,x
         inx
         cpx #$08 ;8 sprites max
         bne dosquare   
         
;Setup starting position of game
;sprites, by reading the startpos table
;and store to carpos table.

         ldx #$00
makepos  lda startpos,x
         sta carpos,x
         inx
         cpx #16 ;16 bytes position
         bne makepos
         
;Initialize score to 000000

          ldx #$00
initsc    lda #$30 ;digit 0
          sta score,x
          inx
          cpx #6 ;Max digits=6
          bne initsc

;Place in the score panel (at the
;bottom of the screen)

          jsr maskpanel
          
;Prepare IRQ raster interrupt

      ldx #<irq ;IRQ flag pos lo
      ldy #>irq ;IRQ flag pos hi
      lda #$7f
      stx $0314 ;Store IRQ flag lo
      sty $0315 ;Store IRQ flag hi
      sta $dc0d
      sta $dd0d
      lda #$32 ;Raster pos
      sta $d012
      lda #$1b ;VScreen default
      sta $d011
      lda #$01 ;IRQ speeder
      sta $d01a
      cli ;Clear IRQ

;After calling IRQ jump
;directly to the main
;game loop

      jmp gameloop                                 
      
;Make an IRQ raster interrupt. This is
;being used to control the timing of
;the game play.

irq         inc $d019 ; IRQ speeder again
            lda $dc0d
            sta $dd0d ; Stabilize CIA

            lda #$fa ; Set end raster
            sta $d012 ; Position

            lda #1 ; Enable raster
            sta rt ; synctimer

            jmp $ea7e ; Loop IRQ
            
;The main game loop (Call subroutines)

gameloop jsr syncall ;Synchronize game  
         jsr obj2spr ;Store objects pos
                     ;to sprite pos
         jsr movplr ;Move player
         jsr movbad ;Move baddies
         jsr spr2spr;Sprite/sprite
                    ;collision.

         jsr scoring ;Scoring points
         jmp gameloop ;Infinite loop
                      ;until next event
                      ;occurs                  
                      
;Synchronise raster timer (RT) with IRQ
;outside interrupt.

syncall  lda #$00 ;Zero RT
         sta rt
syncloop cmp rt ;Synced?
         beq syncloop ;No, loop until
         rts ;sync ready       
         
;Convert all virtual car positions to
;hardware sprite positions.

obj2spr  ldx #$00
objploop lda carpos+1,x ;Read Y position
         sta $d001,x ;Store sprite Y
         lda carpos,x ;Read X position
         asl a ;Double size of
         ror $d010 ;X sprite pos
         sta $d000,x ;Store sprite X
         inx ;X sprite pos
         inx ;Y sprite pos
         cpx #16 ;16 positions
         bne objploop ;Loop if not 16
         rts          
         
;Move player using joystick port 2

movplr     lda #1 ;Read joystick up
           bit $dc00
           bne notup
           jsr movplrup ;Move car up

notup      lda #2 ;Read joystick down
           bit $dc00
           bne notdown
           jsr movplrdn ;Move car down

notdown

           lda #4 ;Read joystick left
           bit $dc00
           bne notleft
                      jsr movplrlf ;Move car left

notleft    lda #8 ;Read joystick right
           bit $dc00
           bne notright
           jsr movplrgt ;Move car right

notright   rts ;Exit subroutine

;Move player car up

movplrup    lda carpos+1 ;Read Y of car
            sec ;subtract pos by
            sbc #4 ;4
            cmp #$90 ;Pos below $90
            bcs storup ;No, update pos

            lda #$90 ;Force stop pos
storup      sta carpos+1 ;Updated position
            rts
            
;Move player car down

movplrdn    lda carpos+1 ;Read Y of car
            clc ;add pos by
            adc #4 ;4
            cmp #$da ;Pos above $da
            bcc stordn ;No, update pos
            lda #$da ;Force stop pos
stordn      sta carpos+1 ;Updated position
            rts
            
;Move player car left

movplrlf    lda carpos ;Read X of car
            sec ;subtract pos by
            sbc #2 ;2
            cmp #$2e ;Pos below $2e?
            bcs storlft ;No, update pos
            lda #$2e ;Force stop pos
storlft     sta carpos ;Updated position
            rts
            
;Move player car right

movplrgt    lda carpos ;Read X of car
            clc ;add pos by
            adc #2 ;2
            cmp #$7e ;Pos above $7e?
            bcc storrgt ;No update pos
            lda #$7e ;Force stop pos
storrgt     sta carpos
            rts

;Move the enemy cars at twice the
;speed of the player

movbad     ldx #$00
movloop    lda carpos+3,x ;Read sprite 1
                          ;Y pos (Enemy
                          ;cars)
           clc
           adc #$04 ;2x speed
           sta carpos+3,x
           inx
           inx
           cpx #14 ;7 sprites for baddies
           bne movloop
           rts
           
;Hardware pixel based sprite to sprite
;collision.

spr2spr     lda $d01e
            lsr a
            bcc nocrash
            jmp crashed
nocrash     rts

;-------------------------------------

;The player has crashed, but make sure
;the crash counter has reached zero
;before the player dies.

crashed     dec colltimer
            lda colltimer
            beq gameover
            rts 
            
;The game is over so now work out if
;the player has scored a new hi score

gameover    lda #$00 ;All sprites off
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
makenewsc   lda score,x
            sta hiscore,x
            inx
            cpx #6
            bne makenewsc
            
                                                
;Display A NEW HI SCORE onto the screen

            ldx #$00
dispnewhi   lda hitext,x ;New hi score text
            cmp #$30
            bcc storok
            sec
            sbc #$40
storok      sta $054c,x
            lda #$0d    ;Colour light green
            sta $d94c,x  
            inx
            cpx #14
            bne dispnewhi
nohiscore
            jsr maskpanel

;Display the GAME OVER text

            ldx #$00
setgo       lda gotext,x ;Game over text
            ;cmp #$3b
            ;bcc gook  
            ;sec
            ;sbc #$40
gook        sta $05c7,x
            lda #$0a    ;Colour light red
            sta $d9c7,x
            inx
            cpx #9;Length of text
            bne setgo

gameoverloop

            lda #16 ;Fire press wait
            bit $dc00
            bne gameoverloop ;Loop it
           
            jmp gamecode ;Re-run game
            
;Scoring points
;Enemy cars must exit the screen
;before points are scored in units of
;10s.

scoring ldx #$00
chkloop lda carpos+3,x
        cmp #$fa ;Range $f0 reached
        beq setnextpos
        cmp #$fc
        beq setnextpos
        inx
        inx
        cpx #14
        bne chkloop
        rts
        

;Set new X position for next enemy car
;by calling setnextpos

setnextpos
        ldy rseqptr ;Read sequence
                    ;pointer to read
        lda seqtable,y ;next byte on tb
        sta rndstor ;store rndstor
        ldy rndstor ;read rbdstor,y
        lda randpostbl,y ;read table
        sta carpos+2,x ;store to car
                       ;x position

        inc rseqptr ;then increment
                    ;sequence read
                    ;pointer    
                    
;Add points in units of 10 then copy
;the updated score to screen.

scoreit inc score+4
        ldx #$04
scloop  lda score,x
        cmp #$3a ;Illegal char value (:)
        bne scoreok
        lda #$30 ;Make as 0
        sta score,x
        inc score-1,x
scoreok dex
        bne scloop
        
maskpanel

         ldx #$00
maskloop lda scorepanel,x
         ;cmp #$3f
         ;bcc panelok
         ;sec
         ;sbc #$40
panelok
         sta $07c0,x
         inx
         cpx #$28
         bne maskloop
         rts
         
;POINTERS

;Raster sync timer

rt !BYTE 0

;Fairer collision timer avoiding bugs

colltimer !BYTE 0

;Random sequence pointer

rseqptr !BYTE 0
rndstor !BYTE 0

;Car position table. Car 1 is the main
;player. Cars 2 - 8 are the baddies.

carpos  !BYTE $00,$00 ;Car 1-Sprite 0
        !BYTE $00,$00 ;Car 2-Sprite 1
        !BYTE $00,$00 ;Car 3-Sprite 2
        !BYTE $00,$00 ;Car 4-Sprite 3
        !BYTE $00,$00 ;Car 5-Sprite 4
        !BYTE $00,$00 ;Car 6-Sprite 5
        !BYTE $00,$00 ;Car 7-Sprite 6
        !BYTE $00,$00 ;Car 8-Sprite 7
        
;Car colour table

carcolor

        !BYTE $0a,$0d,$0f,$0e
        !BYTE $04,$07,$0a,$0c
        
;Starting position table. Car 1 is the
;main player. Cars 2-8 are the baddies.

startpos !BYTE $56,$da ;Car 1-Sprite 0
         !BYTE $2e,$80 ;Car 2-Sprite 1
         !BYTE $42,$c0 ;Car 3-Sprite 2
         !BYTE $56,$40 ;Car 4-Sprite 3
         !BYTE $6a,$80 ;Car 5-Sprite 4
         !BYTE $42,$c0 ;Car 6-Sprite 5
         !BYTE $7e,$00 ;Car 7-Sprite 6
         !BYTE $2e,$40 ;Car 8-Sprite 7
         
;Posible positions:
;$2e,$42,$56,$6a,$7e,$00 ;00 = no enemy

randpostbl
        !BYTE $2e,$42,$56,$6a,$7e,$00
        
;Text objects
;Score panel, for playing game

scorepanel

!ct scr ;This is needed in C64Studio

!text "score: "
score !text "000000"
!text " race 'n smash "
!text "hi: "
hiscore !text "000000"

;Game over text

gotext !text "game over"

;New hi score text

hitext !text "a new hi score"

;A 256 byte set of random numbers 0-5
; 25*10 + 6 bytes = 256

*= $4800

seqtable

!BYTE 0,1,2,3,4,5,0,4,3,1,5
!BYTE 3,1,2,0,4,3,4,1,0,2,3
!BYTE 4,0,3,1,2,4,5,1,0,3,1
!BYTE 5,0,2,3,5,1,0,2,0,4,1
!BYTE 5,1,0,2,0,4,5,1,0,2,3

!BYTE 2,4,0,3,2,5,1,4,0,1,3
!BYTE 4,5,1,3,2,4,0,1,3,0,2
!BYTE 4,1,3,0,5,1,2,5,2,4,1
!BYTE 0,3,5,1,4,3,2,1,4,0,3
!BYTE 2,5,1,2,4,1,2,3,1,3,2

!BYTE 5,0,1,3,0,3,1,0,5,1,3
!BYTE 4,0,2,1,3,1,4,2,3,1,5
!BYTE 2,0,3,1,5,1,2,4,1,3,1
!BYTE 4,1,5,3,1,2,4,5,1,2,4
!BYTE 1,3,4,5,1,2,4,3,1,2,3

!BYTE 4,3,0,1,0,3,2,0,4,5,1
!BYTE 2,0,4,0,5,1,3,2,0,3,4
!BYTE 1,3,4,0,1,2,4,3,1,2,0
!BYTE 3,0,1,4,3,1,2,5,3,1,5
!BYTE 2,3,1,5,3,1,0,2,3,1,4

!BYTE 3,1,5,4,1,2,1,4,3,1,3
!BYTE 4,1,5,0,3,1,2,4,1,3,2
!BYTE 1,4,3,4,2,5,3,2,0,3,1
!BYTE 3,1,0,4,3,1,2,4,3,4,1
!BYTE 3,0,1,4,3,5,1,0,2,4,3

!BYTE 5,4,3,2,1,0

                                          
                                                                                                     