.bss
    elements:   .skip 72          # 9 * sizeof(char) 

.data
    cell:       .quad 0

.text
    grid:       .asciz " %c | %c | %c \n-----------\n %c | %c | %c \n-----------\n %c | %c | %c \n"
    numeration: .asciz "Grid numeration:\n 1 | 2 | 3 \n-----------\n 4 | 5 | 6 \n-----------\n 7 | 8 | 9 \n\n"
    clear:      .asciz "\033[2J\033[1;1H"

    mltp_turn:  .asciz "Player %c's turn. Enter cell number (1-9): "
    mltp_won:   .asciz "Player %c won!\n"
    sngl_turn:  .asciz "Your turn. Enter cell number (1-9): "
    sngl_won:   .asciz "Congratulations! You won!\n"
    sngl_lost:  .asciz "You lost. Loser lol!\n"
    draw_text:  .asciz "It's a draw!\n"
    bot_turn:   .asciz "Bot's turn...\n"

    welcome_msg:.asciz "------------------------------------------\n| WELCOME TO TIC TAC TOE in Assembly x64 |\n------------------------------------------"
    options:    .asciz "\n1- Play turn based multiplayer\n2- Play against bot\n0- Exit the game\n"
    exiting:    .asciz "Exiting the game...\n"
    inv_choice: .asciz "Invalid choice. Please enter 1 or 2 to start the game or 0 to exit.\n"
    input_str:  .asciz "%ld"
    end_game:   .asciz "\nPress any number to return to main menu\n"
    choice:     .asciz "Please make a choice: "

.global main
main:
    pushq   %rbp
    movq    %rsp, %rbp

    subq    $16, %rsp
    movq    $1, -16(%rbp)                       # -16(%rbp) = replay = false

main_loop:
    leaq    clear(%rip), %rdi
    call    printf

    leaq    welcome_msg(%rip), %rdi
    call    printf

    leaq    options(%rip), %rdi
    call    printf

    leaq    choice(%rip), %rdi
    call    printf
    
    leaq    -8(%rbp), %rsi                      # -8(%rbp) = user_choice
    leaq    input_str(%rip), %rdi
    call    scanf

    cmpq    $1, -8(%rbp)
    je      multi_mode
    cmpq    $2, -8(%rbp)
    je      single_mode
    cmpq    $0, -8(%rbp)
    je      exit
    jmp     invalid

invalid:
    leaq    inv_choice(%rip), %rdi
    call    printf
    jmp     main_loop

exit:
    leaq    exiting(%rip), %rdi
    call    printf

    movq    %rbp, %rsp
    popq    %rbp
    
    movq    $0, %rax
    ret

multi_mode:
    call    clear_board
    call    multiplayer
    jmp     main_loop

single_mode:
    call    clear_board
    call    singleplayer
    jmp     main_loop

clear_board:
    movq    $0, %rcx
    leaq    elements(%rip), %rax

clear_loop:
    cmpq    $9, %rcx
    jge     clear_end

    movb    $' ', (%rax, %rcx, 8)
    incq    %rcx
    jmp     clear_loop

clear_end:
    ret

# variables: %12 = current_player
multiplayer:
    pushq   %rbp
    movq    %rsp, %rbp

    movq    $'X', %r12

multiplayer_main_loop:
    call    display_grid

    leaq    mltp_turn(%rip), %rdi
    movq    %r12, %rsi
    call    printf

    leaq    cell(%rip), %rsi
    leaq    input_str(%rip), %rdi
    call    scanf
    decq    cell(%rip)

    cmpq    $0, cell(%rip)                    # if (cell < 0 || cell >= 9 || elements[cell] != ' ')
    jl      multiplayer_main_loop       
    cmpq    $9, cell(%rip)
    jge     multiplayer_main_loop
    leaq    elements(%rip), %rsi
    movq    cell(%rip), %rdi
    cmpq    $' ', (%rsi, %rdi, 8)
    jne     multiplayer_main_loop

    movq    %r12, (%rsi, %rdi, 8)             # elements[cell] = current_player
    
    movq    %r12, %rdi
    call    check_win
    cmpq    $1, %rax
    je      multiplayer_won

    call    check_draw
    cmpq    $1, %rax
    je      draw

    cmpq    $'X', %r12
    je      update_x

    movq    $'X', %r12
    jmp     multiplayer_main_loop

