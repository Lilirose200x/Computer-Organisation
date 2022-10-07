.section .data

.equ PIXEL_BUFFER_ADDR, 0xc8000000
.equ CHAR_BUFFER_ADDR, 0xc9000000
.equ PS2_INPUT_MEMORY, 0xff200100
.equ GRID_COLOR, 0b0000000000011111
.equ PLAYER1_COLOR, 0b00000011111100000
.equ PLAYER2_COLOR, 0b1111100000000000
.equ PLAYER1_MARK, 1
.equ PLAYER2_MARK, 2

//Game marks 3x3
g_aMarks: .word 0, 0, 0, 0, 0, 0, 0, 0, 0

//Current player mark (1:player1, 2:player2)
//use one-hot encoding when to keep track of the players¡¯ marks
g_nPlayerMark: .word 1

//Current Player count
g_nPlayerCount: .word 0

//game status (0:init, 1:play, 2:win, 3:fin)
g_gameStatus: .word 0

//Is need repaint
g_isRepaint: .word 1

//Is Break Scan code
g_isBreakSCode: .word 0

//const strings
g_szInitStr: .ascii "Press Num-0 start"
	.byte 0
g_szPlayer1Win: .ascii "Player-1 Wins"
	.byte 0
g_szPlayer2Win: .ascii "Player-2 Wins"
	.byte 0
g_szFinalStr: .ascii "Nobody Wins"
	.byte 0



.section .text

.colors:
        .word   2911
        .word   65535
        .word   45248


.global _start
_start:
        #ldr r3, .colors+8  //Only .text can use this
	bl init_env
	
endless_loop:
	ldr r1, =g_isRepaint
	ldr r0, [r1]
	cmp r0, #0
	beq ln_repaint_end

ln_repaint_begin:
	mov r0, #0
	str r0, [r1]
	bl VGA_clear_charbuff_ASM
	bl VGA_clear_pixelbuff_ASM
        bl draw_grid_and_status
	bl draw_marks
ln_repaint_end:

ln_check_input_begin:
	mov r0, #0
	stmfd sp!, {r0}
	mov r0, sp
	bl read_PS2_data_ASM
	pop {r1}
	cmp r0, #0
	beq ln_check_input_end

	ldr r0, =g_isBreakSCode
	ldr r0, [r0]
	cmp r0, #0
	beq ln_check_input_pressing

ln_check_input_has_released:
	push {r1}
	ldr r0, =g_isBreakSCode
	mov r1, #0
	str r1, [r0]
	pop {r0}
	bl on_keyboard_released
	b ln_check_input_begin

ln_check_input_pressing:
	cmp r1, #0xF0
	beq ln_check_input_do_released
	b ln_check_input_begin

ln_check_input_do_released:
	ldr r0, =g_isBreakSCode
	mov r1, #1
	str r1, [r0]
	b ln_check_input_begin

ln_check_input_end:

	b endless_loop


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ TODO: copy VGA driver here.

//void VGA_draw_point_ASM(int x, int y, short c);
//R0=X, R1=Y, R2=COLOR
VGA_draw_point_ASM:
	push {R0-R3}
	MOV R3, #PIXEL_BUFFER_ADDR
	LSL R0,R0,#1
	LSL R1,R1,#10
	ADD R3,R3,R0
	ADD R3,R3,R1
	STRH R2, [R3]
	POP {R0-R3}
	BX LR
	

//void VGA_clear_pixelbuff_ASM();
//pixel buffer size is 320x240
VGA_clear_pixelbuff_ASM:
	push {r0-r2}
	LDR R0,=319
	LDR R1,=239	
ln_X_Axis:
	CMP R0, #0
	BLT ln_BACK	
ln_Y_Axis:	
	CMP R1, #0
	BLT ln_NEXT_X
	
	push {lr}
	mov r2, #0
	bl VGA_draw_point_ASM
	pop {lr}
	SUB R1, R1, #1
	B ln_Y_Axis	
ln_NEXT_X:
	LDR R1,=239
	SUB R0,R0,#1
	B ln_X_Axis	
ln_BACK:
	pop {r0-r2}
	bx lr	
	

