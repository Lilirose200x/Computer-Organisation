.global	_start
_start:

MOV R1, #0  @ y = 0

Y_LOOP:
LDR R2, =ih @ load address of ih to r2
LDR R2, [R2] 
CMP R1, R2
BEQ END_OF_PROGRAM

@ x loop
MOV R3, #0  

X_LOOP:
LDR R2, =iw 
LDR R2, [R2] 
CMP R3, R2
BEQ END_OF_X_LOOP
MOV R4, #0  @ initialize sum to 0

@ i loop
MOV R5, #0  @ i = 0
I_LOOP:
LDR R2, =kw 
LDR R2, [R2] 
CMP R5, R2
BEQ END_OF_I_LOOP

@ j loop
MOV R6, #0  @ j = 0
J_LOOP:
LDR R2, =kh 
LDR R2, [R2] 
CMP R6, R2
BEQ END_OF_J_LOOP

@ inside j loop
ADD R8, R3, R6 @ temp1 = x+j, r3 is x, r6 is j
SUB R8, R8, #2 @ temp1 = temp1 - 2, ksw is 2 here
ADD R9, R1, R5 @ temp2 = y+i, r1 is y, r5 is i
SUB R9, R9, #2 @ temp2 = temp2 -2, khw is 2 here

CMP R8, #0 @ compare temp1 and 0
BGE LOGIC1_TRUE 
B INCREMENT_J

LOGIC1_TRUE:
CMP R8, #9 @ compare temp1 and 9
BLE LOGIC2_TRUE 
B INCREMENT_J

LOGIC2_TRUE:
CMP R9, #0 @ compare temp2 and 0
BGE LOGIC3_TRUE 
B INCREMENT_J

LOGIC3_TRUE:
CMP R9, #9 @ compare temp2 and 9
BLE ALL_LOGIC_TRUE 
B INCREMENT_J

ALL_LOGIC_TRUE:
@ following code to fetch value of kx[j][i]
LDR R2, =Kernel_row0 
MOV R10, #5 
MUL R10, R6, R10 
ADD R10, R10, R5 
LSL R10, R10, #2 
ADD R10, R2, R10 
LDR R10, [R10] 

@ following code to fetech value of fx[temp1][temp2]
LDR R2, =row0 
MOV R0, #10 
MUL R0, R8, R0 
ADD R0, R0, R9 
LSL R0, R0, #2 
ADD R0, R2, R0 
LDR R0, [R0] 

MUL R10, R10, R0 
ADD R4, R4, R10 @ sum = sum + kx[j][i] * fx [temp1][temp2]

INCREMENT_J:
ADD R6, R6, #1 
B J_LOOP

END_OF_J_LOOP:
ADD R5, R5, #1 
B I_LOOP

END_OF_I_LOOP:
@ write sum to memory, gx[x][y] = sum
LDR R0, =result @ load base address to r0
MOV R10, #10 
MUL R10, R3, R10
ADD R10, R10, R1 
LSL R10, R10, #2 
ADD R0, R0, R10 
STR R4, [R0] @ write into memory location of gx[x][y]

ADD R3, R3, #1 @ x++
B X_LOOP

END_OF_X_LOOP:
ADD R1, R1, #1 @ y++
B Y_LOOP

END_OF_PROGRAM:
LDR R1, =result
LDR R0, [R1]
ADD R1, R1, #4
LDR R1, [R1]
THE_END:
B THE_END

.data
@		set 4 byte alignment
.balign	4
result:		.skip 400 @ because output result has 10 by 10 elements, 10*10*4 = 400

row0: .4byte 183, 207, 128, 30, 109, 0, 14, 52, 15, 210
row1: .4byte 228, 76, 48, 82, 179, 194, 22, 168, 58, 116
row2: .4byte 228, 217, 180, 181, 243, 65, 24, 127, 216, 118
row3: .4byte 64, 210, 138, 104, 80, 137, 212, 196, 150, 139
row4: .4byte 155, 154, 36, 254, 218, 65, 3, 11, 91, 95
row5: .4byte 219, 10, 45, 193, 204, 196, 25, 177, 188, 170
row6: .4byte 189, 241, 102, 237, 251, 223, 10, 24, 171, 71
row7: .4byte 0, 4, 81, 158, 59, 232, 155, 217, 181, 19
row8: .4byte 25, 12, 80, 244, 227, 101, 250, 103, 68, 46
row9: .4byte 136, 152, 144, 2, 97, 250, 47, 58, 214, 51


Kernel_row0: .4byte 1,   1,  0,  -1,  -1
Kernel_row1: .4byte 0,   1,  0,  -1,   0
Kernel_row2: .4byte 0,   0,  1,   0,   0
Kernel_row3: .4byte 0,  -1,  0,   1,   0
Kernel_row4: .4byte -1, -1,  0,   1,   1

iw: .4byte 10
ih: .4byte 10
kw: .4byte 5
kh: .4byte 5
ksw: .4byte 2
khw: .4byte 2