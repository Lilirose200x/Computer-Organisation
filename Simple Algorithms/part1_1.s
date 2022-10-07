.global	_start
_start:

main:
    MOV R0,#0   @ initialize index veriable
    MOV R8,#1   @ load n parameter to r8, n should larger than or equal to 2

loop:
    LDR R1, =a  @ load base address of a to r1
    
    MOV	R3, #0  
    LSL	R2, R0, #2   
    ADD	R2, R1, R2   
    STR	R3, [R2]    
    ADD	R0, R0, #1  
   
    MOV	R3, #1  
    LSL	R2, R0, #2  
    ADD	R2, R1, R2   
    STR	R3, [R2]   
	
    ADD	R0, R0, #1  @ increment index
    MOV	R3, #2  

fill_fib:
    CMP	R3, R8  @ compare,  i == n?
    BGT	return_last_element 
    @	load value of f[i - 1] to r5
    SUB	R6, R0, #1  
    LSL	R2, R6, #2   
    ADD	R2, R1, R2   
    LDR	R5, [R2]    
    @	load value of f[i - 2] to r4
    SUB	R6, R0, #2  
    LSL	R2, R6, #2   
    ADD	R2, R1, R2   
    LDR	R4, [R2]    
    @	r7 = f[i - 1] + f[i - 2]
    ADD	R7, R4, R5
    LSL	R2, R0, #2   
    ADD	R2, R1, R2   
    STR	R7, [R2]    
    ADD	R0, R0, #1  
    ADD R3, R3, #1  @ i++
    B fill_fib

return_last_element:
    MOV	R0,R7
	
END:
    B END

.data
a:		.skip 20 @ because array has 5 elements, 4*5 = 20	