//void VGA_write_char_ASM(int x, int y, char c);
//r0=x, r1=y, r2=ascii
VGA_write_char_ASM:
	push {r0-r3}
	
	MOV R3, #CHAR_BUFFER_ADDR
	
	CMP R0, #0
	BLT ln_BACK_CHAR
	CMP R0, #79
	BGT ln_BACK_CHAR
	CMP R1, #0
	BLT ln_BACK_CHAR
	CMP R1, #59
	BGT ln_BACK_CHAR
	
	lsl r1, r1, #7
	add r3, r3, r0
	add r3, r3, r1
	strb R2, [R3]	//R2 IS ASCII
	
ln_BACK_CHAR:	
	pop {r0-r3}	
	bx lr


//void VGA_write_string_ASM(int x, int y, const char *str);
//r0=x, r1=y, r2=str
VGA_write_string_ASM:
	push {r4-r6, lr}
	mov r4, r0
	mov r5, r1
	mov r6, r2

ln_VGA_write_string_ASM_begin:
	ldrb r0, [r6]
	cmp r0, #0
	beq ln_VGA_write_string_ASM_end

	mov r2, r0
	mov r0, r4
	mov r1, r5
	bl VGA_write_char_ASM

ln_VGA_write_string_ASM_next:
	add r4, r4, #1
	add r6, r6, #1
	b ln_VGA_write_string_ASM_begin

ln_VGA_write_string_ASM_end:
	pop {r4-r6, pc}


//void VGA_clear_charbuff_ASM();
//character buffer size is 80x60
VGA_clear_charbuff_ASM:
	PUSH {R0-R2}
	LDR R0, =79
	LDR R1, =59
ln_x_start:
	CMP R0, #0
	BLT ln_BACK_CLEAR
	
ln_y_start:	
	CMP R1, #0
	BLT ln_x_next
	
	PUSH {LR}
	MOV R2,#0
	BL VGA_write_char_ASM
	POP {LR}
	SUB R1, R1, #1
	B ln_y_start
	
ln_x_next:
	SUB R0,R0, #1
	LDR R1, =59
	B ln_x_start

ln_BACK_CLEAR:
	POP {R0-R2}
	BX LR


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ TODO: insert PS/2 driver here.


//int read_PS2_data_ASM(char *data);
//input R0 the address 
//output r0 (bool) =1 or 0
read_PS2_data_ASM:
	push {r1-r5}
	ldr r4, =PS2_INPUT_MEMORY
	//automatically present the next code
	ldr r1, [r4]
	mov r5, r1
	//RVALID = ((*(volatile int *)0xff200100) >> 15) & 0x1
	mov r2, #1
	lsr r1, r1, #15
	AND R3, R1, R2
	CMP R3, R2
	BEQ ln_ret_TRUE
	MOV R0, #0
	B ln_ret_FALSE
ln_ret_TRUE:
	mov r1, r5
	STRB R1, [R0]
	MOV R0, #1
ln_ret_FALSE:
	POP {R1-R5}
	BX LR


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@


write_hex_digit:
        push    {r4, lr}
        cmp     r2, #9
        addhi   r2, r2, #55
        addls   r2, r2, #48
        and     r2, r2, #255
        bl      VGA_write_char_ASM
        pop     {r4, pc}


write_byte:
        push    {r4, r5, r6, lr}
        mov     r5, r0
        mov     r6, r1
        mov     r4, r2
        lsr     r2, r2, #4
        bl      write_hex_digit
        and     r2, r4, #15
        mov     r1, r6
        add     r0, r5, #1
        bl      write_hex_digit
        pop     {r4, r5, r6, pc}


write_byte_ex:
        push    {r3, r4, lr}
        ldr     r4, =0xfff0
        and     r3, r3, #0xff
        str     r3, [r4]
        pop     {r3, r4, pc}


input_loop:
        push    {r4, r5, lr}
        sub     sp, sp, #12
        bl      VGA_clear_pixelbuff_ASM
        bl      VGA_clear_charbuff_ASM
        mov     r4, #0  //r4=pos_y
        mov     r5, r4  //r5=pos_x
        b       .input_loop_L9
