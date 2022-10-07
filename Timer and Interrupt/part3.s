.section .data
PB_int_flag:
    .word 0x0
tim_int_flag:
    .word 0x0
tim_is_start:
    .word 0x0
tim_data_vals:
    .word 0, 0, 0, 0, 0, 0


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



.section .vectors, "ax"
B _start
B SERVICE_UND       // undefined instruction vector
B SERVICE_SVC       // software interrupt vector
B SERVICE_ABT_INST  // aborted prefetch vector
B SERVICE_ABT_DATA  // aborted data vector
.word 0             // unused vector
B SERVICE_IRQ       // IRQ interrupt vector
B SERVICE_FIQ       // FIQ interrupt vector



.section .text
.global _start


_start:
	b GIC_IRQ_start
ln_GIC_IRQ_start_retaddr:
	@b ln_GIC_IRQ_start_retaddr

 	@All r4-r15 must be save
	//mov r8, #0   @is_start = tim_is_start
	//mov r9, #0   @edge
	//
	//mov r4, #0   @min_L
	//mov r5, #0   @sec_L
	//mov r6, #0   @10ms_sec_L
	//mov r10, #0  @min_H
	//mov r11, #0  @sec_H
	//mov r12, #0  @10ms_sec_H

 ln_init:
 	mov r0, #HEX_ALL
 	bl HEX_clear_ASM
 
 	mov r0, #PB_ALL
 	bl enable_PB_INT_ASM
 
 	mov r0, #PB_ALL
 	bl PB_clear_edgecp_ASM

endless_loop:
	//bl read_PB_edgecp_ASM
 	//mov r9, r0  @edge
	//r9 is always 0
	b endless_loop
 

KEY_ISR_INTERNAL:
	push {r7, r8, r9, lr}
	mov r9, r1
	ldr r7, =tim_is_start
	ldr r8, [r7]

 	bl read_PB_data_ASM
 	tst r0, r9  @old status before pressed
 	bne ln_edgecp_data_released

	teq r9, #PB0
	beq ln_edgecp_data_pressed_start
	teq r9, #PB1
	beq ln_edgecp_data_pressed_stop
	teq r9, #PB2
	beq ln_edgecp_data_pressed_reset
	b ln_edgecp_data_released
 
 ln_edgecp_data_pressed_start:
	teq r8, #0
	bne ln_edgecp_data_released
	mov r8, #1
	str r8, [r7]
	bl init_10ms_timer_ASM_with_interrupt
 	b ln_edgecp_data_released

ln_edgecp_data_pressed_stop:
	teq r8, #0
	beq ln_edgecp_data_released
	mov r8, #0
	str r8, [r7]
	bl stop_timer_ASM
	b ln_edgecp_data_released