update_x:
    movq    $'O', %r12
    jmp     multiplayer_main_loop

# variables: %r12 = human_player, $r13 = bot_player
singleplayer:
    pushq   %rbp
    movq    %rsp, %rbp

    movq    $'X', %r12
    movq    $'O', %r13

singleplayer_main_loop:
    call    display_grid

    leaq    sngl_turn(%rip), %rdi
    call    printf

    leaq    cell(%rip), %rsi
    leaq    input_str(%rip), %rdi
    call    scanf
    decq    cell(%rip)

    cmpq    $0, cell(%rip)                    # if (cell < 0 || cell >= 9 || elements[cell] != ' ')
    jl      singleplayer_main_loop       
    cmpq    $9, cell(%rip)
    jge     singleplayer_main_loop
    leaq    elements(%rip), %rsi
    movq    cell(%rip), %rdi
    cmpq    $' ', (%rsi, %rdi, 8)
    jne     singleplayer_main_loop

    movq    %r12, (%rsi, %rdi, 8)             # elements[cell] = human_player

    movq    %r12, %rdi
    call    check_win
    cmpq    $1, %rax
    je      player_won

    call    check_draw
    cmpq    $1, %rax
    je      draw

    call    display_grid
    leaq    bot_turn(%rip), %rdi
    call    printf

    movq    $-1, %rcx
    leaq    elements(%rip), %rax

bot_win_check_ai:
    incq    %rcx
    cmpq    $9, %rcx
    jge     bot_placement_ai

    cmpq    $' ', (%rax, %rcx, 8)
    jne     bot_win_check_ai

    leaq    elements(%rip), %rsi
    movq    %r13, (%rsi, %rcx, 8)               # elements[i] = bot_player

    pushq   %rcx                                # save loop counter
    pushq   %rcx

    movq    %r13, %rdi
    call    check_win

    popq    %rcx
    popq    %rcx

    cmpq    $1, %rax
    jne     undo

    movq    %rcx, cell(%rip)                    # cell = i
    jmp     bot_check

undo:
    leaq    elements(%rip), %rax
    movq    $' ', (%rax, %rcx, 8)
    jmp     bot_win_check_ai

bot_placement_ai:
    leaq    elements(%rip), %rax
    cmpq    $' ', 32(%rax)
    je      place_middle_cell

    movq    $0, %rdi
    call    time

    movq    %rax, %rdi
    call    srand                     # srand(time(NULL))

    movq    $0, %rbx

bot_placement_loop:
    call    rand

    movq    $9, %rcx
    idivq   %rcx 

    leaq    elements(%rip), %rax
    cmpq    $' ', (%rax, %rdx, 8)
    jne     bot_placement_loop

    movq    %rdx, cell(%rip)
    jmp     bot_check

place_middle_cell:
    movq    $4, cell(%rip)

bot_check:
    leaq    elements(%rip), %rsi
    movq    cell(%rip), %rdi
    movq    %r13, (%rsi, %rdi, 8)             # elements[cell] = bot_player

    movq    %r13, %rdi
    call    check_win
    cmpq    $1, %rax
    je      bot_won

    call    check_draw
    cmpq    $1, %rax
    je      draw

    jmp     singleplayer_main_loop

multiplayer_won:
    call    display_grid

    leaq    mltp_won(%rip), %rdi
    movq    %r12, %rsi
    call    printf

    jmp     won