.input_loop_L13:
        ldrb    r2, [sp, #7]
        mov     r1, r4
        mov     r0, r5
        bl      write_byte
        add     r5, r5, #3
        cmp     r5, #79
        addgt   r4, r4, #1
        movgt   r5, #0
.input_loop_L8:
        cmp     r4, #59
        bgt     .input_loop_L12
.input_loop_L9:
        add     r0, sp, #7
        bl      read_PS2_data_ASM
        cmp     r0, #0
        beq     .input_loop_L8
        b       .input_loop_L13
.input_loop_L12:
        add     sp, sp, #12
        pop     {r4, r5, pc}


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ TODO: copy VGA driver here.


//void draw_rectangle(int x, int y, int width, int height, int c);
draw_rectangle:
        push    {r4, r5, r6, r7, r8, r9, r10, lr}
        ldr     r7, [sp, #32]
        add     r9, r1, r3
        cmp     r1, r9
        popge   {r4, r5, r6, r7, r8, r9, r10, pc}
        mov     r8, r0
        mov     r5, r1
        add     r6, r0, r2
        b       .line_L2
.line_L5:
        add     r5, r5, #1
        cmp     r5, r9
        popeq   {r4, r5, r6, r7, r8, r9, r10, pc}
.line_L2:
        cmp     r8, r6
        movlt   r4, r8
        bge     .line_L5
.line_L4:
        mov     r2, r7
        mov     r1, r5
        mov     r0, r4
        bl      VGA_draw_point_ASM
        add     r4, r4, #1
        cmp     r4, r6
        bne     .line_L4
        b       .line_L5


//COLORREF = make_rgb(Red, Green, Blue)
make_rgb:
	lsl r0, r0, #11
	add r0, r1, lsl #5
	add r0, r2
	bx lr


//The grid must be a square of size 207-by-207 pixels
//so, the left-top point is likely (56, 16), and size is 69x69 
VGA_fill_ASM:
draw_grid_ASM:
Player_turn_ASM:
result_ASM:
draw_grid_and_status:
	push {lr}

	mov r0, #GRID_COLOR
	stmfd sp!, {r0}

	//row1
	mov r0, #56 + 1
	mov r1, #16 + 1
	mov r2, #69 - 2
	mov r3, #69 - 2
	bl draw_rectangle

	mov r0, #125 + 1
	mov r1, #16 + 1
	mov r2, #69 - 2
	mov r3, #69 - 2
	bl draw_rectangle

	mov r0, #194 + 1
	mov r1, #16 + 1
	mov r2, #69 - 2
	mov r3, #69 - 2
	bl draw_rectangle

	//row2
	mov r0, #56 + 1
	mov r1, #85 + 1
	mov r2, #69 - 2
	mov r3, #69 - 2
	bl draw_rectangle

	mov r0, #125 + 1
	mov r1, #85 + 1
	mov r2, #69 - 2
	mov r3, #69 - 2
	bl draw_rectangle

	mov r0, #194 + 1
	mov r1, #85 + 1
	mov r2, #69 - 2
	mov r3, #69 - 2
	bl draw_rectangle

	//row3
	mov r0, #56 + 1
	mov r1, #154 + 1
	mov r2, #69 - 2
	mov r3, #69 - 2
	bl draw_rectangle

	mov r0, #125 + 1
	mov r1, #154 + 1
	mov r2, #69 - 2
	mov r3, #69 - 2
	bl draw_rectangle

	mov r0, #194 + 1
	mov r1, #154 + 1
	mov r2, #69 - 2
	mov r3, #69 - 2
	bl draw_rectangle

	add sp, sp, #4

ln_draw_play_info_begin:
	ldr r1, =g_gameStatus
	ldr r0, [r1]
	cmp r0, #0
	beq ln_draw_play_info_init
	cmp r0, #2
	beq ln_draw_play_info_win
	cmp r0, #3
	beq ln_draw_play_info_fin

	ldr r1, =g_nPlayerMark
	ldr r0, [r1]
	cmp r0, #PLAYER1_MARK
	beq ln_draw_play_info_player1
	cmp r0, #PLAYER2_MARK
	beq ln_draw_play_info_player2
	b ln_draw_play_info_end

ln_draw_play_info_init:
	mov r0, #32
	mov r1, #0
	ldr r2, =g_szInitStr
	bl VGA_write_string_ASM
	b ln_draw_play_info_end

ln_draw_play_info_win:
	ldr r1, =g_nPlayerMark
	ldr r0, [r1]
	cmp r0, #PLAYER2_MARK
	ldreq r2, =g_szPlayer1Win
	ldrne r2, =g_szPlayer2Win
	mov r0, #33
	mov r1, #0
	bl VGA_write_string_ASM
	b ln_draw_play_info_end

ln_draw_play_info_fin:
	mov r0, #32
	mov r1, #0
	ldr r2, =g_szFinalStr
	bl VGA_write_string_ASM
	b ln_draw_play_info_end

ln_draw_play_info_player1:
	mov r0, #39
	mov r1, #0
	mov r2, #0x31
	bl VGA_write_char_ASM
	b ln_draw_play_info_end

ln_draw_play_info_player2:
	mov r0, #39
	mov r1, #0
	mov r2, #0x32
	bl VGA_write_char_ASM
	b ln_draw_play_info_end

ln_draw_play_info_end:
	pop {pc}


//The grid must be a square of size 207-by-207 pixels
//so, the left-top point is likely (56, 16), and size is 69x69 
draw_marks:
	push {r4-r7, lr}

	mov r4, #0   //i
	mov r7, #16  //y

ln_draw_marks_loop1_begin:
	cmp r4, #3
	bge ln_draw_marks_loop1_end

	mov r5, #0   //j
	mov r6, #56  //x
ln_draw_marks_loop2_begin:
	cmp r5, #3
	bge ln_draw_marks_loop2_end

	add r0, r4, r4
	add r0, r0, r4
	add r0, r0, r5
	ldr r1, =g_aMarks
	add r1, r1, r0, lsl #2
	ldr r0, [r1]

	mov r1, r6
	mov r2, r7
	cmp r0, #PLAYER1_MARK
	beq ln_draw_player1
	cmp r0, #PLAYER2_MARK
	beq ln_draw_player2

ln_draw_empty:
	bl draw_empty
	b ln_draw_marks_loop2_next

ln_draw_player1:
	bl draw_player1
	b ln_draw_marks_loop2_next
	
ln_draw_player2:
	bl draw_player2
	b ln_draw_marks_loop2_next

ln_draw_marks_loop2_next:
	add r5, r5, #1
	add r6, r6, #69
	b ln_draw_marks_loop2_begin

ln_draw_marks_loop2_end:
ln_draw_marks_loop1_next:
	add r4, r4, #1
	add r7, r7, #69
	b ln_draw_marks_loop1_begin

ln_draw_marks_loop1_end:
	pop {r4-r7, pc}


//draw_empty(mark, x, y), size = 69x69
draw_empty:
	bx lr


//draw_player1(mark=1, x, y), size = 69x69
draw_plus_ASM:
draw_player1:
	push {r4-r5, lr}
	mov r4, r1
	mov r5, r2

	mov r0, #PLAYER1_COLOR
	stmfd sp!, {r0}

	add r0, r4, #30
	add r1, r5, #10
	mov r2, #9
	mov r3, #49
	bl draw_rectangle

	add r0, r4, #10
	add r1, r5, #30
	mov r2, #49
	mov r3, #9
	bl draw_rectangle

	add sp, sp, #4
	pop {r4-r5, pc}


//draw_player2(mark=2, x, y), size = 69x69
draw_square_ASM:
draw_player2:
	push {r4-r5, lr}
	mov r4, r1
	mov r5, r2

	mov r0, #PLAYER2_COLOR
	stmfd sp!, {r0}

	add r0, r4, #10
	add r1, r5, #10
	mov r2, #49
	mov r3, #49
	bl draw_rectangle

	mov r0, #GRID_COLOR
	str r0, [sp]

	add r0, r4, #10 + 9
	add r1, r5, #10 + 9
	mov r2, #49 - 18
	mov r3, #49 - 18
	bl draw_rectangle
	
	add sp, sp, #4
	pop {r4-r5, pc}


//on_keyboard_released(key)
on_keyboard_released:
	push {r4-r5, lr}
	mov r4, r0
	ldr r5, =g_gameStatus

	cmp r4, #0x45
	beq ln_on_keyboard_released_num0
	ldr r0, [r5]
	cmp r0, #1
	bne ln_on_keyboard_released_ret
	cmp r4, #0x3D
	beq ln_on_keyboard_released_num1
	cmp r4, #0x3E
	beq ln_on_keyboard_released_num2
	cmp r4, #0x46
	beq ln_on_keyboard_released_num3
	cmp r4, #0x25
	beq ln_on_keyboard_released_num4
	cmp r4, #0x2E
	beq ln_on_keyboard_released_num5
	cmp r4, #0x36
	beq ln_on_keyboard_released_num6
	cmp r4, #0x16
	beq ln_on_keyboard_released_num7
	cmp r4, #0x1E
	beq ln_on_keyboard_released_num8
	cmp r4, #0x26
	beq ln_on_keyboard_released_num9
	b ln_on_keyboard_released_ret

ln_on_keyboard_released_num0:
	mov r0, #1
	str r0, [r5]
	ldr r5, =g_isRepaint
	str r0, [r5]
	bl init_env
	b ln_on_keyboard_released_ret

ln_on_keyboard_released_num1:
	ldr r0, =g_aMarks
	add r0, r0, #24
	bl do_put_mark
	b ln_on_keyboard_released_ret

ln_on_keyboard_released_num2:
	ldr r0, =g_aMarks
	add r0, r0, #28
	bl do_put_mark
	b ln_on_keyboard_released_ret

ln_on_keyboard_released_num3:
	ldr r0, =g_aMarks
	add r0, r0, #32
	bl do_put_mark
	b ln_on_keyboard_released_ret

ln_on_keyboard_released_num4:
	ldr r0, =g_aMarks
	add r0, r0, #12
	bl do_put_mark
	b ln_on_keyboard_released_ret

ln_on_keyboard_released_num5:
	ldr r0, =g_aMarks
	add r0, r0, #16
	bl do_put_mark
	b ln_on_keyboard_released_ret

ln_on_keyboard_released_num6:
	ldr r0, =g_aMarks
	add r0, r0, #20
	bl do_put_mark
	b ln_on_keyboard_released_ret

ln_on_keyboard_released_num7:
	ldr r0, =g_aMarks
	add r0, r0, #0
	bl do_put_mark
	b ln_on_keyboard_released_ret

ln_on_keyboard_released_num8:
	ldr r0, =g_aMarks
	add r0, r0, #4
	bl do_put_mark
	b ln_on_keyboard_released_ret

ln_on_keyboard_released_num9:
	ldr r0, =g_aMarks
	add r0, r0, #8
	bl do_put_mark
	b ln_on_keyboard_released_ret

ln_on_keyboard_released_ret:
	pop {r4-r5, pc}


//do_put_mark(unsigned int *addr)
do_put_mark:
	push {r4, lr}
	mov r4, r0

	ldr r0, [r4]
	cmp r0, #PLAYER1_MARK
	beq ln_do_put_mark_ret
	cmp r0, #PLAYER2_MARK
	beq ln_do_put_mark_ret

	ldr r2, =g_nPlayerCount
	ldr r0, [r2]
	add r0, r0, #1
	str r0, [r2]

	ldr r2, =g_nPlayerMark
	ldr r1, [r2]
	str r1, [r4]

ln_check_player_win_begin:
	mov r0, r1
	bl check_player_win
	cmp r0, #0
	beq ln_no_player_win
ln_this_player_win:
	ldr r0, =g_gameStatus
	mov r1, #2  //win
	str r1, [r0]
	b ln_check_player_win_end
ln_no_player_win:
	ldr r2, =g_nPlayerCount
	ldr r0, [r2]
	cmp r0, #9
	blt ln_check_player_win_end
ln_check_player_final:
	ldr r0, =g_gameStatus
	mov r1, #3  //fin
	str r1, [r0]
ln_check_player_win_end:

	ldr r2, =g_nPlayerMark
	ldr r1, [r2]
	mov r0, #3  //(PLAYER1_MARK + PLAYER2_MARK)
	sub r1, r0, r1
	str r1, [r2]

	ldr r2, =g_isRepaint
	mov r0, #1
	str r0, [r2]

ln_do_put_mark_ret:
	pop {r4, pc}


//isWin = check_player_win(mark)
check_player_win:
	push {r4-r5, lr}
	mov r4, r0
	ldr r5, =g_aMarks

ln_check_player_win_check_row1:
	ldr r0, [r5]
	cmp r0, r4
	bne ln_check_player_win_check_row2
	ldr r0, [r5, #4]
	cmp r0, r4
	bne ln_check_player_win_check_row2
	ldr r0, [r5, #8]
	cmp r0, r4
	bne ln_check_player_win_check_row2
	b ln_check_player_win_ret1

ln_check_player_win_check_row2:
	ldr r0, [r5, #12]
	cmp r0, r4
	bne ln_check_player_win_check_row3
	ldr r0, [r5, #16]
	cmp r0, r4
	bne ln_check_player_win_check_row3
	ldr r0, [r5, #20]
	cmp r0, r4
	bne ln_check_player_win_check_row3
	b ln_check_player_win_ret1

ln_check_player_win_check_row3:
	ldr r0, [r5, #24]
	cmp r0, r4
	bne ln_check_player_win_check_col1
	ldr r0, [r5, #28]
	cmp r0, r4
	bne ln_check_player_win_check_col1
	ldr r0, [r5, #32]
	cmp r0, r4
	bne ln_check_player_win_check_col1
	b ln_check_player_win_ret1

ln_check_player_win_check_col1:
	ldr r0, [r5]
	cmp r0, r4
	bne ln_check_player_win_check_col2
	ldr r0, [r5, #12]
	cmp r0, r4
	bne ln_check_player_win_check_col2
	ldr r0, [r5, #24]
	cmp r0, r4
	bne ln_check_player_win_check_col2
	b ln_check_player_win_ret1

ln_check_player_win_check_col2:
	ldr r0, [r5, #4]
	cmp r0, r4
	bne ln_check_player_win_check_col3
	ldr r0, [r5, #16]
	cmp r0, r4
	bne ln_check_player_win_check_col3
	ldr r0, [r5, #28]
	cmp r0, r4
	bne ln_check_player_win_check_col3
	b ln_check_player_win_ret1

ln_check_player_win_check_col3:
	ldr r0, [r5, #8]
	cmp r0, r4
	bne ln_check_player_win_check_x1
	ldr r0, [r5, #20]
	cmp r0, r4
	bne ln_check_player_win_check_x1
	ldr r0, [r5, #32]
	cmp r0, r4
	bne ln_check_player_win_check_x1
	b ln_check_player_win_ret1

ln_check_player_win_check_x1:
	ldr r0, [r5]
	cmp r0, r4
	bne ln_check_player_win_check_x2
	ldr r0, [r5, #16]
	cmp r0, r4
	bne ln_check_player_win_check_x2
	ldr r0, [r5, #32]
	cmp r0, r4
	bne ln_check_player_win_check_x2
	b ln_check_player_win_ret1

ln_check_player_win_check_x2:
	ldr r0, [r5, #8]
	cmp r0, r4
	bne ln_check_player_win_ret0
	ldr r0, [r5, #16]
	cmp r0, r4
	bne ln_check_player_win_ret0
	ldr r0, [r5, #24]
	cmp r0, r4
	bne ln_check_player_win_ret0
	b ln_check_player_win_ret1

ln_check_player_win_ret0:
	mov r0, #0
	pop {r4-r5, pc}

ln_check_player_win_ret1:
	mov r0, #1
	pop {r4-r5, pc}


//void init_env()
init_env:
	ldr r1, =g_nPlayerMark
	mov r0, #1
	str r0, [r1]

	ldr r1, =g_isBreakSCode
	mov r0, #0
	str r0, [r1]

	ldr r1, =g_nPlayerCount
	mov r0, #0
	str r0, [r1]

	ldr r1, =g_aMarks
	mov r0, #0
	str r0, [r1], #4
	str r0, [r1], #4
	str r0, [r1], #4
	str r0, [r1], #4
	str r0, [r1], #4
	str r0, [r1], #4
	str r0, [r1], #4
	str r0, [r1], #4
	str r0, [r1]

	bx lr
