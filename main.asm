section .data

    clear_screen db 27, "[2J", 27, "[H"
    clear_len equ $ - clear_screen

    title db "================================", 10
          db "       RACE 'N' SMASH           ", 10
          db "================================", 10
          db "                                ", 10
    title_len equ $ - title

    left_car db "       |          |             ", 10
             db "       |          |             ", 10
             db "       |          |             ", 10
             db "       | [CAR]    |             ", 10
             db "       |          |             ", 10
    left_len equ $ - left_car

    center_car db "       |          |             ", 10
               db "       |          |             ", 10
               db "       |          |             ", 10
               db "       |   [CAR]  |             ", 10
               db "       |          |             ", 10
    center_len equ $ - center_car

    right_car db "       |          |             ", 10
              db "       |          |             ", 10
              db "       |          |             ", 10
              db "       |      [CAR]|             ", 10
              db "       |          |             ", 10
    right_len equ $ - right_car

    controls db "================================", 10
             db " A = LEFT   D = RIGHT   Q = QUIT", 10
    controls_len equ $ - controls

section .bss

    key resb 1
    player_lane resb 1

section .text
    global _start

_start:

    ; Start player in center lane
    mov byte [player_lane], 1

game_loop:

    call draw_screen
    call read_key

    ; Check if Q was pressed
    cmp byte [key], 'q'
    je exit_game

    cmp byte [key], 'Q'
    je exit_game

    ; Check A
    cmp byte [key], 'a'
    je move_left

    cmp byte [key], 'A'
    je move_left

    ; Check D
    cmp byte [key], 'd'
    je move_right

    cmp byte [key], 'D'
    je move_right

    jmp game_loop


move_left:

    ; Already at left?
    cmp byte [player_lane], 0
    je game_loop

    dec byte [player_lane]

    jmp game_loop


move_right:

    ; Already at right?
    cmp byte [player_lane], 2
    je game_loop

    inc byte [player_lane]

    jmp game_loop


draw_screen:

    ; Clear terminal
    mov rax, 1
    mov rdi, 1
    mov rsi, clear_screen
    mov rdx, clear_len
    syscall

    ; Draw title
    mov rax, 1
    mov rdi, 1
    mov rsi, title
    mov rdx, title_len
    syscall

    ; Determine player position
    cmp byte [player_lane], 0
    je .draw_left

    cmp byte [player_lane], 1
    je .draw_center

    jmp .draw_right


.draw_left:

    mov rsi, left_car
    mov rdx, left_len
    jmp .print_car


.draw_center:

    mov rsi, center_car
    mov rdx, center_len
    jmp .print_car


.draw_right:

    mov rsi, right_car
    mov rdx, right_len


.print_car:

    mov rax, 1
    mov rdi, 1
    syscall

    ; Draw controls
    mov rax, 1
    mov rdi, 1
    mov rsi, controls
    mov rdx, controls_len
    syscall

    ret


read_key:

    ; Read one character from keyboard
    mov rax, 0
    mov rdi, 0
    mov rsi, key
    mov rdx, 1
    syscall

    ret


exit_game:

    mov rax, 60
    xor rdi, rdi
    syscall