ln_edgecp_data_pressed_reset:
	ldr r7, =tim_data_vals
	mov r0, #0
	str r0, [r7]
	str r0, [r7, #0x4]
	str r0, [r7, #0x8]
	str r0, [r7, #0xC]
	str r0, [r7, #0x10]
	str r0, [r7, #0x14]
	bl update_hex_time_ASM
	b ln_edgecp_data_released
 
 ln_edgecp_data_released:
 	//mov r0, r9
 	//bl PB_clear_edgecp_ASM
 	pop {r7, r8, r9, pc}


GIC_IRQ_start:
    /* Set up stack pointers for IRQ and SVC processor modes */
    MOV        R1, #0b11010010      // interrupts masked, MODE = IRQ
    MSR        CPSR_c, R1           // change to IRQ mode
    LDR        SP, =0xFFFFFFFF - 3  // set IRQ stack to A9 onchip memory
    /* Change to SVC (supervisor) mode with interrupts disabled */
    MOV        R1, #0b11010011      // interrupts masked, MODE = SVC
    MSR        CPSR, R1             // change to supervisor mode
    LDR        SP, =0x3FFFFFFF - 3  // set SVC stack to top of DDR3 memory
    BL     CONFIG_GIC           // configure the ARM GIC
    // To DO: write to the pushbutton KEY interrupt mask register
    // Or, you can call enable_PB_INT_ASM subroutine from previous task
    // to enable interrupt for ARM A9 private timer, use ARM_TIM_config_ASM subroutine
    LDR        R0, =0xFF200050      // pushbutton KEY base address
    MOV        R1, #0xF             // set interrupt mask bits
    STR        R1, [R0, #0x8]       // interrupt mask register (base + 8)
    // enable IRQ interrupts in the processor
    MOV        R0, #0b01010011      // IRQ unmasked, MODE = SVC
    MSR        CPSR_c, R0
    b ln_GIC_IRQ_start_retaddr
IDLE:
    B IDLE // This is where you write your objective task



/*--- Undefined instructions ---------------------------------------- */
SERVICE_UND:
    B SERVICE_UND
/*--- Software interrupts ------------------------------------------- */
SERVICE_SVC:
    B SERVICE_SVC
/*--- Aborted data reads -------------------------------------------- */
SERVICE_ABT_DATA:
    B SERVICE_ABT_DATA
/*--- Aborted instruction fetch ------------------------------------- */
SERVICE_ABT_INST:
    B SERVICE_ABT_INST
/*--- IRQ ----------------------------------------------------------- */
SERVICE_IRQ:
    PUSH {R0-R7, LR}
/* Read the ICCIAR from the CPU Interface */
    LDR R4, =0xFFFEC100
    LDR R5, [R4, #0x0C] // read from ICCIAR
/* To Do: Check which interrupt has occurred (check interrupt IDs)
   Then call the corresponding ISR
   If the ID is not recognized, branch to UNEXPECTED
   See the assembly example provided in the De1-SoC Computer_Manual on page 46 */
 Timer_check:
    cmp r5, #29
    bne Pushbutton_check
    bl ARM_TIM_ISR
    b EXIT_IRQ
 Pushbutton_check:
    CMP R5, #73
UNEXPECTED:
    BNE UNEXPECTED      // if not recognized, stop here
    BL KEY_ISR
EXIT_IRQ:
/* Write to the End of Interrupt Register (ICCEOIR) */
    STR R5, [R4, #0x10] // write to ICCEOIR
    POP {R0-R7, LR}
    SUBS PC, LR, #4
/*--- FIQ ----------------------------------------------------------- */
SERVICE_FIQ:
    B SERVICE_FIQ



CONFIG_GIC:
    PUSH {LR}
/* To configure the FPGA KEYS interrupt (ID 73):
* 1. set the target to cpu0 in the ICDIPTRn register
* 2. enable the interrupt in the ICDISERn register */
/* CONFIG_INTERRUPT (int_ID (R0), CPU_target (R1)); */
/* To Do: you can configure different interrupts
   by passing their IDs to R0 and repeating the next 3 lines */
    MOV R0, #73            // KEY port (Interrupt ID = 73)
    MOV R1, #1             // this field is a bit-mask; bit 0 targets cpu0
    BL CONFIG_INTERRUPT
    mov r0, #29            // ARM A9 private timer (ID: 29)
    mov r1, #1
    bl CONFIG_INTERRUPT
/* configure the GIC CPU Interface */
    LDR R0, =0xFFFEC100    // base address of CPU Interface
/* Set Interrupt Priority Mask Register (ICCPMR) */
    LDR R1, =0xFFFF        // enable interrupts of all priorities levels
    STR R1, [R0, #0x04]
/* Set the enable bit in the CPU Interface Control Register (ICCICR).
* This allows interrupts to be forwarded to the CPU(s) */
    MOV R1, #1
    STR R1, [R0]
/* Set the enable bit in the Distributor Control Register (ICDDCR).
* This enables forwarding of interrupts to the CPU Interface(s) */
    LDR R0, =0xFFFED000
    STR R1, [R0]
    POP {PC}


/*
* Configure registers in the GIC for an individual Interrupt ID
* We configure only the Interrupt Set Enable Registers (ICDISERn) and
* Interrupt Processor Target Registers (ICDIPTRn). The default (reset)
* values are used for other registers in the GIC
* Arguments: R0 = Interrupt ID, N
* R1 = CPU target
*/
CONFIG_INTERRUPT:
    PUSH {R4-R5, LR}
/* Configure Interrupt Set-Enable Registers (ICDISERn).
* reg_offset = (integer_div(N / 32) * 4
* value = 1 << (N mod 32) */
    LSR R4, R0, #3    // calculate reg_offset
    BIC R4, R4, #3    // R4 = reg_offset
    LDR R2, =0xFFFED100
    ADD R4, R2, R4    // R4 = address of ICDISER
    AND R2, R0, #0x1F // N mod 32
    MOV R5, #1        // enable
    LSL R2, R5, R2    // R2 = value
/* Using the register address in R4 and the value in R2 set the
* correct bit in the GIC register */
    LDR R3, [R4]      // read current register value
    ORR R3, R3, R2    // set the enable bit
    STR R3, [R4]      // store the new register value
/* Configure Interrupt Processor Targets Register (ICDIPTRn)
* reg_offset = integer_div(N / 4) * 4
* index = N mod 4 */
    BIC R4, R0, #3    // R4 = reg_offset
    LDR R2, =0xFFFED800
    ADD R4, R2, R4    // R4 = word address of ICDIPTR
    AND R2, R0, #0x3  // N mod 4
    ADD R4, R2, R4    // R4 = byte address in ICDIPTR
/* Using register address in R4 and the value in R2 write to
* (only) the appropriate byte */
    STRB R1, [R4]
    POP {R4-R5, PC}


KEY_ISR:
    push {lr}
    LDR R0, =0xFF200050    // base address of pushbutton KEY port
    LDR R1, [R0, #0xC]     // read edge capture register
    MOV R2, #0xF
    STR R2, [R0, #0xC]     // clear the interrupt
    LDR R0, =0xFF200020    // based address of HEX display
    ldr r2, =PB_int_flag
    str r1, [r2]
    bl KEY_ISR_INTERNAL
// CHECK_KEY0:
//     MOV R3, #0x1
//     ANDS R3, R3, R1        // check for KEY0
//     BEQ CHECK_KEY1
//     MOV R2, #0b00111111
//     STR R2, [R0]           // display "0"
//     B END_KEY_ISR
// CHECK_KEY1:
//     MOV R3, #0x2
//     ANDS R3, R3, R1        // check for KEY1
//     BEQ CHECK_KEY2
//     MOV R2, #0b00000110
//     STR R2, [R0]           // display "1"
//     B END_KEY_ISR
// CHECK_KEY2:
//     MOV R3, #0x4
//     ANDS R3, R3, R1        // check for KEY2
//     BEQ IS_KEY3
//     MOV R2, #0b01011011
//     STR R2, [R0]           // display "2"
//     B END_KEY_ISR
// IS_KEY3:
//     MOV R2, #0b01001111
//     STR R2, [R0]           // display "3"
END_KEY_ISR:
    pop {lr}
    BX LR


ARM_TIM_ISR:
	push {lr}
	ldr r0, =1
	ldr r1, =tim_int_flag
	str r0, [r1]
	bl update_check_timer_ASM
	ldr r0, =0
	ldr r1, =tim_int_flag
	str r0, [r1]
	pop {pc}


update_hex_time_ASM:
	push {r4, lr}
	ldr r4, =tim_data_vals

	mov r0, #HEX0
	ldr r1, [r4]
	bl HEX_write_ASM

	mov r0, #HEX1
	ldr r1, [r4, #0x4]
	bl HEX_write_ASM

	mov r0, #HEX2
	ldr r1, [r4, #0x8]
	bl HEX_write_ASM

	mov r0, #HEX3
	ldr r1, [r4, #0xC]
	bl HEX_write_ASM

	mov r0, #HEX4
	ldr r1, [r4, #0x10]
	bl HEX_write_ASM

	mov r0, #HEX5
	ldr r1, [r4, #0x14]
	bl HEX_write_ASM

	pop {r4, pc}


update_check_timer_ASM:
	push {r4, lr}
	ldr r0, =tim_is_start
	ldr r0, [r0]
	teq r0, #0
	beq ln_update_check_timer_ASM_ret

	//bl ARM_TIM_read_INT_ASM
	//tst r0, #0x01
	//beq ln_update_check_timer_ASM_ret

	bl ARM_TIM_clear_INT_ASM
	
ln_update_check_timer_ASM_inc_start:
	ldr r4, =tim_data_vals

	ldr r0, [r4]
	add r0, r0, #1
	cmp r0, #10
	blt ln_update_check_timer_ASM_inc_end
	mov r0, #0
	str r0, [r4], #4

	ldr r0, [r4]
	add r0, r0, #1
	cmp r0, #10
	blt ln_update_check_timer_ASM_inc_end
	mov r0, #0
	str r0, [r4], #4

	ldr r0, [r4]
	add r0, r0, #1
	cmp r0, #10
	blt ln_update_check_timer_ASM_inc_end
	mov r0, #0
	str r0, [r4], #4

	ldr r0, [r4]
	add r0, r0, #1
	cmp r0, #6
	blt ln_update_check_timer_ASM_inc_end
	mov r0, #0
	str r0, [r4], #4

	ldr r0, [r4]
	add r0, r0, #1
	cmp r0, #10
	blt ln_update_check_timer_ASM_inc_end
	mov r0, #0
	str r0, [r4], #4

	ldr r0, [r4]
	add r0, r0, #1

ln_update_check_timer_ASM_inc_end:
	str r0, [r4]
	bl update_hex_time_ASM
	//bl init_10ms_timer_ASM_with_interrupt

ln_update_check_timer_ASM_ret:
	pop {r4, pc}


init_10ms_timer_ASM:
	push {lr}
	ldr r0, =10000
	ldr r1, =TIMER_FREQ
	sub r1, r1, #1
	lsl r1, r1, #8
	orr r1, r1, #0x01
	bl ARM_TIM_config_ASM
	bl ARM_TIM_clear_INT_ASM
	pop {pc}


init_10ms_timer_ASM_with_interrupt:
	push {lr}
	ldr r0, =10000
	ldr r1, =TIMER_FREQ
	sub r1, r1, #1
	lsl r1, r1, #8
	orr r1, r1, #0x07
	bl ARM_TIM_config_ASM
	bl ARM_TIM_clear_INT_ASM
	pop {pc}


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


stop_timer_ASM:
	ldr r1, =TIMER_CTRL_MEMORY
	ldr r0, [r1]
	bic r0, r0, #0x01
	str r0, [r1]
	bx lr


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