player_won:
    call    display_grid

    leaq    sngl_won(%rip), %rdi
    call    printf

    jmp     won

bot_won:
    call    display_grid

    leaq    sngl_lost(%rip), %rdi
    call    printf

won:
    leaq    end_game(%rip), %rdi
    call    printf

    leaq    cell(%rip), %rsi
    leaq    input_str(%rip), %rdi
    call    scanf

    movq    %rbp, %rsp
    popq    %rbp

    ret

draw:
    call    display_grid

    leaq    draw_text(%rip), %rdi
    movq    %r12, %rsi
    call    printf

    leaq    end_game(%rip), %rdi
    call    printf

    leaq    cell(%rip), %rsi
    leaq    input_str(%rip), %rdi

    call    scanf

    movq    %rbp, %rsp
    popq    %rbp

    ret

display_grid:
    pushq   %rbp
    movq    %rsp, %rbp

    leaq    clear(%rip), %rdi
    call    printf
    leaq    numeration(%rip), %rdi
    call    printf

    leaq    grid(%rip), %rdi
    movq    elements(%rip), %rsi
    movq    elements+8(%rip), %rdx
    movq    elements+16(%rip), %rcx
    movq    elements+24(%rip), %r8
    movq    elements+32(%rip), %r9
    pushq   elements+64(%rip)
    pushq   elements+56(%rip)
    pushq   elements+48(%rip)
    pushq   elements+40(%rip)
    call    printf

    movq    %rbp, %rsp
    popq    %rbp

    movq    $0, %rax
    ret

# arguments: %rdi = player
check_win:
    movq    $-1, %rcx
    leaq    elements(%rip), %rax

check_win_first_loop:
    incq    %rcx
    cmpq    $3, %rcx
    jge     check_win_second

    movq    %rcx, %rdx
    imulq   $3, %rdx                    # %rdx = i * 3

    cmpq    %rdi, (%rax, %rdx, 8)       # elements[i * 3] == player
    jne     check_win_first_loop
    incq    %rdx 
    cmpq    %rdi, (%rax, %rdx, 8)       # elements[i * 3 + 1] == player
    jne     check_win_first_loop
    incq    %rdx 
    cmpq    %rdi, (%rax, %rdx, 8)       # elements[i * 3 + 2] == player
    jne     check_win_first_loop     
    
    jmp     return_true

check_win_second:
    movq    $-1, %rcx

check_win_second_loop:
    incq    %rcx
    cmpq    $3, %rcx
    jge     check_diag_first

    movq    %rcx, %rdx

    cmpq    %rdi, (%rax, %rdx, 8)       # elements[i] == player
    jne     check_win_second_loop
    addq    $3, %rdx
    cmpq    %rdi, (%rax, %rdx, 8)       # elements[i + 3] == player
    jne     check_win_second_loop
    addq    $3, %rdx
    cmpq    %rdi, (%rax, %rdx, 8)       # elements[i + 6] == player
    jne     check_win_second_loop

    jmp     return_true

check_diag_first:
    cmpq    %rdi, (%rax)
    jne     check_diag_second
    cmpq    %rdi, 32(%rax)
    jne     check_diag_second
    cmpq    %rdi, 64(%rax)
    jne     check_diag_second

    jmp     return_true

check_diag_second:
    cmpq    %rdi, 16(%rax)
    jne     return_false
    cmpq    %rdi, 32(%rax)
    jne     return_false
    cmpq    %rdi, 48(%rax)
    jne     return_false

    jmp     return_true

check_draw:
    movq    $0, %rcx
    leaq    elements(%rip), %rax

check_draw_loop:
    cmpq    $9, %rcx
    jge     return_true

    cmpq    $' ', (%rax, %rcx, 8)
    je      return_false

    incq    %rcx
    jmp     check_draw_loop

return_true:
    movq    $1, %rax
    ret

return_false:
    movq    $0, %rax
    ret
