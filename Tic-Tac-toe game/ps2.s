.section .data
.equ PIXEL_BUFFER_ADDR, 0xc8000000
.equ CHAR_BUFFER_ADDR, 0xc9000000
.equ PS2_INPUT_MEMORY, 0xff200100


.section .text
.global _start
_start:
        bl      input_loop
end:
        b       end


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
