.section .data

// Sider Switches Driver
// returns the state of slider switches in R0
.equ SW_MEMORY, 0xFF200040

// LEDs Driver
// writes the state of LEDs (On/Off state) in R0 to the LEDs memory location
.equ LED_MEMORY, 0xFF200000

// HEX display
.equ HEX_NUM_MASK,0x0F
.equ HEX_MEMORY0_3, 0xff200020
.equ HEX_MEMORY4_5, 0xff200030
.equ HEX0,0x00000001
.equ HEX1,0x00000002
.equ HEX2,0x00000004
.equ HEX3,0x00000008
.equ HEX4,0x00000010
.equ HEX5,0x00000020
.equ HEX_ALL, 0x3F
.equ PB0,0x00000001
.equ PB1,0x00000002
.equ PB2,0x00000004
.equ PB3,0x00000008
.equ PB_ALL, 0x0F
.equ PUSH_DATA_MEMORY, 0xFF200050
.equ PUSH_INT_MEMORY, 0xFF200058
.equ PUSH_EDGE_MEMORY, 0xFF20005C
.equ TIMER_INIT_MEMORY,0xFFFEC600
.equ TIMER_TICK_MEMORY,0xFFFEC604
.equ TIMER_CTRL_MEMORY,0xFFFEC608
.equ TIMER_STAT_MEMORY,0xFFFEC60C
.equ TIMER_FREQ,200


.section .text
.global _start


_start:
	mov r8, #0

	mov r0, #HEX_ALL
	bl HEX_clear_ASM

	bl init_1s_timer_ASM

loop_start:
	bl ARM_TIM_read_INT_ASM
	tst r0, #0x01
	beq loop_start

	bl ARM_TIM_clear_INT_ASM
	
	mov r0, r8
	bl write_LEDs_ASM

	mov r0, #HEX0
	mov r1, r8
	bl HEX_write_ASM

	add r8, r8, #1
	cmp r8, #0x10
	movge r8, #0

	bl init_1s_timer_ASM

	b loop_start

endless_loop:
	b endless_loop

// @task1_2 used
// my_start:
// 	@All r4-r15 must be save
// 	mov r12, #0
// 
// ln_init:
// 	mov r0, #HEX_ALL
// 	bl HEX_clear_ASM
// 
// 	mov r0, #PB_ALL
// 	bl enable_PB_INT_ASM
// 
// 	mov r0, #PB_ALL
// 	bl PB_clear_edgecp_ASM
// 
// ln_main:
// 	bl read_slider_switches_ASM
// 	mov r8, r0  @switch
// 	bl write_LEDs_ASM
// 
// 	bl read_PB_edgecp_ASM
// 	mov r9, r0  @edge
// 	tst r9, r9
// 	beq ln_main
// 
// 	bl read_PB_data_ASM
// 	tst r0, r9  @old status before pressed
// 	bne ln_edgecp_data_released
// 
// ln_edgecp_data_pressed:
// 	tst r8, #0x200
// 	bne ln_edgecp_data_pressed_cls
// 
// 	mov r0, r9
// 	and r1, r8, #HEX_NUM_MASK
// 	bl HEX_write_ASM
// 	bl PB_clear_edgecp_ASM
// 
// 	mov r0, #0x30
// 	bl HEX_flood_ASM
// 
// 	b ln_main
// 
// ln_edgecp_data_pressed_cls:
// 	mov r0, #HEX_ALL
// 	bl HEX_clear_ASM
// 
// 	b ln_main
// 
// ln_edgecp_data_released:
// 	mov r0, r9
// 	bl PB_clear_edgecp_ASM
// 
// 	b ln_main


init_1s_timer_ASM:
	push {lr}
	@mov r0, #0x1
	@ldr r1, =1000000
	@mul r0, r0, r1
	ldr r0, =1000000
	ldr r1, =TIMER_FREQ
	sub r1, r1, #1
	lsl r1, r1, #8
	orr r1, r1, #0x01
	bl ARM_TIM_config_ASM
	bl ARM_TIM_clear_INT_ASM
	pop {pc}


read_slider_switches_ASM:
	LDR R1, =SW_MEMORY
	LDR R0, [R1]
	BX  LR


write_LEDs_ASM:
	LDR R1, =LED_MEMORY
	STR R0, [R1]
	BX  LR


HEX_flood_ASM:
	push {r4, lr}
	ldr r4, =HEX_MEMORY0_3
	ldr r1, [r4]
	tst r0, #HEX0
	orrne r1, r1, #0x7F
	tst r0, #HEX1
	orrne r1, r1, #0x7F00
	tst r0, #HEX2
	orrne r1, r1, #0x7F0000
	tst r0, #HEX3
	orrne r1, r1, #0x7F000000
	str r1, [r4]

	ldr r4, =HEX_MEMORY4_5
	ldr r1, [r4]
	tst r0, #HEX4
	orrne r1, r1, #0x7F
	tst r0, #HEX5
	orrne r1, r1, #0x7F00
	str r1, [r4]
	pop {r4, pc}


HEX_clear_ASM:
	push {r4, lr}
	ldr r4, =HEX_MEMORY0_3
	ldr r1, [r4]
	tst r0, #HEX0
	bicne r1, r1, #0x7F
	tst r0, #HEX1
	bicne r1, r1, #0x7F00
	tst r0, #HEX2
	bicne r1, r1, #0x7F0000
	tst r0, #HEX3
	bicne r1, r1, #0x7F000000
	str r1, [r4]

	ldr r4, =HEX_MEMORY4_5
	ldr r1, [r4]
	tst r0, #HEX4
	bicne r1, r1, #0x7F
	tst r0, #HEX5
	bicne r1, r1, #0x7F00
	str r1, [r4]
	pop {r4, pc}


