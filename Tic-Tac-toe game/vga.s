.section .data
.equ PIXEL_BUFFER_ADDR, 0xc8000000
.equ CHAR_BUFFER_ADDR, 0xc9000000


.section .text

.global _start
_start:
        bl      draw_test_screen
end:
        b       end

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ TODO: Insert VGA driver functions here.


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

draw_test_screen:
        push    {r4, r5, r6, r7, r8, r9, r10, lr}
        bl      VGA_clear_pixelbuff_ASM
        bl      VGA_clear_charbuff_ASM
        mov     r6, #0
        ldr     r10, .draw_test_screen_L8
        ldr     r9, .draw_test_screen_L8+4
        ldr     r8, .draw_test_screen_L8+8
        b       .draw_test_screen_L2
.draw_test_screen_L7:
        add     r6, r6, #1
        cmp     r6, #320
        beq     .draw_test_screen_L4
.draw_test_screen_L2:
        smull   r3, r7, r10, r6
        asr     r3, r6, #31
        rsb     r7, r3, r7, asr #2
        lsl     r7, r7, #5
        lsl     r5, r6, #5
        mov     r4, #0
.draw_test_screen_L3:
        smull   r3, r2, r9, r5
        add     r3, r2, r5
        asr     r2, r5, #31
        rsb     r2, r2, r3, asr #9
        orr     r2, r7, r2, lsl #11
        lsl     r3, r4, #5
        smull   r0, r1, r8, r3
        add     r1, r1, r3
        asr     r3, r3, #31
        rsb     r3, r3, r1, asr #7
        orr     r2, r2, r3
        mov     r1, r4
        mov     r0, r6
        bl      VGA_draw_point_ASM
        add     r4, r4, #1
        add     r5, r5, #32
        cmp     r4, #240
        bne     .draw_test_screen_L3
        b       .draw_test_screen_L7
.draw_test_screen_L4:
        mov     r2, #72
        mov     r1, #5
        mov     r0, #20
        bl      VGA_write_char_ASM
        mov     r2, #101
        mov     r1, #5
        mov     r0, #21
        bl      VGA_write_char_ASM
        mov     r2, #108
        mov     r1, #5
        mov     r0, #22
        bl      VGA_write_char_ASM
        mov     r2, #108
        mov     r1, #5
        mov     r0, #23
        bl      VGA_write_char_ASM
        mov     r2, #111
        mov     r1, #5
        mov     r0, #24
        bl      VGA_write_char_ASM
        mov     r2, #32
        mov     r1, #5
        mov     r0, #25
        bl      VGA_write_char_ASM
        mov     r2, #87
        mov     r1, #5
        mov     r0, #26
        bl      VGA_write_char_ASM
        mov     r2, #111
        mov     r1, #5
        mov     r0, #27
        bl      VGA_write_char_ASM
        mov     r2, #114
        mov     r1, #5
        mov     r0, #28
        bl      VGA_write_char_ASM
        mov     r2, #108
        mov     r1, #5
        mov     r0, #29
        bl      VGA_write_char_ASM
        mov     r2, #100
        mov     r1, #5
        mov     r0, #30
        bl      VGA_write_char_ASM
        mov     r2, #33
        mov     r1, #5
        mov     r0, #31
        bl      VGA_write_char_ASM
        pop     {r4, r5, r6, r7, r8, r9, r10, pc}
.draw_test_screen_L8:
        .word   1717986919
        .word   -368140053
        .word   -2004318071
