;Race 'n Smash - Full game build

                !to "racensmash.prg",cbm
                
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


                  *=$0801 ;SYS 20480
                  !byte $0c,$08,$0a,$00,$9e
                  !byte $32,$30,$34,$38,$30
                  !byte $00,$00,$00,$00,$00
                 
                  *=$0c00 ;"Game track"
                  !bin "c64/gamescreen.prg",,2
                  
                   *=$1000 ;"In game music"
                  !bin "c64/gamemusic.prg",,2 
                  
                  *=$2100 ;"In game sprites"
                  !bin "c64/gamesprites.prg",,2
                  
                  *=$2500 ;"2x Score Pickup Sprite ($94)"
                  !bin "c64/x2pickup.prg",,2

                  *=$2540 ;"Invincibility Pickup Sprite ($95)"
                  !bin "c64/invpickup.prg",,2
                  
                  *=$2800 ;"Charset"
                  !bin "c64/gfxcharset.prg",,2
                  
                  ;Title screen scroll text
                  *=$3000
                  !bin "c64/scrolltext.prg",,2
                  
                  ;Main game code 
                  *=$4000
                  !source "gamecode.asm"
                  
                  *=$5000
                  ;Main title code 
                  !source "titlecode.asm"
                  
                  ;Logo colour RAM memory
                  *=$5800
                  !bin "c64/logo_col.prg",,2
                  
                  ;Logo video RAM memory 
                  *=$5c00
                  !bin "c64/logo_vid.prg",,2
                  
                  ;Logo bitmap memory 
                  *=$6000
                  !bin "c64/logo_bmp.prg",,2
                  
                  *=$9000
                  ;Title music
                  !bin "c64/titlemusic.prg",,2
                  
                  
                  