hex_to_mask:
	mov r1, r0
	teq r1, #0
	moveq r0, #0x3F  @%011 1111
	beq ln_hex_to_mask_ret
	teq r1, #1
	moveq r0, #0x06  @%000 0110
	beq ln_hex_to_mask_ret
	teq r1, #2
	moveq r0, #0x5B  @%101 1011
	beq ln_hex_to_mask_ret
	teq r1, #3
	moveq r0, #0x4F  @%100 1111
	beq ln_hex_to_mask_ret
	teq r1, #4
	moveq r0, #0x66  @%110 0110
	beq ln_hex_to_mask_ret
	teq r1, #5
	moveq r0, #0x6D  @%110 1101
	beq ln_hex_to_mask_ret
	teq r1, #6
	moveq r0, #0x7D  @%111 1101
	beq ln_hex_to_mask_ret
	teq r1, #7
	moveq r0, #0x07  @%000 0111
	beq ln_hex_to_mask_ret
	teq r1, #8
	moveq r0, #0x7F  @%111 1111
	beq ln_hex_to_mask_ret
	teq r1, #9
	moveq r0, #0x6F  @%110 1111
	beq ln_hex_to_mask_ret
	teq r1, #0x0A
	moveq r0, #0x77  @%111 0111
	beq ln_hex_to_mask_ret
	teq r1, #0x0B
	moveq r0, #0x7C  @%111 1100
	beq ln_hex_to_mask_ret
	teq r1, #0x0C
	moveq r0, #0x39  @%011 1001
	beq ln_hex_to_mask_ret
	teq r1, #0x0D
	moveq r0, #0x5E  @%101 1110
	beq ln_hex_to_mask_ret
	teq r1, #0x0E
	moveq r0, #0x79  @%111 1001
	beq ln_hex_to_mask_ret
	teq r1, #0x0F
	moveq r0, #0x71  @%111 0001
	beq ln_hex_to_mask_ret
	mov r0, #0
ln_hex_to_mask_ret:
	bx lr


HEX_write_ASM:
	push {r4, r5, r6, lr}
	mov r5, r0
	mov r0, r1
	bl hex_to_mask
	mov r6, r0  @display_mask
	mov r0, r5
	mov r5, r6  @display_mask

	ldr r4, =HEX_MEMORY0_3
	ldr r1, [r4]

	tst r0, #HEX0
	bicne r1, r1, #0xFF
	orrne r1, r1, r5
	strne r1, [r4]
	movne r0, #HEX0
	bne ln_HEX_write_ASM_ret

	tst r0, #HEX1
	bicne r1, r1, #0xFF00
	orrne r1, r1, r5, lsl #8
	strne r1, [r4]
	movne r0, #HEX1
	bne ln_HEX_write_ASM_ret

	tst r0, #HEX2
	bicne r1, r1, #0xFF0000
	orrne r1, r1, r5, lsl #16
	strne r1, [r4]
	movne r0, #HEX2
	bne ln_HEX_write_ASM_ret

	tst r0, #HEX3
	bicne r1, r1, #0xFF000000
	orrne r1, r1, r5, lsl #24
	strne r1, [r4]
	movne r0, #HEX3
	bne ln_HEX_write_ASM_ret

	ldr r4, =HEX_MEMORY4_5
	ldr r1, [r4]

	tst r0, #HEX4
	bicne r1, r1, #0xFF
	orrne r1, r1, r5
	strne r1, [r4]
	movne r0, #HEX4
	bne ln_HEX_write_ASM_ret

	tst r0, #HEX5
	bicne r1, r1, #0xFF00
	orrne r1, r1, r5, lsl #8
	strne r1, [r4]
	movne r0, #HEX5
	bne ln_HEX_write_ASM_ret

	mov r0, #0
ln_HEX_write_ASM_ret:
	pop {r4, r5, r6, pc}


read_PB_data_ASM:
	ldr r1, =PUSH_DATA_MEMORY
	ldr r0, [r1]
	and r0, r0, #0x0F
	bx lr


read_PB_edgecp_ASM:
	ldr r1, =PUSH_EDGE_MEMORY
	ldr r0, [r1]
	and r0, r0, #0x0F
	bx lr


PB_clear_edgecp_ASM:
	ldr r1, =PUSH_EDGE_MEMORY
	ldr r0, [r1]
	str r0, [r1]
	and r0, r0, #0x0F
	bx lr


enable_PB_INT_ASM:
	ldr r1, =PUSH_INT_MEMORY
	ldr r2, [r1]
	and r0, r0, #0x0F
	orr r0, r0, r2
	str r0, [r1]
	bx lr


disable_PB_INT_ASM:
	ldr r1, =PUSH_INT_MEMORY
	ldr r2, [r1]
	and r0, r0, #0x0F
	bic r0, r2, r0
	str r0, [r1]
	bx lr


ARM_TIM_config_ASM:
	ldr r2, =TIMER_INIT_MEMORY
	str r0, [r2]
	ldr r2, =TIMER_CTRL_MEMORY
	ldr r3, =0xFF07
	and r1, r1, r3
	str r1, [r2]
	bx lr


ARM_TIM_read_INT_ASM:
	ldr r2, =TIMER_STAT_MEMORY
	ldr r0, [r2]
	and r0, r0, #0x01
	bx lr


ARM_TIM_clear_INT_ASM:
	ldr r2, =TIMER_STAT_MEMORY
	ldr r0, [r2]
	tst r0, #0x01
	strne r0, [r2]
	bx lr
