.section .data

// Sider Switches Driver
// returns the state of slider switches in R0
.equ SW_MEMORY, 0xFF200040

// LEDs Driver
// writes the state of LEDs (On/Off state) in R0 to the LEDs memory location
.equ LED_MEMORY, 0xFF200000


.section .text
.global _start


_start:
main:
	bl read_slider_switches_ASM
	bl write_LEDs_ASM
	b main

endless_loop:
	b endless_loop


read_slider_switches_ASM:
	LDR R1, =SW_MEMORY
	LDR R0, [R1]
	BX  LR


write_LEDs_ASM:
	LDR R1, =LED_MEMORY
	STR R0, [R1]
	BX  LR

