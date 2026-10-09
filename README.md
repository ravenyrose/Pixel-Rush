# Pixel Rush

## Acknowledgement
This project is a modification of the Commodore 64 game, Race 'N Smash, made by Richard Bayliss.

Source code link: https://github.com/RichardTND/RaceNSmash

## Modifications
- Changed upper player movement limit from #$90 to #$3a
- Changed player vertical movement speed from 4 pixels to 3
- 5 Difficulty Levels (not indicated in the ui yet) input through joystick port 2:
    - Normal (approximatly 60 sec interval per level) - fire button
    - Fast (30) - up direction
    - Faster (15) - down direction
    - Fastest (10) - left direction
    - Extreme (5) - right direction
- 2-player mode (hold joystick port 1 fire button before selecting difficulty)
- Scoring based on difficulty
    - Normal (increments score by 100)
    - Fast (200)
    - Faster (300)
    - Fastest (400)
    - Extreme (500)
- 3-lives system for both 1 and 2-player mode
- Score pickups

## Potentially add
- invincibility item
- Keyboard support (I think it's possible)